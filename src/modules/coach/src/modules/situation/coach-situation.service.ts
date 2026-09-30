import { Injectable, Logger } from '@nestjs/common';

import { RequestService } from '@base/service/request.service';
import { ITranslation } from '@utils/interface/common.interface';
import { ContentSource } from 'src/modules/courses/src/modules/course-version/content-source.service';
import { KeypointRepository } from 'src/modules/courses/src/modules/keypoint/repository/keypoint.repository';
import { HabitLibraryService } from 'src/modules/habit/src/modules/habit-library/habit-library.service';

import { pickPooledScene } from './coach-situation-pool.helper';
import {
  CoachSituationContextGroup,
  CoachSituationSource,
  CoachSituationVariant,
} from './enum/situation.enum';
import {
  ICoachSituation,
  ICoachSituationOption,
} from './interface/situation.interface';
import { CoachSituationRepository } from './repository/coach-situation.repository';
import {
  COACH_AUDIENCE_HINT,
  CoachAudience,
} from '../../shared/coach-audience';
import { detachedFromCoachDeadline } from '../../shared/coach-deadline';
import {
  COACH_SCENE_SETTING_EXAMPLES,
  SCENE_OPTION_MIN,
  SITUATION_AVOID_PROMPTS,
  SITUATION_MAX_BEATS,
  SITUATION_FREE_CONTEXT_EVERY,
  SITUATION_MAX_LEVEL,
  SITUATION_MIN_LEVEL,
} from '../../shared/coach.constant';
import { CoachAi, CoachSituationInput } from '../ai/coach-ai.types';

/**
 * The write-through cache for ⑦'s short situations.
 *
 * The first reader to reach a `(habitId, locale, variant)` that does not exist
 * pays one generation; everyone after reads the row. That caching is not only a
 * cost decision — ⑤ "ĐỔI THAY" compares two answers to the SAME situation three
 * weeks apart, which is only possible because the situation is stable.
 */
/**
 * Keypoints whose text grounds one scene.
 *
 * Three, because the relation is many-to-many and a popular habit can be
 * suggested by a dozen keypoints — feeding all of them would bury the habit
 * itself under material and cost a long prompt on a cache miss the reader is
 * waiting through.
 */
const HABIT_MATERIAL_LIMIT = 3;

/**
 * The three named approaches, cleaned and re-lettered.
 *
 * `key` is accepted from callers but never trusted: it is re-stamped A·B·C from
 * position. An editor who deletes the middle row, or an import sheet with the
 * letters typed by hand, would otherwise leave "A" and "C" on screen with
 * nothing between them — and `resolveSceneOption` matches on that letter.
 *
 * Returns `undefined` for "not sent" so a caller can tell it apart from "sent
 * and empty", which is a deliberate clearing of the trio.
 */
export function normaliseSituationOptions(
  value?: Array<{ key?: string; label?: string; text?: string }>,
): ICoachSituationOption[] | undefined {
  if (value === undefined) return undefined;

  const cleaned = value
    .map((option) => ({
      label: (option?.label ?? '').trim(),
      text: (option?.text ?? '').trim(),
    }))
    .filter((option) => option.label && option.text)
    .map((option, index) => ({
      key: String.fromCharCode(65 + index),
      ...option,
    }));

  // Two or three, never one: a single "way to answer" is not a choice, it is
  // the answer — which is the one thing this must never hand over. An editor
  // who deletes down to one clears the set instead.
  return cleaned.length >= SCENE_OPTION_MIN ? cleaned : [];
}

@Injectable()
export class CoachSituationService {
  private readonly logger = new Logger(CoachSituationService.name);

  constructor(
    private readonly repository: CoachSituationRepository,
    private readonly habitLibraryService: HabitLibraryService,
    private readonly keypointRepository: KeypointRepository,
    private readonly ai: CoachAi,
    private readonly contentSource: ContentSource,
    private readonly requestService: RequestService,
  ) {}

