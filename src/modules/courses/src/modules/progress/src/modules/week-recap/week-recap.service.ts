import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { I18nContext } from 'nestjs-i18n';

import { RequestService } from '@base/service/request.service';
import { IResponseListPage } from '@utils/interface/paging/page.interface';
import { getTranslationValue } from '@utils/translate';
import { CoachDayLogService } from 'src/modules/coach/src/modules/day-log/coach-day-log.service';
import { CoachPlanService } from 'src/modules/coach/src/modules/plan/coach-plan.service';
import { CoachReflectionService } from 'src/modules/coach/src/modules/reflection/coach-reflection.service';
import { CHANGE_BLOCK_MIN_WEEKS } from 'src/modules/coach/src/shared/coach.constant';


import {
  GetCurrentWeekRecapDto,
  GetWeekRecapArchiveDto,
} from './dto/week-recap.dto';
import {
  IWeekRecapCoach,
  IWeekRecapDay,
  IWeekRecapHabit,
  IWeekRecapLesson,
} from './interface/week-recap.interface';
import {
  WeekRecapCheckin,
  WeekRecapHabitRepository,
} from './repository/week-recap-habit.repository';
import { WeekRecapRepository } from './repository/week-recap.repository';
import { WeekRecap } from './schema/week-recap.schema';
import {
  formatLocalDate,
  longestRun,
  weekBounds,
  WeekBounds,
} from './week-recap.helper';
import { StudyDayItem, StudyJournalRepository } from '../study-journal/repository/study-journal.repository';

/** Rows the poster's notepad has room for. */
const POSTER_LESSON_ROWS = 3;

/**
 * How long after a week closes its recap may still be rebuilt.
 *
 * Progress can land late — a check-in filed offline, a batch of keypoints that
 * synced a day after they were done — and a recap the learner has not been shown
 * yet has nothing to protect. The same three days, for the same reason, as
 * `AnalyticsRollupService.BACKFILL_DAYS`. After that the snapshot is final
 * whether it was ever opened or not: a poster that could still change a month
 * later is not a snapshot.
 */
const REBUILD_WINDOW_MS = 3 * 24 * 60 * 60 * 1000;

export interface WeekRecapDto {
  id: string;
  weekNumber: number;
  weekStart: string;
  weekEnd: string;
  tzOffset: number;
  stats: {
    activeDays: number;
    streakDays: number;
    habitsKept: number;
    keypoints: number;
    minutes: number;
  };
  days: Array<{ date: string; active: boolean; mood: number | null }>;
  /** ⑤ the AI Coach block. Null when the week has nothing to show — the norm at first. */
  coach: IWeekRecapCoach | null;
  lessons: Array<{
    courseId: string;
    courseTitle: string;
    image: string;
    lessonId: string;
    lessonTitle: string;
  }>;
  habits: Array<{ habitId: string; title: string; doneCount: number }>;
  favouriteCourse: { courseId: string; title: string; image: string } | null;
  viewedAt: string | null;
  dismissedAt: string | null;
}

export interface WeekRecapSummaryDto {
  id: string;
  weekNumber: number;
  weekStart: string;
  weekEnd: string;
}

/**
 * "Hành trình tuần qua" — the week that just finished, wrapped as one poster.
 *
 * The week is cut and written the first time a client asks for it, not by a
 * cron. Two reasons, both load-bearing:
 *
 * 1. The boundary is the learner's local Monday. A single scheduled run has to
 *    pick one timezone, and would hand everyone outside it a week starting on
 *    the wrong day. The client already sends `tzOffset` on every progress call.
 * 2. `@Cron` handlers in this app are singletons, and injecting anything
 *    request-scoped bubbles `Scope.REQUEST` up the graph and silently stops the
 *    schedule firing at all — the trap already documented on
 *    `notification-campaign.service.ts` and `segment.module.ts`. This service
 *    reads `RequestService`, so it could never have been the cron's collaborator
 *    without being split in two.
 *
 * Generation only ever covers the week immediately past. A learner joining
 * today does not get a year of empty posters backfilled.
 */
