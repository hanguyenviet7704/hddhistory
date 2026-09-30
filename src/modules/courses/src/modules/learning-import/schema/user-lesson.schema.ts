import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  UserLessonAudioStatus,
  UserLessonContentStatus,
} from '../enum/learning-import.enum';
import {
  IImportSource,
  ILessonKeypoint,
  ILessonSection,
  IUserLessonAudio,
  IUserLessonGeneration,
} from '../interface/learning-import.interface';

/**
 * A lesson the user generated from their own material, stored whole in one
 * document.
 *
 * NOT the catalogue schemas. Reusing Course/Lesson/Keypoint with an owner flag
 * was the first design, and it fails on the read side: every existing catalogue
 * query -- Home, Explore, search, roadmap, recently-viewed, my-course,
 * badge-progress, the admin statistics aggregations -- would need a filter added
 * to keep private content out, and missing one leaks a user's private material
 * into someone else's app with nothing to alert us. A separate collection makes
 * that class of bug impossible instead of merely unlikely.
 *
 * The price is that these lessons do not feed `user_progress` (which keys off a
 * catalogue courseId) and so never reach badges or the learning statistics.
 * Streaks are unaffected -- `user_streak` references no course at all.
 *
 * See plans/260810-user-content-import/design.md §4.3.
 */
// No `timestamps: true`: AbstractDocument already declares createdAt/updatedAt
// with defaults, and layering Mongoose's own timestamps on top of them has
// broken a GET in this codebase before.
@Schema({ collection: 'user_lessons' })
export class UserLesson extends AbstractDocument {
  @Prop({ type: String, required: true, index: true })
  userId: string;

  @Prop({ type: String, default: '' })
  title: string;

  @Prop({ type: String, default: '' })
  description: string;

  /**
   * The single locale this lesson exists in.
   *
   * A plain string, not the 5-locale `ITranslation` map the catalogue schemas
   * use. The user picked one output language at import time and we generate once
   * -- carrying four permanently-empty locale keys would only invite code that
   * assumes they might be filled.
   */
  @Prop({ type: String, required: true })
  outputLocale: string;

  @Prop({ type: Object, required: true })
  source: IImportSource;

  /**
   * The lesson body: keypoints, each holding its own cards.
   *
   * `Array` (not a nested schema) because the shape is closed and
   * self-describing -- Mongoose validating it a second time buys nothing.
   */
  @Prop({ type: Array, default: [] })
  keypoints: ILessonKeypoint[];

  /**
   * The pre-keypoint body: one flat list of cards.
   *
   * Kept only to read lessons generated before the split. Nothing writes it any
   * more; `UserLessonService.findOne` wraps whatever is here into a single
   * keypoint so an old lesson still opens. Delete the field once no lesson
   * carries it.
   *
   * @deprecated superseded by [keypoints]
   */
  @Prop({ type: Array, default: [] })
  sections: ILessonSection[];

  /**
   * The lesson's cover, dealt ONCE at creation from the admin's course-cover
   * pool (`LearningImportConfig.courseCoverUrls`) and kept for life — pool
   * edits change only lessons born after them. Empty = the app's bundled
   * placeholder, which is also every pre-existing lesson.
   */
  @Prop({ type: String, default: '' })
  coverUrl: string;

  @Prop({ type: Number, default: 0 })
  wordCount: number;

  @Prop({ type: Number, default: 0 })
  estimatedMinutes: number;

  /**
   * Which keypoint the reader was last in.
   *
   * The unit that matters now: opening an imported lesson resumes at a keypoint,
   * the same way tapping a course lesson does. The card within it
   * ([stopAtSectionIndex]) only refines where inside that sitting to land.
   */
  @Prop({ type: Number, default: 0 })
  stopAtKeypointIndex: number;

  /**
   * How far into that keypoint, as a card index RELATIVE to it.
   *
   * A card boundary rather than a scroll offset: it survives a re-render or a
   * font-size change, which a raw offset would not.
   */
  @Prop({ type: Number, default: 0 })
  stopAtSectionIndex: number;

  /**
   * When the reader reached the last card of the last keypoint. Null until then.
   *
   * Derived server-side rather than sent by the client, because only the server
   * holds the body: "finished" means the last card of the LAST keypoint, and the
   * list response deliberately omits the keypoints, so the app literally cannot
   * work it out for the card it is drawing.
   *
   * A date and not a bool so it also answers "when", and set ONCE -- re-reading
   * a finished lesson must not un-finish it.
   */
  @Prop({ type: Date, default: null })
  completedAt: Date | null;

