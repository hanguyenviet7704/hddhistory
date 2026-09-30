import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';

import { RequestService } from '@base/service/request.service';
import { Keypoint } from 'src/modules/courses/src/modules/keypoint/schema/keypoint.schema';
import { LessonType } from 'src/modules/courses/src/modules/lesson/enum/lesson.enum';
import { Lesson } from 'src/modules/courses/src/modules/lesson/schema/lesson.schema';
import { GradeResultType } from 'src/modules/courses/src/modules/progress/src/modules/user-progress/enum/user-progress.enum';

import { IUserStreakResponse } from './interface/user-streak.interface';
import { UserStreakRepository } from './repository/user-streak.repository';
import { UserStreak } from './schema/user-streak.schema';
import {
  getDayDiff,
  getWeekContext,
  inferLastCompletedDate,
  normalizeTimezoneOffset,
  normalizeWeekStudy,
  toFloatingDay,
} from './user-streak.helper';

type StreakContext = {
  streak: UserStreak;
  previousCompletedDate: Date | null;
  today: Date;
  todayIndex: number;
};

@Injectable()
export class UserStreakService {
  constructor(
    private readonly userStreakRepository: UserStreakRepository,
    @InjectModel(Lesson.name)
    private readonly lessonModel: Model<Lesson>,
    @InjectModel(Keypoint.name)
    private readonly keypointModel: Model<Keypoint>,
    private readonly requestService: RequestService,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  /**
   * The caller's UTC offset in minutes, so every day boundary below is the one
   * the user actually sees on their phone. Absent header = 0 (UTC).
   */
  private get timezoneOffsetMinutes() {
    return normalizeTimezoneOffset(
      this.requestService.headers?.['x-timezone-offset'],
    );
  }

  async getStreak(userId = this.user?.id?.toString?.()) {
    if (!userId) {
      const { weekStartDate } = getWeekContext(
        new Date(),
        this.timezoneOffsetMinutes,
      );
      return {
        weekStartDate,
        weekStudy: normalizeWeekStudy(),
        studyTime: 0,
        currentStreak: 0,
        bestStreak: 0,
      } as IUserStreakResponse;
    }

    const { streak } = await this.getCurrentSyncedStreakContext(userId, {
      persistSyncChanges: false,
    });

    return {
      weekStartDate: streak.weekStartDate,
      weekStudy: normalizeWeekStudy(streak.weekStudy),
      studyTime: Math.max(0, +streak.studyTime || 0),
      currentStreak: Math.max(0, +streak.currentStreak || 0),
      bestStreak: Math.max(0, +streak.bestStreak || 0),
    } as IUserStreakResponse;
  }

  async updateUserStudyTime(params: {
    grade: GradeResultType;
    lessonType?: LessonType;
    dto: any;
  }) {
    const { grade, lessonType, dto } = params;
    const activity = await this.getEstimateCompleTimeNumberLearningUnits({
      grade,
      lessonType,
      dto,
    });

    if (!activity.shouldCountAsCompletion) {
      return;
    }

    const userId = dto?.userId?.toString?.();
    if (!userId) {
      return;
    }

    if (activity.studyTimeToAdd <= 0) {
      return;
    }

    // TV: Chỉ còn cộng studyTime. Việc đánh dấu ngày (weekStudy/currentStreak)
    // đã chuyển sang [markPresence] — streak giờ tính theo thời gian ở trong
    // app, không theo việc hoàn thành bài học nữa.
    const { streak } = await this.getCurrentSyncedStreakContext(userId);
    streak.studyTime =
      Math.max(0, +streak.studyTime || 0) + activity.studyTimeToAdd;

    await this.persistStreak(streak);
  }

  /**
   * Marks TODAY as a day the user showed up, which is now the only thing that
   * moves the streak. The app calls this once a day, after the reader has had
   * the app in the foreground for the admin-configured number of seconds
   * (`streak-config.triggerAfterSeconds`).
   *
   * Idempotent: a second call on the same day writes nothing and returns the
   * streak unchanged, so a retry after a flaky request is free.
   */
  async markPresence(userId = this.user?.id?.toString?.()) {
    if (!userId) {
      return this.getStreak(userId);
    }

    const { streak, previousCompletedDate, today, todayIndex } =
      await this.getCurrentSyncedStreakContext(userId);

    if (this.applyDayCompletion({ streak, previousCompletedDate, today, todayIndex })) {
      await this.persistStreak(streak);
    }

    return {
      weekStartDate: streak.weekStartDate,
      weekStudy: normalizeWeekStudy(streak.weekStudy),
      studyTime: Math.max(0, +streak.studyTime || 0),
      currentStreak: Math.max(0, +streak.currentStreak || 0),
      bestStreak: Math.max(0, +streak.bestStreak || 0),
    } as IUserStreakResponse;
  }

  /**
   * Ticks [todayIndex] on the week strip and moves `currentStreak` accordingly.
   * Mutates [streak] in place and reports whether anything changed; persisting
   * is the caller's job.
   *
   * TV: Hôm nay đã được đánh dấu rồi thì không tăng streak lần hai.
   */
  private applyDayCompletion(context: {
    streak: UserStreak;
    previousCompletedDate: Date | null;
    today: Date;
    todayIndex: number;
  }) {
    const { streak, previousCompletedDate, today, todayIndex } = context;
    const weekStudy = normalizeWeekStudy(streak.weekStudy);

    if (weekStudy[todayIndex]) {
      return false;
    }

    const gapDays = previousCompletedDate
      ? getDayDiff(today, previousCompletedDate)
      : null;

    // TV: gapDays=1 nghĩa là học liền ngày -> +1 streak.
    // Các trường hợp còn lại (lần đầu hoặc đứt streak) -> reset về 1.
    streak.currentStreak =
      gapDays === 1 ? Math.max(0, +streak.currentStreak || 0) + 1 : 1;
    weekStudy[todayIndex] = true;
    streak.weekStudy = weekStudy;
    streak.bestStreak = Math.max(
      Math.max(0, +streak.bestStreak || 0),
      Math.max(0, +streak.currentStreak || 0),
    );

    return true;
  }

  private async persistStreak(streak: UserStreak) {
    await this.userStreakRepository.updateOne(
      { userId: streak.userId },
      {
        weekStartDate: streak.weekStartDate,
        weekStudy: normalizeWeekStudy(streak.weekStudy),
        studyTime: Math.max(0, +streak.studyTime || 0),
        currentStreak: Math.max(0, +streak.currentStreak || 0),
        bestStreak: Math.max(0, +streak.bestStreak || 0),
      },
      this.user,
    );
  }

  // TV: Hàm này chỉ quyết định "event này có được tính streak không"
  // và "được cộng bao nhiêu phút studyTime", chưa đụng vào state streak.
  private async getEstimateCompleTimeNumberLearningUnits(params: {
    grade: GradeResultType;
    lessonType?: LessonType;
    dto: any;
  }): Promise<{ shouldCountAsCompletion: boolean; studyTimeToAdd: number }> {
    const { grade, lessonType, dto } = params;

    // Roleplay/Practice/Video learning is tracked from lesson-grade payload.
    if (grade === GradeResultType.LESSON) {
      const isLessonCompletionTracked =
        lessonType === LessonType.ROLEPLAY ||
        lessonType === LessonType.OUTPUT ||
        lessonType === LessonType.VIDEO;
      if (!isLessonCompletionTracked || !dto?.lessonId) {
        return { shouldCountAsCompletion: false, studyTimeToAdd: 0 };
      }

      const lesson = await this.lessonModel
        .findOne({ _id: dto.lessonId }, { estimateCompleTimeNumber: 1 })
        .lean();

      return {
        shouldCountAsCompletion: true,
        studyTimeToAdd: Math.max(
          0,
          +((lesson as any)?.estimateCompleTimeNumber ?? 0) || 0,
        ),
      };
    }

    // Keypoint learning is tracked only for normal lesson flow.
    if (grade === GradeResultType.KEYPOINT) {
      if (lessonType !== LessonType.LESSON || !Array.isArray(dto?.keypoints)) {
        return { shouldCountAsCompletion: false, studyTimeToAdd: 0 };
      }

      // TV: Chỉ cần có update keypoint (có keypointId) là tính học và cộng studyTime.
      const completedKeypointIds = Array.from(
        new Set<string>(
          dto.keypoints
            .filter((item: any) => item?.keypointId)
            .map((item: any) => String(item.keypointId)) as string[],
        ),
      );

      if (!completedKeypointIds.length) {
        return { shouldCountAsCompletion: false, studyTimeToAdd: 0 };
      }

      const keypoints = await this.keypointModel
        .find(
          { _id: { $in: completedKeypointIds } },
          { estimateCompleTimeNumber: 1 },
        )
        .lean();

      return {
        shouldCountAsCompletion: true,
        studyTimeToAdd: keypoints.reduce(
          (sum, keypoint: any) =>
            sum + Math.max(0, +(keypoint?.estimateCompleTimeNumber ?? 0) || 0),
          0,
        ),
      };
    }

    return { shouldCountAsCompletion: false, studyTimeToAdd: 0 };
  }

  // TV: "Synced" nghĩa là record sau khi đã áp dụng đầy đủ rule đứt streak + đổi tuần.
  private async getCurrentSyncedStreakContext(
    userId: string,
    options?: {
      persistSyncChanges?: boolean;
    },
  ): Promise<StreakContext> {
    const persistSyncChanges = options?.persistSyncChanges ?? true;
    const {
      todayStart,
      weekStartDate: currentWeekStartDate,
      weekDayIndex,
    } = getWeekContext(new Date(), this.timezoneOffsetMinutes);
    const defaultWeekStartDate = currentWeekStartDate;
    const existingStreak = await this.userStreakRepository.findOne(
      { userId },
      {},
      { lean: true },
    );

    // - cần get lại weekStartDate chuẩn thời gian hiện tại
    const streak = existingStreak
      ? ({
          ...(existingStreak as UserStreak),
          // toFloatingDay, NOT getWeekContext: the stored date is already a
          // calendar day in the user's timezone, so shifting it by the offset a
          // second time would move it a day backwards every read.
          weekStartDate: existingStreak.weekStartDate
            ? toFloatingDay(existingStreak.weekStartDate)
            : defaultWeekStartDate,
          weekStudy: normalizeWeekStudy(existingStreak.weekStudy),
          studyTime: Math.max(0, +existingStreak.studyTime || 0),
          currentStreak: Math.max(0, +existingStreak.currentStreak || 0),
          bestStreak: Math.max(0, +existingStreak.bestStreak || 0),
        } as UserStreak)
      : ((await this.userStreakRepository.create(
          {
            userId,
            weekStartDate: defaultWeekStartDate,
            weekStudy: normalizeWeekStudy(),
            studyTime: 0,
            currentStreak: 0,
            bestStreak: 0,
          },
          this.user,
        )) as UserStreak);

    const today = todayStart;
    const normalizedWeekStudy = normalizeWeekStudy(streak.weekStudy);
    const normalizedWeekStartDate =
      streak.weekStartDate || currentWeekStartDate;
    const previousCompletedDate = inferLastCompletedDate(
      normalizedWeekStartDate,
      normalizedWeekStudy,
    );

    let hasStreakChanges = false;

    // GET and COMPLETE both need this guard:
    // TV: Nếu bỏ >= 1 ngày trọn vẹn (chênh từ 2 ngày trở lên) thì coi như đứt streak.
    if (
      previousCompletedDate &&
      getDayDiff(today, previousCompletedDate) >= 2
    ) {
      if (Math.max(0, +streak.currentStreak || 0) !== 0) {
        streak.currentStreak = 0;
        hasStreakChanges = true;
      }
    }

    // sang tuần mới
    if (normalizedWeekStartDate.getTime() !== currentWeekStartDate.getTime()) {
      streak.weekStartDate = currentWeekStartDate;
      streak.weekStudy = normalizeWeekStudy();
      streak.studyTime = 0;
      hasStreakChanges = true;
    } else if (
      streak.weekStudy.some(
        (day, index) => Boolean(day) !== Boolean(normalizedWeekStudy[index]),
      )
    ) {
      streak.weekStudy = normalizedWeekStudy;
      hasStreakChanges = true;
    }

    const currentWeekStudy = normalizeWeekStudy(streak.weekStudy);
    const hasCompletedDayInCurrentWeek = currentWeekStudy.some(Boolean);
    const todayIndex = weekDayIndex;

    // từ thứ 3 trở đi phải ép currentStreak=0 để tránh giữ streak "ảo".
    if (
      !hasCompletedDayInCurrentWeek &&
      todayIndex > 0 &&
      Math.max(0, +streak.currentStreak || 0) !== 0
    ) {
      streak.currentStreak = 0;
      hasStreakChanges = true;
    }

    // TV: Với luồng GET streak, chỉ cần tính đúng kết quả trả về, không bắt buộc ghi DB.
    // Tránh case thứ 2: GET vào thứ 2 làm reset tuần và mất dấu completion chủ nhật.
    if (hasStreakChanges && persistSyncChanges) {
      await this.persistStreak(streak);
    }

    return {
      streak,
      previousCompletedDate,
      today,
      todayIndex,
    };
  }
}
