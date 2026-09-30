import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';

import { RequestService } from '@base/service/request.service';
import { normalizeTimezoneOffset } from 'src/modules/courses/src/modules/progress/src/modules/user-streak/user-streak.helper';
import { SubscriptionService } from 'src/modules/payment/subscriptions/subscription.service';
import { UserRepository } from 'src/modules/user/src/modules/auth/repository/user.repository';

import { CheckInUserHabitDto } from './dto/check-in-user-habit.dto';
import { CreateUserHabitDto } from './dto/create-user-habit.dto';
import { GetCheckinsUserHabitDto } from './dto/get-checkins-user-habit.dto';
import { GetListUserHabitDto } from './dto/get-list-user-habit.dto';
import { UpdateUserHabitDto } from './dto/update-user-habit.dto';
import { UserHabitState } from './enum/user-habit.enum';
import { HabitCheckinRepository } from './repository/habit-checkin.repository';
import { UserHabitRepository } from './repository/user-habit.repository';
import { UserProgressReadRepository } from './repository/user-progress-read.repository';
import { UserHabit } from './schema/user-habit.schema';
import {
  buildWeekGrid,
  computeStreakFromDoneDates,
  getDayDiff,
  getWeekStartDate,
  localDateOnly,
  localDateOnlyFromOffsetMinutes,
  normalizeDateOnly,
} from './user-habit.helper';
import { HabitConfigService } from '../habit-config/habit-config.service';
import { HabitLibraryService } from '../habit-library/habit-library.service';

// [CONFIRM-2 in design.md] free active-habit slot cap; unlimited with an
// active subscription (SubscriptionService.findActivePremiumForUser).
// The effective value is admin-configurable (HabitConfigService); this
// constant remains as the fallback default.
export const FREE_ACTIVE_HABIT_SLOTS = 3;

@Injectable()
export class UserHabitService {
  constructor(
    private readonly userHabitRepository: UserHabitRepository,
    private readonly habitCheckinRepository: HabitCheckinRepository,
    private readonly userProgressReadRepository: UserProgressReadRepository,
    private readonly habitLibraryService: HabitLibraryService,
    private readonly habitConfigService: HabitConfigService,
    private readonly subscriptionService: SubscriptionService,
    private readonly userRepository: UserRepository,
    private readonly requestService: RequestService,
    private readonly i18n: I18nService,
  ) {}

  private get userId(): string {
    return this.requestService.user?.id?.toString?.();
  }

  /**
   * "Today" for the caller — the single definition every date-only read and write
   * in this service shares.
   *
   * It must be one definition or nothing adds up: the writes used to file a
   * check-in under the server's UTC date while the 21:00 habit reminder asked for
   * the user's local date, so for UTC+7 anything ticked before 07:00 looked
   * unchecked. Mixing the two the other way round would be just as wrong — the
   * today/week grids would blank out a check-in just made.
   *
   * Two sources, in this order:
   * 1. `x-timezone-offset`, the same header `user-streak` reads. It comes from the
   *    device making the call, so it survives a stale stored zone and travel.
   * 2. The `timezone` on the user document, for app builds that predate the
   *    header — which is the whole point of fixing this server-side.
   *
   * Neither available keeps the old UTC behaviour rather than guessing a zone.
   */
  // Public because it must stay the ONE definition of "today for this caller"
  // across every date-only read and write in the habit domain — including
  // HabitPracticeService, which stamps an attempt with the same day the
  // check-in it files lands on. Re-deriving it there would reintroduce exactly
  // the UTC-vs-local split the comment above warns about.
  async localToday(): Promise<Date> {
    const rawOffset = this.requestService.headers?.['x-timezone-offset'];
    if (rawOffset !== undefined && rawOffset !== '') {
      return localDateOnlyFromOffsetMinutes(
        normalizeTimezoneOffset(rawOffset),
      );
    }

    const user = await this.userRepository.findOne(
      { _id: this.userId } as any,
      { timezone: 1 },
    );
    return localDateOnly((user as any)?.timezone);
  }

  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  private async hasUnlimitedSlots(userId: string): Promise<boolean> {
    const activeSubscription =
      await this.subscriptionService.findActivePremiumForUser(userId);
    return Boolean(activeSubscription);
  }

