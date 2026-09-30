import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';

import { RequestService } from '@base/service/request.service';
import { exercisesWithQuestionsOf } from 'src/modules/courses/src/modules/course-version/content-projection';
import { ContentSource } from 'src/modules/courses/src/modules/course-version/content-source.service';
import { KeypointRepository } from 'src/modules/courses/src/modules/keypoint/repository/keypoint.repository';
import { LearningItemType } from 'src/modules/courses/src/modules/learning-item/enum/learning-item.enum';
import { LearningItemRepository } from 'src/modules/courses/src/modules/learning-item/repository/learning-item.repository';
import { UserProgressRepository } from 'src/modules/courses/src/modules/progress/src/modules/user-progress/repository/user-progress.repository';

import {
  CreateHabitPracticeDto,
  GetListHabitPracticeDto,
  UpdateHabitPracticeDto,
} from './dto/habit-practice.dto';
import { SubmitHabitPracticeAttemptDto } from './dto/submit-habit-practice-attempt.dto';
import { HabitPracticeStatus } from './enum/habit-practice.enum';
import { HabitPracticeAttemptRepository } from './repository/habit-practice-attempt.repository';
import { HabitPracticeRepository } from './repository/habit-practice.repository';
import { HabitLibraryRepository } from '../habit-library/repository/habit-library.repository';
import { HabitCheckinMethod } from '../user-habit/enum/user-habit.enum';
import { UserHabitRepository } from '../user-habit/repository/user-habit.repository';
import { normalizeDateOnly } from '../user-habit/user-habit.helper';
import { UserHabitService } from '../user-habit/user-habit.service';

/**
 * A practice's method is the type of the `learning_item` it points at, so this
 * map is the only place the two vocabularies meet. `THEORY` is absent on
 * purpose: a theory document is reading material, not something you can complete
 * as a check-in.
 */
const METHOD_BY_LEARNING_ITEM_TYPE: Partial<
  Record<LearningItemType, HabitCheckinMethod>
> = {
  [LearningItemType.EXERCISE]: HabitCheckinMethod.EXERCISE,
  [LearningItemType.VIDEO]: HabitCheckinMethod.VIDEO,
  [LearningItemType.ROLEPLAY]: HabitCheckinMethod.ROLEPLAY,
};

@Injectable()
export class HabitPracticeService {
  constructor(
    private readonly habitPracticeRepository: HabitPracticeRepository,
    private readonly attemptRepository: HabitPracticeAttemptRepository,
    private readonly learningItemRepository: LearningItemRepository,
    private readonly keypointRepository: KeypointRepository,
    private readonly habitLibraryRepository: HabitLibraryRepository,
    private readonly userHabitRepository: UserHabitRepository,
    private readonly userHabitService: UserHabitService,
    private readonly userProgressRepository: UserProgressRepository,
    private readonly requestService: RequestService,
    private readonly i18n: I18nService,
    private readonly contentSource: ContentSource,
  ) {}

  private get userId(): string {
    return this.requestService.user?.id?.toString?.();
  }

  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  /**
   * Practices for one habit with their content hydrated.
   *
   * A row whose learning item has since been deleted is dropped rather than
   * returned with a null body: the app would render a practice the user can
   * open and then find empty, with nothing to report. `deleteByLearningItemId`
   * is meant to prevent this, so a drop here also means that cleanup was missed.
   */
  private async hydrate(practices: Record<string, any>[]) {
    const itemIds = Array.from(
      new Set(practices.map(p => p.learningItemId?.toString()).filter(Boolean)),
    );
    // Nội dung practice user nhìn thấy phải là bản đã phát hành. Practice
    // trải nhiều khoá nên mỗi item đọc từ đúng tag của nó.
    // Xem `plans/260907-course-content-versions/README.md`.
    const items = await this.contentSource.getLearningItemsAcrossVersions(
      itemIds,
      this.requestService.headers,
    );
    const byId = new Map(
      (items as any[]).map(item => [item._id.toString(), item]),
    );

    // The practice session deals questions ACROSS keypoints, so each row also
    // names the keypoint its item teaches — the app tags quiz cards with it.
    const keypointIds = Array.from(
      new Set(
        (items as any[])
          .map(item => item.keypointId?.toString())
          .filter(Boolean),
      ),
    ) as string[];
    const keypoints = await this.contentSource.getKeypointBriefsAcrossVersions(
      keypointIds,
      this.requestService.headers,
    );
    const keypointTitleById = new Map(
      (keypoints as any[]).map(keypoint => [
        keypoint._id.toString(),
        keypoint.title,
      ]),
    );

    return practices
      .map(practice => {
        const item = byId.get(practice.learningItemId?.toString());
        if (!item) return null;
        return {
          ...practice,
          method: METHOD_BY_LEARNING_ITEM_TYPE[item.type as LearningItemType],
          learningItem: item,
          keypointTitle:
            keypointTitleById.get(item.keypointId?.toString()) ?? null,
        };
      })
      .filter(Boolean);
  }

