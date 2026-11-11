import {
  ILessonKeypoint,
  ILessonSection,
} from '../interface/learning-import.interface';

/**
 * The material handed to the generator, already resolved from whatever the user
 * gave us.
 *
 * A PDF stays BYTES rather than being turned into text first: the model reads
 * the document itself, which is what lets scanned pages and tables survive. A
 * YouTube video has no document to read, so it arrives as transcript text.
 */
export type ResolvedSource =
  | { kind: 'pdfBytes'; bytes: Buffer; fileName: string }
  | { kind: 'text'; text: string; title?: string }
  /**
   * A URL the PROVIDER fetches for itself, rather than one we download.
   *
   * This exists because of YouTube. Reading a transcript meant scraping the
   * watch page, and YouTube strips the caption list from responses it does not
   * trust -- from a datacenter IP the same video that shows 14 caption tracks on
   * a laptop shows none. Handing Gemini the URL sidesteps that entirely: Google
   * fetches from Google, our server's address never enters into it. It also
   * works on videos with no captions at all, because the model watches and
   * listens rather than reading a transcript.
   */
  | { kind: 'remoteUri'; uri: string; title?: string };

export interface LessonGenerationInput {
  source: ResolvedSource;
  outputLocale: string;
  targetWordCount: { min: number; max: number };
  targetKeypointCount: { min: number; max: number };
  targetCardsPerKeypoint: { min: number; max: number };
  targetWordsPerCard: { min: number; max: number };
  /** The takeaway, deliberately shorter than a theory card. */
  targetWordsPerShortCard: { min: number; max: number };
  /** The ceiling no card may cross, whatever its kind. */
  hardWordsPerCard: number;
}

/**
 * The whole lesson body, as either phase's output assembles into.
 *
 * Still the currency of `normalizeGeneratedLesson`: the opening contributes
 * `keypoints[0]`, the continuation the rest, and validation runs on this
 * assembled shape exactly as it did when one call produced it.
 */
export interface GeneratedLesson {
  title: string;
  description: string;
  keypoints: ILessonKeypoint[];
}

/**
 * The lesson's identity and committed table of contents — the first thing the
 * STREAMED generation emits, before any keypoint body exists.
 *
 * This is the moment the import job completes: the roadmap can be drawn from
 * these titles alone, and every keypoint after it arrives as its own event.
 */
export interface GeneratedLessonOutline {
  title: string;
  description: string;
  keypointPlan: string[];
}

export interface GenerationUsage {
  inputTokens: number;
  outputTokens: number;
}

/**
 * What a streamed generation calls back into as the response flows.
 *
 * `onOutline` fires exactly once, as soon as the plan is complete; `onKeypoint`
 * fires once per keypoint the moment its object closes in the stream, in plan
 * order. Handlers are awaited — a slow handler backpressures the parse, not the
 * other way round — so keep them quick and push slow work (dubbing) elsewhere.
 */
export interface LessonStreamHandlers {
  onOutline: (outline: GeneratedLessonOutline) => void | Promise<void>;
  onKeypoint: (keypoint: ILessonKeypoint, index: number) => void | Promise<void>;

  /**
   * A keypoint's title + takeaway became final (its sections array opened).
   * Optional; exists so takeaway narration can start synthesizing early.
   */
  onKeypointHead?: (head: {
    index: number;
    title: string;
    takeaway: string;
  }) => void | Promise<void>;

  /**
   * One CARD's text became final, mid-keypoint. Optional; exists so the card's
   * narration can start synthesizing while the rest of its keypoint is still
   * being written.
   */
  onSection?: (event: {
    keypointIndex: number;
    section: ILessonSection;
  }) => void | Promise<void>;
}

/**
 * The stream's final tally. `keypoints` is everything that fully arrived —
 * on a clean stream that is the whole plan, on a broken one the prefix the
 * caller already saw via `onKeypoint` (the continuation fallback writes the
 * rest).
 */
export interface LessonStreamResult {
  keypoints: ILessonKeypoint[];
  usage: GenerationUsage;
}

/**
 * What the continuation phase is given on top of the ordinary input: the
 * decisions phase 1 already made. The source rides along UNCHANGED — the model
 * re-reads it, because the remaining keypoints must come from the material,
 * not from a summary of a summary.
 */
export interface LessonContinuationInput extends LessonGenerationInput {
  lessonTitle: string;
  /** The full outline phase 1 committed to, in order. */
  keypointPlan: string[];
  /** Every keypoint that already exists, in order — keypoint 0 at minimum. */
  writtenKeypoints: ILessonKeypoint[];
}

export interface LessonContinuationResult {
  /** The keypoints that were still missing, in plan order. */
  keypoints: ILessonKeypoint[];
  usage: GenerationUsage;
}

/**
 * The whole surface the rest of the feature knows about the AI provider.
 *
 * Kept this narrow on purpose. Swapping Gemini for another provider -- or for a
 * self-hosted model -- should be a new implementation of these two methods, with
 * the job runner, the schemas, the app and the admin all untouched. Nothing
 * above this line may mention a vendor.
 *
 * Two methods (plans/260813-progressive-import, streaming addendum):
 * `generateLessonStream` is the whole lesson in ONE call — the source is read
 * once, the outline surfaces within seconds of that read, and keypoints drip
 * out as they are written. `generateContinuation` is the batch FALLBACK the
 * sweep uses when a stream died partway: same lesson, picked up from the last
 * keypoint that fully arrived.
 */
export abstract class LessonGenerator {
  abstract generateLessonStream(
    input: LessonGenerationInput,
    handlers: LessonStreamHandlers,
  ): Promise<LessonStreamResult>;

  abstract generateContinuation(
    input: LessonContinuationInput,
  ): Promise<LessonContinuationResult>;
}

/**
 * Thrown by a generator when the provider itself failed.
 *
 * Carries `timedOut` so the runner can tell AI_TIMEOUT from AI_FAILED without
 * matching on message strings.
 */
export class LessonGenerationError extends Error {
  constructor(
    message: string,
    readonly timedOut = false,
  ) {
    super(message);
    this.name = 'LessonGenerationError';
  }
}