  /**
   * The situation to show, generating it if this is the first time anyone has
   * needed this combination.
   *
   * Returns null when there is nothing to show — no habit, no configured model,
   * or the provider failed. Callers must handle null by skipping the situation
   * step rather than blocking: a missing scene is a shorter conversation, not a
   * broken one.
   */
  async resolve(params: {
    habitId: string;
    locale: string;
    variant: CoachSituationVariant;

    /**
     * Luồng 7 — the keypoint the reader has JUST read, when the habit was added
     * at the end of it. The scene is then built from that lesson rather than
     * from a keypoint of the habit picked at random: "cảnh sinh từ chính bài
     * vừa học… đây là điểm khác luồng 4 — ở đó cảnh sinh từ habit đã nằm trong
     * kho lâu rồi". Ignored when it is not one of the habit's own keypoints.
     */
    preferKeypointId?: string | null;

    /** Age band from onboarding — part of the cache key. */
    audience?: CoachAudience;

    /** The learning goal's stable trackingLabel — part of the cache key. */
    goalKey?: string;

    /** The goal in the reader's own language, for the prompt alone. */
    goalLabel?: string | null;

    /**
     * Scenes this reader has already answered, most recent first.
     *
     * A scene they have answered is not shown again while the pool has one
     * they have not; once every scene in a full pool has been answered, the
     * one answered longest ago comes round.
     */
    avoid?: string[];

    /**
     * Which corner of life to prefer, inferred from words the reader wrote.
     *
     * A PREFERENCE, not a filter — "ưu tiên cảnh cùng nhóm bối cảnh với nhắc
     * hẹn gần nhất; hết cảnh trong nhóm mới lấy nhóm khác". A pool with nothing
     * in that group must still hand back a scene.
     */
    contextGroup?: string | null;

    /**
     * Difficulty to write this scene at, 1–5, overriding the slot's turn on the
     * ladder.
     *
     * Set only when the reader ASKED for a harder one. Left alone the pool keeps
     * walking 1..5 by slot, which is what makes a growing pool cover the whole
     * ladder instead of five variations on one level.
     */
    level?: number | null;

    /**
     * Whose practice this is — only so a scene written ahead of time FOR them
     * can be recognised. Optional: a caller that does not pass it simply never
     * collects a pre-written scene and generates as before.
     */
    userId?: string | null;
  }): Promise<(ICoachSituation & { _id: unknown }) | null> {
    const { habitId, locale, variant } = params;
    const audience: CoachAudience = params.audience ?? 'unknown';
    const goalKey = params.goalKey || 'unknown';
    const avoid = params.avoid ?? [];

    type Scene = ICoachSituation & { _id: unknown };

    // Owner's call (2026-08-28): the pre-authored catalogue is gone — a scene
    // is WRITTEN AT PRACTICE TIME for the habit this practice is about,
    // grounded in the habit's own description, contexts and material (both
    // stages, both tellings, in one call). What the habit already has serves
    // only as the generator's memory (a different moment, a climbing ladder)
    // and as the fallback when the provider fails — a scene already written
    // beats no practice at all. The row is still stored: the answer files
    // against it, and ④ replays it by id.
    const recent = (await this.repository
      .findAnyForHabit(habitId, locale)
      .catch(() => [])) as Scene[];

    /**
     * A scene written for this reader while they were busy with something else
     * — reading the invite, or answering the scene before this one.
     *
     * Tried BEFORE generation, because the whole point of writing it early is
     * that the wait already happened somewhere nobody was watching. Claiming is
     * one indexed read and one update; generating is 5–13 seconds.
     */
    const prewarmed = await this.claimPrewarmed(params.userId, {
      habitId,
      locale,
      variant,
      wantedLevel: params.level ?? null,
      avoid,
    });
    if (prewarmed) return prewarmed;

    const generated = await this.generateInto(recent, {
      habitId,
      locale,
      variant,
      audience,
      goalKey,
      goalLabel: params.goalLabel ?? null,
      contextGroup: params.contextGroup ?? null,
      preferKeypointId: params.preferKeypointId ?? null,
      level: params.level ?? null,
    });
    if (generated) return generated;

    const answered = new Set(avoid);
    const usable = recent.filter((scene) => !answered.has(String(scene._id)));
    if (usable.length) {
      /**
       * A reader who asked to go UP is answered by RUNG first, corner of life
       * second.
       *
       * `pickForGroup` picks at random inside a context group and reads no
       * level at all. That is right for an ordinary scene and wrong for this
       * one: with generation over its budget — which the dev log shows happens
       * — "Luyện cảnh khó hơn" was handed whatever difficulty the pool
       * happened to hold, usually the same rung again. The button did
       * something, and the something was indistinguishable from nothing.
       */
      if (params.level) {
        const picked = pickPooledScene({
          pool: usable.map((scene) => ({
            id: String(scene._id),
            level: scene.level,
            slot: scene.slot,
            scene,
          })),
          wantedLevel: params.level,
          // `usable` is already the unseen half.
          avoidIds: [],
        });
        if (picked) return picked.scene;
      }

      return this.pickForGroup(usable, params.contextGroup);
    }

    // Everything stored has been answered and generation is down: the one
    // answered longest ago beats skipping the practice. `avoid` is
    // most-recent-first, so its highest index is the oldest.
    if (!recent.length) return null;
    const rank = new Map(avoid.map((id, index) => [id, index]));

    return recent.reduce((oldest, scene) =>
      (rank.get(String(scene._id)) ?? Infinity) >
      (rank.get(String(oldest._id)) ?? Infinity)
        ? scene
        : oldest,
    );
  }

