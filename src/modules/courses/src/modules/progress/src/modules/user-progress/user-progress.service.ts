import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Types } from 'mongoose';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';

import { LoggerService } from '@base/logging/logger.service';
import { RequestService } from '@base/service/request.service';
import { ITranslation } from '@utils/interface/common.interface';
import { IResponseListPage } from '@utils/interface/paging/page.interface';
import { viewerMarketsForRequest } from '@utils/market-query.util';
import { OrderType } from '@utils/type/orderByType';
import { R2Service } from 'src/modules/file/cloudflare/config/r2.config';
import { resolveTimezoneOffsetMinutes } from 'src/modules/keypoint-access/keypoint-access.util';
import { KeypointQuotaLedgerService } from 'src/modules/keypoint-access/keypoint-quota-ledger.service';
import { UserRepository } from 'src/modules/user/src/modules/auth/repository/user.repository';

import { DeleteUserProgressDto } from './dto/delete-user-progress.dto';
import {
  GetCourseDropOffDto,
  GetDropOffOverviewDto,
} from './dto/get-course-drop-off.dto';
import {
  GetListMyCourseDto,
  GetUserProgressDto,
  GetProgressOfUserDto,
} from './dto/get-list-user-progress.dto';
import { StatisticsUsersLearningCoursesDto } from './dto/statistics-users-learning-courses.dto';
import { UpdateCompletedLevelAdditionalContentRequestDto } from './dto/user-progress.dto';
import { UserProgressExportStatus } from './enum/user-progress-export.enum';
import {
  GradeResultType,
  StatisticsUsersLearningCoursesOrderBy,
} from './enum/user-progress.enum';
import { countPassedItems } from './helper/passed-count.helper';
import {
  ICompletedLevel,
  IKeypointResult,
  IAchievenmentResponse,
  ICourseLearningStatistics,
  ICourseLevelProgress,
  ICourseProgressSummary,
  IExerciseResultSummary,
  IKeypointResultDetail,
  ILessonResultDetail,
  IStopAtDetail,
  IStopAt,
  IUserProgressDetail,
  ProgressSnapshot,
} from './interface/user-progress.interface';
import { UserProgressExportRepository } from './repository/user-progress-export.repository';
import { UserProgressRepository } from './repository/user-progress.repository';
import { UserProgress } from './schema/user-progress.schema';
import {
  EXPORT_COOLDOWN_MS,
  EXPORT_FILE_KEY,
  EXPORT_JOB_NAME,
  buildExportResponse,
  buildExportArchive,
} from './user-progress-export.helper';
import { ensureProgressNode, isKeypointPassed } from './user-progress.helper';
import { CourseLevel, CourseStatus } from '../../../../course/enum/course.enum';
import { ICourseBrief } from '../../../../course/interface/course.interface';
import { CourseRepository } from '../../../../course/repository/course.repository';
import { RoadmapRepository } from '../../../../course/repository/roadmap.repository';
import { ContentSource } from '../../../../course-version/content-source.service';
import { UserFeedbackRepository } from '../../../../feedback/user-feedback/repository/user-feedback.repository';
import { IKeypointBrief } from '../../../../keypoint/interface/keypoint.interface';
import { KeypointRepository } from '../../../../keypoint/repository/keypoint.repository';
import { ExerciseInput } from '../../../../learning-item/interface/learning-item.interface';
import { LearningItemRepository } from '../../../../learning-item/repository/learning-item.repository';
import { LessonType } from '../../../../lesson/enum/lesson.enum';
import { ILessonBrief2 } from '../../../../lesson/interface/lesson.interface';
import { LessonRepository } from '../../../../lesson/repository/lesson.repository';
import { CategoryStatus } from '../../../../category/enum/category.enum';
import { CategoryRepository } from '../../../../category/repository/category.repository';
import { UserStreakService } from '../user-streak/user-streak.service';

interface AchievementsCatalog {
  categories: any[];
  categoryCoursesMap: Map<string, any[]>;
  roadmapMap: Map<string, any>;
}

interface DailyWarmUpResponse {
  courseId?: string;
  suggestedCourseId?: string;
  lessonId?: string | null;
  keypointId?: string;
  isCourseCompleted?: boolean;
  submittedAt?: Date;
  questions: ExerciseInput[];
}

@Injectable()
export class UserProgressService {
  // getAchievements() previously re-fetched the ENTIRE published course
  // catalog (categories + courses + roadmaps) from scratch on every call, for
  // every user — identical data reused across every request. This service is
  // request-scoped (it depends on RequestService/`this.user`), so an
  // instance field would be recreated empty on every request just like it
  // was for QuoteRepository before that got fixed — a `static` field is used
  // instead so the cache survives across request-scoped instantiations.
  // Per-user progress is fetched fresh every call (see getAchievements) and
  // is never part of this cache.
  private static achievementsCatalogCache: {
    data: AchievementsCatalog;
    expiresAt: number;
  } | null = null;
  private static readonly ACHIEVEMENTS_CATALOG_TTL_MS = 3 * 60 * 1000;

