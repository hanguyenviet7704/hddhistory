import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CoachEntry, CoachHomeTier, CoachStep } from '../../../shared/coach.enum';
import { CoachSessionStatus } from '../enum/session.enum';
import { ICoachShownTurn } from '../interface/session.interface';
import { CoachSession } from '../schema/coach-session.schema';

@Injectable()
export class CoachSessionRepository extends AbstractRepository<CoachSession> implements OnModuleInit {
  protected readonly logger = new Logger(CoachSessionRepository.name);

  constructor(
    @InjectModel(CoachSession.name) model: Model<CoachSession>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Drops the old `expiresAt` TTL index. The schema no longer declares it, and
   * `syncIndexes` removes what the schema does not declare — the one way to
   * take an index away without a manual step, since Mongo has no migrations
   * here. Sessions are kept for good from this boot on.
   */
  async onModuleInit(): Promise<void> {
    try {
      await this.model.syncIndexes();
    } catch (error: any) {
      this.logger.warn(`Coach could not sync session indexes: ${error?.message}`);
    }
  }

  /** The exchange as the app drew it — appended, never rewritten. */
  async appendShown(id: string, items: ICoachShownTurn[]): Promise<void> {
    if (!items.length) return;
    await this.model.updateOne({ _id: id }, { $push: { shown: { $each: items } } });
  }

  /**
   * Luồng 1 — an onboarding the reader left unfinished, whatever day it was
   * started: it is resumed at the question they were on, not started over.
   */
  /**
   * A session left in the middle of a scene, at this door — the one the reader
   * means by opening the sheet again the next morning.
   *
   * Newest first, and bounded by `since` rather than by the day: the row is
   * spared from the day close by its STEP (see `SCENE_RESUME_STEPS`), so
   * without a floor here a scene from months ago would come back.
   */
  async findSceneInProgress(
    userId: string,
    entry: CoachEntry,
    steps: CoachStep[],
    since: Date,
  ) {
    return this.model
      .findOne({
        userId,
        entry,
        status: CoachSessionStatus.ACTIVE,
        step: { $in: steps },
        createdAt: { $gte: since },
      })
      .sort({ createdAt: -1 })
      .lean();
  }

  async findOnboardingInProgress(userId: string, steps: CoachStep[]) {
    return this.model
      .findOne({
        userId,
        entry: CoachEntry.HOME,
        status: CoachSessionStatus.ACTIVE,
        onboarding: true,
        step: { $in: steps },
      })
      .sort({ createdAt: -1 })
      .lean();
  }

  /**
   * The reader's most recent sessions that have anything to show, newest
   * first — the history a reopened sheet draws above today's exchange.
   */
  async findRecentWithLines(userId: string, excludeId: string | null, limit: number) {
    return this.model
      .find({
        userId,
        ...(excludeId ? { _id: { $ne: excludeId } } : {}),
        $or: [{ 'shown.0': { $exists: true } }, { 'turns.0': { $exists: true } }],
      })
      .sort({ createdAt: -1 })
      .limit(limit)
      .select('shown turns entry createdAt')
      .lean();
  }

  /**
   * "Has the reader already had a session at this door since [since]?"
   *
   * This one query stands in for the flag table the prototype implied. Both
   * day-flags it replaces — `coach has already appeared in this lesson` and
   * `Home has already asked today` — are the same question with a different
   * door and a different window, so they are the same read.
   *
   * `lessonId` narrows ① to the lesson actually being finished: a reader may
   * complete two lessons in a day and each gets its own one-shot.
   */
  async existsSince(params: {
    userId: string;
    entry: CoachEntry;
    since: Date;
    lessonId?: string | null;
    /** ④ — "has the replay already been offered today?" reads by tier. */
    tier?: CoachHomeTier | null;
    /**
     * Luồng 7 — which FLAVOUR of the lesson door, since three now share
     * `entry: LESSON`: the talk after a keypoint (`'talk'`), the course recap
     * (`'recap'`), and the habit-practice invitation (`null`).
     *
     * Filtered on only when the key is present, because the value being asked
     * for is itself `null` — omitting the key means "any flavour", and passing
     * `null` means "the habit one". `{ talkMode: null }` also matches sessions
     * written before the field existed, which is what we want.
     */
    talkMode?: 'talk' | 'recap' | null;
  }): Promise<boolean> {
    const { userId, entry, since, lessonId, tier } = params;

    const found = await this.model.exists({
      userId,
      entry,
      createdAt: { $gte: since },
      ...(lessonId ? { lessonId } : {}),
      ...(tier ? { tier } : {}),
      ...('talkMode' in params ? { talkMode: params.talkMode } : {}),
    });

    return Boolean(found);
  }

  /**
   * The reader's still-open session at this door, if any — opened since
   * `since`.
   *
   * Newest first, and only ACTIVE — a session the reader ended is over, and a
   * session past its TTL is already gone. `since` is the reader's own midnight:
   * a sheet swiped away at lunch is picked back up at dinner, but yesterday's
   * half-told story is not what today opens on.
   */
  async findActiveForEntry(userId: string, entry: CoachEntry, since: Date) {
    return this.model
      .findOne({
        userId,
        entry,
        status: CoachSessionStatus.ACTIVE,
        expiresAt: { $gt: new Date() },
        createdAt: { $gte: since },
      })
      .sort({ createdAt: -1 })
      .lean();
  }

  /**
   * Close every session at this door still ACTIVE from before `before`.
   *
   * What was said stays (the reader's own record); only the status moves.
   * `keepSteps` — luồng 1 — spares a session parked on one of those steps: an
   * unfinished onboarding is resumed on the next visit, not abandoned.
   */
  async closeActiveBefore(
    userId: string,
    entry: CoachEntry,
    before: Date,
    keepSteps: CoachStep[] = [],
  ) {
    return this.model.updateMany(
      {
        userId,
        entry,
        status: CoachSessionStatus.ACTIVE,
        createdAt: { $lt: before },
        ...(keepSteps.length ? { step: { $nin: keepSteps } } : {}),
      },
      {
        $set: {
          status: CoachSessionStatus.CLOSED,
          closedAt: new Date(),
        },
      },
    );
  }

  async findActive(id: string, userId: string) {
    return this.model.findOne({ _id: id, userId }).lean();
  }
}
