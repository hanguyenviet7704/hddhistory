import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model, Types } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import {
  CoachSituationSource,
  CoachSituationVariant,
} from '../enum/situation.enum';
import { ICoachSituationOption } from '../interface/situation.interface';
import { CoachSituation } from '../schema/coach-situation.schema';

@Injectable()
export class CoachSituationRepository extends AbstractRepository<CoachSituation> {
  protected readonly logger = new Logger(CoachSituationRepository.name);

  constructor(
    @InjectModel(CoachSituation.name) model: Model<CoachSituation>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /** Admin list. Small by nature — one row per habit x locale x variant. */
  async findForAdmin(filter: {
    habitId?: string;
    locale?: string;
    variant?: CoachSituationVariant;
  }) {
    const where: Record<string, unknown> = {};
    if (filter.habitId) where.habitId = filter.habitId;
    if (filter.locale) where.locale = filter.locale;
    if (filter.variant) where.variant = filter.variant;

    return this.model.find(where).sort({ updatedAt: -1 }).limit(500).lean();
  }

  /**
   * Boot-time index sync — this is the Mongo "migration" for the cache key
   * growing audience+goal. Without it the OLD three-field unique index
   * survives in the collection and rejects every per-audience row as a
   * duplicate of the legacy one. syncIndexes drops indexes the schema no
   * longer declares and creates the ones it now does; failure is logged, not
   * thrown — a booted app with a stale index beats one that will not boot.
   */
  async onModuleInit() {
    try {
      await this.model.syncIndexes();
    } catch (error) {
      this.logger.warn(`coach_situations index sync failed: ${error}`);
    }
  }

  /**
   * Every scene cached for one key, oldest slot first.
   *
   * `$in` with null so rows cached before the key grew — which have neither
   * audience nor goal — keep serving the unknown/unknown readers they were
   * made for; rows cached before the pool existed have no slot and are slot 0.
   */
  async findPool(
    habitId: string,
    locale: string,
    variant: CoachSituationVariant,
    audience = 'unknown',
    goalKey = 'unknown',
  ) {
    const keyOf = (value: string) =>
      value === 'unknown' ? { $in: ['unknown', null] } : value;

    return this.model
      .find({
        habitId,
        locale,
        variant,
        audience: keyOf(audience),
        goalKey: keyOf(goalKey),
      })
      .sort({ slot: 1, createdAt: 1 })
      .lean();
  }

  /**
   * Every scene the habit has in one language, across audience/goal/variant.
   *
   * The fallback pool: when live generation for the exact key fails and that
   * key is empty, a scene written for a different reader is still a real
   * practice scene for this habit — far better than none.
   */
  async findAnyForHabit(habitId: string, locale: string) {
    return this.model
      .find({ habitId, locale })
      .sort({ createdAt: -1 })
      .limit(50)
      .lean();
  }

  /** Every generated scene of a habit, so its pool can be rebuilt. Edited ones stay. */
  async deleteGeneratedForHabit(habitId: string): Promise<{ deleted: number }> {
    const result = await this.model.deleteMany({
      habitId,
      source: CoachSituationSource.GENERATED,
    });

    return { deleted: result.deletedCount ?? 0 };
  }

  /**
   * Store a freshly generated situation, losing the race gracefully.
   *
   * Two readers can reach the same empty cache key at once; both generate, both
   * write. `$setOnInsert` means the second write is a no-op that returns the
   * first one's row rather than throwing a duplicate-key error or — worse —
   * replacing a row that answers already point at. Whoever got there first
   * wins, and both readers see the same situation.
   */
  async cacheGenerated(params: {
    habitId: string;
    locale: string;
    variant: CoachSituationVariant;
    audience: string;
    goalKey: string;
    slot: number;
    prompt: string;
    promptThirdPerson?: string | null;
    promptStage2?: string | null;
    promptStage2ThirdPerson?: string | null;
    contextGroup?: string | null;
    samples: string[];
    openingOptions?: ICoachSituationOption[];
    beats?: string[];
    beatLines?: string[];
    counterpart?: string | null;
    level?: number | null;
    takeaway?: string | null;
    goodMove?: string | null;
    model?: string | null;
    /** GENERATED for the write-through cache; EDITED for hand-authored imports. */
    source?: CoachSituationSource;
    /** Set when this scene was written ahead of time for one reader. */
    reservedForUserId?: string | null;
  }) {
    const {
      habitId,
      locale,
      variant,
      audience,
      goalKey,
      slot,
      prompt,
      promptThirdPerson,
      promptStage2,
      promptStage2ThirdPerson,
      contextGroup,
      samples,
      openingOptions,
      beats,
      beatLines,
      counterpart,
      level,
      takeaway,
      goodMove,
      model,
      source,
      reservedForUserId,
    } = params;

    return this.model
      .findOneAndUpdate(
        { habitId, locale, variant, audience, goalKey, slot },
        {
          $setOnInsert: {
            habitId,
            locale,
            variant,
            audience,
            goalKey,
            slot,
            prompt,
            promptThirdPerson: promptThirdPerson ?? null,
            promptStage2: promptStage2 ?? null,
            promptStage2ThirdPerson: promptStage2ThirdPerson ?? null,
            contextGroup: contextGroup ?? null,
            samples,
            openingOptions: openingOptions ?? [],
            beats: beats ?? [],
            beatLines: beatLines ?? [],
            counterpart: counterpart ?? null,
            level: level ?? null,
            takeaway: takeaway ?? null,
            goodMove: goodMove ?? null,
            model,
            reservedForUserId: reservedForUserId ?? null,
            ...(source ? { source } : {}),
          },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .lean();
  }

  /**
   * Scenes written ahead of time for this reader and not yet handed over.
   *
   * Filtered by VARIANT as well as reader. A scene is written in one telling —
   * second person, third person, after-done, after-missed — and the variant is
   * decided by the step the reader turns out to take. Pre-generation has to
   * guess it; handing over a guess that turned out wrong would show somebody a
   * scene about "một người" when the step wanted "bạn". A mismatched
   * reservation is simply not collected, and stays in the pool as an ordinary
   * fallback scene.
   */
  async findReservedFor(
    habitId: string,
    locale: string,
    userId: string,
    variant: CoachSituationVariant,
  ) {
    return this.model
      .find({ habitId, locale, variant, reservedForUserId: userId })
      .sort({ slot: 1 })
      .lean();
  }

  /**
   * Hand a reserved scene over — and only once.
   *
   * `reservedForUserId` is in the FILTER, not just the update, so two turns
   * racing for the same pre-written scene cannot both win it: the loser matches
   * nothing, gets null, and falls through to generating one of its own.
   */
  async claimReserved(id: string, userId: string) {
    return this.model
      .findOneAndUpdate(
        { _id: id, reservedForUserId: userId },
        { $set: { reservedForUserId: null } },
        { new: true },
      )
      .lean();
  }

  /** The highest slot already used for a key, or -1 when the pool is empty. */
  async maxSlotForKey(
    habitId: string,
    locale: string,
    variant: CoachSituationVariant,
    audience: string,
    goalKey: string,
  ): Promise<number> {
    const rows = (await this.model
      .find({ habitId, locale, variant, audience, goalKey }, { slot: 1 })
      .lean()) as Array<{ slot?: number }>;

    return rows.reduce((max, row) => Math.max(max, row.slot ?? 0), -1);
  }

  /**
   * The prompts behind a batch of answers, for the admin thread.
   *
   * A `coach_situation_answers` row stores only what the reader typed and the
   * id of the scene they typed it into. The scene's own text is authored — it
   * outlives the session that showed it — so joining it back is what turns a
   * column of loose answers into something that reads like the exchange it was.
   */
  async findPromptsByIds(ids: string[]) {
    // A malformed id would make Mongoose throw a CastError for the whole batch
    // and take the reading list down with it, so it is dropped here instead.
    const valid = ids.filter((id) => Types.ObjectId.isValid(id));
    if (!valid.length) return [];

    return this.model
      .find(
        { _id: { $in: valid } },
        { prompt: 1, promptStage2: 1, habitId: 1, variant: 1, level: 1 },
      )
      .lean();
  }
}
