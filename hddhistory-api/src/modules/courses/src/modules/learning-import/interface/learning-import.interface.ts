import { ImportSourceType, LessonBlockType } from '../enum/learning-import.enum';

/**
 * Where a lesson came from, stored on both the job and the lesson it produced.
 *
 * Duplicated on purpose: the job is a progress record that can be pruned, while
 * the lesson has to keep showing "PDF: Giáo trình A2.pdf" on its card for as long
 * as the user keeps it.
 */
export interface IImportSource {
  type: ImportSourceType;

  // PDF only. `fileKey` is the R2 object key from the upload endpoint;
  // `fileName` is the user's original filename, kept purely for display.
  fileKey?: string;
  fileName?: string;
  pageCount?: number;

  // YouTube only.
  url?: string;
  videoTitle?: string;
  videoDurationSeconds?: number;
}

export interface ILessonBlock {
  type: LessonBlockType;
  text: string;
}

/** One CARD in the reader. Named "section" from when a lesson was a flat list. */
export interface ILessonSection {
  title: string;
  blocks: ILessonBlock[];
}

/**
 * A group of cards read as one sitting, the way a catalogue keypoint is.
 *
 * Generated content used to be ten flat cards, which read nothing like the rest
 * of the app: the catalogue divides a lesson into keypoints, and finishing one
 * is the unit of progress the whole reader is built around. Grouping here is
 * what lets an imported lesson enter the SAME reader instead of a parallel one.
 *
 * How many keypoints is the model's call, not a constant -- see
 * `LEARNING_IMPORT_CONFIG.targetKeypointCount`. A five-minute video and a
 * forty-page chapter should not both come out as three.
 */
export interface ILessonKeypoint {
  title: string;
  sections: ILessonSection[];

  /**
   * This keypoint's roadmap-node thumbnail, dealt from the admin's
   * keypoint-image pool when the keypoint is written (phase 1 for the first,
   * the completion phase for the rest). Empty when the pool was empty — the
   * app then falls back to its bundled placeholder, which is also what every
   * keypoint written before this field existed shows.
   */
  coverUrl?: string;

  /**
   * One or two sentences the reader should leave this keypoint with.
   *
   * Not decoration: it is the BACK FACE of the reader's recap card, the flip
   * card that ends every keypoint. A catalogue keypoint gets one from its
   * authored "Take This With You" theory item; a generated keypoint has no such
   * item, so without this the card has nothing to flip to and the reader ends
   * the keypoint on a dead quote card.
   *
   * Optional because lessons generated before this field exist and must keep
   * opening.
   */
  takeaway?: string;
}

// What one generation run cost. Recorded per job so that after a month of real
// traffic the quota and the model choice can be re-tuned against measurements
// instead of the estimates in learning-import.config.ts.
export interface IImportUsage {
  inputTokens: number;
  outputTokens: number;
  estimatedCostVnd: number;
}

export interface IImportError {
  code: string;
  message: string;
}

/**
 * Bookkeeping for the background phase that finishes a partially-generated
 * lesson (see `UserLessonContentStatus.PARTIAL`).
 *
 * Present ONLY on lessons born from the progressive pipeline — its absence is
 * how the completion sweep leaves every older lesson alone, which is a product
 * decision (2026-08-13), not an accident. Never deleted, only quiesced: a
 * completed lesson keeps the record so "how many attempts did this take" stays
 * answerable, and so audio top-ups can keep using the same scoping test.
 */
export interface IUserLessonGeneration {
  /** Continuation runs started so far, successful or not. Feeds the backoff. */
  attempts: number;
  /** When the last continuation run STARTED. Null before the first. */
  lastAttemptAt: Date | null;
  /**
   * Stamped every 30s while a continuation run is alive, null when none is.
   * The sweep's claim is an atomic write on this field — stale-or-null means
   * the run that owned it is dead (deploy, crash) and the lesson is up for
   * grabs again.
   */
  heartbeatAt: Date | null;
}

/**
 * Where one card's narration sits inside its KEYPOINT's merged file.
 *
 * `cardIndex` is relative to the keypoint, not the lesson, because the file it
 * indexes into is per keypoint. Carrying a lesson-wide index instead would make
 * every consumer subtract an offset it has no business knowing.
 *
 * Deliberately not the catalogue's `(learningItemId, documentIndex)` pair: a
 * generated keypoint has no learning items on the server. The app synthesises
 * that identity when it maps a keypoint into the reader's entities -- one
 * keypoint becomes one theory item, so `cardIndex` IS the document index.
 */
export interface IUserLessonAudioCue {
  cardIndex: number;
  startMs: number;
  durMs: number;
}

/** One keypoint's narration: its own mp3, its own cue map. */
export interface IUserLessonKeypointAudio {
  keypointIndex: number;
  url: string;
  durationMs: number;
  cues: IUserLessonAudioCue[];
}

/**
 * Narration for a generated lesson: one merged mp3 PER KEYPOINT.
 *
 * One file per keypoint rather than one per lesson, because the reader loads
 * narration a keypoint at a time (`LessonAudioCubit.configure(keypoint)`). A
 * single lesson-wide file would have to be handed to every keypoint with cue
 * offsets pointing into the middle of it, and the player treats the end of the
 * file as the end of the keypoint -- so the last card of keypoint one would run
 * on into keypoint two's narration.
 *
 * `voice` and `hash` stay at the lesson level: one dub run, one narrator, one
 * content identity. Single-locale, since a generated lesson exists in exactly
 * one language (`UserLesson.outputLocale`).
 */
export interface IUserLessonAudio {
  voice: string;
  // Content identity of the narration. Included in each url via `appendVersion`
  // so a re-dub under the same deterministic R2 keys is served as new urls.
  hash: string;
  keypoints: IUserLessonKeypointAudio[];
}