  // Back-reference to the run that produced this. One-way on purpose: deleting a
  // job must never take a lesson with it, so nothing points the other way.
  @Prop({ type: String, default: '' })
  jobId: string;

  /**
   * True while the run that is producing this lesson has not completed yet.
   *
   * The document is saved at stage SAVING (95%) so the dubbing phase has a
   * lessonId to write audio onto, but the shelf must not show it until the run
   * finishes -- the app is already drawing a "generating" card for that run, and
   * listing the row too shows the same import twice. The runner clears this
   * right before marking the job completed; a run that dies in between leaves
   * the row permanently unlisted, which matches what the user was told (the
   * import failed).
   *
   * Default false, not true: pre-existing documents have no field at all and
   * must stay listed, so the list filters on `draft: { $ne: true }` and only the
   * runner ever writes `true`.
   */
  @Prop({ type: Boolean, default: false })
  draft: boolean;

  /**
   * Narration, written by a phase that runs AFTER this document already exists.
   *
   * Null for the whole window between "lesson saved" and "dub finished", and
   * permanently null when dubbing fails -- see `UserLessonAudioStatus.FAILED`.
   * Readers must treat a lesson with no audio as ordinary, not broken.
   */
  @Prop({ type: Object, default: null })
  audio: IUserLessonAudio | null;

  @Prop({
    type: String,
    enum: UserLessonAudioStatus,
    default: UserLessonAudioStatus.NONE,
  })
  audioStatus: UserLessonAudioStatus;

  /**
   * Whether the body is all there yet — `partial` while the background phase is
   * still writing keypoints (see plans/260813-progressive-import).
   *
   * Default COMPLETE, not PARTIAL: every lesson that predates this field was
   * generated whole, and the default is what those documents read as.
   */
  @Prop({
    type: String,
    enum: UserLessonContentStatus,
    default: UserLessonContentStatus.COMPLETE,
  })
  contentStatus: UserLessonContentStatus;

  /**
   * The whole outline, by keypoint title, written at first-bite time.
   *
   * What lets the app draw the FULL roadmap of a lesson whose later keypoints
   * do not exist yet — the not-yet-written ones render as "Đang tạo…" nodes.
   * Phase 2 writes keypoints against these titles, in this order.
   */
  @Prop({ type: [String], default: [] })
  plannedKeypointTitles: string[];

  /**
   * The node artwork for the WHOLE outline, dealt at first-bite time alongside
   * [plannedKeypointTitles] — index i is the picture keypoint i will carry.
   *
   * Exists so a roadmap node does not change its picture when the keypoint
   * behind it finally lands. Without it the app has nothing to draw for a
   * keypoint that does not exist yet, falls back to its own bundled rotation,
   * and then swaps to the pool image the moment the real keypoint arrives —
   * the reader watches the artwork change under them for no reason.
   *
   * Deal-once, same as every other picture here: `pickPoolImage` is
   * deterministic in (jobId, index), so these are exactly the urls the runner
   * and the completion sweep go on to stamp on the keypoints themselves. A
   * later edit to the admin pool does not restyle a lesson already dealt.
   *
   * Empty on lessons born before this field, and on an empty pool — both fall
   * back to the app's bundled art, which is what they showed anyway.
   */
  @Prop({ type: [String], default: [] })
  plannedKeypointCoverUrls: string[];

  /**
   * Background-completion bookkeeping. Null on lessons that predate the
   * progressive pipeline — the completion sweep scopes itself to documents
   * where this exists, which is what keeps it off the old rows.
   */
  @Prop({ type: Object, default: null })
  generation: IUserLessonGeneration | null;

  /**
   * When the reader asked for MORE content on this lesson, from the panel at the
   * end of its roadmap. Null until they do.
   *
   * A wish, not a job: nothing is generated off the back of it. It is the same
   * signal the catalogue collects when a level runs out
   * (`additionalContentRequest` on user progress) -- a count of who wanted more
   * and for what, which is the only honest thing to record when the answer is
   * "the content is being updated".
   *
   * A date rather than a bool so it also answers "when", and written ONCE: asking
   * twice is the same wish, and re-stamping it would lose the moment the reader
   * actually finished and asked.
   */
  @Prop({ type: Date, default: null })
  additionalContentRequestedAt: Date | null;
}

export const UserLessonSchema = SchemaFactory.createForClass(UserLesson);

// Backs the only list query there is: this user's lessons, newest first.
UserLessonSchema.index({ userId: 1, createdAt: -1 });