  /**
   * Collect a scene written ahead of time for this reader, if one is waiting.
   *
   * Level decides which one, through the same ranking the timeout fallback
   * uses: a reader who asked to go up is answered by rung first. A reservation
   * that does not match well enough is left alone rather than spent — it stays
   * waiting for the practice it was written for.
   */
  private async claimPrewarmed(
    userId: string | null | undefined,
    key: {
      habitId: string;
      locale: string;
      variant: CoachSituationVariant;
      wantedLevel: number | null;
      avoid: string[];
    },
  ): Promise<(ICoachSituation & { _id: unknown }) | null> {
    if (!userId) return null;

    const waiting = (await this.repository
      .findReservedFor(key.habitId, key.locale, userId, key.variant)
      .catch(() => [])) as (ICoachSituation & { _id: unknown })[];
    if (!waiting.length) return null;

    const picked = pickPooledScene({
      pool: waiting.map((scene) => ({
        id: String(scene._id),
        level: scene.level,
        slot: scene.slot,
        scene,
      })),
      // No level asked for means the ordinary walk up the ladder, and any
      // waiting scene beats a five-second wait.
      wantedLevel: key.wantedLevel ?? SITUATION_MIN_LEVEL,
      avoidIds: key.avoid,
    });
    if (!picked) return null;

    // The claim is what makes it theirs, and it can fail: another turn of the
    // same session may have taken it a moment ago. Falling through to
    // generation is the right answer then, not an error.
    const claimed = await this.repository
      .claimReserved(picked.id, userId)
      .catch(() => null);

    return (claimed as (ICoachSituation & { _id: unknown }) | null) ?? null;
  }

  /**
   * Write the next scene while the reader is busy with something else.
   *
   * Fired at the two moments the product already makes somebody wait for a
   * reason of its own: when the invite to practise is put on screen (they are
   * reading it and deciding), and when a scene is being answered (they are
   * typing). Both are far longer than the 5–13 seconds a scene takes to write,
   * so the wait costs nobody anything — and the tap that follows is instant.
   *
   * Detached from the turn's 20s budget for the same reason the second stage is:
   * it is triggered from inside a turn but deliberately does not sit on that
   * turn's clock. Without it this inherits whatever milliseconds are left and
   * gets cut off by a ceiling meant for the person sitting there waiting.
   *
   * At most one reservation per reader per habit. A second would be a second
   * paid call for a tap that only happens once.
   */
  prewarm(params: {
    userId: string;
    habitId: string;
    locale: string;
    variant: CoachSituationVariant;
    audience?: CoachAudience;
    goalKey?: string;
    goalLabel?: string | null;
    contextGroup?: string | null;
    preferKeypointId?: string | null;
    level?: number | null;
  }): void {
    if (!params.userId || !this.ai.isConfigured()) return;

    const guard = `${params.userId}:${params.habitId}:${params.locale}:${params.variant}`;
    if (this.prewarming.has(guard)) return;
    this.prewarming.add(guard);

    detachedFromCoachDeadline(() => {
      void (async () => {
        try {
          const waiting = await this.repository
            .findReservedFor(
              params.habitId,
              params.locale,
              params.userId,
              params.variant,
            )
            .catch(() => []);
          if (waiting.length) return;

          const recent = (await this.repository
            .findAnyForHabit(params.habitId, params.locale)
            .catch(() => [])) as ICoachSituation[];

          await this.generateInto(recent, {
            habitId: params.habitId,
            locale: params.locale,
            variant: params.variant,
            audience: params.audience ?? 'unknown',
            goalKey: params.goalKey || 'unknown',
            goalLabel: params.goalLabel ?? null,
            contextGroup: params.contextGroup ?? null,
            preferKeypointId: params.preferKeypointId ?? null,
            level: params.level ?? null,
            reservedForUserId: params.userId,
          });
        } catch (error: any) {
          // Swallowed: nothing is waiting on this. The reader simply pays the
          // ordinary generation wait when they tap, exactly as before.
          this.logger.warn(
            `Coach scene prewarm failed for habit=${params.habitId} locale=${params.locale}: ${error?.message}`,
          );
        } finally {
          this.prewarming.delete(guard);
        }
      })();
    });
  }

  /**
   * The reader's corner of life as a phrase the setting instruction can use.
   * NEUTRAL (or unknown) means their words point nowhere yet — no preference.
   */
  private settingGroupPhrase(group?: string | null): string | null {
    switch (group) {
      case CoachSituationContextGroup.WORK:
        return 'work';
      case CoachSituationContextGroup.FAMILY:
        return 'family';
      case CoachSituationContextGroup.FRIENDS:
        return 'friends';
      case CoachSituationContextGroup.STUDY:
        return 'study';
      case CoachSituationContextGroup.SERVICE:
        return 'errands-and-public-places';
      default:
        return null;
    }
  }

