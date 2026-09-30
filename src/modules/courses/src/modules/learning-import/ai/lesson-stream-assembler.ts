import { GeneratedLessonOutline } from './lesson-generation.types';
import {
  ILessonKeypoint,
  ILessonSection,
} from '../interface/learning-import.interface';

/**
 * Incremental reader for the STREAMED_LESSON_RESPONSE_SCHEMA payload.
 *
 * The provider streams one JSON document in schema order (title, description,
 * keypointPlan, keypoints[]), and the whole point of streaming it is to act on
 * parts before the document is finished: the outline commits the lesson and
 * completes the import job; each keypoint object, the moment it closes, is
 * appended and dubbed. This class is that "moment it closes" detector.
 *
 * It does NOT parse JSON incrementally in the general case — it scans the
 * byte stream for structural boundaries (tracking string/escape state and
 * bracket depth, the only context-free parts of JSON) and, at each interesting
 * boundary, REPAIRS the buffer into a complete document (close the open
 * string, then the open brackets) and hands it to `JSON.parse`. Repair-and-
 * parse costs a full parse per event, but events are rare (one per keypoint)
 * and the document is a few tens of KB — simplicity wins over a streaming
 * parser dependency.
 *
 * Feed it chunks in arrival order via [push]; it returns whatever became
 * newly available. Chunks may split ANYWHERE — mid-escape, mid-surrogate-pair,
 * mid-key — the scanner state carries across pushes.
 */
export class LessonStreamAssembler {
  private buffer = '';

  // --- scanner state, carried across push() calls ---
  private inString = false;
  private escaped = false;
  /** Bracket stack of '{' / '[' as they open. */
  private readonly stack: string[] = [];
  /** Index into [buffer] of the next character to scan. */
  private cursor = 0;

  /** Depth of the root `keypoints` array while inside it, else null. */
  private keypointsDepth: number | null = null;
  /** True once the scanner has ENTERED the keypoints array. */
  private sawKeypointsArray = false;
  /** Root-level arrays opened so far — the 2nd one IS `keypoints` (schema shape). */
  private rootArraysSeen = 0;

  private outlineEmitted = false;
  private keypointsEmitted = 0;
  /** True while the scanner is inside the CURRENT keypoint's `sections` array. */
  private inSectionsArray = false;
  /** Sections already emitted for the keypoint currently being written. */
  private sectionsEmitted = 0;

