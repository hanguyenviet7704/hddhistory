import { GeneratedLesson } from './ai/lesson-generation.types';
import { LessonBlockType } from './enum/learning-import.enum';
import {
  ILessonBlock,
  ILessonKeypoint,
  ILessonSection,
} from './interface/learning-import.interface';
import { LEARNING_IMPORT_CONFIG } from './learning-import.config';

// Hiragana/katakana, CJK ideographs (incl. extension A) and Hangul syllables.
// Escapes rather than literal characters so the range survives any editor or
// terminal that is unsure about the encoding.
const CJK_CHAR = /[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uac00-\ud7af]/g;

/**
 * Words in a string, for languages that space them and for ones that don't.
 *
 * Chinese and Japanese write without spaces, so splitting on whitespace would
 * score a perfectly good 4000-character Japanese lesson as a handful of "words"
 * and reject it as too short. CJK characters are therefore counted individually
 * -- a rough but stable proxy -- and added to the whitespace-delimited count of
 * everything else.
 */
export function countWords(text: string): number {
  if (!text) return 0;

  const cjkCount = text.match(CJK_CHAR)?.length ?? 0;
  const rest = text.replace(CJK_CHAR, ' ').trim();
  const restCount = rest ? rest.split(/\s+/).length : 0;

  return cjkCount + restCount;
}

export function countSectionWords(sections: ILessonSection[]): number {
  return sections.reduce(
    (total, section) =>
      total +
      countWords(section.title) +
      section.blocks.reduce((sum, block) => sum + countWords(block.text), 0),
    0,
  );
}

export function countLessonWords(keypoints: ILessonKeypoint[]): number {
  return keypoints.reduce(
    (total, keypoint) =>
      total + countWords(keypoint.title) + countSectionWords(keypoint.sections),
    0,
  );
}

export function estimateReadingMinutes(wordCount: number): number {
  return Math.max(
    1,
    Math.round(wordCount / LEARNING_IMPORT_CONFIG.wordsReadPerMinute),
  );
}

/**
 * Give a line back its capital first letter.
 *
 * The model was asked for sentence case and delivered lowercase everything --
 * titles, card headings and body sentences alike ("thức ăn của bộ não"). The
 * prompt now says it in plainer words, but a prompt is a request, not a
 * contract, so the shape is enforced here as well.
 *
 * Three things it deliberately does NOT do:
 * - It never touches anything but the FIRST letter, so a mid-sentence term keeps
 *   whatever case the model chose.
 * - It steps over an emoji signpost, an opening quote or a `<b>` tag to find
 *   that letter, because those lead a card heading often enough that skipping
 *   them would leave the visible first letter lower anyway.
 * - It leaves a word that carries its own capital later alone (iPhone, eSIM,
 *   macOS): those spell themselves that way on purpose, and "IPhone" is a worse
 *   error than the one being fixed.
 *
 * A caseless script (Chinese, Japanese, Korean) passes through untouched --
 * `toUpperCase` is identity there, so the check simply finds nothing to do.
 */