  /**
   * One of `list`, preferring the reader's own corner of life.
   *
   * Order: their group → the neutral scenes (written to fit anybody) → whatever
   * is left. Never a filter, because a habit whose pool has nothing set at work
   * must still hand back a scene. Random within the winning band so two readers
   * with the same history do not walk the pool in lockstep.
   */
  private pickForGroup<T extends { contextGroup?: string | null }>(
    list: T[],
    wanted?: string | null,
  ): T {
    const pick = (from: T[]) => from[Math.floor(Math.random() * from.length)];
    if (!wanted) return pick(list);

    const inGroup = list.filter((scene) => scene.contextGroup === wanted);
    if (inGroup.length) return pick(inGroup);

    const neutral = list.filter(
      (scene) => scene.contextGroup === CoachSituationContextGroup.NEUTRAL,
    );

    return pick(neutral.length ? neutral : list);
  }

  /** One more scene for a key, distinct from the ones already in its pool. */
  private async generateInto(
    pool: ICoachSituation[],
    key: {
      habitId: string;
      locale: string;
      variant: CoachSituationVariant;
      audience: CoachAudience;
      goalKey: string;
      goalLabel: string | null;
      /** The reader's corner of life, for the invented setting. */
      contextGroup?: string | null;
      /** Luồng 7 — build the scene from the lesson just read, not the whole habit. */
      preferKeypointId?: string | null;
      /** Asked-for difficulty, overriding the slot's place on the ladder. */
      level?: number | null;
      /** Set when this scene is being written ahead of time for one reader. */
      reservedForUserId?: string | null;
    },
  ): Promise<(ICoachSituation & { _id: unknown }) | null> {
    const { habitId, locale, variant, audience, goalKey } = key;
    if (!this.ai.isConfigured()) return null;

    const habit = await this.habitLibraryService.findOne(habitId).catch(() => null);
    if (!habit) return null;

    const habitTitle = this.pickTranslation(
      (habit as { title?: ITranslation })?.title,
      locale,
    );
    if (!habitTitle) return null;

    // The editor's grounding: what the habit is, and the moments it comes up.
    // Slot i of the pool stands in moment i, so the pool covers the habit's
    // real situations instead of four variations on whatever the model
    // pictured first.
    const habitDescription = this.pickTranslation(
      (habit as { description?: ITranslation | null }).description ?? undefined,
      locale,
    );
    const habitContexts = this.splitContexts(
      this.pickTranslation(
        (habit as { contexts?: ITranslation | null }).contexts ?? undefined,
        locale,
      ),
    );

    // The skill's own ladder decides what this slot's difficulty MEANS. Slots
    // walk 1..5 and round, so a growing pool covers the whole ladder instead of
    // five variations on "someone pushes back".
    const ladder = this.parseLadder(
      this.pickTranslation(
        (habit as { ladder?: ITranslation | null }).ladder ?? undefined,
        locale,
      ),
    );

    /**
     * The next free slot FOR THIS KEY — not `pool.length`.
     *
     * `pool` is `findAnyForHabit`, which filters on habit+locale only and is
     * capped at 50, while the row's unique index is
     * (habit, locale, variant, audience, goalKey, SLOT) and `cacheGenerated`
     * upserts with `$setOnInsert`. Using the pool's length meant slot numbers
     * that (a) counted rows belonging to OTHER variants/audiences/goals and
     * (b) stopped moving once the habit had 50 scenes — from then on every
     * generation asked for the same slot, the upsert matched the row already
     * there, and the freshly written scene was silently thrown away and an old
     * one returned instead. That is the repeated scenes, and the provider was
     * billed for every discarded one.
     *
     * Also why the ladder froze: a level derived from the capped length sat at
     * `50 % 5 + 1 = 1` forever, so every scene past the cap was the easiest one.
     */
    const slot =
      (await this.repository.maxSlotForKey(
        habitId,
        locale,
        variant,
        audience,
        goalKey,
      )) + 1;

    // Owner 2026-09-05 — one slot in every N invents its own moment, so a
    // habit's pool grows past whatever list an editor happened to write down
    // ("loanh quanh 1 vài tình huống"). The other slots stay grounded: the
    // authored moments are what guarantee the pool covers the habit's REAL
    // situations.
    const freeMoment =
      habitContexts.length > 0 &&
      slot % SITUATION_FREE_CONTEXT_EVERY === SITUATION_FREE_CONTEXT_EVERY - 1;
    // The grounded slots count themselves rather than reusing `slot`. With a
    // plain `slot % contexts.length`, the free slots would keep landing on the
    // same index — a habit with exactly N contexts would then have one of them
    // NEVER written, which is the opposite of what this change is for.
    const groundedIndex = slot - Math.floor(slot / SITUATION_FREE_CONTEXT_EVERY);

    // An asked-for level wins over the slot's turn on the ladder. Clamped rather
    // than trusted: the caller derives it by adding one to the scene just
    // practised, and level 6 is a prompt instruction with no rung behind it.
    const sceneLevel = key.level
      ? Math.max(SITUATION_MIN_LEVEL, Math.min(SITUATION_MAX_LEVEL, key.level))
      : (slot % (SITUATION_MAX_LEVEL - SITUATION_MIN_LEVEL + 1)) +
        SITUATION_MIN_LEVEL;
    const sceneLevelShape = ladder.get(sceneLevel) ?? null;

    try {
      const generated = await this.ai.generateSituation({
        locale,
        variant,
        habitTitle,
        habitMaterial: await this.habitMaterial(habit, locale, key.preferKeypointId),
        habitDescription,
        habitContexts,
        // ONE moment per scene, assigned by slot — the pool then walks the
        // habit's real moments instead of returning to whichever one the model
        // pictures first ("tình huống bị lặp lại", 2026-08-28: two scenes for
        // one habit, different words, both about an unopened message).
        sceneContext:
          habitContexts.length && !freeMoment
            ? habitContexts[groundedIndex % habitContexts.length]
            : null,
        inventMoment: freeMoment,
        // "Bối cảnh vẫn gắn chặt chẽ theo habit, nhưng phụ thuộc vào độ tuổi,
        // tính cách của từng user" — the setting is invented per scene from
        // habit × reader; the ten reference settings only show the register.
        settingExamples: [...COACH_SCENE_SETTING_EXAMPLES],
        settingGroup: this.settingGroupPhrase(key.contextGroup),
        audienceHint: COACH_AUDIENCE_HINT[audience],
        goalLabel: key.goalLabel,
        sceneLevel,
        sceneLevelShape,
        // The NEWEST scenes, which is what `slice(0, n)` gives: the pool comes
        // back `createdAt: -1`. `slice(-n)` took the OLDEST n instead, so once
        // a habit had more than 12 scenes the model was told to avoid the ones
        // nobody had seen for weeks while being free to rewrite the ones the
        // reader had just answered.
        avoidPrompts: pool
          .slice(0, SITUATION_AVOID_PROMPTS)
          .map((scene) => scene.prompt),
        // Hai pha: cú này chỉ viết những gì người đọc nhìn thấy khi cảnh mở ra.
        openingOnly: true,
      });

      const stored = await this.repository.cacheGenerated({
        habitId,
        locale,
        variant,
        audience,
        goalKey,
        slot,
        prompt: generated.prompt,
        promptThirdPerson: generated.promptThirdPerson,
        promptStage2: generated.promptStage2,
        promptStage2ThirdPerson: generated.promptStage2ThirdPerson,
        samples: generated.samples,
        openingOptions: generated.openingOptions,
        // No script: the v4 practice is the two written stages above, and a
        // row with beats would flip the session onto the legacy scripted path.
        beats: [],
        beatLines: [],
        counterpart: generated.counterpart,
        level: sceneLevel,
        reservedForUserId: key.reservedForUserId ?? null,
        takeaway: generated.takeaway,
        goodMove: generated.goodMove,
      });

      // Ba trường còn lại được viết ở cú thứ hai, NGOÀI đồng hồ người đọc —
      // cảnh đã ở trên màn hình và họ đang đọc nó.
      this.completeInBackground(String((stored as { _id: unknown })._id), {
        locale,
        variant,
        habitTitle,
        prompt: generated.prompt,
        counterpart: generated.counterpart,
      });

      return stored as unknown as ICoachSituation & { _id: unknown };
    } catch (error: any) {
      // A failed generation is a missing scene, not a failed conversation.
      this.logger.warn(
        `Situation generation failed for habit=${habitId} locale=${locale} variant=${variant} audience=${audience}: ${error?.message}`,
      );

      return null;
    }
  }

