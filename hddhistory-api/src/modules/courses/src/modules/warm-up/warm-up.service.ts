import { Injectable } from '@nestjs/common';

import { RequestService } from '@base/service/request.service';

import { IWarmUpForCourseResponse } from './interface/warm-up.interface';
import { warmUpQuestionsOf } from '../course-version/content-projection';
import { ContentSource } from '../course-version/content-source.service';
import { LearningItemRepository } from '../learning-item/repository/learning-item.repository';
import { LessonRepository } from '../lesson/repository/lesson.repository';
import { UserProgressRepository } from '../progress/src/modules/user-progress/repository/user-progress.repository';
import { toMilliseconds } from '../warm-up-config/enum/warm-up-inactivity-unit.enum';
import { WarmUpConfigService } from '../warm-up-config/warm-up-config.service';

@Injectable()
export class WarmUpService {
  constructor(
    private readonly warmUpConfigService: WarmUpConfigService,
    private readonly userProgressRepository: UserProgressRepository,
    private readonly lessonRepository: LessonRepository,
    private readonly learningItemRepository: LearningItemRepository,
    private readonly requestService: RequestService,
    private readonly contentSource: ContentSource,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  async getForCourse(courseId: string): Promise<IWarmUpForCourseResponse> {
    const notDue: IWarmUpForCourseResponse = {
      isDue: false,
      previousLesson: null,
    };

    const config = await this.warmUpConfigService.getConfig();
    if (!config.enabled) {
      return notDue;
    }

    const userId = this.user.id.toString();

    // Global inactivity: most recent activity across ALL of the user's
    // courses, not just this one.
    const globalLastActivity =
      await this.userProgressRepository.findGlobalLastActivity(userId);
    if (!globalLastActivity) {
      return notDue;
    }

    const inactiveMs = Date.now() - new Date(globalLastActivity).getTime();
    const thresholdMs = toMilliseconds(
      config.inactivityValue,
      config.inactivityUnit,
    );
    if (inactiveMs < thresholdMs) {
      return notDue;
    }

    // Previous lesson = the furthest lesson (by course order) the user has
    // studied IN this course — not merely the most recently touched one, so
    // going back to redo an earlier lesson doesn't regress the warm-up.
    const studiedLessonIds =
      await this.userProgressRepository.findStudiedLessonIdsInCourse(
        userId,
        courseId,
      );
    if (!studiedLessonIds.length) {
      return notDue;
    }

    // Tiebreak on createdAt: some courses have duplicate/out-of-order
    // `index` values from data-entry mistakes, so index alone isn't a
    // reliable total order — later-created lessons are still a reasonable
    // proxy for "later in the course" when indices collide.
    const lesson = await this.lessonRepository.findOne(
      { _id: { $in: studiedLessonIds } },
      { title: 1, keypoints: 1 },
      { lean: true, sort: { index: -1, createdAt: -1 } },
    );
    if (!lesson) {
      return notDue;
    }

    // Chọn bài thì dựa trên bản đang sửa (thứ tự index/createdAt là metadata,
    // và studiedLessonIds đến từ tiến trình), nhưng NỘI DUNG đọc từ tag đang
    // phát hành. Xem `plans/260907-course-content-versions/README.md`.
    const lessonId = lesson._id.toString();
    const versionId = await this.contentSource.versionForEntity(
      'lesson',
      lessonId,
      this.requestService.headers,
      null,
      this.user?.id,
    );
    const published = versionId
      ? await this.contentSource.getLesson(lessonId, versionId)
      : null;

    const keypointIds = (
      ((published?.keypoints ?? lesson.keypoints) as string[]) ?? []
    ).filter(Boolean);

    const questions = !keypointIds.length
      ? []
      : versionId
      ? (warmUpQuestionsOf(
          await this.contentSource.getLearningItemsByKeypointIds(
            keypointIds,
            versionId,
          ),
        ) as any[])
      : await this.learningItemRepository.findWarmUpEligibleExercisesByKeypointIds(
          keypointIds,
        );

    return {
      isDue: true,
      previousLesson: {
        id: lessonId,
        title: (published?.title as any) ?? lesson.title,
        questions,
      },
    };
  }
}