  /**
   * Consume the next chunk of response text. Returns what it completed:
   * the outline (at most once, ever), each keypoint HEAD (title + takeaway,
   * available the moment its `sections` array opens), each section (card) as
   * its object closes, and each whole keypoint as ITS object closes — all in
   * stream order.
   *
   * The head and section events exist for TTS prefetch: narration for a card
   * can start synthesizing the moment the card's text exists, so by the time
   * the keypoint closes its clips are already made and "text done" and "audio
   * done" land together.
   */
  push(chunk: string): {
    outline?: GeneratedLessonOutline;
    heads: { index: number; title: string; takeaway: string }[];
    sections: { keypointIndex: number; section: ILessonSection }[];
    keypoints: { index: number; keypoint: ILessonKeypoint }[];
  } {
    this.buffer += chunk;

    const completed: { index: number; keypoint: ILessonKeypoint }[] = [];
    const heads: { index: number; title: string; takeaway: string }[] = [];
    const sections: { keypointIndex: number; section: ILessonSection }[] = [];
    let outline: GeneratedLessonOutline | undefined;

    while (this.cursor < this.buffer.length) {
      const char = this.buffer[this.cursor];
      this.cursor++;

      if (this.inString) {
        if (this.escaped) {
          this.escaped = false;
        } else if (char === '\\') {
          this.escaped = true;
        } else if (char === '"') {
          this.inString = false;
        }
        continue;
      }

      switch (char) {
        case '"':
          this.inString = true;
          break;
        case '{':
        case '[':
          this.stack.push(char);
          // The first ARRAY opened while the root `keypoints` key is pending…
          // — keys are strings, so instead of tokenizing keys, use the shape:
          // in this schema the ROOT object holds exactly two arrays,
          // `keypointPlan` (of strings) and `keypoints` (of objects). The
          // second array to open at depth 2 IS `keypoints`.
          if (char === '[' && this.stack.length === 2) {
            this.rootArraysSeen++;
            if (this.rootArraysSeen === 2) {
              this.sawKeypointsArray = true;
              this.keypointsDepth = this.stack.length;
              // Entering `keypoints` means `keypointPlan` closed: the outline
              // is complete. Emit it once.
              if (!this.outlineEmitted) {
                const parsed = this.repairAndParse();
                const emitted = this.toOutline(parsed);
                if (emitted) {
                  this.outlineEmitted = true;
                  outline = emitted;
                }
              }
            }
          }
          // A keypoint object's only ARRAY property is `sections` (title and
          // takeaway are strings), so an array opening one level inside a
          // keypoint object IS its sections — and per the keypoint schema's
          // property order, title and takeaway have both arrived by now: the
          // HEAD event that lets takeaway narration start synthesizing early.
          if (
            char === '[' &&
            this.keypointsDepth !== null &&
            this.stack.length === this.keypointsDepth + 2
          ) {
            this.inSectionsArray = true;
            const keypoint = this.toKeypoints(this.repairAndParse())[
              this.keypointsEmitted
            ];
            if (keypoint) {
              heads.push({
                index: this.keypointsEmitted,
                title: keypoint.title ?? '',
                takeaway: keypoint.takeaway ?? '',
              });
            }
          }
          break;
        case '}':
        case ']': {
          this.stack.pop();
          // A SECTION (one card) closes when depth returns to the sections
          // array's level. Its text is final: narration can start now.
          if (
            char === '}' &&
            this.inSectionsArray &&
            this.keypointsDepth !== null &&
            this.stack.length === this.keypointsDepth + 2
          ) {
            const keypoint = this.toKeypoints(this.repairAndParse())[
              this.keypointsEmitted
            ];
            const section = keypoint?.sections?.[this.sectionsEmitted];
            if (section) {
              sections.push({
                keypointIndex: this.keypointsEmitted,
                section,
              });
              this.sectionsEmitted++;
            }
          }
          if (
            char === ']' &&
            this.inSectionsArray &&
            this.keypointsDepth !== null &&
            this.stack.length === this.keypointsDepth + 1
          ) {
            this.inSectionsArray = false;
          }
          // A keypoint object closes when depth returns to the keypoints
          // array's own level while we are inside that array.
          if (
            char === '}' &&
            this.sawKeypointsArray &&
            this.keypointsDepth !== null &&
            this.stack.length === this.keypointsDepth
          ) {
            const parsed = this.repairAndParse();
            const keypoints = this.toKeypoints(parsed);
            while (this.keypointsEmitted < keypoints.length) {
              completed.push({
                index: this.keypointsEmitted,
                keypoint: keypoints[this.keypointsEmitted],
              });
              this.keypointsEmitted++;
            }
            this.sectionsEmitted = 0;
          }
          // The keypoints array itself closing ends the interesting region.
          if (
            char === ']' &&
            this.keypointsDepth !== null &&
            this.stack.length < this.keypointsDepth
          ) {
            this.keypointsDepth = null;
          }
          break;
        }
        default:
          break;
      }
    }

    return { outline, heads, sections, keypoints: completed };
  }

  /**
   * Everything that has FULLY arrived, best effort — what a caller falls back
   * on when the stream dies: the emitted prefix is already committed, and this
   * confirms there is nothing extra worth salvaging beyond it.
   */
  snapshotKeypoints(): ILessonKeypoint[] {
    return this.toKeypoints(this.repairAndParse()).slice(
      0,
      this.keypointsEmitted,
    );
  }

  /**
   * Close the open string and brackets, then parse. Returns null when even the
   * repaired text is not valid JSON — early chunks ("`{"ti`") are exactly that,
   * and callers treat null as "not yet".
   *
   * Repairs the SCANNED prefix (`buffer[0..cursor)`), never the whole buffer:
   * the string/stack state describes exactly where the scanner stands, and on
   * a large push the buffer runs arbitrarily far ahead of it — repairing that
   * tail with the scanner's closers produces garbage.
   */
  private repairAndParse(): unknown {
    let text = this.buffer.slice(0, this.cursor);
    if (this.inString) {
      // An open escape would swallow the closing quote being appended.
      if (this.escaped) text = text.slice(0, -1);
      text += '"';
    }
    for (let i = this.stack.length - 1; i >= 0; i--) {
      text += this.stack[i] === '{' ? '}' : ']';
    }

    try {
      return JSON.parse(text);
    } catch {
      return null;
    }
  }

  private toOutline(parsed: unknown): GeneratedLessonOutline | undefined {
    const doc = parsed as {
      title?: string;
      description?: string;
      keypointPlan?: unknown[];
    } | null;
    if (!doc || !Array.isArray(doc.keypointPlan)) return undefined;

    const keypointPlan = doc.keypointPlan
      .map(title => String(title ?? '').trim())
      .filter(title => title.length > 0);
    if (keypointPlan.length === 0) return undefined;

    return {
      title: doc.title ?? '',
      description: doc.description ?? '',
      keypointPlan,
    };
  }

  private toKeypoints(parsed: unknown): ILessonKeypoint[] {
    const doc = parsed as { keypoints?: ILessonKeypoint[] } | null;

    return Array.isArray(doc?.keypoints) ? doc.keypoints : [];
  }
}