  /**
   * Viết nốt chặng hai, bài học và nước đi — sau khi cảnh đã ra màn hình.
   *
   * Không await, và mọi lỗi đều bị nuốt: một cảnh thiếu chặng hai vẫn luyện
   * được (nó chạy một chặng, đúng nhánh `promptStage2: null` vốn đã có), còn
   * một cảnh không kịp hiện thì không.
   *
   * `detachedFromCoachDeadline` vì nó châm ngòi từ trong một lượt có ngân sách
   * 20 giây, mà nó cố ý KHÔNG nằm trên đồng hồ ấy — hệt như việc viết quiz cho
   * ngày mai. Không có nó thì cú này thừa kế số mili-giây còn lại của lượt và
   * bị cắt ngang bởi cái trần dành cho người đang ngồi chờ.
   *
   * Khoá theo id để một cảnh không bị viết nốt hai lần khi hai lượt cùng chạm
   * vào nó — cùng cách `CoachQuizService.replenish` tự bảo vệ.
   */
  private completeInBackground(
    situationId: string,
    input: {
      locale: string;
      variant: CoachSituationVariant;
      habitTitle: string;
      prompt: string;
      counterpart: string | null;
    },
  ): void {
    if (this.completing.has(situationId)) return;
    this.completing.add(situationId);

    detachedFromCoachDeadline(() => {
      void (async () => {
        try {
          const rest = await this.ai.completeSituation(
            {
              locale: input.locale,
              variant: input.variant,
              habitTitle: input.habitTitle,
            } as CoachSituationInput,
            { prompt: input.prompt, counterpart: input.counterpart },
          );

          await this.repository.updateOne({ _id: situationId }, rest as never);
        } catch (error: any) {
          this.logger.warn(
            `Coach scene ${situationId} left without its second stage: ${error?.message}`,
          );
        } finally {
          this.completing.delete(situationId);
        }
      })();
    });
  }

