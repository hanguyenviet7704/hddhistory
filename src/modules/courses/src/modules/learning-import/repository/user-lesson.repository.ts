import { Injectable } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { IResponseListPage } from '@utils/interface/paging/page.interface';
import { OrderType } from '@utils/type/orderByType';

import {
  UserLessonAudioStatus,
  UserLessonContentStatus,
} from '../enum/learning-import.enum';
import {
  ILessonKeypoint,
  IUserLessonAudio,
} from '../interface/learning-import.interface';
import { UserLesson } from '../schema/user-lesson.schema';

// The card fields the list screen renders. Excluding the body (`keypoints`, and
// the legacy `sections`) here is what keeps the list cheap: a page of ten
// lessons would otherwise ship ~50k words of body text to draw ten titles.
const LIST_PROJECTION = {
  title: 1,
  description: 1,
  outputLocale: 1,
  source: 1,
  coverUrl: 1,
  wordCount: 1,
  estimatedMinutes: 1,
  stopAtKeypointIndex: 1,
  stopAtSectionIndex: 1,
  // The card's progress line reads 100% off this and nothing else -- see the
  // schema note on why the app cannot derive it.
  completedAt: 1,
  createdAt: 1,
  // Status only, never the `audio` object: the card just needs to know whether
  // to draw a headphone icon. Anything omitted from this list comes back
  // `undefined` with no error and no warning, so a field added to the card must
  // be added here too.
  audioStatus: 1,
  contentStatus: 1,
};

