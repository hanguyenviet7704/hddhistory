import { Injectable, UnauthorizedException } from '@nestjs/common';
import { Types } from 'mongoose';

import { RequestService } from '@base/service/request.service';
import { viewerMarketsForRequest } from '@utils/market-query.util';
import {
  CourseRepository,
  IOnboardingCourseCandidate,
} from 'src/modules/courses/src/modules/course/repository/course.repository';
import { OnboardingLabelRepository } from 'src/modules/onboarding-taxonomy/repository/onboarding-label.repository';
import { OnboardingPackageRepository } from 'src/modules/onboarding-taxonomy/repository/onboarding-package.repository';
import { UserRepository } from 'src/modules/user/src/modules/auth/repository/user.repository';

import { SaveOnboardingAnswerDto } from './dto/save-onboarding-answer.dto';
import {
  IOnboardingAnswer,
  IRecommendedCourse,
} from './interface/onboarding-answer.interface';
import { rankCourses } from './onboarding-recommendation.ranker';
import { OnboardingAnswerRepository } from './repository/onboarding-answer.repository';

const RECOMMENDATION_COUNT = 3;

@Injectable()
export class OnboardingAnswerService {
  constructor(
    private readonly answerRepository: OnboardingAnswerRepository,
    private readonly packageRepository: OnboardingPackageRepository,
    private readonly labelRepository: OnboardingLabelRepository,
    private readonly courseRepository: CourseRepository,
    private readonly userRepository: UserRepository,
    private readonly requestService: RequestService,
  ) {}

  private get userId(): string {
    const id = this.requestService.user?.id;
    if (!id) throw new UnauthorizedException();
    return String(id);
  }

  /** Upsert phần dto gửi, đồng bộ giờ nhắc lên users, rồi tính lại gợi ý từ answers đã merge. */
  async save(dto: SaveOnboardingAnswerDto) {
    const userId = this.userId;
    const existing = await this.answerRepository.findByUserId(userId);
    const up = (codes?: string[]) =>
      codes?.map(c => c.trim().toUpperCase()).filter(Boolean);
    const patch: Partial<IOnboardingAnswer> = {
      branchCodes: up(dto.branchCodes),
      packageCodes: up(dto.packageCodes),
      desireCode:
        dto.desireCode === undefined
          ? undefined
          : dto.desireCode
          ? dto.desireCode.toUpperCase()
          : null,
      reminderEnabled: dto.reminderEnabled,
      reminderTime: dto.reminderTime,
      chosenCourseId: dto.chosenCourseId,
      ageKey: dto.ageKey,
      // Stamp once: a retry or re-entering the result screen must not move the
      // original completion time forward.
      completedAt:
        dto.completed && !existing?.completedAt ? new Date() : undefined,
    };
    if (dto.reminderEnabled === false) patch.reminderTime = null;

    let answers = await this.answerRepository.upsertByUserId(userId, patch);

    if (dto.reminderEnabled !== undefined || dto.reminderTime !== undefined) {
      const time = answers.reminderEnabled ? answers.reminderTime : null;
      await this.userRepository.setStudyReminderTime(userId, time);
    }

    const recommendations = await this.recommend(answers);
    const ids = recommendations.map(r => r._id);
    if (ids.join(',') !== (answers.recommendedCourseIds ?? []).join(',')) {
      answers = await this.answerRepository.upsertByUserId(userId, {
        recommendedCourseIds: ids,
      });
    }
    return { answers: stripMeta(answers), recommendations };
  }

  async me() {
    const answers = await this.answerRepository.findByUserId(this.userId);
    if (!answers)
      return { answers: null, recommendations: [] as IRecommendedCourse[] };
    return {
      answers: stripMeta(answers),
      recommendations: await this.recommend(answers),
    };
  }

  /** §3.4 design.md: ứng viên → rankCourses → bù đủ 3. */
  private async recommend(
    answers: IOnboardingAnswer,
  ): Promise<IRecommendedCourse[]> {
    const viewerMarkets = viewerMarketsForRequest(this.requestService.headers);
    const packageCodes = answers.packageCodes ?? [];
    const labels = await this.labelRepository.findByPackageCodes(packageCodes);
    const labelsByPackage = new Map<string, string[]>();
    for (const l of labels)
      labelsByPackage.set(l.packageCode, [
        ...(labelsByPackage.get(l.packageCode) ?? []),
        l.code,
      ]);

    const candidates = await this.courseRepository.findOnboardingCandidates({
      labelCodes: labels.map(l => l.code),
      desireCode: answers.desireCode,
      viewerMarkets,
    });
    const ranked = rankCourses(candidates, {
      packageCodes,
      desireCode: answers.desireCode,
      labelsByPackage,
    }).slice(0, RECOMMENDATION_COUNT);

    if (ranked.length < RECOMMENDATION_COUNT) {
      const packages = await this.packageRepository.findByCodes(packageCodes);
      const branchCodes = new Set([
        ...(answers.branchCodes ?? []),
        ...packages.map(p => p.branchCode),
      ]);
      const allPackages = await this.packageRepository.findAll(true);
      const desireCodes = allPackages
        .filter(p => branchCodes.has(p.branchCode))
        .map(p => p.code);
      // Safety net for Task 3's `findPublishedFallback`: it runs `new Types.ObjectId(id)`
      // on every excludeId with no validity guard, so an invalid id here would 500
      // instead of just being ignored.
      const excludeIds = ranked
        .map(r => String(r.course._id))
        .filter(id => Types.ObjectId.isValid(id));
      const fill = await this.courseRepository.findPublishedFallback({
        excludeIds,
        desireCodes,
        limit: RECOMMENDATION_COUNT - ranked.length,
        viewerMarkets,
      });
      for (const course of fill)
        ranked.push({
          course,
          matchReason: { desire: false, labelCodes: [], packageCodes: [] },
        });
    }

    return ranked.map(({ course, matchReason }) =>
      toRecommended(course, matchReason),
    );
  }
}

function toRecommended(
  c: IOnboardingCourseCandidate,
  matchReason: IRecommendedCourse['matchReason'],
): IRecommendedCourse {
  return {
    _id: String(c._id),
    title: c.title,
    description: c.description,
    image: c.image,
    skillsetId: c.skillsetId,
    numberOfLesson: c.numberOfLesson ?? 0,
    status: c.status,
    matchReason,
  };
}

/** Bỏ field nội bộ của Mongo trước khi trả ra ngoài — mirrors
 * `onboarding-taxonomy.service.ts`'s `stripMeta`. */
function stripMeta<T extends Record<string, any>>(row: T): T {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const { _id, createdAt, updatedAt, createdBy, updatedBy, __v, ...rest } =
    row as any;
  return rest;
}
