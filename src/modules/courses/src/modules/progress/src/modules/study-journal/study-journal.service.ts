import { Injectable } from '@nestjs/common';
import { I18nContext } from 'nestjs-i18n';

import { RequestService } from '@base/service/request.service';
import { getTranslationValue } from '@utils/translate';

import { GetStudyJournalDayDto, GetStudyJournalDto } from './dto/study-journal.dto';
import { StudyJournalHabitRepository } from './repository/study-journal-habit.repository';
import { StudyJournalRepository } from './repository/study-journal.repository';

/**
 * Keypoints-per-day thresholds behind the calendar's four shades.
 *
 * Fixed rather than relative to the learner's own best day: a scale that
 * rescales itself makes today's square change colour because of what happened
 * last week, and the legend ("Ít → Nhiều") would then mean something different
 * in every screenshot. One keypoint is already a day that counts — level 1
 * starts there, so showing up is never rendered as nothing.
 */
const LEVEL_THRESHOLDS = [1, 2, 4, 6];

const MINUTES_PER_HOUR = 60;

export interface StudyJournalDay {
  date: string;
  keypoints: number;
  /** 0 = no study, 1..4 = the legend's four shades. */
  level: number;
}

@Injectable()
export class StudyJournalService {
  constructor(
    private readonly studyJournalRepository: StudyJournalRepository,
    private readonly studyJournalHabitRepository: StudyJournalHabitRepository,
    private readonly requestService: RequestService,
  ) {}

  private get userId(): string {
    return this.requestService.user?.id?.toString() ?? '';
  }

  /**
   * One month of the learner's calendar, in their own timezone.
   *
   * Returns only the days that have study on them. The client draws the empty
   * squares itself — it already knows the month's shape, and sending 31 zeroes
   * would make the response mostly padding.
   */
  async getMonth(dto: GetStudyJournalDto): Promise<{
    month: string;
    tzOffset: number;
    days: StudyJournalDay[];
    summary: { activeDays: number; keypoints: number };
    firstActiveDate: string | null;
  }> {
    const tzOffset = dto.tzOffset ?? 0;
    const month = dto.month ?? this.currentMonth(tzOffset);
    const [year, monthIndex] = month.split('-').map(Number);

    // The window is built in local time and shifted into UTC, which is what the
    // stored timestamps are: local midnight on the 1st through local midnight on
    // the 1st of the next month.
    const fromUtc = this.localMidnightToUtc(year, monthIndex, 1, tzOffset);
    const toUtc = this.localMidnightToUtc(year, monthIndex + 1, 1, tzOffset);

    const [counts, firstAt] = await Promise.all([
      this.studyJournalRepository.countKeypointsPerDay({
        userId: this.userId,
        fromUtc,
        toUtc,
        tzOffsetString: this.tzOffsetString(tzOffset),
      }),
      this.studyJournalRepository.findFirstSubmissionAt(this.userId),
    ]);

    const days = counts.map(row => ({
      date: row.date,
      keypoints: row.keypoints,
      level: this.levelOf(row.keypoints),
    }));

    return {
      month,
      tzOffset,
      days,
      summary: {
        activeDays: days.length,
        keypoints: days.reduce((sum, day) => sum + day.keypoints, 0),
      },
      firstActiveDate: firstAt
        ? this.formatLocalDate(firstAt, tzOffset)
        : null,
    };
  }