  /**
   * The practices for one habit, DERIVED from the keypoint it belongs to unless
   * an author has curated them.
   *
   * A habit hangs off `habits.keypointIds`, and practising a habit means doing
   * that keypoint's exercises — the habit is the behaviour the keypoint teaches,
   * so its practice is the keypoint's practice. Deriving rather than storing is
   * what makes that true by construction: every keypoint with exercises offers
   * its habits a practice with no wiring, and content authored later shows up
   * without anyone remembering to link it. Storing the pairing instead needed one
   * `habit_practices` row per habit — ~1000 of them for the current library — each
   * of which could silently go missing or point at a keypoint the habit had since
   * been re-anchored away from.
   *
   * Curated rows still win when they exist: `habit_practices` is how an author
   * says "not this keypoint's exercises, THESE items", and is the only way to
   * offer a video or roleplay as practice (see [findExercisesByKeypoints], which
   * derives exercises only). Absence of rows means "the keypoint's own", not
   * "nothing" — which is the whole change here.
   *
   * The synthetic rows carry the same shape as stored ones, `_id` included, so no
   * client can tell the two apart. `_id` is the learning item's own id: it has to
   * be stable across calls because the app keys the practice list by it.
   */
  private async deriveFromKeypoints(
    habitIds: string[],
    // When set, only these keypoints contribute exercises — the app read
    // passes the user's PASSED keypoints, so practice only ever quizzes what
    // was actually studied. Undefined (badge counts) keeps the full habit.
    allowedKeypointIds?: Set<string>,
  ) {
    const byHabit = new Map<string, Record<string, any>[]>();
    if (!habitIds.length) return byHabit;

    const habits = await this.habitLibraryRepository.findByIds(habitIds);
    const habitKeypointIds = (habit: any): string[] =>
      ((habit.keypointIds ?? []) as any[])
        .map((id: any) => id?.toString())
        .filter(
          (id: string) =>
            Boolean(id) && (allowedKeypointIds?.has(id) ?? true),
        );
    const keypointIds = Array.from(
      new Set((habits as any[]).flatMap(habitKeypointIds)),
    ) as string[];

    const items = exercisesWithQuestionsOf(
      await this.contentSource.getLearningItemsByKeypointIdsAcrossVersions(
        keypointIds,
        this.requestService.headers,
      ),
    );
    const itemsByKeypoint = new Map<string, any[]>();
    for (const item of items as any[]) {
      const key = item.keypointId?.toString();
      if (!key) continue;
      const bucket = itemsByKeypoint.get(key) ?? [];
      bucket.push(item);
      itemsByKeypoint.set(key, bucket);
    }

    for (const habit of habits as any[]) {
      const habitId = habit._id?.toString();
      // A habit re-anchored onto several keypoints practises all of them, in the
      // keypoint order the habit lists — `order` then reflects that walk, so the
      // app's `order`-sorted list keeps each keypoint's exercises together and in
      // their authored index.
      const rows = habitKeypointIds(habit)
        .flatMap((keypointId: string) => itemsByKeypoint.get(keypointId) ?? [])
        .map((item: any, index: number) => ({
          _id: item._id,
          habitId: habit._id,
          learningItemId: item._id,
          order: index,
          status: HabitPracticeStatus.PUBLISHED,
        }));
      byHabit.set(habitId, rows);
    }

    return byHabit;
  }

  /**
   * App read: curated published practices, else the keypoint's own exercises —
   * derived ONLY from keypoints this user has finished studying (spec: practice
   * quizzes what was learned, never what is still ahead). Curated rows are an
   * author's explicit override and stay unfiltered.
   */
  async findForHabit(dto: GetListHabitPracticeDto) {
    const curated = await this.habitPracticeRepository.findPublishedForHabit(
      dto.habitId,
    );
    if (curated.length) {
      return this.hydrate(curated as Record<string, any>[]);
    }

    const passedKeypointIds = await this.userProgressRepository
      .findPassedKeypointIds(this.userId)
      .then(ids => new Set(ids));
    const derived = await this.deriveFromKeypoints(
      [dto.habitId],
      passedKeypointIds,
    );
    return this.hydrate(derived.get(dto.habitId) ?? []);
  }

  /**
   * Admin read: every CURATED practice on the habit, whatever its status.
   *
   * Deliberately not derived. This screen exists to author and delete rows, and a
   * derived entry has no row to delete — listing it would offer an action that
   * cannot work. So an empty list here does not mean the habit has no practice in
   * the app: it means nobody has overridden the keypoint's own exercises, which
   * is the normal state.
   */
  async findAllForHabitAdmin(dto: GetListHabitPracticeDto) {
    const practices = await this.habitPracticeRepository.findAllForHabit(
      dto.habitId,
    );
    return this.hydrate(practices as Record<string, any>[]);
  }