  private async assertSlotAvailable(userId: string) {
    const [activeCount, unlimited, freeSlots] = await Promise.all([
      this.userHabitRepository.countActiveForUser(userId),
      this.hasUnlimitedSlots(userId),
      this.habitConfigService.getFreeActiveSlots(),
    ]);

    if (!unlimited && activeCount >= freeSlots) {
      throw new ConflictException({
        code: 'SLOT_FULL',
        // Included so clients can render the CURRENT admin-configured cap
        // instead of a hardcoded number.
        freeActiveSlots: freeSlots,
        message: this.i18n.t('error.HABIT.SLOT_FULL', { lang: this.lang }),
      });
    }
  }

  private async enrichWithLibrary<T extends { habitId: any }>(items: T[]) {
    const habitIds = Array.from(
      new Set(items.map(item => item.habitId?.toString())),
    );
    const libraryHabits = await this.habitLibraryService.findByIds(habitIds);
    const byId = new Map(
      libraryHabits.map(habit => [habit._id.toString(), habit]),
    );

    return items.map(item => ({
      ...item,
      habit: byId.get(item.habitId?.toString()) ?? null,
    }));
  }

  // Shared by adopt/update/check-in so every single-item response carries the
  // SAME shape as findAll's list items (habit title/icon + today/week grid) —
  // Flutter replaces its cached item with whatever these endpoints return, so
  // an inconsistent shape here would silently blank out the card's title,
  // icon, and weekly grid after any pause/resume/check-in action.
  private async enrichSingleUserHabit(userHabit: UserHabit) {
    const [enriched] = await this.enrichWithLibrary([userHabit]);
    const id = (userHabit as any)._id.toString();
    const today = await this.localToday();
    const weekStartDate = getWeekStartDate(today);
    const weekEndDate = new Date(weekStartDate);
    weekEndDate.setUTCDate(weekStartDate.getUTCDate() + 6);

    const [todayDates, weekDates] = await Promise.all([
      this.habitCheckinRepository.findDoneDatesInRange(id, today, today),
      this.habitCheckinRepository.findDoneDatesInRange(
        id,
        weekStartDate,
        weekEndDate,
      ),
    ]);

    return {
      ...enriched,
      todayDone: todayDates.length > 0,
      weekStartDate,
      weekGrid: buildWeekGrid(weekStartDate, weekDates),
    };
  }

  async adopt(dto: CreateUserHabitDto) {
    const userId = this.userId;
    const [habit] = await this.habitLibraryService.findByIds([dto.habitId]);
    if (!habit) {
      throw new NotFoundException(
        this.i18n.t('error.HABIT.NOT_FOUND', { lang: this.lang }),
      );
    }

    await this.assertSlotAvailable(userId);

    const created = await this.userHabitRepository.create(
      {
        userId,
        habitId: dto.habitId as any,
        state: UserHabitState.ACTIVE,
        reminderTime: dto.reminderTime ?? habit.defaultReminderTime,
        packLength: dto.packLength ?? (3 as any),
        startedAt: new Date(),
        currentStreak: 0,
        bestStreak: 0,
        totalCheckIns: 0,
        lastCheckInDate: null,
        sourceKeypointId: (dto.sourceKeypointId ?? null) as any,
        sourceCourseId: (dto.sourceCourseId ?? null) as any,
        reanchorReasonId: (dto.reanchorReasonId ?? null) as any,
        reanchorReason: (dto.reanchorReason ?? null) as any,
      },
      this.requestService.user as any,
    );

    return this.enrichSingleUserHabit(created);
  }