@Injectable()
export class WeekRecapService {
  private readonly logger = new Logger(WeekRecapService.name);

  constructor(
    private readonly weekRecapRepository: WeekRecapRepository,
    private readonly weekRecapHabitRepository: WeekRecapHabitRepository,
    private readonly studyJournalRepository: StudyJournalRepository,
    private readonly requestService: RequestService,
    private readonly coachDayLogService: CoachDayLogService,
    private readonly coachReflectionService: CoachReflectionService,
    private readonly coachPlanService: CoachPlanService,
  ) {}

  private get userId(): string {
    return this.requestService.user?.id?.toString() ?? '';
  }

  /**
   * Last week's poster, generating it if this is the first ask.
   *
   * `archiveCount` rides along so the client can decide the Library "Sổ tay"
   * row and the locked popup's secondary button without a second round trip —
   * both are the same question ("do I have any recap at all") asked at the same
   * moment.
   */
  async getCurrent(dto: GetCurrentWeekRecapDto): Promise<{
    recap: WeekRecapDto | null;
    archiveCount: number;
  }> {
    const tzOffset = dto.tzOffset ?? 0;
    const weeksAgo = dto.weekOffset ?? 1;
    const now = new Date();
    const bounds = weekBounds(now, tzOffset, weeksAgo);

    // The week still in progress is a PREVIEW: built live and thrown away. It
    // must not be stored, because storing it would give an unfinished week a
    // `weekNumber` and a slot in the Sổ tay that the real Monday recap would
    // then collide with.
    if (weeksAgo === 0) {
      const preview = await this.build(bounds, tzOffset);
      const archiveCount = await this.weekRecapRepository.countArchive(this.userId);

      return {
        // Shown with the number Monday WILL assign (nextWeekNumber is exactly
        // archiveCount + 1) — a poster titled "Tuần 00" reads as broken. Still
        // never written, so nothing is actually spent.
        recap: preview.hasActivity
          ? this.toDto({
              ...this.asDocument(preview),
              weekNumber: archiveCount + 1,
            } as WeekRecap)
          : null,
        archiveCount,
      };
    }

    let recap = await this.weekRecapRepository.findForWeek(
      this.userId,
      bounds.weekStart,
    );
    if (!recap) {
      recap = await this.generate(bounds, tzOffset);
    } else if (this.isRebuildable(recap, now)) {
      recap = await this.rebuild(recap, bounds, tzOffset);
    }

    const archiveCount = await this.weekRecapRepository.countArchive(this.userId);

    return {
      recap: recap.hasActivity ? this.toDto(recap) : null,
      archiveCount,
    };
  }

  /**
   * Whether a stored recap may still be recomputed.
   *
   * Only while the learner has never been shown it — once they have, the numbers
   * they saw are the numbers, and a poster they may already have shared must not
   * drift. And only inside [REBUILD_WINDOW_MS], so a quiet week does not
   * re-aggregate on every app open for the rest of time.
   */
  private isRebuildable(recap: WeekRecap, now: Date): boolean {
    if (recap.viewedAt || recap.dismissedAt) return false;

    return now.getTime() - recap.weekEnd.getTime() < REBUILD_WINDOW_MS;
  }

  /** The Sổ tay grid. Quiet weeks are not in it. */
  async getArchive(
    dto: GetWeekRecapArchiveDto,
  ): Promise<IResponseListPage<WeekRecapSummaryDto>> {
    const page = dto.page ?? 1;
    const take = dto.take ?? 20;

    const [rows, total] = await Promise.all([
      this.weekRecapRepository.findArchive({
        userId: this.userId,
        skip: (page - 1) * take,
        take,
      }),
      this.weekRecapRepository.countArchive(this.userId),
    ]);

    return {
      items: rows.map(row => this.toSummaryDto(row)),
      itemsPerPage: take,
      totalPages: Math.ceil(total / take),
      currentPage: page,
    };
  }