  /**
   * What the learner studied on one local day — the list behind "chạm vào ô
   * ngày để xem lịch sử học".
   *
   * Titles are resolved to the request's language here rather than in the
   * repository: the repository's job ends at the raw translation object, and
   * the same document serves five locales.
   */
  async getDay(dto: GetStudyJournalDayDto): Promise<{
    date: string;
    tzOffset: number;
    summary: { lessons: number; minutes: number; habits: number };
    courses: Array<{
      courseId: string;
      title: string;
      image: string;
      lessons: number;
      minutes: number;
    }>;
    habits: Array<{
      userHabitId: string;
      habitId: string;
      title: string;
      image: string;
      method: string | null;
      note: string | null;
    }>;
  }> {
    const tzOffset = dto.tzOffset ?? 0;
    const [year, month, day] = dto.date.split('-').map(Number);
    const fromUtc = this.localMidnightToUtc(year, month, day, tzOffset);
    const toUtc = this.localMidnightToUtc(year, month, day + 1, tzOffset);

    const [rows, habitRows] = await Promise.all([
      this.studyJournalRepository.findItemsInWindow({
        userId: this.userId,
        fromUtc,
        toUtc,
      }),
      // Habit check-ins are filed date-only at UTC midnight, so the same
      // calendar day is addressed by that midnight rather than by the shifted
      // window above (see StudyJournalHabitRepository).
      this.studyJournalHabitRepository.findDoneOnDate({
        userId: this.userId,
        dateOnlyUtc: new Date(Date.UTC(year, month - 1, day)),
      }),
    ]);
    const lang = I18nContext.current()?.lang ?? 'en';

    // One row per COURSE, not per keypoint: a day of six keypoints inside one
    // course is one thing the learner did, and six near-identical rows read as
    // six unrelated ones. The keypoint count and minutes roll up into the row
    // instead of being spelled out line by line.
    const courses = new Map<
      string,
      { courseId: string; title: string; image: string; lessons: number; minutes: number }
    >();
    for (const row of rows) {
      const existing = courses.get(row.courseId);
      if (existing) {
        existing.lessons += 1;
        existing.minutes += row.minutes ?? 0;
        continue;
      }
      courses.set(row.courseId, {
        courseId: row.courseId,
        title: getTranslationValue(row.courseTitle, lang),
        image: row.image ?? '',
        lessons: 1,
        minutes: row.minutes ?? 0,
      });
    }

    const grouped = [...courses.values()];

    return {
      date: dto.date,
      tzOffset,
      summary: {
        // Still counted in keypoints: that is what the calendar square shades
        // by, and a header that disagreed with the square it was opened from
        // would look like a bug in one of the two.
        lessons: rows.length,
        minutes: grouped.reduce((sum, course) => sum + course.minutes, 0),
        habits: habitRows.length,
      },
      courses: grouped,
      habits: habitRows.map(habit => ({
        userHabitId: habit.userHabitId,
        habitId: habit.habitId,
        title: getTranslationValue(habit.title, lang),
        image: habit.image ?? '',
        method: habit.method ?? null,
        note: habit.note ?? null,
      })),
    };
  }

  /** 0 for an empty day, then one shade per threshold crossed. */
  private levelOf(keypoints: number): number {
    return LEVEL_THRESHOLDS.filter(threshold => keypoints >= threshold).length;
  }

  private currentMonth(tzOffset: number): string {
    const local = new Date(Date.now() + tzOffset * 60_000);

    return `${local.getUTCFullYear()}-${this.pad(local.getUTCMonth() + 1)}`;
  }

  /**
   * Local midnight of (year, month, day) as the instant it is in UTC.
   *
   * `Date.UTC` normalises out-of-range parts for us, which is what lets the
   * callers above ask for "the 1st of month+1" and "day+1" without handling
   * December or the 31st as special cases.
   */
  private localMidnightToUtc(
    year: number,
    month: number,
    day: number,
    tzOffset: number,
  ): Date {
    return new Date(Date.UTC(year, month - 1, day) - tzOffset * 60_000);
  }

  private formatLocalDate(instant: Date, tzOffset: number): string {
    const local = new Date(instant.getTime() + tzOffset * 60_000);

    return [
      local.getUTCFullYear(),
      this.pad(local.getUTCMonth() + 1),
      this.pad(local.getUTCDate()),
    ].join('-');
  }

  /** `+07:00` / `-05:30`, the offset form `$dateToString` accepts. */
  private tzOffsetString(tzOffset: number): string {
    const sign = tzOffset < 0 ? '-' : '+';
    const absolute = Math.abs(tzOffset);

    return `${sign}${this.pad(Math.floor(absolute / MINUTES_PER_HOUR))}:${this.pad(
      absolute % MINUTES_PER_HOUR,
    )}`;
  }

  private pad(value: number): string {
    return String(value).padStart(2, '0');
  }
}