export function capitalizeFirstLetter(value: string): string {
  const text = value ?? '';
  // Tags are MASKED rather than stripped so the index found below still points
  // at the same character in the original string.
  const masked = text.replace(/<[^>]*>/g, tag => ' '.repeat(tag.length));
  const at = masked.search(/\p{L}/u);
  if (at < 0) return text;

  const first = text[at];
  if (first !== first.toLowerCase()) return text;

  const word = masked.slice(at).split(/[\s.,;:!?()[\]"']/, 1)[0] ?? '';
  if (/\p{Lu}/u.test(word)) return text;

  return text.slice(0, at) + first.toUpperCase() + text.slice(at + 1);
}

export interface NormalizedLesson {
  title: string;
  description: string;
  keypoints: ILessonKeypoint[];
  wordCount: number;
  estimatedMinutes: number;
}

/**
 * Raised when the model returned something structurally fine but not usable as a
 * lesson -- almost always because the source had too little in it.
 *
 * Distinct from a provider failure: there is nothing to retry, and the honest
 * message is "tài liệu này quá ngắn" rather than "lỗi hệ thống".
 */
export class LessonTooShortError extends Error {
  constructor(readonly wordCount: number) {
    super(`Generated lesson has only ${wordCount} words`);
    this.name = 'LessonTooShortError';
  }
}

/**
 * Clean up what the model returned and decide whether it is good enough to keep.
 *
 * Generating something is not the same as generating something usable, and this
 * is the only place that difference is enforced. The checks are deliberately
 * few: drop empty blocks and sections (cosmetic, always safe), then apply ONE
 * substantive gate on total length. Policing section count or per-section
 * balance here would reject lessons a reader would be perfectly happy with --
 * the prompt asks for those, the floor below is what we actually insist on.
 *
 * `enforceWordFloor: false` is for the progressive pipeline (both phases). At
 * the FIRST BITE one keypoint on its own is legitimately under
 * `minAcceptedWordCount`; at COMPLETION the reader has been inside keypoint 1
 * for minutes, so "too short" is no longer a rejectable condition — the
 * completion service logs a loud warning instead of throwing (see
 * `UserLessonCompletionService.completeWith`). The throwing path below now
 * serves only single-call flows and the spec.
 */
export function normalizeGeneratedLesson(
  lesson: GeneratedLesson,
  options: { enforceWordFloor?: boolean } = {},
): NormalizedLesson {
  const { enforceWordFloor = true } = options;
  const keypoints: ILessonKeypoint[] = (lesson.keypoints ?? [])
    .map(keypoint => ({
      title: capitalizeFirstLetter((keypoint?.title ?? '').trim()),
      // Carried through the rebuild rather than spread: this map is what decides
      // the stored shape, and a field left out here is a field the reader never
      // sees no matter what the model wrote.
      takeaway:
        capitalizeFirstLetter((keypoint?.takeaway ?? '').trim()) || undefined,
      // Not model output — dealt from the admin pool before/after generation.
      // Must survive the completion phase re-normalizing an assembled lesson
      // whose earlier keypoints already carry their art.
      coverUrl: keypoint?.coverUrl || undefined,
      sections: normalizeSections(keypoint?.sections ?? []),
    }))
    // A keypoint with no readable card cannot be entered -- the reader would
    // open an empty deck -- so it is dropped rather than shown.
    .filter(keypoint => keypoint.sections.length > 0);

  const wordCount = countLessonWords(keypoints);

  if (enforceWordFloor && wordCount < LEARNING_IMPORT_CONFIG.minAcceptedWordCount) {
    throw new LessonTooShortError(wordCount);
  }

  return {
    // Fall back to the first keypoint's heading rather than shipping an
    // untitled lesson: the list screen has nothing else to draw.
    title:
      capitalizeFirstLetter((lesson.title ?? '').trim()) ||
      keypoints[0]?.title ||
      'Untitled',
    description: capitalizeFirstLetter((lesson.description ?? '').trim()),
    keypoints: titleKeypoints(keypoints),
    wordCount,
    estimatedMinutes: estimateReadingMinutes(wordCount),
  };
}

/**
 * Exported for the TTS prefetcher: a card streamed mid-generation must be
 * synthesized from EXACTLY the text that will be stored, or the prefetched
 * clip's script key never matches the stored keypoint's script and the
 * prefetch silently buys nothing.
 */
export function normalizeSections(sections: ILessonSection[]): ILessonSection[] {
  return sections
    .map(section => {
      const title = capitalizeFirstLetter((section?.title ?? '').trim());
      const blocks = (section?.blocks ?? [])
        .map(
          (block): ILessonBlock => ({
            type:
              block?.type === LessonBlockType.HEADING
                ? LessonBlockType.HEADING
                : LessonBlockType.PARAGRAPH,
            text: capitalizeFirstLetter((block?.text ?? '').trim()),
          }),
        )
        .filter(block => block.text.length > 0);

      return { title, blocks: dropLeadingTitleEcho(title, blocks) };
    })
    .filter(section => section.blocks.length > 0);
}

/**
 * Drop an opening block that just says the card's title again.
 *
 * The schema carries the heading in `title` and the prompt used to ALSO ask for
 * "a short heading block" first, so the model wrote it in both places and every
 * card rendered its heading twice -- in the app and in the admin panel, which
 * each draw the two fields independently. The prompt no longer asks for that; a
 * prompt is a request, and this is where it becomes a guarantee.
 *
 * Only the FIRST block, and only when it echoes the title: a genuine mid-card
 * heading (or a paragraph that happens to open with the same few words) is left
 * alone. The block's type is not part of the test — the echo has arrived as both
 * a heading and a paragraph.
 */
function dropLeadingTitleEcho(
  title: string,
  blocks: ILessonBlock[],
): ILessonBlock[] {
  if (!title || blocks.length === 0) return blocks;
  if (!isSameLine(title, blocks[0].text)) return blocks;

  return blocks.slice(1);
}

/** Same visible line, ignoring markup, emoji, punctuation and case. */
function isSameLine(left: string, right: string): boolean {
  const strip = (value: string) =>
    value
      .replace(/<[^>]*>/g, '')
      .replace(/[^\p{L}\p{N}]+/gu, ' ')
      .trim()
      .toLowerCase();

  const a = strip(left);

  return a.length > 0 && a === strip(right);
}

/**
 * Give every keypoint a name.
 *
 * The reader puts the keypoint title in the header of every card under it, so an
 * empty one leaves a blank strip across the whole sitting. Borrowing the first
 * card's heading is a better answer than "Phần 2" because the model already
 * wrote it about this exact content.
 */
function titleKeypoints(keypoints: ILessonKeypoint[]): ILessonKeypoint[] {
  return keypoints.map((keypoint, index) => ({
    ...keypoint,
    title:
      keypoint.title || keypoint.sections[0]?.title || `Part ${index + 1}`,
    // Dropped when blank rather than stored as '': the reader's recap card
    // checks for text, and an empty string is a promise of a flip it cannot
    // keep.
    takeaway: keypoint.takeaway?.trim() || undefined,
  }));
}

/**
 * Deal one image from an admin-curated pool, deterministically.
 *
 * Seeded by the lesson's JOB id (known before the lesson document exists, and
 * stored on the lesson as `jobId` so the completion phase reproduces the same
 * sequence) plus the keypoint's absolute index as `offset` — so one lesson's
 * keypoints walk the pool in order and neighbouring nodes differ whenever the
 * pool is big enough, while two lessons start from different places in it.
 *
 * Returns '' on an empty pool: the app's bundled placeholder is the fallback,
 * never a guess from here.
 */
export function pickPoolImage(
  pool: string[],
  seedText: string,
  offset = 0,
): string {
  const urls = (pool ?? []).filter(url => Boolean(url));
  if (urls.length === 0) return '';

  let hash = 0;
  for (const char of seedText ?? '') {
    hash = (hash * 31 + char.charCodeAt(0)) >>> 0;
  }

  return urls[(hash + offset) % urls.length];
}

/**
 * The quota window: the calendar week containing `now`, Monday to Monday.
 *
 * Monday rather than Sunday because that is the boundary the app states out loud
 * ("back to 5 tickets on Monday"), and Monday is the start of the week for every
 * locale HDDhistory ships bar one.
 *
 * Server time, like `monthWindow`, and that is a deliberate simplification: a
 * per-user timezone would mean the reset moment differs from the date the app
 * prints unless the client also localised it, and the cost of being a few hours
 * out on a refill nobody is watching is far lower than the cost of two clocks
 * that disagree. `getDay()` returns 0 for Sunday, which is the END of the week
 * here, hence the `|| 7`.
 */
export function weekWindow(now: Date): { from: Date; to: Date } {
  const isoDay = now.getDay() || 7;

  const from = new Date(
    now.getFullYear(),
    now.getMonth(),
    now.getDate() - (isoDay - 1),
    0,
    0,
    0,
    0,
  );
  const to = new Date(
    from.getFullYear(),
    from.getMonth(),
    from.getDate() + 7,
    0,
    0,
    0,
    0,
  );

  return { from, to };
}