  async getById(id: string): Promise<WeekRecapDto> {
    const recap = await this.weekRecapRepository.findOwnedById(this.userId, id);
    if (!recap) {
      throw new NotFoundException('Week recap not found');
    }

    return this.toDto(recap);
  }

  /**
   * "Xem hành trình" and "Để sau" — two different promises.
   *
   * Viewing silences the Monday popup for good. "Để sau" mutes it only for the
   * rest of today: the popup re-offers on the first open of every day, Monday
   * through Sunday, until the week is actually seen. That is why the dismissed
   * stamp moves on every press while the viewed stamp is written exactly once.
   */
  async markInteracted(id: string, field: 'viewedAt' | 'dismissedAt'): Promise<void> {
    const recap = await this.weekRecapRepository.findOwnedById(this.userId, id);
    if (!recap) {
      throw new NotFoundException('Week recap not found');
    }

    if (field === 'viewedAt') {
      await this.weekRecapRepository.stampViewed({ userId: this.userId, id });
    } else {
      await this.weekRecapRepository.stampDismissed({ userId: this.userId, id });
    }
  }

  /**
   * Cuts the week. Pure computation — nothing is written here.
   *
   * Both halves are read in parallel and everything after is plain arithmetic
   * in memory: a week is a few dozen keypoints at most, so one pass over the
   * rows costs less than the four separate aggregations it would take to have
   * the database do the same grouping.
   *
   * Split out from [generate] so the in-progress preview and a rebuild can reuse
   * it without either of them being able to write a `weekNumber` by accident.
   */
  private async build(
    bounds: WeekBounds,
    tzOffset: number,
  ): Promise<Omit<Partial<WeekRecap>, 'weekNumber'> & { hasActivity: boolean }> {
    const [items, checkins, dayLogs, coach] = await Promise.all([
      this.studyJournalRepository.findItemsInWindow({
        userId: this.userId,
        fromUtc: bounds.weekStart,
        toUtc: bounds.weekEnd,
      }),
      this.weekRecapHabitRepository.findInRange({
        userId: this.userId,
        dateOnlyFrom: bounds.dateOnlyFrom,
        dateOnlyTo: bounds.dateOnlyTo,
      }),
      // The day-level mood the Coach records, which outranks a journal mood —
      // see `buildDays`.
      this.coachDayLogService.findBetween(
        this.userId,
        bounds.weekStart,
        bounds.weekEnd,
      ),
      this.buildCoachBlock(bounds),
    ]);

    const days = this.buildDays(bounds, tzOffset, items, checkins, dayLogs);
    const habits = this.buildHabits(checkins);

    return {
      userId: this.userId,
      weekStart: bounds.weekStart,
      weekEnd: bounds.weekEnd,
      tzOffset,
      // Read off the seven days rather than off the two source lists, so it can
      // never disagree with the calendar the poster draws. A week whose only
      // trace is a journal mood still counts: someone wrote something down.
      hasActivity: days.some(day => day.active),
      stats: {
        activeDays: days.filter(day => day.active).length,
        streakDays: longestRun(days.map(day => day.active)),
        habitsKept: habits.length,
        keypoints: items.length,
        minutes: items.reduce((sum, item) => sum + (item.minutes ?? 0), 0),
      },
      days,
      lessons: this.buildLessons(items),
      habits,
      favouriteCourse: this.pickFavouriteCourse(items),
      coach,
      generatedAt: new Date(),
    };
  }

  /** Cuts the week and writes it once. */
  private async generate(bounds: WeekBounds, tzOffset: number): Promise<WeekRecap> {
    const built = await this.build(bounds, tzOffset);

    return this.weekRecapRepository.createIfAbsent({
      ...built,
      // Zero for a quiet week: the row exists only to stop this aggregation
      // running again, and handing it a number would spend one of the learner's
      // "Tuần NN" on a week they never see.
      weekNumber: built.hasActivity
        ? await this.weekRecapRepository.nextWeekNumber(this.userId)
        : 0,
    });
  }

