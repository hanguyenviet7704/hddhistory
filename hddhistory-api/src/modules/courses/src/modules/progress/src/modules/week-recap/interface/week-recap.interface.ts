import { ITranslation } from '@utils/interface/common.interface';

/** One of the seven days on the poster's calendar row. */
export interface IWeekRecapDay {
  /** Local calendar day, `YYYY-MM-DD`. */
  date: string;
  /** Studied a keypoint or ticked a habit on this day. */
  active: boolean;
  /**
   * Journal mood, 1..3, absent when the learner filed no journal that day.
   *
   * Absent is NOT the same as low: the poster leaves such a day without a
   * chip so its date number shows through, which is how a day off reads as a
   * day off rather than as a bad day.
   */
  mood?: number;
}

/** A row of the poster's "BÀI HỌC TUẦN QUA" notepad. */
export interface IWeekRecapLesson {
  courseId: string;
  courseTitle: ITranslation;
  image: string;
  lessonId: string;
  lessonTitle: ITranslation;
}

/** A line of the poster's "THÓI QUEN ĐÃ GIỮ" list. */
export interface IWeekRecapHabit {
  habitId: string;
  title: ITranslation;
  /** Days in the week this habit was ticked. Drives the list's order. */
  doneCount: number;
}

/**
 * ⑤ "Bản ghi cải thiện" — the AI Coach's four blocks, appended to the poster.
 *
 * Null on a week with none of it, and the poster then draws nothing: an empty
 * "what changed" panel is worse than no panel, because it reads as a week where
 * nothing changed rather than a week the feature has nothing to say about. It
 * WILL be null for everyone for the first few weeks, which is expected.
 */
export interface IWeekRecapCoach {
  /** ĐỜI THẬT — what actually happened out there, in their words. */
  evidence: string[];
  /**
   * ĐÃ TẬP — how the week's answers fell out.
   *
   * Counts only, and only upward: the poster never draws a downward arrow on
   * these. "The occasion came and I didn't take it" is not a regression to be
   * charted at somebody.
   */
  practised: { done: number; missed: number; noOccasion: number; answers: number };
  /**
   * ĐỔI THAY — the same situation, answered twice, at least three weeks apart.
   *
   * Only possible because situations are cached rather than generated fresh:
   * `situationId` is what makes the two answers comparable.
   */
  change: { before: string; after: string; weeksApart: number } | null;
  /** CHỮ CỦA CHÍNH BẠN — "the real problem is …", from ⑦. */
  ownWords: string[];
}

export interface IWeekRecapCourse {
  courseId: string;
  title: ITranslation;
  image: string;
}

/**
 * The four stamps, plus `activeDays` which the client's encouragement sentence
 * is chosen from.
 *
 * All five travel even though the poster draws four: the artwork's captions are
 * the designer's to change, and a caption that starts meaning something else
 * should cost a client binding, not an API change plus a backfill of every
 * document already written.
 */
export interface IWeekRecapStats {
  activeDays: number;
  streakDays: number;
  habitsKept: number;
  keypoints: number;
  minutes: number;
}

export interface IWeekRecap {
  userId: string;
  weekStart: Date;
  weekEnd: Date;
  tzOffset: number;
  weekNumber: number;
  hasActivity: boolean;
  stats: IWeekRecapStats;
  days: IWeekRecapDay[];
  coach?: IWeekRecapCoach | null;
  lessons: IWeekRecapLesson[];
  habits: IWeekRecapHabit[];
  favouriteCourse?: IWeekRecapCourse;
  viewedAt?: Date;
  dismissedAt?: Date;
  generatedAt: Date;
}