  /** Cảnh đang được viết nốt — chống viết hai lần. */
  private readonly completing = new Set<string>();

  /** Readers with a scene already being written ahead of them. */
  private readonly prewarming = new Set<string>();

  /** Admin list — every cached row, newest edit first. */
  /** ④ replays the SAME scene by id — re-resolving could hand back a different one. */
  async findById(id: string) {
    return this.repository.findById(id);
  }

  async findForAdmin(filter: {
    habitId?: string;
    locale?: string;
    variant?: CoachSituationVariant;
  }) {
    return this.repository.findForAdmin(filter);
  }

  /**
   * An editor rewrote a scene.
   *
   * Flips `source` to EDITED, which is what stops generation ever overwriting
   * the fix — there is no approval queue, so this one flag is the whole
   * difference between "the model's guess" and "a person decided".
   */
  /**
   * Bulk-insert hand-authored scenes into the pool — no generation, no provider
   * call. Each row is appended after the key's current last slot and marked
   * EDITED so the write-through generator never overwrites it. This is the seed
   * path: variety without paying the model for every scene.
   */
  async importScenes(
    items: Array<{
      habitId: string;
      locale: string;
      variant?: string;
      audience?: string;
      goalKey?: string;
      prompt: string;
      promptThirdPerson?: string | null;
      promptStage2?: string | null;
      promptStage2ThirdPerson?: string | null;
      contextGroup?: string | null;
      samples?: string[];
      openingOptions?: Array<{ key?: string; label?: string; text?: string }>;
      beats?: string[];
      beatLines?: string[];
      counterpart?: string | null;
      level?: number;
      takeaway?: string | null;
      goodMove?: string | null;
    }>,
  ): Promise<{ inserted: number; skipped: number }> {
    let inserted = 0;
    let skipped = 0;
    // Slots are assigned per key across the whole batch, so ten scenes for one
    // habit land in slots 0..9 rather than colliding on the pool's current max.
    const nextSlot = new Map<string, number>();

    for (const item of items) {
      const variant = (item.variant || 'default') as CoachSituationVariant;
      const audience = item.audience || 'unknown';
      const goalKey = item.goalKey || 'unknown';
      const prompt = (item.prompt || '').trim();
      if (!item.habitId || !item.locale || !prompt) {
        skipped++;
        continue;
      }

      const key = [item.habitId, item.locale, variant, audience, goalKey].join(
        '|',
      );
      if (!nextSlot.has(key)) {
        const max = await this.repository.maxSlotForKey(
          item.habitId,
          item.locale,
          variant,
          audience,
          goalKey,
        );
        nextSlot.set(key, max + 1);
      }
      const slot = nextSlot.get(key) as number;
      nextSlot.set(key, slot + 1);

      try {
        await this.repository.cacheGenerated({
          habitId: item.habitId,
          locale: item.locale,
          variant,
          audience,
          goalKey,
          slot,
          prompt,
          promptThirdPerson: item.promptThirdPerson?.trim() || null,
          promptStage2: item.promptStage2?.trim() || null,
          promptStage2ThirdPerson: item.promptStage2ThirdPerson?.trim() || null,
          contextGroup: item.contextGroup || null,
          samples: (item.samples ?? [])
            .map((s) => s.trim())
            .filter(Boolean)
            .slice(0, 3),
          openingOptions: normaliseSituationOptions(item.openingOptions),
          beats: (item.beats ?? [])
            .map((s) => s.trim())
            .filter(Boolean)
            .slice(0, SITUATION_MAX_BEATS),
          // NOT filtered for empties: an empty entry is meaningful here — it
          // marks a beat the Coach probes instead of performing, and dropping
          // it would shift every later line onto the wrong beat.
          beatLines: (item.beatLines ?? [])
            .map((s) => (s ?? '').trim())
            .slice(0, SITUATION_MAX_BEATS),
          counterpart: item.counterpart?.trim() || null,
          level: item.level ?? null,
          takeaway: item.takeaway?.trim() || null,
          goodMove: item.goodMove?.trim() || null,
          source: CoachSituationSource.EDITED,
        });
        inserted++;
      } catch (error: any) {
        this.logger.warn(
          `Import skipped a scene for habit=${item.habitId} locale=${item.locale} slot=${slot}: ${error?.message}`,
        );
        skipped++;
      }
    }

    return { inserted, skipped };
  }