  /**
   * Recomputes a stored recap the learner has not been shown yet.
   *
   * The existing `weekNumber` is kept, so a rebuild never renumbers a poster.
   * The one exception is a week first cut as quiet that turns out to have
   * activity after all — that one has no number yet and earns one now.
   */
  private async rebuild(
    existing: WeekRecap,
    bounds: WeekBounds,
    tzOffset: number,
  ): Promise<WeekRecap> {
    const built = await this.build(bounds, tzOffset);
    const weekNumber =
      existing.weekNumber > 0
        ? existing.weekNumber
        : built.hasActivity
          ? await this.weekRecapRepository.nextWeekNumber(this.userId)
          : 0;

    const updated = await this.weekRecapRepository.replaceUnseen({
      userId: this.userId,
      weekStart: bounds.weekStart,
      data: { ...built, weekNumber },
    });

    // A concurrent request may have stamped `viewedAt` between the guard and
    // this write, which makes the recap off-limits. The stored copy wins.
    return updated ?? existing;
  }

  /**
   * Dresses a freshly built week as a document so [toDto] can read it.
   *
   * The preview has no `_id` because it was never written; the client uses the
   * id only to mark a recap seen, and an unfinished week is not something to
   * mark.
   */
  private asDocument(
    built: Omit<Partial<WeekRecap>, 'weekNumber'> & { hasActivity: boolean },
  ): WeekRecap {
    return { ...built, weekNumber: 0, _id: '' } as unknown as WeekRecap;
  }

  /**
   * The seven calendar cells, Monday first.
   *
   * Keypoint timestamps are mapped through the learner's offset; habit
   * check-ins are already a bare calendar date at UTC midnight and are read
   * with no offset at all. Applying the offset to both is how a habit ends up
   * a day away from the keypoint it was done beside.
   */
  private buildDays(
    bounds: WeekBounds,
    tzOffset: number,
    items: StudyDayItem[],
    checkins: WeekRecapCheckin[],
    dayLogs: Array<{ date: Date; mood?: number | null }> = [],
  ): IWeekRecapDay[] {
    const studied = new Set(
      items.map(item => formatLocalDate(item.submittedAt, tzOffset)),
    );

    const ticked = new Set<string>();
    const moods = new Map<string, number>();
    for (const checkin of checkins) {
      const date = formatLocalDate(checkin.date, 0);
      if (checkin.done) ticked.add(date);
      // Rows arrive oldest first, so the last write wins: the mood shown is the
      // most recent thing the learner said about that day, not the first.
      if (checkin.mood) moods.set(date, checkin.mood);
    }

    // The Coach's day-level mood WINS over a journal mood, and that ordering is
    // the point of having two sources at all. `habit_checkins.mood` answers
    // "how did that one habit feel"; the Coach asks "how is your day", which is
    // the question this row of the poster is actually captioned with. Applied
    // second so it overwrites rather than being overwritten, and weeks that
    // predate Coach simply have no rows here and keep their old behaviour.
    for (const log of dayLogs) {
      if (!log.mood) continue;
      moods.set(formatLocalDate(log.date, 0), log.mood);
    }

    return bounds.dates.map(date => {
      const mood = moods.get(date);
      const day: IWeekRecapDay = {
        date,
        // A mood counts as showing up even with nothing ticked: the poster
        // draws a chip for it, and a chip on a day the stamps call inactive
        // reads as one of the two being broken.
        active: studied.has(date) || ticked.has(date) || mood !== undefined,
      };
      if (mood) day.mood = mood;

      return day;
    });
  }