@Injectable()
export class UserLessonRepository extends AbstractRepository<UserLesson> {
  constructor(
    @InjectModel(UserLesson.name) model: Model<UserLesson>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * One lesson, but only if it belongs to `userId`.
   *
   * The ownership filter lives here, not in the service. These lessons are built
   * from material the user uploaded themselves, so "can this caller read it" is
   * not a rule a future caller should be able to forget to apply.
   */
  async findOwned(id: string, userId: string): Promise<UserLesson | null> {
    return this.model.findOne({ _id: id, userId }).lean<UserLesson>();
  }

  // Admin detail view. Deliberately a separate method from `findOwned` so that
  // reading across users is something a caller has to ask for by name.
  async findAny(id: string): Promise<UserLesson | null> {
    return this.model.findById(id).lean<UserLesson>();
  }

  async findPaginatedByUser(
    userId: string,
    page: number,
    take: number,
  ): Promise<IResponseListPage<UserLesson>> {
    return this.paginateQuery<UserLesson>({
      // `$ne: true` rather than `draft: false`: documents created before the
      // draft field existed have no field at all and must stay listed. See the
      // schema note on `draft` for the whole story.
      where: { userId, draft: { $ne: true } },
      projection: LIST_PROJECTION,
      orderBy: 'createdAt',
      order: OrderType.DESC,
      page,
      take,
    });
  }

  /**
   * Lift the lesson onto the shelf once its run has completed.
   *
   * Called by the runner right BEFORE the job is marked completed: the app
   * refetches the list at the exact moment the job stops running, so the row
   * has to be listable by then or the shelf comes back without the lesson the
   * reader just watched being made.
   */
  async clearDraft(id: string): Promise<void> {
    await this.model.updateOne({ _id: id }, { $set: { draft: false } });
  }

  async findByJobId(jobId: string): Promise<UserLesson | null> {
    return this.model.findOne({ jobId }).lean<UserLesson>();
  }

  async updateProgress(
    id: string,
    userId: string,
    stopAtKeypointIndex: number,
    stopAtSectionIndex: number,
    completedAt?: Date,
  ): Promise<void> {
    await this.model.updateOne(
      { _id: id, userId },
      {
        $set: {
          stopAtKeypointIndex,
          stopAtSectionIndex,
          updatedAt: new Date(),
          // Only ever written on the pass that finishes the lesson; the caller
          // leaves it undefined otherwise, which keeps the first completion
          // date rather than stamping a new one on every reread.
          ...(completedAt ? { completedAt } : {}),
        },
      },
    );
  }

  /**
   * Stamps the "I want more of this" wish, and only the first time.
   *
   * `additionalContentRequestedAt: null` in the filter is what makes a second ask
   * a no-op in ONE round trip -- no read-then-write, so two taps racing each other
   * cannot both pass a check and overwrite the first date. Returns whether this
   * call was the one that recorded it.
   */
  async markAdditionalContentRequested(
    id: string,
    userId: string,
    requestedAt: Date,
  ): Promise<boolean> {
    const result = await this.model.updateOne(
      { _id: id, userId, additionalContentRequestedAt: null },
      { $set: { additionalContentRequestedAt: requestedAt } },
    );

    return result.modifiedCount > 0;
  }

  /**
   * Written by the dubbing phase, which runs after the lesson already exists and
   * is not scoped to a user -- it is our own background work, not a request.
   */
  async setAudioStatus(
    id: string,
    audioStatus: UserLessonAudioStatus,
  ): Promise<void> {
    await this.model.updateOne({ _id: id }, { $set: { audioStatus } });
  }

  async setAudio(
    id: string,
    audio: IUserLessonAudio,
    audioStatus: UserLessonAudioStatus,
  ): Promise<void> {
    await this.model.updateOne({ _id: id }, { $set: { audio, audioStatus } });
  }

  async deleteOwned(id: string, userId: string): Promise<number> {
    const result = await this.model.deleteOne({ _id: id, userId });

    return result.deletedCount ?? 0;
  }

  // ---------------------------------------------------------------------------
  // Background completion (plans/260813-progressive-import). Everything below is
  // our own machinery, never a user request, so nothing here filters by userId.
  // ---------------------------------------------------------------------------

  /**
   * Take ownership of a lesson's background work, atomically.
   *
   * The filter IS the lock: only a document whose generation heartbeat is null
   * or stale can be claimed, and the write that claims it stamps a fresh
   * heartbeat in the same operation — two sweeps (or a sweep racing the
   * runner's fire-and-forget) cannot both see `modifiedCount: 1`. Also counts
   * the attempt, because a claim is exactly one background run starting.
   */
  async claimGeneration(id: string, staleBefore: Date): Promise<boolean> {
    const now = new Date();
    const result = await this.model.updateOne(
      {
        _id: id,
        generation: { $ne: null },
        $or: [
          { 'generation.heartbeatAt': null },
          { 'generation.heartbeatAt': { $lt: staleBefore } },
        ],
      },
      {
        $set: {
          'generation.heartbeatAt': now,
          'generation.lastAttemptAt': now,
        },
        $inc: { 'generation.attempts': 1 },
      },
    );

    return result.modifiedCount > 0;
  }

  /** Keep a claimed run visibly alive. See IUserLessonGeneration.heartbeatAt. */
  async beatGeneration(id: string): Promise<void> {
    await this.model.updateOne(
      { _id: id },
      { $set: { 'generation.heartbeatAt': new Date() } },
    );
  }

  /**
   * Hand the lesson back to the sweep. Called on every exit of a background
   * run, success or not — a claim that is never released only heals after the
   * staleness window, which is exactly the slow path this exists to avoid.
   */
  async releaseGeneration(id: string): Promise<void> {
    await this.model.updateOne(
      { _id: id },
      { $set: { 'generation.heartbeatAt': null } },
    );
  }

  /**
   * Land a body snapshot: the ASSEMBLED keypoint list (in plan order), the
   * recounted totals, and the content status they add up to — one write, so a
   * crash can never leave the totals describing a body they don't match.
   *
   * Called once per streamed keypoint (status PARTIAL until the last) and by
   * the batch continuation (status COMPLETE).
   */
  async writeBody(
    id: string,
    keypoints: ILessonKeypoint[],
    wordCount: number,
    estimatedMinutes: number,
    contentStatus: UserLessonContentStatus,
  ): Promise<void> {
    await this.model.updateOne(
      { _id: id },
      {
        $set: {
          keypoints,
          wordCount,
          estimatedMinutes,
          contentStatus,
          updatedAt: new Date(),
        },
      },
    );
  }

  /** The continuation's landing: whole body, flipped to COMPLETE. */
  async completeContent(
    id: string,
    keypoints: ILessonKeypoint[],
    wordCount: number,
    estimatedMinutes: number,
  ): Promise<void> {
    await this.writeBody(
      id,
      keypoints,
      wordCount,
      estimatedMinutes,
      UserLessonContentStatus.COMPLETE,
    );
  }

  /**
   * Lessons whose body is still missing keypoints and whose last run is dead.
   *
   * Candidates only: the caller applies the per-attempt backoff in code, since
   * each document's next-eligible time depends on its own attempt count. Draft
   * rows are excluded because their import job is still alive and owns them.
   */
  async findStalledPartial(
    staleBefore: Date,
    limit: number,
  ): Promise<UserLesson[]> {
    return this.model
      .find({
        contentStatus: UserLessonContentStatus.PARTIAL,
        generation: { $ne: null },
        draft: { $ne: true },
        $or: [
          { 'generation.heartbeatAt': null },
          { 'generation.heartbeatAt': { $lt: staleBefore } },
        ],
      })
      .sort({ createdAt: 1 })
      .limit(limit)
      .lean<UserLesson[]>();
  }

  /**
   * Completed lessons whose narration does not cover every keypoint yet.
   *
   * Scoped to `generation: {$ne: null}` — the progressive pipeline's own rows —
   * so the sweep never touches lessons that predate it (product decision,
   * 2026-08-13). `failed` is excluded: that status is now written only for the
   * two permanent conditions (no narrator for the locale, nothing sayable),
   * and retrying those would loop forever by design.
   */
  async findAudioIncomplete(
    staleBefore: Date,
    limit: number,
  ): Promise<UserLesson[]> {
    return this.model
      .find({
        contentStatus: UserLessonContentStatus.COMPLETE,
        generation: { $ne: null },
        draft: { $ne: true },
        audioStatus: { $ne: UserLessonAudioStatus.FAILED },
        $or: [
          { 'generation.heartbeatAt': null },
          { 'generation.heartbeatAt': { $lt: staleBefore } },
        ],
        $expr: {
          $lt: [
            { $size: { $ifNull: ['$audio.keypoints', []] } },
            { $size: { $ifNull: ['$keypoints', []] } },
          ],
        },
      })
      .sort({ createdAt: 1 })
      .limit(limit)
      .lean<UserLesson[]>();
  }
}