  async findAll(dto: GetListUserHabitDto) {
    const userId = this.userId;
    const userHabits = await this.userHabitRepository.findForUser(
      userId,
      dto.state,
    );
    if (!userHabits.length) return [];

    const today = await this.localToday();
    const weekStartDate = getWeekStartDate(today);
    const weekEndDate = new Date(weekStartDate);
    weekEndDate.setUTCDate(weekStartDate.getUTCDate() + 6);

    // enrichWithLibrary and this week's done check-ins are independent — fetch
    // them concurrently instead of one after the other. Check-ins for ALL
    // habits are batched into a single $in query (today always falls within
    // [weekStartDate, weekEndDate]), mirroring findSummary.
    const allIds = userHabits.map(h => (h as any)._id.toString());
    const [enrichedAll, weekDoneCheckins] = await Promise.all([
      this.enrichWithLibrary(userHabits),
      this.habitCheckinRepository.findDoneForUserHabitsInRange(
        allIds,
        weekStartDate,
        weekEndDate,
      ),
    ]);
    // Drop habits whose library entry has been deleted (habit == null): they'd
    // render as blank cards (no title/icon) and inflate the "N tasks" count.
    // The orphaned user_habit rows stay in the DB, they just never surface.
    const enriched = enrichedAll.filter(e => (e as any).habit != null);
    const doneDatesByHabit = new Map<string, Date[]>();
    for (const c of weekDoneCheckins) {
      const key = (c.userHabitId as any)?.toString();
      if (!key) continue;
      const dates = doneDatesByHabit.get(key) ?? [];
      dates.push(normalizeDateOnly(c.date));
      doneDatesByHabit.set(key, dates);
    }

    return enriched.map(userHabit => {
      const id = (userHabit as any)._id.toString();
      const weekDates = doneDatesByHabit.get(id) ?? [];
      const todayDone = weekDates.some(d => d.getTime() === today.getTime());

      return {
        ...userHabit,
        todayDone,
        weekStartDate,
        weekGrid: buildWeekGrid(weekStartDate, weekDates),
      };
    });
  }

  // One round-trip for the Habit screen. The app used to fire GET /habit-config
  // + GET /user-habits + GET /user-habits/summary as three concurrent calls,
  // each paying its own network latency (and, on a slow dev link, dragging one
  // another). This runs the same three reads server-side in parallel and returns
  // them together, so the client makes a single request. The three standalone
  // endpoints stay for older app builds.
  async getScreenData(dto: GetListUserHabitDto) {
    const [config, habits, summary] = await Promise.all([
      this.habitConfigService.getConfig(),
      this.findAll(dto),
      this.findSummary(),
    ]);

    return { config, habits, summary };
  }