  async updateScript(
    id: string,
    patch: {
      prompt: string;
      promptThirdPerson?: string;
      promptStage2?: string;
      promptStage2ThirdPerson?: string;
      contextGroup?: string;
      samples?: string[];
      openingOptions?: Array<{ key?: string; label?: string; text?: string }>;
      beats?: string[];
      beatLines?: string[];
      counterpart?: string;
      level?: number;
      takeaway?: string;
      goodMove?: string;
    },
  ) {
    const clean = (value?: string) => {
      if (value === undefined) return undefined;
      const trimmed = value.trim();

      return trimmed.length ? trimmed : null;
    };
    const cleanList = (value?: string[]) =>
      value === undefined
        ? undefined
        : value.map((line) => line.trim()).filter(Boolean);

    // Only fields the editor actually sent are written — a blank column left out
    // of the form does not wipe the generated value. Every save flips `source`
    // to EDITED, which is what stops generation ever overwriting the fix.
    const update: Record<string, unknown> = {
      prompt: patch.prompt.trim(),
      source: CoachSituationSource.EDITED,
    };
    const samples = cleanList(patch.samples);
    if (samples !== undefined) update.samples = samples;
    // The trio is read and rewritten together, so it is written whole or not at
    // all — a half-sent list would leave the reader looking at two approaches
    // labelled A and C. Rows that lose every usable entry are stored empty,
    // which the renderer reads as "no block" rather than as a broken one.
    const openingOptions = normaliseSituationOptions(patch.openingOptions);
    if (openingOptions !== undefined) update.openingOptions = openingOptions;
    const third = clean(patch.promptThirdPerson);
    if (third !== undefined) update.promptThirdPerson = third;
    const stage2 = clean(patch.promptStage2);
    if (stage2 !== undefined) update.promptStage2 = stage2;
    const stage2Third = clean(patch.promptStage2ThirdPerson);
    if (stage2Third !== undefined) {
      update.promptStage2ThirdPerson = stage2Third;
    }
    if (patch.contextGroup !== undefined) update.contextGroup = patch.contextGroup;
    const beats = cleanList(patch.beats);
    if (beats !== undefined) update.beats = beats;
    // Empties are kept: index i of `beatLines` belongs to beat i, and a blank
    // there is the difference between performing and probing that beat.
    if (patch.beatLines !== undefined) {
      update.beatLines = patch.beatLines.map((line) => (line ?? '').trim());
    }
    const counterpart = clean(patch.counterpart);
    if (counterpart !== undefined) update.counterpart = counterpart;
    if (patch.level !== undefined) update.level = patch.level;
    const takeaway = clean(patch.takeaway);
    if (takeaway !== undefined) update.takeaway = takeaway;
    const goodMove = clean(patch.goodMove);
    if (goodMove !== undefined) update.goodMove = goodMove;

    return this.repository.findOneAndUpdate({ _id: id }, update);
  }

  /**
   * Delete a cached scene.
   *
   * The next reader who needs it regenerates, so this is "try again" rather
   * than destruction. Answers already filed against it keep their
   * `situationId` and simply stop resolving — which is correct: they were
   * answers to THAT scene, and ⑤ comparing them against a new one would be
   * comparing two different questions.
   */
  async remove(id: string) {
    return this.repository.deleteOne({ _id: id });
  }

  /**
   * Drop every GENERATED scene of one habit so the pool is rebuilt from its
   * current description and contexts. Scenes an editor fixed by hand stay.
   */
  async removeGeneratedForHabit(habitId: string) {
    return this.repository.deleteGeneratedForHabit(habitId);
  }

  /**
   * `<level> | <shape>` per line → a map from 1..5 to what that rung means.
   *
   * Tolerant like the other authored fields: a line with no level prefix takes
   * the next free rung, so a ladder pasted as five bare lines still works.
   */
  private parseLadder(value: string | null): Map<number, string> {
    const rungs = new Map<number, string>();
    if (!value) return rungs;

    let next = SITUATION_MIN_LEVEL;
    for (const raw of value.split(/\r?\n/)) {
      const line = raw.trim().replace(/^[-•·]\s*/, '');
      if (!line) continue;

      const match = line.match(/^([1-5])\s*[|.):-]\s*(.+)$/);
      const level = match ? Number(match[1]) : next;
      const shape = (match ? match[2] : line).trim();
      if (!shape || level > SITUATION_MAX_LEVEL) continue;

      rungs.set(level, shape);
      next = level + 1;
    }