  /**
   * The notepad's rows: the last few DISTINCT lessons of the week.
   *
   * Distinct by lesson, because six keypoints of one lesson is one thing the
   * learner did and six near-identical rows would read as six. Most recent
   * first — the poster is read top-down and the freshest memory belongs at the
   * top.
   */
  private buildLessons(items: StudyDayItem[]): IWeekRecapLesson[] {
    const seen = new Set<string>();
    const rows: IWeekRecapLesson[] = [];

    for (let index = items.length - 1; index >= 0; index--) {
      const item = items[index];
      if (seen.has(item.lessonId)) continue;
      seen.add(item.lessonId);
      rows.push({
        courseId: item.courseId,
        courseTitle: item.courseTitle,
        image: item.image ?? '',
        lessonId: item.lessonId,
        lessonTitle: item.lessonTitle,
      });
      if (rows.length === POSTER_LESSON_ROWS) break;
    }

    return rows;
  }

  /**
   * "THÓI QUEN ĐÃ GIỮ", most-kept first.
   *
   * `done` only: a journal written on a day the habit was skipped still carries
   * that day's mood, but listing it here would credit work nobody did.
   */
  private buildHabits(checkins: WeekRecapCheckin[]): IWeekRecapHabit[] {
    const byHabit = new Map<string, IWeekRecapHabit>();

    for (const checkin of checkins) {
      if (!checkin.done || !checkin.habitId) continue;
      const existing = byHabit.get(checkin.habitId);
      if (existing) {
        existing.doneCount += 1;
        continue;
      }
      byHabit.set(checkin.habitId, {
        habitId: checkin.habitId,
        title: checkin.title,
        doneCount: 1,
      });
    }

    return [...byHabit.values()].sort((a, b) => b.doneCount - a.doneCount);
  }

  /** The week's centre of gravity: most keypoints, then most minutes. */
  private pickFavouriteCourse(items: StudyDayItem[]) {
    const byCourse = new Map<
      string,
      { courseId: string; title: StudyDayItem['courseTitle']; image: string; count: number; minutes: number }
    >();

    for (const item of items) {
      const existing = byCourse.get(item.courseId);
      if (existing) {
        existing.count += 1;
        existing.minutes += item.minutes ?? 0;
        continue;
      }
      byCourse.set(item.courseId, {
        courseId: item.courseId,
        title: item.courseTitle,
        image: item.image ?? '',
        count: 1,
        minutes: item.minutes ?? 0,
      });
    }

    const ranked = [...byCourse.values()].sort(
      (a, b) => b.count - a.count || b.minutes - a.minutes,
    );

    if (!ranked.length) return undefined;

    return {
      courseId: ranked[0].courseId,
      title: ranked[0].title,
      image: ranked[0].image,
    };
  }

  /**
   * Titles are resolved here rather than at write time: one document serves all
   * five locales, and a learner who switches language should see their own
   * history in the new one.
   */
  /**
   * ⑤ — the Coach's four blocks for this week, or null when there is nothing.
   *
   * Null rather than a shape full of zeroes: the poster must draw nothing at
   * all in that case. A "0 done, 0 missed" panel is a worse answer than no
   * panel, because it reports a bad week rather than a week the Coach was not
   * part of — and for the first weeks after launch that is everybody.
   */
  private async buildCoachBlock(
    bounds: WeekBounds,
  ): Promise<IWeekRecapCoach | null> {
    const userId = this.userId;

    const [evidence, ownWords, answered, answerCount, pairs] =
      await Promise.all([
        this.coachReflectionService.findEvidenceBetween(
          userId,
          bounds.weekStart,
          bounds.weekEnd,
        ),
        this.coachReflectionService.findProblemStatementsBetween(
          userId,
          bounds.weekStart,
          bounds.weekEnd,
        ),
        this.coachPlanService.findAnsweredBetween(
          userId,
          bounds.weekStart,
          bounds.weekEnd,
        ),
        this.coachReflectionService.countAnswersBetween(
          userId,
          bounds.weekStart,
          bounds.weekEnd,
        ),
        this.coachReflectionService.findAnswerPairs(userId),
      ]);

    const practised = {
      done: answered.filter(p => p.lastAnswer === 'done').length,
      missed: answered.filter(p => p.lastAnswer === 'missed').length,
      noOccasion: answered.filter(p => p.lastAnswer === 'none').length,
      answers: answerCount,
    };

    const hasAnything =
      evidence.length > 0 ||
      ownWords.length > 0 ||
      answered.length > 0 ||
      answerCount > 0;

    if (!hasAnything) return null;

    return {
      evidence: evidence.map(row => row.content),
      practised,
      change: this.pickChange(pairs),
      ownWords: ownWords.map(row => row.content),
    };
  }

