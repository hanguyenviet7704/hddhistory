import { Injectable } from '@nestjs/common';

import { localDateOnlyFromOffsetMinutes } from 'src/modules/habit/src/modules/user-habit/user-habit.helper';

import { DayLogMoment } from './enum/day-log.enum';
import { UserDayLogRepository } from './repository/user-day-log.repository';

/**
 * The day's mood, and the ⑥ line.
 *
 * Both at user+day grain, both optional on the same document, because the two
 * writers are independent: the mood prompt records a level with no note, and ⑥
 * records a note with no level.
 */
@Injectable()
export class CoachDayLogService {
  constructor(private readonly repository: UserDayLogRepository) {}

  /**
   * The reader's local date as a UTC-midnight stamp.
   *
   * Reuses the habit domain's helper rather than re-deriving it: the two write
   * date-only rows that end up side by side on the same weekly recap, and two
   * definitions of "today" is exactly how a check-in made at 06:00 in UTC+7
   * lands on yesterday.
   */
  localDate(tzOffsetMinutes: number, now: Date = new Date()): Date {
    return localDateOnlyFromOffsetMinutes(tzOffsetMinutes, now);
  }

  async hasStartMoodToday(
    userId: string,
    tzOffsetMinutes: number,
  ): Promise<boolean> {
    return this.repository.hasStartMoodOn(
      userId,
      this.localDate(tzOffsetMinutes),
    );
  }

  async recordMood(params: {
    userId: string;
    tzOffsetMinutes: number;
    moment: DayLogMoment;
    mood: number;
    sessionId?: string | null;
  }) {
    const { userId, tzOffsetMinutes, moment, mood, sessionId } = params;

    return this.repository.create({
      userId,
      date: this.localDate(tzOffsetMinutes),
      moment,
      mood,
      sessionId: sessionId ?? null,
    });
  }

  /** ⑥ — the one line someone writes when they do not want to talk today. */
  async recordNote(params: {
    userId: string;
    tzOffsetMinutes: number;
    note: string;
    sessionId?: string | null;
  }) {
    const { userId, tzOffsetMinutes, note, sessionId } = params;

    return this.repository.create({
      userId,
      date: this.localDate(tzOffsetMinutes),
      moment: DayLogMoment.START,
      note,
      sessionId: sessionId ?? null,
    });
  }

  async findBetween(userId: string, from: Date, to: Date) {
    return this.repository.findBetween(userId, from, to);
  }
}