    return rungs;
  }

  /** "One moment per line" — also tolerates `;` and `|` from spreadsheets. */
  private splitContexts(value: string | null): string[] {
    if (!value) return [];

    return value
      .split(/\r?\n|;|\|/)
      .map((line) => line.trim().replace(/^[-•·]\s*/, ''))
      .filter(Boolean);
  }

  /**
   * What this habit actually TEACHES, as text the model can read.
   *
   * A habit title alone is a label — "nói ra ý mình" can be grounded in a
   * meeting, a family dinner or a traffic light, and the model picks whichever
   * it likes. The keypoints are the app's own teaching material for that habit,
   * so a scene written against them lands inside the world the reader has been
   * learning about instead of an anecdote from nowhere.
   *
   * Read-only and best-effort: a habit with no keypoints still gets a scene,
   * just a thinner one. `HABIT_MATERIAL_LIMIT` bounds the prompt because this
   * many-to-many can attach a habit to a long tail of keypoints.
   */
  /**
   * The habit's teaching material for a REPLY prompt — what the habit means
   * and the keypoints it comes from, in the reader's language.
   *
   * The scene generator has always read this; the reply after the scene never
   * did, which is why that reply could only mirror the reader's answer back.
   * Read-only, best-effort, null when the habit has nothing to teach with.
   */
  async materialFor(
    habitId: string | null | undefined,
    locale: string,
  ): Promise<string | null> {
    if (!habitId) return null;

    const habit = await this.habitLibraryService.findOne(habitId).catch(() => null);
    if (!habit) return null;

    const description = this.pickTranslation(
      (habit as { description?: ITranslation | null }).description ?? undefined,
      locale,
    );
    const keypoints = await this.habitMaterial(habit, locale);

    const parts = [
      description ? `What this habit means, concretely: ${description}` : null,
      keypoints ? `The lesson's keypoints:\n${keypoints}` : null,
    ].filter(Boolean);

    return parts.length ? parts.join('\n') : null;
  }

  /**
   * The ONE keypoint nhịp 4 speaks from — retrieved, never generated.
   *
   * The habit's first keypoint, deterministically: "truy xuất, không sinh… một
   * keypoint, tối đa hai. Một course." Its id is what the tail then uses to
   * offer the course that holds it, so it has to be a choice the session can
   * remember rather than something the model names.
   */
  async keypointFor(
    habitId: string | null | undefined,
    locale: string,
    preferKeypointId?: string | null,
  ): Promise<{ id: string; title: string; description: string | null } | null> {
    if (!habitId) return null;

    const habit = await this.habitLibraryService.findOne(habitId).catch(() => null);
    const all = (((habit as { keypointIds?: unknown[] })?.keypointIds ?? []) as unknown[]).map(
      (id) => String(id),
    );
    if (!all.length) return null;

    // One at random rather than always the first: the same reader telling a
    // second story about the same habit deserves a different idea, and the
    // habit's first keypoint is often its most generic one.
    // Luồng 7 hands in the keypoint just read; everything else takes one at
    // random rather than always the first, so a second story about the same
    // habit gets a different idea.
    const ids = [
      preferKeypointId && all.includes(preferKeypointId)
        ? preferKeypointId
        : all[Math.floor(Math.random() * all.length)],
    ];

    // Nguyên liệu dựng cảnh phải là nội dung ĐÃ PHÁT HÀNH: nếu đọc bản đang
    // sửa, Coach sẽ nói về chữ user chưa được thấy.
    // Xem `plans/260907-course-content-versions/README.md`.
    const [keypoint] = (await this.contentSource
      .getKeypointBriefsAcrossVersions(ids, this.requestService.headers)
      .catch(() => [])) as Array<{
      _id: unknown;
      title?: ITranslation;
      description?: ITranslation;
    }>;
    const title = this.pickTranslation(keypoint?.title, locale);
    if (!keypoint || !title) return null;

    return {
      id: String(keypoint._id),
      title,
      description: this.pickTranslation(keypoint.description, locale),
    };
  }

  private async habitMaterial(
    habit: unknown,
    locale: string,
    preferKeypointId?: string | null,
  ): Promise<string | null> {
    const all = ((habit as { keypointIds?: unknown[] })?.keypointIds ?? []).map((id) =>
      String(id),
    );
    // Luồng 7 — the habit was added at the end of a lesson, so the scene is
    // built from THAT lesson alone: "cảnh sinh từ chính bài vừa học, không
    // phải cảnh chung". Every other door reads the habit's whole material.
    const ids =
      preferKeypointId && all.includes(preferKeypointId)
        ? [preferKeypointId]
        : all.slice(0, HABIT_MATERIAL_LIMIT);
    if (!ids.length) return null;

    const keypoints = await this.contentSource
      .getKeypointBriefsAcrossVersions(ids, this.requestService.headers)
      .catch(() => []);

    const lines = (
      keypoints as Array<{ title?: ITranslation; description?: ITranslation }>
    )
      .map((keypoint) => {
        const title = this.pickTranslation(keypoint.title, locale);
        if (!title) return null;

        const description = this.pickTranslation(keypoint.description, locale);

        return description ? `- ${title}: ${description}` : `- ${title}`;
      })
      .filter(Boolean);

    return lines.length ? lines.join('\n') : null;
  }

  /**
   * Locale fallback for a habit title.
   *
   * English before Vietnamese: an untranslated title is far more likely to
   * exist in English, and a scene grounded in a title the model cannot read is
   * worse than one grounded in a title from the wrong language.
   */
  private pickTranslation(
    value: ITranslation | undefined,
    locale: string,
  ): string | null {
    if (!value) return null;

    const byLocale = (value as Record<string, string | undefined>)[locale];

    return byLocale || value.en || value.vi || null;
  }
}