  async findSummary() {
    const userId = this.userId;
    const allUserHabits = await this.userHabitRepository.findForUser(userId);

    // The recapped week = the Mon–Sun week containing the user's own "today".
    // Every stat below is scoped to this week so the screen matches its header
    // date range, instead of mixing a "today" rate with lifetime totals. We only
    // count up to today, never future days of the week.
    const today = await this.localToday();
    const weekStartDate = getWeekStartDate(today);
    const weekEndDate = new Date(weekStartDate);
    weekEndDate.setUTCDate(weekStartDate.getUTCDate() + 6);
    const rangeEnd = today.getTime() < weekEndDate.getTime() ? today : weekEndDate;
    // Exclusive upper bound (start of the day after rangeEnd) for the
    // timestamp-based lessons query.
    const rangeEndExclusive = new Date(rangeEnd);
    rangeEndExclusive.setUTCDate(rangeEnd.getUTCDate() + 1);

    // enrichWithLibrary (for the best-habit title), the lessons-passed-this-week
    // count, and this week's done check-ins are mutually independent — each
    // depends only on the habits/userId/dates resolved above, not on one
    // another — so fetch all three concurrently instead of in three serialized
    // round-trips:
    //   (1) lessons passed THIS WEEK (by LessonResult.submittedAt)
    //   (2)+(3) done check-ins THIS WEEK across ALL the user's habits, so
    //       "Total check-ins" reflects everything they did this week (even a
    //       habit paused later in the week); the rate is over ACTIVE habits only.
    const allIds = allUserHabits.map(h => h._id.toString());
    const [enrichedAll, totalLessons, weekDoneCheckins] = await Promise.all([
      this.enrichWithLibrary(allUserHabits),
      this.userProgressReadRepository.countPassedLessonsInRange(
        userId,
        weekStartDate,
        rangeEndExclusive,
      ),
      this.habitCheckinRepository.findDoneForUserHabitsInRange(
        allIds,
        weekStartDate,
        rangeEnd,
      ),
    ]);
    // Exclude habits whose library entry was deleted (habit == null) so the
    // recap stats (count, rate, best habit, total check-ins) match the
    // library-filtered list and don't count blank/orphaned habits.
    const enriched = enrichedAll.filter(h => (h as any).habit != null);
    const validIds = new Set(enriched.map(h => (h as any)._id.toString()));
    const activeHabits = enriched.filter(
      h => (h as any).state === UserHabitState.ACTIVE,
    );

    // Best habit (longest loop) — enriched so the card can show its title.
    let bestHabit: { title: Record<string, string>; loop: number } | null =
      null;
    for (const h of enriched) {
      const loop = (h as any).bestStreak ?? 0;
      if (loop > 0 && h.habit && (!bestHabit || loop > bestHabit.loop)) {
        bestHabit = { title: (h.habit as any).title ?? {}, loop };
      }
    }

    const totalCheckIns = weekDoneCheckins.filter(c =>
      validIds.has((c.userHabitId as any)?.toString()),
    ).length;

    // Check-in rate = done ÷ opportunities over the week, counting each active
    // habit only from the day it started — so adopting mid-week isn't scored
    // against the days before the habit existed. The numerator is clipped to
    // the same [effectiveStart..rangeEnd] window as the denominator: check-ins
    // CAN be backdated via the API's `date` param, and counting a done that
    // predates the habit's start would push the rate past 100%.
    const doneDatesByHabit = new Map<string, Date[]>();
    for (const c of weekDoneCheckins) {
      const key = (c.userHabitId as any)?.toString();
      if (!key) continue;
      const dates = doneDatesByHabit.get(key) ?? [];
      dates.push(normalizeDateOnly(c.date));
      doneDatesByHabit.set(key, dates);
    }
    let doneCount = 0;
    let opportunityCount = 0;
    for (const h of activeHabits) {
      const habitStart = normalizeDateOnly((h as any).startedAt ?? weekStartDate);
      const effectiveStart =
        habitStart.getTime() > weekStartDate.getTime()
          ? habitStart
          : weekStartDate;
      if (effectiveStart.getTime() > rangeEnd.getTime()) continue;
      opportunityCount += getDayDiff(rangeEnd, effectiveStart) + 1; // inclusive
      const dates = doneDatesByHabit.get(h._id.toString()) ?? [];
      doneCount += dates.filter(
        d => d.getTime() >= effectiveStart.getTime(),
      ).length;
    }
    const checkInRate =
      opportunityCount > 0
        ? Math.min(100, Math.round((doneCount / opportunityCount) * 100))
        : 0;

    return {
      checkInRate,
      activeCount: activeHabits.length,
      bestStreak: enriched.reduce(
        (max, h) => Math.max(max, (h as any).bestStreak ?? 0),
        0,
      ),
      totalCheckIns,
      totalLessons,
      bestHabit,
      // Server-driven Weekly-recap trigger: the client shows the recap on the
      // server's Sunday (UTC) and dedups by this week start, so it no longer
      // depends on the device clock (which a user can fake / have wrong).
      isRecapDay: today.getUTCDay() === 0,
      weekStartDate,
    };
  }