  async create(dto: CreateHabitPracticeDto) {
    const [item] = await this.learningItemRepository.findByIds([
      dto.learningItemId,
    ]);
    if (!item) {
      throw new NotFoundException('learningItemId does not exist');
    }
    if (!METHOD_BY_LEARNING_ITEM_TYPE[(item as any).type as LearningItemType]) {
      // Catching this here rather than at render time: a theory item linked as a
      // practice would list fine in admin and then have no way to be completed.
      throw new BadRequestException(
        `A learning item of type "${(item as any).type}" cannot be a practice — use exercise, video or roleplay`,
      );
    }

    return this.habitPracticeRepository.create(
      dto as any,
      this.requestService.user as any,
    );
  }

  async update(id: string, dto: UpdateHabitPracticeDto) {
    const updated = await this.habitPracticeRepository.findOneAndUpdate(
      { _id: id },
      { $set: dto },
    );
    if (!updated) throw new NotFoundException('Practice not found');
    return updated;
  }

  async remove(id: string) {
    const practice = await this.habitPracticeRepository.findById(id);
    if (!practice) throw new NotFoundException('Practice not found');
    await this.habitPracticeRepository.deleteById(id);
    return { deleted: true };
  }

  /**
   * Record a finished practice AND file the day's check-in.
   *
   * Both in one call on purpose. The picker asks "How do you want to check in?",
   * so the practice *is* the check-in; if the client posted the attempt and the
   * check-in separately, the two writes would race on the same
   * `{userHabitId, date}` row and a dropped second request would leave a
   * completed practice that never counted.
   *
   * The check-in goes through [UserHabitService.checkIn] rather than the
   * repository so the streak recomputation stays in exactly one place.
   */
  async submitAttempt(dto: SubmitHabitPracticeAttemptDto) {
    const userHabit = await this.userHabitRepository.findOneForUser(
      dto.userHabitId,
      this.userId,
    );
    if (!userHabit) {
      throw new NotFoundException(
        this.i18n.t('error.HABIT.USER_HABIT_NOT_FOUND', { lang: this.lang }),
      );
    }

    if (dto.method !== HabitCheckinMethod.JOURNAL && !dto.learningItemId) {
      throw new BadRequestException(
        'learningItemId is required for every method except journal',
      );
    }

    const results = dto.exercisesResult ?? [];
    // Trust the answers over the summary: a client that disagrees with itself
    // would otherwise write a score the per-question detail contradicts.
    const score = results.length
      ? results.filter(result => result.passed === true).length
      : dto.score;
    const total = results.length ? results.length : dto.total;

    // Same "today" the check-in below resolves to, so the attempt and the
    // check-in it files always share a date.
    const today = await this.userHabitService.localToday();
    const date = dto.date ? normalizeDateOnly(dto.date) : today;

    const attempt = await this.attemptRepository.create(
      {
        userHabitId: dto.userHabitId,
        habitId: userHabit.habitId,
        date,
        method: dto.method,
        learningItemId: dto.learningItemId ?? null,
        exercisesResult: results,
        score,
        total,
        mood: dto.mood,
        completedAt: new Date(),
      } as any,
      this.requestService.user as any,
    );

    const updatedHabit = await this.userHabitService.checkIn(dto.userHabitId, {
      done: true,
      date: dto.date,
      note: dto.note,
      method: dto.method,
      mood: dto.mood,
      score,
    });

    return { attempt, userHabit: updatedHabit };
  }

  /** Attempt log for one adopted habit — the caller's own. */
  async findMyAttempts(userHabitId: string) {
    const userHabit = await this.userHabitRepository.findOneForUser(
      userHabitId,
      this.userId,
    );
    if (!userHabit) {
      throw new NotFoundException(
        this.i18n.t('error.HABIT.USER_HABIT_NOT_FOUND', { lang: this.lang }),
      );
    }
    return this.attemptRepository.findForUserHabit(userHabitId);
  }

  /** Admin: attempts across all users for one adopted habit row. */
  async findAttemptsForUserHabits(userHabitIds: string[]) {
    return this.attemptRepository.findForUserHabits(userHabitIds);
  }

  /** Called when a learning item is deleted, so no practice aims at nothing. */
  async removeByLearningItemId(learningItemId: string) {
    return this.habitPracticeRepository.deleteByLearningItemId(learningItemId);
  }

  /**
   * How many practices each habit offers — lets a client hide an empty method.
   *
   * Counts what [findForHabit] would actually return, derivation included. A count
   * taken from `habit_practices` alone would read 0 for nearly every habit now
   * that the keypoint's exercises are the default, and a client would hide the
   * practice option on habits that do have one.
   */
  async countPublishedByHabitIds(habitIds: string[]) {
    const practices = await this.habitPracticeRepository.findByHabitIds(
      habitIds,
    );
    const counts = new Map<string, number>();
    for (const practice of practices as any[]) {
      const key = practice.habitId?.toString();
      counts.set(key, (counts.get(key) ?? 0) + 1);
    }

    const derived = await this.deriveFromKeypoints(
      habitIds.filter(id => !counts.get(id)),
    );
    for (const [habitId, rows] of derived) {
      if (rows.length) counts.set(habitId, rows.length);
    }
    return counts;
  }

  /** Guard for the admin UI: only these statuses exist. */
  static get statuses() {
    return Object.values(HabitPracticeStatus);
  }
}