  /**
   * The widest-apart pair of answers to the SAME situation, if any pair spans
   * the minimum gap.
   *
   * Widest rather than most recent: the point of the block is to show distance
   * travelled, and two answers a week apart rarely read as change even when
   * they differ. Below the gap the block is omitted entirely rather than shown
   * with a caveat.
   */
  private pickChange(
    pairs: Array<{
      first: { content: string; createdAt: Date };
      latest: { content: string; createdAt: Date };
    }>,
  ): IWeekRecapCoach['change'] {
    const WEEK_MS = 7 * 24 * 60 * 60 * 1000;

    const eligible = pairs
      .map(pair => ({
        pair,
        weeks: Math.floor(
          (new Date(pair.latest.createdAt).getTime() -
            new Date(pair.first.createdAt).getTime()) /
            WEEK_MS,
        ),
      }))
      .filter(entry => entry.weeks >= CHANGE_BLOCK_MIN_WEEKS)
      // Identical wording is not change, however long the gap.
      .filter(
        entry =>
          entry.pair.first.content.trim() !== entry.pair.latest.content.trim(),
      )
      .sort((a, b) => b.weeks - a.weeks);

    const best = eligible[0];
    if (!best) return null;

    return {
      before: best.pair.first.content,
      after: best.pair.latest.content,
      weeksApart: best.weeks,
    };
  }

  private toDto(recap: WeekRecap): WeekRecapDto {
    const lang = I18nContext.current()?.lang ?? 'en';

    return {
      id: recap._id.toString(),
      weekNumber: recap.weekNumber,
      weekStart: recap.weekStart.toISOString(),
      weekEnd: recap.weekEnd.toISOString(),
      tzOffset: recap.tzOffset,
      stats: recap.stats,
      days: (recap.days ?? []).map(day => ({
        date: day.date,
        active: day.active,
        mood: day.mood ?? null,
      })),
      lessons: (recap.lessons ?? []).map(lesson => ({
        courseId: lesson.courseId,
        courseTitle: getTranslationValue(lesson.courseTitle, lang),
        image: lesson.image ?? '',
        lessonId: lesson.lessonId,
        lessonTitle: getTranslationValue(lesson.lessonTitle, lang),
      })),
      habits: (recap.habits ?? []).map(habit => ({
        habitId: habit.habitId,
        title: getTranslationValue(habit.title, lang),
        doneCount: habit.doneCount,
      })),
      favouriteCourse: recap.favouriteCourse
        ? {
            courseId: recap.favouriteCourse.courseId,
            title: getTranslationValue(recap.favouriteCourse.title, lang),
            image: recap.favouriteCourse.image ?? '',
          }
        : null,
      coach: recap.coach ?? null,
      viewedAt: recap.viewedAt ? recap.viewedAt.toISOString() : null,
      dismissedAt: recap.dismissedAt ? recap.dismissedAt.toISOString() : null,
    };
  }

  private toSummaryDto(recap: WeekRecap): WeekRecapSummaryDto {
    return {
      id: recap._id.toString(),
      weekNumber: recap.weekNumber,
      weekStart: recap.weekStart.toISOString(),
      weekEnd: recap.weekEnd.toISOString(),
    };
  }
}