  async update(id: string, dto: UpdateUserHabitDto) {
    const userId = this.userId;
    const userHabit = await this.userHabitRepository.findOneForUser(
      id,
      userId,
    );
    if (!userHabit) {
      throw new NotFoundException(
        this.i18n.t('error.HABIT.USER_HABIT_NOT_FOUND', { lang: this.lang }),
      );
    }

    if (dto.state === UserHabitState.ACTIVE && userHabit.state !== UserHabitState.ACTIVE) {
      await this.assertSlotAvailable(userId);
    }

    await this.userHabitRepository.updateOne(
      { _id: id },
      { ...dto },
      this.requestService.user as any,
    );

    const refreshed = await this.userHabitRepository.findOneForUser(
      id,
      userId,
    );
    return this.enrichSingleUserHabit(refreshed);
  }

  async remove(id: string) {
    const userId = this.userId;
    const userHabit = await this.userHabitRepository.findOneForUser(
      id,
      userId,
    );
    if (!userHabit) {
      throw new NotFoundException(
        this.i18n.t('error.HABIT.USER_HABIT_NOT_FOUND', { lang: this.lang }),
      );
    }

    await this.userHabitRepository.updateOne(
      { _id: id },
      { state: UserHabitState.ARCHIVED },
      this.requestService.user as any,
    );

    return { success: true };
  }

  async checkIn(id: string, dto: CheckInUserHabitDto) {
    const userId = this.userId;
    const userHabit = await this.userHabitRepository.findOneForUser(
      id,
      userId,
    );
    if (!userHabit) {
      throw new NotFoundException(
        this.i18n.t('error.HABIT.USER_HABIT_NOT_FOUND', { lang: this.lang }),
      );
    }

    // The client normally sends its own local calendar date. When it doesn't —
    // the app's own check-in call omits `date` — resolve the day from the user's
    // stored timezone instead of the server's UTC date, or a UTC+7 reader ticking
    // before 07:00 files the check-in under yesterday.
    const today = await this.localToday();
    const dateOnly = dto.date ? normalizeDateOnly(dto.date) : today;
    await this.habitCheckinRepository.upsertDay(id, dateOnly, dto.done, {
      note: dto.note,
      method: dto.method,
      mood: dto.mood,
      score: dto.score,
    });

    const doneDates = await this.habitCheckinRepository.findDoneDates(id);
    const { currentStreak, lastCheckInDate } = computeStreakFromDoneDates(
      doneDates,
      today,
    );

    await this.userHabitRepository.updateOne(
      { _id: id },
      {
        currentStreak,
        bestStreak: Math.max(userHabit.bestStreak ?? 0, currentStreak),
        totalCheckIns: doneDates.length,
        lastCheckInDate,
      },
      this.requestService.user as any,
    );

    const refreshed = await this.userHabitRepository.findOneForUser(
      id,
      userId,
    );
    return this.enrichSingleUserHabit(refreshed);
  }

  // Full check-in log for one habit — powers the Habit detail heatmap
  // (done per date) and diary list (note per date).
  async getCheckins(id: string, dto: GetCheckinsUserHabitDto) {
    const userId = this.userId;
    const userHabit = await this.userHabitRepository.findOneForUser(
      id,
      userId,
    );
    if (!userHabit) {
      throw new NotFoundException(
        this.i18n.t('error.HABIT.USER_HABIT_NOT_FOUND', { lang: this.lang }),
      );
    }

    const from = dto.from ? normalizeDateOnly(dto.from) : undefined;
    const to = dto.to ? normalizeDateOnly(dto.to) : undefined;

    const checkins = await this.habitCheckinRepository.findAllForUserHabit(
      id,
      from,
      to,
    );

    return checkins.map(checkin => ({
      date: normalizeDateOnly(checkin.date).toISOString().slice(0, 10),
      done: checkin.done,
      ...(checkin.note !== undefined ? { note: checkin.note } : {}),
      ...(checkin.method !== undefined ? { method: checkin.method } : {}),
      ...(checkin.mood !== undefined ? { mood: checkin.mood } : {}),
      ...(checkin.score !== undefined ? { score: checkin.score } : {}),
    }));
  }
}