  constructor(
    private readonly userProgressRepository: UserProgressRepository,
    private readonly learningItemRepository: LearningItemRepository,
    private readonly userStreakService: UserStreakService,
    private readonly courseRepository: CourseRepository,
    private readonly lessonRepository: LessonRepository,
    private readonly keypointRepository: KeypointRepository,
    private readonly roadmapRepository: RoadmapRepository,
    private readonly categoryRepository: CategoryRepository,
    private readonly userProgressExportRepository: UserProgressExportRepository,
    private readonly userFeedbackRepository: UserFeedbackRepository,
    private readonly r2Service: R2Service,
    private readonly requestService: RequestService,
    private readonly userRepository: UserRepository,
    private readonly logger: LoggerService,
    private readonly i18n: I18nService,
    private readonly keypointQuotaLedgerService: KeypointQuotaLedgerService,
    private readonly contentSource: ContentSource,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  /**
   * Markets to scope SUGGESTED courses to, or `null` for the admin panel.
   *
   * Only the suggestion path uses this. A course the reader already has
   * progress in is theirs and stays visible whatever its markets -- the rule is
   * "do not promote it here", not "take it away".
   */
  private get viewerMarkets(): string[] | null {
    return viewerMarketsForRequest(this.requestService.headers);
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async findOne(courseId: string, id: string): Promise<UserProgress> {
    const userProgress = await this.userProgressRepository.findOne({
      _id: id,
      courseId,
    });
    if (!userProgress)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_USER_PROGRESS.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    return userProgress;
  }

  async getDailyWarmUp(): Promise<DailyWarmUpResponse> {
    const userId = this.user.id.toString();
    const activeProgress = await this.userProgressRepository.model
      .findOne({ userId })
      .sort({ lastTime: -1, updatedAt: -1 })
      .lean();

    if (!activeProgress) {
      return { questions: [] };
    }

    let latest = await this.userProgressRepository.findLatestStudiedKeypoint(
      userId,
      activeProgress.courseId,
    );

    if (!latest) {
      latest = await this.userProgressRepository.findLatestStudiedKeypoint(userId);
    }

    if (!latest?.keypoint) {
      return { questions: [] };
    }

    const isCourseCompleted =
      await this.isLastCourseKeypointCompleted(userId, activeProgress.courseId);
    const suggestedCourseId = await this.resolveDailyWarmUpSuggestedCourseId(
      activeProgress.courseId,
      isCourseCompleted,
    );

    // If the latest lesson is already passed, suggest the next uncompleted lesson
    // instead (possibly from a different course).
    const progressForLatestCourse =
      latest.courseId?.toString() === activeProgress.courseId?.toString()
        ? activeProgress
        : await this.userProgressRepository.model
            .findOne({ userId, courseId: latest.courseId })
            .lean();

    const isLatestLessonAttempted = (progressForLatestCourse?.lessonsResult ?? []).some(
      (l: any) => l.lessonId?.toString() === latest.lessonId?.toString(),
    );

    let suggestedLessonId: string | null = latest.lessonId;
    if (isLatestLessonAttempted) {
      const nextInCourse = await this.findNextUncompletedLesson(
        latest.courseId,
        progressForLatestCourse?.lessonsResult ?? [],
      );
      if (nextInCourse) {
        suggestedLessonId = nextInCourse;
      } else if (suggestedCourseId && suggestedCourseId !== latest.courseId?.toString()) {
        const progressForSuggested = await this.userProgressRepository.model
          .findOne({ userId, courseId: suggestedCourseId })
          .lean();
        const nextInSuggested = await this.findNextUncompletedLesson(
          suggestedCourseId,
          progressForSuggested?.lessonsResult ?? [],
        );
        suggestedLessonId = nextInSuggested ?? null;
      } else {
        // User has attempted all lessons in all available courses
        suggestedLessonId = null;
      }
    }

    const exerciseIds = (latest.keypoint.exercisesResult ?? [])
      .map(item => item.exerciseId)
      .filter(Boolean);

    if (!exerciseIds.length) {
      return {
        courseId: latest.courseId,
        suggestedCourseId,
        lessonId: suggestedLessonId,
        keypointId: latest.keypoint.keypointId,
        isCourseCompleted,
        submittedAt: latest.keypoint.submittedAt,
        questions: [],
      };
    }

    const questions = await this.learningItemRepository.findDailyWarmUpQuestions(
      latest.keypoint.keypointId,
      exerciseIds,
    );

    return {
      courseId: latest.courseId,
      suggestedCourseId,
      lessonId: suggestedLessonId,
      keypointId: latest.keypoint.keypointId,
      isCourseCompleted,
      submittedAt: latest.keypoint.submittedAt,
      questions: this.pickRandomQuestions(questions, 3),
    };
  }

  private async findNextUncompletedLesson(
    courseId: string,
    lessonsResult: any[],
  ): Promise<string | null> {
    const attemptedIds = new Set(
      lessonsResult
        .map((l: any) => l.lessonId?.toString())
        .filter(Boolean),
    );

    const roadmap = await this.roadmapRepository.findOne(
      { courseId },
      { levels: 1 },
      { lean: true },
    );

    if (!roadmap?.levels?.length) return null;

    for (const level of roadmap.levels as any[]) {
      for (const node of level.nodes ?? []) {
        for (const lessonId of node.lessonIds ?? []) {
          const id = lessonId?.toString();
          if (id && !attemptedIds.has(id)) return id;
        }
      }
    }

    return null;
  }

  private async resolveDailyWarmUpSuggestedCourseId(
    courseId: string,
    isCourseCompleted: boolean,
  ): Promise<string> {
    if (!isCourseCompleted) return courseId;

    const course = await this.courseRepository.findOne(
      { _id: courseId },
      { categoryId: 1 },
      { lean: true },
    );

    if (!course?.categoryId) return courseId;

    return (
      (await this.courseRepository.findRandomPublishedCourseIdInCategory(
        course.categoryId,
        courseId,
        this.viewerMarkets,
      )) ?? courseId
    );
  }

  private async isLastCourseKeypointCompleted(
    userId: string,
    courseId: string,
  ): Promise<boolean> {
    const [roadmap, progress] = await Promise.all([
      this.roadmapRepository.findOne(
        { courseId },
        { levels: 1 },
        { lean: true },
      ),
      this.userProgressRepository.findOne(
        { userId, courseId },
        { lessonsResult: 1, keypointOptional: 1 },
        { lean: true },
      ),
    ]);
    const lastKeypointId = this.getLastCourseKeypointId(roadmap?.levels);
    if (!lastKeypointId) return false;

    return this.buildPassedKeypointSet(progress as any).has(lastKeypointId);
  }

  private getLastCourseKeypointId(levels: any[] = []) {
    for (let levelIndex = levels.length - 1; levelIndex >= 0; levelIndex -= 1) {
      const keypointIds = Array.isArray(levels[levelIndex]?.keypointIds)
        ? levels[levelIndex].keypointIds
        : [];
      for (let keyIndex = keypointIds.length - 1; keyIndex >= 0; keyIndex -= 1) {
        const keypointId = keypointIds[keyIndex];
        if (keypointId) return keypointId;
      }
    }

    return null;
  }

  private pickRandomQuestions<T extends ExerciseInput>(
    questions: T[],
    limit: number,
  ): T[] {
    if (questions.length <= limit) return questions;

    const shuffled = [...questions];
    for (let i = shuffled.length - 1; i > 0; i -= 1) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }

    return shuffled.slice(0, limit);
  }

  async updateUserProgressResult(grade: GradeResultType, dto: any) {
    const {
      userId,
      courseId,
      lessonId,
      averageScore,
      passed,
      reviews,
      keypoints,
      exercises,
    } = dto;
    const now = new Date();
    let progress = await this.userProgressRepository.findOne(
      {
        userId,
        courseId,
      },
      {},
      { lean: true },
    );

    if (!progress) {
      progress = await this.userProgressRepository.create(
        {
          userId,
          courseId,
          lessonsResult: [],
          completedLevels: [],
          keypointOptional: [],
          lastTime: now,
        },
        this.user,
      );
    }

    const existingLessonType = progress.lessonsResult?.find(
      lesson => lesson.lessonId === lessonId,
    )?.lessonType;
    const lessonType =
      existingLessonType ||
      (lessonId
        ? (
            await this.lessonRepository.findOne(
              { _id: lessonId },
              { type: 1 },
              { lean: true },
            )
          )?.type
        : undefined);

    // Which keypoints were ALREADY finished before this write, for the daily
    // quota: finishing a keypoint spends the day's ticket, re-finishing one does
    // not. `ensureProgressNode` below mutates `progress` in place, so the snapshot
    // has to be taken here or the answer is always "already passed".
    const passedBeforeWrite = this.passedKeypointIdsForQuota(progress);

    const helperPayload: Parameters<typeof ensureProgressNode>[2] = {
      lessonId,
      averageScore,
      passed,
      reviews,
      lessonType,
      keypoints: grade === GradeResultType.KEYPOINT ? keypoints : undefined,
      exercises: grade === GradeResultType.EXERCISE ? exercises : undefined,
      keypointId: dto.keypointId,
    };

    ensureProgressNode(progress, grade, helperPayload);

    const stopAt = this.resolveStopAt(
      lessonType,
      lessonId,
      dto.keypointId,
      keypoints,
    );
    if (stopAt) {
      progress.stopAt = stopAt;
    }
    progress.lastTime = now;

    if (lessonType === LessonType.ROLEPLAY && keypoints?.length) {
      const optionalSet = new Set(progress.keypointOptional || []);
      for (const item of keypoints) {
        if (isKeypointPassed(item.averageScore)) {
          optionalSet.add(item.keypointId);
        } else {
          optionalSet.delete(item.keypointId);
        }
      }
      progress.keypointOptional = [...optionalSet];
    }

    // Update completed levels if roadmap exists and user has passed all keypoints of a level.
    const roadmap = await this.roadmapRepository.findOne(
      { courseId },
      { levels: 1 },
      { lean: true },
    );
    const completedLevels: ICompletedLevel[] = progress.completedLevels || [];
    const existingCompleted = new Set(
      completedLevels.map(level => level.level),
    );
    const passedKeypoints = this.buildPassedKeypointSet(progress as any);
    for (const level of roadmap?.levels || []) {
      const keypointIds: string[] = Array.isArray(level.keypointIds)
        ? level.keypointIds.filter(Boolean)
        : [];
      if (
        keypointIds.length &&
        keypointIds.every(kp => passedKeypoints.has(kp)) &&
        !existingCompleted.has(level.level)
      ) {
        completedLevels.push({
          level: level.level,
          completedAt: new Date(),
        });
        existingCompleted.add(level.level);
      }
    }
    progress.completedLevels = completedLevels;

    const updatePayload: Partial<UserProgress> = {
      lessonsResult: progress.lessonsResult,
      completedLevels,
      keypointOptional: progress.keypointOptional,
      lastTime: now,
    };
    if (stopAt) {
      updatePayload.stopAt = stopAt;
    }

    await this.userProgressRepository.updateOne(
      { userId, courseId },
      updatePayload,
    );

    await this.userStreakService.updateUserStudyTime({
      grade,
      lessonType,
      dto,
    });

    if (grade === GradeResultType.KEYPOINT) {
      await this.spendDailyQuotaOnCompletions(userId, keypoints, passedBeforeWrite);
    }

    return progress;
  }

  /**
   * Charge the daily free-keypoint quota for keypoints FINISHED by this request.
   *
   * This endpoint is what "hoàn thành keypoint" means end to end — the app posts
   * `passed: true` when the reader reaches the end of a deck — so it is where the
   * ticket is spent. Opening a keypoint, reading part of it and leaving writes
   * nothing here and therefore costs nothing.
   *
   * Only keypoints that were NOT already passed count: revision is free, and
   * without [passedBefore] every re-read of an old keypoint would eat the day.
   *
   * The AUTHENTICATED reader is charged, never `dto.userId`: that field comes off
   * the request body, so trusting it would let one client spend another reader's
   * day (or dodge their own by sending someone else's id).
   */
  private async spendDailyQuotaOnCompletions(
    bodyUserId: string,
    keypoints: IKeypointResult[] | undefined,
    passedBefore: Set<string>,
  ): Promise<void> {
    if (!keypoints?.length) return;

    const userId = this.user?.id?.toString();
    if (!userId || (bodyUserId && bodyUserId.toString() !== userId)) return;

    const offsetMinutes = resolveTimezoneOffsetMinutes(
      this.requestService.headers?.['x-timezone-offset'],
    );

    const charged = new Set<string>();
    for (const keypoint of keypoints) {
      const keypointId = keypoint?.keypointId?.toString();
      if (!keypointId || !keypoint.passed) continue;
      if (passedBefore.has(keypointId) || charged.has(keypointId)) continue;
      charged.add(keypointId);

      await this.keypointQuotaLedgerService.recordCompletion({
        userId,
        keypointId,
        offsetMinutes,
      });
    }
  }

  /**
   * Every keypoint marked passed in a progress row, whatever kind of lesson it
   * sits in.
   *
   * Deliberately NOT [buildLessonPassedKeypointSet] (lessons only) or
   * [buildPassedKeypointSet] (lessons plus the roleplay optional list): the quota
   * has to match what `KeypointAccessService` calls "already completed", and that
   * reads `findPassedKeypointIds`, which looks at every keypoint result there is.
   * A narrower set here would charge a reader twice for the same keypoint.
   */
  private passedKeypointIdsForQuota(progress?: UserProgress): Set<string> {
    const passed = new Set<string>();
    for (const lesson of progress?.lessonsResult || []) {
      for (const keypoint of lesson.keypointsResult || []) {
        if (keypoint?.passed && keypoint.keypointId) {
          passed.add(keypoint.keypointId.toString());
        }
      }
    }

    return passed;
  }

  async updateCompletedLevelAdditionalContentRequest(
    dto: UpdateCompletedLevelAdditionalContentRequestDto,
  ) {
    const { userId, courseId, level, requested, requestText } = dto;
    const now = new Date();
    const progress = await this.userProgressRepository.findOne(
      {
        userId,
        courseId,
      },
      {},
      { lean: true },
    );

    if (!progress)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_USER_PROGRESS.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    const completedLevels: ICompletedLevel[] = progress.completedLevels || [];
    const completedLevel = completedLevels.find(item => item.level === level);
    const additionalContentRequest = {
      requested,
      submittedAt: now,
      requestText: requestText ?? '',
    };

    if (completedLevel) {
      completedLevel.additionalContentRequest = additionalContentRequest;
    } else {
      completedLevels.push({
        level,
        completedAt: now,
        additionalContentRequest,
      });
    }

    progress.completedLevels = completedLevels;
    progress.lastTime = now;

    await this.userProgressRepository.updateOne(
      { userId, courseId },
      {
        completedLevels,
        lastTime: now,
      },
    );

    return progress;
  }

  async deleteUserProgress(dto: DeleteUserProgressDto) {
    const { userId, courseId, lessonId, keypointId, exerciseId, grade } = dto;
    const progress = await this.userProgressRepository.findOne(
      { userId, courseId },
      {},
      { lean: true },
    );

    if (!progress)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_USER_PROGRESS.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    progress.lessonsResult ||= [];

    switch (grade) {
      case GradeResultType.COURSE:
        return this.userProgressRepository.deleteOne({ userId, courseId });
      case GradeResultType.LESSON:
        if (!lessonId)
          throw new BadRequestException(
            this.i18n.t('error.COURSE_USER_PROGRESS.LESSON_ID_REQUIRED', {
              lang: this.lang,
            }),
          );
        progress.lessonsResult = progress.lessonsResult.filter(
          lesson => lesson.lessonId !== lessonId,
        );
        break;
      case GradeResultType.KEYPOINT:
        if (!lessonId)
          throw new BadRequestException(
            this.i18n.t('error.COURSE_USER_PROGRESS.LESSON_ID_REQUIRED', {
              lang: this.lang,
            }),
          );
        if (!keypointId)
          throw new BadRequestException(
            this.i18n.t('error.COURSE_USER_PROGRESS.KEYPOINT_ID_REQUIRED', {
              lang: this.lang,
            }),
          );
        progress.lessonsResult = progress.lessonsResult.map(lesson =>
          lesson.lessonId === lessonId
            ? {
                ...lesson,
                keypointsResult: (lesson.keypointsResult || []).filter(
                  keypoint => keypoint.keypointId !== keypointId,
                ),
              }
            : lesson,
        );
        break;
      case GradeResultType.EXERCISE:
        if (!lessonId)
          throw new BadRequestException(
            this.i18n.t('error.COURSE_USER_PROGRESS.LESSON_ID_REQUIRED', {
              lang: this.lang,
            }),
          );
        if (!keypointId)
          throw new BadRequestException(
            this.i18n.t('error.COURSE_USER_PROGRESS.KEYPOINT_ID_REQUIRED', {
              lang: this.lang,
            }),
          );
        if (!exerciseId)
          throw new BadRequestException(
            this.i18n.t('error.COURSE_USER_PROGRESS.EXERCISE_ID_REQUIRED', {
              lang: this.lang,
            }),
          );
        progress.lessonsResult = progress.lessonsResult.map(lesson =>
          lesson.lessonId === lessonId
            ? {
                ...lesson,
                keypointsResult: (lesson.keypointsResult || []).map(keypoint =>
                  keypoint.keypointId === keypointId
                    ? {
                        ...keypoint,
                        exercisesResult: (
                          keypoint.exercisesResult || []
                        ).filter(
                          exercise => exercise.exerciseId !== exerciseId,
                        ),
                      }
                    : keypoint,
                ),
              }
            : lesson,
        );
        break;
      default:
        return progress;
    }

    await this.userProgressRepository.updateOne(
      { userId, courseId },
      { lessonsResult: progress.lessonsResult },
    );

    return progress;
  }

  async getUserProgress(dto: GetUserProgressDto) {
    const { userId, lessonId, keypointId, exerciseId, grade } = dto;
    const result = await this.userProgressRepository.getUserProgress(dto);

    switch (grade) {
      case GradeResultType.COURSE:
        return userId ? result[0] || {} : result;
      case GradeResultType.LESSON:
        if (!lessonId)
          throw new BadRequestException(
            this.i18n.t('error.COURSE_USER_PROGRESS.LESSON_ID_REQUIRED', {
              lang: this.lang,
            }),
          );
        return userId ? result[0]?.lesson || {} : result;
      case GradeResultType.KEYPOINT:
        if (!lessonId)
          throw new BadRequestException(
            this.i18n.t('error.COURSE_USER_PROGRESS.LESSON_ID_REQUIRED', {
              lang: this.lang,
            }),
          );
        if (!keypointId)
          throw new BadRequestException(
            this.i18n.t('error.COURSE_USER_PROGRESS.KEYPOINT_ID_REQUIRED', {
              lang: this.lang,
            }),
          );
        return userId ? result[0]?.keypoint || {} : result;
      case GradeResultType.EXERCISE:
        if (!lessonId)
          throw new BadRequestException(
            this.i18n.t('error.COURSE_USER_PROGRESS.LESSON_ID_REQUIRED', {
              lang: this.lang,
            }),
          );
        if (!keypointId)
          throw new BadRequestException(
            this.i18n.t('error.COURSE_USER_PROGRESS.KEYPOINT_ID_REQUIRED', {
              lang: this.lang,
            }),
          );
        if (!exerciseId)
          throw new BadRequestException(
            this.i18n.t('error.COURSE_USER_PROGRESS.EXERCISE_ID_REQUIRED', {
              lang: this.lang,
            }),
          );
        return userId ? result[0]?.exercise || {} : result;
      default:
        return userId ? result[0] || {} : result;
    }
  }

  async getMyCourse(dto: GetListMyCourseDto) {
    const { recent } = dto;

    if (recent) {
      dto.take = 3;
    }

    const process = await this.userProgressRepository.findOption({
      ...dto,
      userId: this.user.id.toString(),
      order: OrderType.DESC,
      orderBy: 'updatedAt',
    });

    const ids: string[] = [];

    for (const item of process.items) {
      ids.push(item.courseId);
    }

    const couses = await this.courseRepository.findOption({
      ids: ids,
      page: 1,
      take: dto.take,
      isAll: true,
      // Same statuses the categories catalog exposes. Without this, a course
      // unpublished after the user started it keeps its "Continue learning"
      // card on Home -- and tapping that card opened a course the catalog
      // cannot resolve, which the app had no state to render.
      statuses: [CourseStatus.PUBLISHED, CourseStatus.COMING_SOON],
    });

    // Attach the user's completed-item count per course so clients can show a
    // real completion percentage on the "Continue learning" card.
    //
    // The denominator (course.numberOfLesson) counts keypoint-bearing lessons by
    // their KEYPOINT count and video/roleplay/output lessons as one unit each —
    // the SAME unit the roadmap displays (each keypoint is its own roadmap item).
    // The numerator must match that unit: count passed keypoints for keypoint-
    // lessons, and the passed flag for every other lesson type. So 1 of 5
    // keypoint-items reads as 20% and matches the roadmap's "1/5".
    const passedByCourse = new Map<string, number>();
    for (const p of process.items) {
      passedByCourse.set(
        p.courseId.toString(),
        countPassedItems(p.lessonsResult),
      );
    }
    // Restore "last studied first". The progress query above IS ordered by the
    // progress row's `updatedAt` DESC, but that order only decided WHICH courses
    // come back: the course query re-sorts the `$in` by its own default, so by
    // the time the two round trips are done the recency order is gone. Clients
    // that show a history list or a "continue learning" strip (Library, Home)
    // need it, and neither can rebuild it — the course payload carries no
    // progress timestamp. So rank by position in `ids`, which is that order.
    const recencyRank = new Map<string, number>();
    ids.forEach((id, index) => {
      const key = id?.toString();
      // First occurrence wins: `ids` is already newest-first, and a duplicate
      // courseId (two progress rows for one course) must not push it down.
      if (key && !recencyRank.has(key)) recencyRank.set(key, index);
    });
    couses.items = couses.items
      .map((c: any) => ({
        ...c,
        numberOfLessonPassed: passedByCourse.get(c._id.toString()) ?? 0,
      }))
      // A course with no rank (shouldn't happen — every id came from `ids`)
      // sorts last instead of jumping to the front on an undefined compare.
      .sort(
        (a: any, b: any) =>
          (recencyRank.get(a._id.toString()) ?? Number.MAX_SAFE_INTEGER) -
          (recencyRank.get(b._id.toString()) ?? Number.MAX_SAFE_INTEGER),
      );

    return couses;
  }

  async getProgressOfUser(
    userId: string,
    dto: GetProgressOfUserDto,
  ): Promise<IResponseListPage<ICourseProgressSummary>> {
    const orderBy = 'lastTime';
    const progressPage = await this.userProgressRepository.findOption({
      ...dto,
      userId: userId,
      orderBy,
    });

    const progressItems = progressPage.items || [];

    if (!progressItems.length) {
      return { ...progressPage, items: [] };
    }

    const courseIds = [
      ...new Set(progressItems.map(progress => progress.courseId)),
    ];
    const lessonIds = [
      ...new Set(
        progressItems
          .map(progress => progress.stopAt?.lessonId)
          .filter(Boolean) as string[],
      ),
    ];
    const keypointIds = [
      ...new Set(
        progressItems
          .map(progress => progress.stopAt?.keypointId)
          .filter(Boolean) as string[],
      ),
    ];

    const [courses, lessons, keypoints] = await Promise.all([
      this.courseRepository.model
        .find({ _id: { $in: courseIds } }, { _id: 1, title: 1 })
        .lean(),
      // Title hiển thị phải là title ĐÃ PHÁT HÀNH, không phải bản editor
      // đang sửa. Danh sách trải nhiều khoá nên mỗi id đọc từ đúng tag của nó.
      // Xem `plans/260907-course-content-versions/README.md`.
      this.contentSource.getLessonBriefsAcrossVersions(
        lessonIds,
        this.requestService.headers,
      ) as unknown as Promise<ILessonBrief2[]>,
      this.contentSource.getKeypointBriefsAcrossVersions(
        keypointIds,
        this.requestService.headers,
      ) as unknown as Promise<IKeypointBrief[]>,
    ]);

    const courseMap = new Map(
      courses.map(
        course =>
          [course._id.toString(), course] as unknown as [string, ICourseBrief],
      ),
    );
    const lessonMap = new Map(
      lessons.map(
        lesson => [lesson._id.toString(), lesson] as [string, ILessonBrief2],
      ),
    );
    const keypointMap = new Map(
      keypoints.map(
        keypoint =>
          [keypoint._id.toString(), keypoint] as [string, IKeypointBrief],
      ),
    );

    const items = progressItems.map(progress => {
      const course = courseMap.get(progress.courseId);
      const stopAt = progress.stopAt;
      let stopAtDetail: IStopAtDetail | undefined;
      if (stopAt?.lessonId) {
        const lesson = lessonMap.get(stopAt.lessonId);
        const fallbackLessonType = progress.lessonsResult?.find(
          item => item.lessonId === stopAt.lessonId,
        )?.lessonType;
        const keypoint = stopAt.keypointId
          ? keypointMap.get(stopAt.keypointId)
          : undefined;
        stopAtDetail = {
          lessonId: stopAt.lessonId,
          keypointId: stopAt.keypointId,
          lessonTitle: lesson?.title,
          lessonType: lesson?.type ?? fallbackLessonType,
          keypointTitle: keypoint?.title,
        };
      }
      return {
        id: progress.courseId,
        title: course?.title,
        createdAt: progress.createdAt,
        lastTime: progress.lastTime || progress.updatedAt || progress.createdAt,
        completedLevels: progress.completedLevels || [],
        stopAt: stopAtDetail,
      };
    });

    return { ...progressPage, items };
  }

  async getCourseProgressDetailOfUser(
    courseId: string,
    userId: string,
  ): Promise<IUserProgressDetail> {
    const progress = await this.userProgressRepository.findOne(
      { userId, courseId },
      {},
      { lean: true },
    );

    if (!progress)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_USER_PROGRESS.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    const lessonsResult = progress.lessonsResult || [];
    const lessonIds = [
      ...new Set(lessonsResult.map(lesson => lesson.lessonId).filter(Boolean)),
    ];
    const keypointIds = [
      ...new Set(
        lessonsResult
          .flatMap(lesson =>
            (lesson.keypointsResult || []).map(kp => kp.keypointId),
          )
          .filter(Boolean),
      ),
    ];

    const lessonsPromise = this.contentSource.getLessonBriefsAcrossVersions(
      lessonIds,
      this.requestService.headers,
    ) as unknown as Promise<ILessonBrief2[]>;
    const keypointsPromise = this.contentSource.getKeypointBriefsAcrossVersions(
      keypointIds,
      this.requestService.headers,
    ) as unknown as Promise<ILessonBrief2[]>;

    const [lessons, keypoints] = await Promise.all([
      lessonsPromise,
      keypointsPromise,
    ]);

    const lessonMap = new Map(
      lessons.map(
        lesson => [lesson._id.toString(), lesson] as [string, ILessonBrief2],
      ),
    );
    const keypointMap = new Map(
      keypoints.map(
        keypoint =>
          [keypoint._id.toString(), keypoint] as [string, IKeypointBrief],
      ),
    );

    const detailedLessons: ILessonResultDetail[] = lessonsResult.map(lesson => {
      const lessonDoc = lessonMap.get(lesson.lessonId);
      const detailedKeypoints: IKeypointResultDetail[] = (
        lesson.keypointsResult || []
      ).map(keypoint => {
        const keypointDoc = keypointMap.get(keypoint.keypointId);
        const exercisesResult: IExerciseResultSummary[] = (
          keypoint.exercisesResult || []
        ).map((exercise, index) => ({
          exerciseId: exercise.exerciseId,
          passed: exercise.passed,
          score: exercise.score ?? 0,
          index: index + 1,
        }));

        return {
          ...keypoint,
          title: keypointDoc?.title,
          exercisesResult,
        };
      });

      return {
        ...lesson,
        lessonType: lesson.lessonType ?? lessonDoc?.type,
        title: lessonDoc?.title,
        keypointsResult: detailedKeypoints,
      };
    });

    return {
      ...progress,
      lessonsResult: detailedLessons,
    };
  }

  private buildLessonPassedKeypointSet(progress?: UserProgress) {
    const passed = new Set<string>();
    if (!progress?.lessonsResult) return passed;

    for (const lesson of progress.lessonsResult) {
      if (lesson.lessonType !== LessonType.LESSON) continue;
      for (const kp of lesson.keypointsResult || []) {
        if (kp.passed) passed.add(kp.keypointId);
      }
    }

    return passed;
  }

  private resolveStopAt(
    lessonType: LessonType | undefined,
    lessonId: string,
    keypointId?: string,
    keypoints?: { keypointId: string }[],
  ): IStopAt | null {
    if (!lessonId) return null;

    if (lessonType === LessonType.LESSON) {
      const resolvedKeypointId =
        keypointId || keypoints?.[keypoints.length - 1]?.keypointId;
      if (!resolvedKeypointId) return null;
      return { lessonId, keypointId: resolvedKeypointId };
    }

    return { lessonId };
  }

  private buildPassedKeypointSet(progress?: UserProgress) {
    const passed = this.buildLessonPassedKeypointSet(progress);
    for (const keypointId of progress?.keypointOptional || []) {
      passed.add(keypointId);
    }
    return passed;
  }

  /**
   * Collapse a full multi-language ITranslation down to just the request's
   * resolved language (HeaderResolver('lang')), keeping an `en` fallback key so
   * a client whose UI locale momentarily differs still resolves a value. The
   * achievements catalog is cached as raw multi-language data shared across all
   * locales, so this MUST run per-request at response-build time and MUST NOT
   * mutate its input — it always returns a fresh object. Shrinks the payload
   * ~5x on every localized field (en/vi/zh/ja/ko → 1–2 keys).
   */
  private localizeTranslation(translation?: ITranslation): ITranslation {
    const source = (translation ?? {}) as Record<string, string>;
    const lang = this.lang;
    const value = source[lang] ?? source.en ?? '';
    const result: Record<string, string> =
      lang === 'en' ? { en: value } : { [lang]: value, en: source.en ?? value };
    return result as ITranslation;
  }

  private buildLevelProgress(
    level: any,
    progress: ProgressSnapshot,
    courseId: string,
    courseTitle: ITranslation,
  ): ICourseLevelProgress {
    const keys: string[] = Array.isArray(level.keypointIds)
      ? level.keypointIds.filter(Boolean)
      : [];
    const uniqueKeys = [...new Set(keys)];
    const total = uniqueKeys.length;
    const completed = uniqueKeys.filter(k =>
      progress.passedEffective.has(k),
    ).length;
    return {
      level: level.level,
      lightBadge: level.lightBadge,
      darkBadge: level.darkBadge,
      titleBadge: this.localizeTranslation(level.titleBadge),
      courseId,
      courseTitle: this.localizeTranslation(courseTitle),
      totalKeypoints: total,
      completedKeypoints: completed,
      isCompleted: progress.completed.has(level.level),
    };
  }

  private findHighestLevelDone(
    levels: any[] = [],
    progress: ProgressSnapshot,
    courseId: string,
    courseTitle: ITranslation,
  ): ICourseLevelProgress | null {
    if (!levels.length) return null;

    const fallbackLevel = levels[0];
    let highest: ICourseLevelProgress | null = null;
    for (const level of levels) {
      if (!level.lightBadge || !level.darkBadge) continue;
      if (progress.completed.has(level.level)) {
        highest = this.buildLevelProgress(
          level,
          progress,
          courseId,
          courseTitle,
        );
      }
    }

    if (highest) return highest;
    if (fallbackLevel.lightBadge && fallbackLevel.darkBadge) {
      return this.buildLevelProgress(
        fallbackLevel,
        progress,
        courseId,
        courseTitle,
      );
    }
    return null;
  }

  async getBadgeProgress(courseId: string): Promise<ICourseLevelProgress[]> {
    const [roadmap, progress, course] = await Promise.all([
      this.roadmapRepository.findOne(
        { courseId },
        { levels: 1 },
        { lean: true },
      ),
      this.userProgressRepository.findOne(
        { userId: this.user.id, courseId },
        { lessonsResult: 1, completedLevels: 1, keypointOptional: 1 },
        { lean: true },
      ),
      this.courseRepository.model.findById(courseId, { title: 1 }).lean(),
    ]);
    if (!roadmap?.levels?.length) return [];

    const snapshot: ProgressSnapshot = {
      passedLesson: this.buildLessonPassedKeypointSet(progress as any),
      passedEffective: this.buildPassedKeypointSet(progress as any),
      completed: new Set(
        (progress?.completedLevels || []).map(
          (item: ICompletedLevel) => item.level,
        ),
      ),
    };

    const courseTitle = course?.title || {};

    return roadmap.levels
      .filter(level => level.lightBadge && level.darkBadge)
      .map(level =>
        this.buildLevelProgress(level, snapshot, courseId, courseTitle),
      );
  }

  // Categories/courses/roadmaps are identical for every user and only change
  // via admin edits — cached with a short TTL instead of re-fetched on every
  // getAchievements() call. NOT invalidated on write (unlike
  // QuoteRepository.clearCache()); an admin publishing/editing a course can
  // take up to ACHIEVEMENTS_CATALOG_TTL_MS to show up here, which is an
  // accepted trade-off for this endpoint.
  private async getAchievementsCatalog(): Promise<AchievementsCatalog> {
    const now = Date.now();
    const cached = UserProgressService.achievementsCatalogCache;
    if (cached && cached.expiresAt > now) {
      return cached.data;
    }

    const categoryDocs = await this.categoryRepository.findOption({
      page: 1,
      take: 1000,
      status: CategoryStatus.PUBLISHED,
    } as any);

    // Fetch all courses for these categories
    const categoryIds = categoryDocs.items.map(s => s._id.toString());
    const categoryCoursesMap = new Map<string, any[]>();
    const courses = await this.courseRepository.model
      .find(
        { categoryId: { $in: categoryIds }, status: CourseStatus.PUBLISHED },
        'title _id categoryId level image description status numberOfLesson',
      )
      .sort({ createdAt: OrderType.ASC })
      .lean();
    for (const course of courses) {
      const key = course.categoryId.toString();
      categoryCoursesMap.set(key, [
        ...(categoryCoursesMap.get(key) || []),
        course,
      ]);
    }
    const allCourseIds: string[] = courses.map(c => c._id.toString());

    // Batch fetch roadmaps for all courses
    const roadmaps = await this.roadmapRepository.model
      .find({ courseId: { $in: allCourseIds } }, { courseId: 1, levels: 1 })
      .lean();
    const roadmapMap = new Map<string, any>();
    for (const rm of roadmaps) {
      roadmapMap.set(rm.courseId.toString(), rm);
    }

    const data: AchievementsCatalog = {
      categories: categoryDocs.items,
      categoryCoursesMap,
      roadmapMap,
    };
    UserProgressService.achievementsCatalogCache = {
      data,
      expiresAt: now + UserProgressService.ACHIEVEMENTS_CATALOG_TTL_MS,
    };
    return data;
  }

  async getAchievements(): Promise<IAchievenmentResponse[]> {
    const userId = this.user.id.toString();

    // Catalog (shared/cached across all users) and this user's progress
    // (always fresh) have no dependency on each other — fetch concurrently.
    const [catalog, progresses] = await Promise.all([
      this.getAchievementsCatalog(),
      this.userProgressRepository.model
        .find(
          { userId },
          {
            courseId: 1,
            lessonsResult: 1,
            completedLevels: 1,
            keypointOptional: 1,
          },
        )
        .lean(),
    ]);
    const { categories, categoryCoursesMap, roadmapMap } = catalog;

    const progressMap = new Map<string, ProgressSnapshot>();
    for (const p of progresses) {
      const completed = new Set(
        (p.completedLevels || []).map((item: ICompletedLevel) => item.level),
      );
      progressMap.set(p.courseId.toString(), {
        passedLesson: this.buildLessonPassedKeypointSet(p as any),
        passedEffective: this.buildPassedKeypointSet(p as any),
        completed,
      });
    }

    const results: IAchievenmentResponse[] = [];

    for (const category of categories) {
      const courseAchievements: ICourseLevelProgress[] = [];
      const courses = categoryCoursesMap.get(category._id.toString()) || [];

      // Category-wide keypoint totals across EVERY level of EVERY course, so the
      // client shows real fractional progress. Deduped per course (a keypoint
      // lives in one roadmap level, but union guards against overlaps).
      let categoryTotalKp = 0;
      let categoryCompletedKp = 0;

      for (const course of courses) {
        const roadmap = roadmapMap.get(course._id.toString());
        if (!roadmap?.levels?.length) continue;

        const progress =
          progressMap.get(course._id.toString()) ??
          ({
            passedLesson: new Set<string>(),
            passedEffective: new Set<string>(),
            completed: new Set<CourseLevel>(),
          } as ProgressSnapshot);

        // Whole-course keypoints = union of keypointIds over all levels.
        const courseKeys = new Set<string>();
        for (const level of roadmap.levels) {
          if (!Array.isArray(level.keypointIds)) continue;
          for (const k of level.keypointIds) if (k) courseKeys.add(k);
        }
        categoryTotalKp += courseKeys.size;
        for (const k of courseKeys) {
          if (progress.passedEffective.has(k)) categoryCompletedKp++;
        }

        const highest = this.findHighestLevelDone(
          roadmap.levels,
          progress,
          course._id.toString(),
          course.title,
        );
        if (highest) {
          courseAchievements.push(highest);
        }
      }

      if (courseAchievements.length) {
        results.push({
          categoryId: category._id.toString(),
          categoryTitle: this.localizeTranslation(category.title),
          courses: courseAchievements,
          totalKeypoints: categoryTotalKp,
          completedKeypoints: categoryCompletedKp,
        });
      }
    }

    return results;
  }

  async getInProgressWidget() {
    const userId = this.user.id.toString();
    const progresses = await this.userProgressRepository.model
      .find(
        { userId },
        { courseId: 1, lessonsResult: 1, completedLevels: 1, lastTime: 1 },
      )
      .sort({ lastTime: -1, updatedAt: -1 })
      .lean();

    if (!progresses.length) return null;

    // Level counts per course so we can tell which courses are fully done.
    const courseIds = progresses.map(p => p.courseId.toString());
    const roadmaps = await this.roadmapRepository.model
      .find({ courseId: { $in: courseIds } }, { courseId: 1, levels: 1 })
      .lean();
    const levelCountByCourse = new Map<string, number>();
    for (const rm of roadmaps) {
      levelCountByCourse.set(rm.courseId.toString(), (rm.levels || []).length);
    }

    // Most recent course that is NOT fully completed. If every course is
    // completed (or has no roadmap levels), there is nothing in progress.
    const target = progresses.find(p => {
      const levelsCount = levelCountByCourse.get(p.courseId.toString()) ?? 0;
      if (levelsCount === 0) return false;
      const completedCount = new Set(
        (p.completedLevels || [])
          .map((item: ICompletedLevel) => item.level)
          .filter(Boolean),
      ).size;
      return completedCount < levelsCount;
    });

    if (!target) return null;

    const course = await this.courseRepository.model
      .findOne(
        { _id: target.courseId },
        { title: 1, image: 1, numberOfLesson: 1 },
      )
      .lean();

    if (!course) return null;

    const completedLesson = (target.lessonsResult || []).reduce((count, lesson) => {
      const type = lesson.lessonType || (lesson.keypointsResult?.length ? LessonType.LESSON : undefined);
      if (type === LessonType.LESSON) {
        const passedKeypoints = (lesson.keypointsResult || []).filter(kp => kp.passed).length;
        return count + passedKeypoints;
      } else {
        return count + (lesson.passed ? 1 : 0);
      }
    }, 0);

    return {
      courseId: target.courseId,
      title: course.title,
      image: course.image,
      completedLesson,
      totalLesson: course.numberOfLesson ?? 0,
    };
  }

  async getSuggestCourseWidget() {
    const userId = this.user.id.toString();

    const startedCourseIds = await this.userProgressRepository.model
      .distinct('courseId', { userId })
      .lean();

    const match: any = {
      status: CourseStatus.PUBLISHED,
      numberOfLesson: { $gt: 0 },
    };

    if (startedCourseIds.length) {
      // courseId is stored as a string in user_progress, but course._id is an
      // ObjectId. The aggregate $match does not auto-cast, so convert to
      // ObjectId, otherwise $nin matches nothing and already-started courses
      // (incl. completed ones) keep getting suggested.
      const startedObjectIds = (startedCourseIds as unknown as string[])
        .filter(id => Types.ObjectId.isValid(id))
        .map(id => new Types.ObjectId(id));
      if (startedObjectIds.length) {
        match._id = { $nin: startedObjectIds };
      }
    }

    const [course] = await this.courseRepository.model.aggregate([
      { $match: match },
      { $sample: { size: 1 } },
      { $project: { _id: 1, title: 1, description: 1, image: 1 } },
    ]);

    if (!course) return null;

    return {
      courseId: course._id.toString(),
      title: course.title,
      description: course.description,
      image: course.image,
    };
  }

  async getSuggestCourses(limit: number) {
    const userId = this.user.id.toString();

    const startedCourseIds = await this.userProgressRepository.model
      .distinct('courseId', { userId })
      .lean();

    // The catalogue floor both halves of the result stand on: a course with
    // nothing to open is a dead card either way.
    const publishedMatch: any = {
      status: CourseStatus.PUBLISHED,
      numberOfLesson: { $gt: 0 },
    };

    // The random half only suggests courses the user has NOT started — a
    // course already in progress is not a suggestion.
    //
    // The PINNED newest course deliberately skips this filter (owner,
    // 2026-09-14): the app's "New today" card must always show the newest
    // course, including one the user has already opened. Filtering it here
    // made the card silently fall back to the second-newest the moment the
    // user touched the new course.
    const suggestMatch: any = { ...publishedMatch };

    if (startedCourseIds.length) {
      const startedObjectIds = (startedCourseIds as unknown as string[])
        .filter(id => Types.ObjectId.isValid(id))
        .map(id => new Types.ObjectId(id));
      if (startedObjectIds.length) {
        suggestMatch._id = { $nin: startedObjectIds };
      }
    }

    const projectStage = {
      $project: {
        _id: 1,
        title: 1,
        description: 1,
        image: 1,
        categoryId: 1,
        numberOfLesson: 1,
        isNew: 1,
        publishAt: 1,
        newDurationDays: 1,
        // Editorial credit + reach for the app's "New today" card.
        author: 1,
        viewCount: 1,
        createdAt: 1,
      },
    };

    // $sample returns a different random subset per call, so the truly
    // newest course is usually missing and the app's "New today" card
    // changes on every reload. Pin the newest course into the result.
    const [newestArr, sampled] = await Promise.all([
      this.courseRepository.model.aggregate([
        { $match: publishedMatch },
        {
          $addFields: {
            sortCreatedAt: { $ifNull: ['$createdAt', { $toDate: '$_id' }] },
          },
        },
        { $sort: { sortCreatedAt: -1, _id: -1 } },
        { $limit: 1 },
        projectStage,
      ]),
      this.courseRepository.model.aggregate([
        { $match: suggestMatch },
        { $sample: { size: limit } },
        projectStage,
      ]),
    ]);

    const newest = newestArr[0];
    const courses = newest
      ? [newest, ...sampled.filter(c => !c._id.equals(newest._id))].slice(
          0,
          limit,
        )
      : sampled;

    return courses.map(course => ({
      courseId: course._id.toString(),
      // The app's "New today" card picks the LATEST course by this. Falls
      // back to the ObjectId's own timestamp so every course has one even on
      // schemas created before timestamps.
      createdAt: course.createdAt ?? course._id.getTimestamp(),
      title: course.title,
      description: course.description,
      image: course.image,
      categoryId: course.categoryId?.toString() ?? null,
      numberOfLesson: course.numberOfLesson ?? 0,
      isNew: course.isNew ?? false,
      publishAt: course.publishAt ?? null,
      newDurationDays: course.newDurationDays ?? null,
      // Null, not '' / 0 — the card hides each half when it has no value,
      // rather than crediting nobody or claiming zero reach.
      author: course.author ?? null,
      viewCount: course.viewCount ?? null,
    }));
  }

  async requestExportAllUserProgress() {
    const now = new Date();
    let job = await this.userProgressExportRepository.findOne(
      { name: EXPORT_JOB_NAME },
      {},
      { lean: true },
    );

    if (job) {
      const lastRequestedAt = job.requestedAt || job.updatedAt || job.createdAt;
      const isCoolingDown =
        lastRequestedAt &&
        now.getTime() - new Date(lastRequestedAt).getTime() <
          EXPORT_COOLDOWN_MS;

      if (isCoolingDown || job.status === UserProgressExportStatus.PROCESSING) {
        return buildExportResponse(job, now);
      }

      await this.userProgressExportRepository.updateOne(
        { _id: job._id },
        {
          status: UserProgressExportStatus.PENDING,
          requestedAt: now,
          fileKey: job.fileKey || EXPORT_FILE_KEY,
          error: null,
          startedAt: null,
          finishedAt: null,
        },
        this.user,
      );
    } else {
      await this.userProgressExportRepository.create(
        {
          name: EXPORT_JOB_NAME,
          status: UserProgressExportStatus.PENDING,
          requestedAt: now,
          fileKey: EXPORT_FILE_KEY,
        },
        this.user,
      );
    }

    job = await this.userProgressExportRepository.findOne(
      { name: EXPORT_JOB_NAME },
      {},
      { lean: true },
    );

    if (job?.status === UserProgressExportStatus.PENDING) {
      setImmediate(() => {
        this.runExportJob(job._id.toString()).catch(error => {
          this.logger.error(
            'User progress export job failed to start',
            error,
            UserProgressService.name,
          );
        });
      });
    }

    return buildExportResponse(job, now);
  }

  /**
   * The drop-off histogram for one course: how many readers are stuck at each
   * stop point, with titles joined in so the panel never has to resolve ids.
   *
   * Rows keep the repository's count-desc order — the panel's question is
   * "where do we lose the most people", so the biggest sink comes first.
   * A row whose lesson or keypoint was deleted since keeps its count under a
   * null title rather than vanishing: those readers are still stuck there,
   * and hiding them would understate exactly the number this screen exists
   * to show.
   */
  /**
   * Mọi khoá học kèm số user kẹt — danh sách bên trái của trang drop-off,
   * đồng thời là bảng xếp hạng "khoá nào đang rơi nhiều người nhất". Title
   * join từ catalog đầy đủ (mọi status): một khoá đã gỡ publish vẫn có user
   * kẹt trong đó, và ẩn nó khỏi list là giấu đúng nhóm cần nhìn thấy nhất.
   */
  async getDropOffOverview(dto: GetDropOffOverviewDto) {
    const staleDays = dto.staleDays ?? 7;
    const cutoff =
      staleDays > 0
        ? new Date(Date.now() - staleDays * 24 * 60 * 60 * 1000)
        : null;

    const [rows, courses] = await Promise.all([
      this.userProgressRepository.aggregateDropOffOverview(cutoff),
      this.courseRepository.findAllBriefTitles(),
    ]);

    const titleMap = new Map(
      courses.map(course => [course._id.toString(), course.title]),
    );

    return {
      staleDays,
      courses: rows.map(row => ({
        courseId: row.courseId,
        // Null cho khoá đã xoá hẳn — vẫn được liệt kê vì user vẫn kẹt ở đó.
        title: titleMap.get(row.courseId) ?? null,
        totalInProgress: row.totalInProgress,
        totalStuck: row.totalStuck,
      })),
    };
  }

  async getCourseDropOff(dto: GetCourseDropOffDto) {
    const staleDays = dto.staleDays ?? 7;
    const cutoff =
      staleDays > 0
        ? new Date(Date.now() - staleDays * 24 * 60 * 60 * 1000)
        : null;

    const [{ totalInProgress, totalStuck, rows }, staleness] =
      await Promise.all([
        this.userProgressRepository.aggregateDropOffByCourse(
          dto.courseId,
          cutoff,
        ),
        // Phân bố "kẹt bao lâu" tính trên MỌI người đang dở (không lọc theo
        // staleDays) — đây là cái phân bố mà bộ lọc kia cắt ngang qua.
        this.userProgressRepository.aggregateStalenessBuckets(dto.courseId),
      ]);

    const lessonIds = [...new Set(rows.map(row => row.lessonId))];
    const keypointIds = [
      ...new Set(rows.map(row => row.keypointId).filter(Boolean) as string[]),
    ];

    const [lessons, keypoints] = await Promise.all([
      this.contentSource.getLessonBriefsAcrossVersions(
        lessonIds,
        this.requestService.headers,
      ) as unknown as Promise<any[]>,
      this.contentSource.getKeypointBriefsAcrossVersions(
        keypointIds,
        this.requestService.headers,
      ) as unknown as Promise<any[]>,
    ]);

    const lessonMap = new Map(
      lessons.map(lesson => [lesson._id.toString(), lesson]),
    );
    const keypointMap = new Map(
      keypoints.map(keypoint => [keypoint._id.toString(), keypoint]),
    );

    return {
      courseId: dto.courseId,
      staleDays,
      totalInProgress,
      totalStuck,
      staleness,
      rows: rows.map(row => {
        const lesson = lessonMap.get(row.lessonId);
        const keypoint = row.keypointId
          ? keypointMap.get(row.keypointId)
          : undefined;

        return {
          lessonId: row.lessonId,
          lessonTitle: lesson?.title ?? null,
          lessonType: lesson?.type ?? null,
          keypointId: row.keypointId,
          keypointTitle: keypoint?.title ?? null,
          count: row.count,
        };
      }),
    };
  }

  async statisticsUsersLearningCourses(
    dto: StatisticsUsersLearningCoursesDto,
  ): Promise<IResponseListPage<ICourseLearningStatistics>> {
    const { page, take, order } = dto;
    const orderBy =
      dto.orderBy ?? StatisticsUsersLearningCoursesOrderBy.STARTED_USER_COUNT;

    const courses = await this.courseRepository.model
      .find({ status: CourseStatus.PUBLISHED }, { _id: 1, title: 1 })
      .lean();

    if (!courses.length) {
      return {
        items: [],
        itemsPerPage: take,
        totalPages: 0,
        currentPage: page,
      };
    }

    const courseIds = courses.map(course => course._id.toString());
    const roadmapDocs = await this.roadmapRepository.model
      .find({ courseId: { $in: courseIds } }, { courseId: 1, levels: 1 })
      .lean();

    const levelsCountByCourseId = new Map<string, number>();
    for (const roadmap of roadmapDocs) {
      const courseId =
        (roadmap as any)?.courseId?.toString?.() !== undefined
          ? (roadmap as any).courseId.toString()
          : String((roadmap as any).courseId);
      const levels = Array.isArray((roadmap as any).levels)
        ? (roadmap as any).levels
        : [];
      levelsCountByCourseId.set(courseId, levels.length);
    }
    for (const courseId of courseIds) {
      if (!levelsCountByCourseId.has(courseId)) {
        levelsCountByCourseId.set(courseId, 0);
      }
    }

    const statsMap = new Map<
      string,
      {
        startedUserIds: Set<string>;
        roleplayPassedCount: number;
        lessonKeypointPassedCount: number;
        completedUserCount: number;
      }
    >();

    for (const courseId of courseIds) {
      statsMap.set(courseId, {
        startedUserIds: new Set<string>(),
        roleplayPassedCount: 0,
        lessonKeypointPassedCount: 0,
        completedUserCount: 0,
      });
    }

    const cursor = this.userProgressRepository.model
      .find(
        { courseId: { $in: courseIds } },
        { userId: 1, courseId: 1, lessonsResult: 1, completedLevels: 1 },
      )
      .lean()
      .cursor();

    for await (const progress of cursor) {
      const courseId =
        (progress as any)?.courseId?.toString?.() !== undefined
          ? (progress as any).courseId.toString()
          : String((progress as any).courseId);
      const levelsCount = levelsCountByCourseId.get(courseId) ?? 0;
      if (!levelsCount) {
        continue;
      }
      const stats = statsMap.get(courseId);
      if (!stats) {
        continue;
      }

      const userId =
        (progress as any)?.userId?.toString?.() !== undefined
          ? (progress as any).userId.toString()
          : String((progress as any).userId);
      if (userId) {
        stats.startedUserIds.add(userId);
      }

      for (const lesson of (progress as any).lessonsResult || []) {
        if (!lesson?.lessonType) continue;
        if (lesson.lessonType === LessonType.ROLEPLAY) {
          if (lesson.passed === true) {
            stats.roleplayPassedCount += 1;
          }
          continue;
        }

        if (lesson.lessonType !== LessonType.LESSON) continue;

        const keypoints = lesson.keypointsResult || [];
        if (!keypoints.length) continue;

        let passedCount = 0;
        for (const keypoint of keypoints) {
          if (keypoint?.passed === true) {
            passedCount += 1;
          }
        }
        if (!passedCount) continue;

        stats.lessonKeypointPassedCount += passedCount;
      }

      const completedLevels = Array.isArray((progress as any).completedLevels)
        ? (progress as any).completedLevels
        : [];
      const completedLevelCount = new Set(
        completedLevels
          .map((item: ICompletedLevel) => item?.level)
          .filter(Boolean),
      ).size;
      if (completedLevelCount >= levelsCount) {
        stats.completedUserCount += 1;
      }
    }

    const items: ICourseLearningStatistics[] = courses.map(course => {
      const courseId = course._id.toString();
      const levelsCount = levelsCountByCourseId.get(courseId) ?? 0;
      const stats = statsMap.get(courseId);
      if (!levelsCount || !stats) {
        return {
          courseId,
          title: course.title,
          startedUserCount: 0,
          roleplayPassedCount: 0,
          lessonKeypointPassedCount: 0,
          completedUserCount: 0,
        };
      }

      return {
        courseId,
        title: course.title,
        startedUserCount: stats.startedUserIds.size,
        roleplayPassedCount: stats.roleplayPassedCount,
        lessonKeypointPassedCount: stats.lessonKeypointPassedCount,
        completedUserCount: stats.completedUserCount,
      };
    });

    const sortKey = orderBy as keyof ICourseLearningStatistics;
    const direction = order === OrderType.ASC ? 1 : -1;
    items.sort((a, b) => {
      const aValue = Number(a[sortKey] ?? 0);
      const bValue = Number(b[sortKey] ?? 0);
      if (aValue === bValue) {
        return a.courseId.localeCompare(b.courseId);
      }
      return (aValue - bValue) * direction;
    });

    const totalPages = Math.ceil(items.length / take);
    const startIndex = (page - 1) * take;
    const pagedItems = items.slice(startIndex, startIndex + take);

    return {
      items: pagedItems,
      itemsPerPage: take,
      totalPages,
      currentPage: page,
    };
  }

  private async runExportJob(jobId: string) {
    const job = await this.userProgressExportRepository.findOne(
      { _id: jobId },
      {},
      { lean: true },
    );
    if (!job) return;
    if (job.status === UserProgressExportStatus.PROCESSING) return;

    await this.userProgressExportRepository.updateOne(
      { _id: jobId },
      {
        status: UserProgressExportStatus.PROCESSING,
        startedAt: new Date(),
        fileKey: job.fileKey || EXPORT_FILE_KEY,
        error: null,
      },
    );

    try {
      const upload = await buildExportArchive({
        userProgressRepository: this.userProgressRepository,
        courseRepository: this.courseRepository,
        lessonRepository: this.lessonRepository,
        keypointRepository: this.keypointRepository,
        userFeedbackRepository: this.userFeedbackRepository,
        userRepository: this.userRepository,
        r2Service: this.r2Service,
        lang: this.lang,
        fileKey: job.fileKey || EXPORT_FILE_KEY,
      });
      await this.userProgressExportRepository.updateOne(
        { _id: jobId },
        {
          status: UserProgressExportStatus.COMPLETED,
          finishedAt: new Date(),
          fileKey: upload.key,
          fileUrl: upload.url,
        },
      );
    } catch (error) {
      await this.userProgressExportRepository.updateOne(
        { _id: jobId },
        {
          status: UserProgressExportStatus.FAILED,
          finishedAt: new Date(),
          error: error instanceof Error ? error.message : 'Export failed',
        },
      );
      this.logger.error(
        'User progress export job failed',
        error,
        UserProgressService.name,
      );
    }
  }
}
