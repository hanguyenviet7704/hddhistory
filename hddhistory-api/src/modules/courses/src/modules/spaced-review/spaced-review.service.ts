import { Injectable } from '@nestjs/common';

import { RequestService } from '@base/service/request.service';

import { SubmitSpacedReviewDto } from './dto/spaced-review.dto';
import {
  ISpacedReviewKeypoint,
  ISpacedReviewSubmitResponse,
  ISpacedReviewTodayResponse,
} from './interface/spaced-review.interface';
import { SpacedReviewItemRepository } from './repository/spaced-review-item.repository';
import {
  addDays,
  firstReviewAt,
  NO_QUESTION_PARK_DAYS,
  nextReview,
} from './spaced-review.schedule';
import { ContentSource } from '../course-version/content-source.service';
import { LearningItemType } from '../learning-item/enum/learning-item.enum';
import { ExerciseInput } from '../learning-item/interface/learning-item.interface';
import { UserProgressRepository } from '../progress/src/modules/user-progress/repository/user-progress.repository';

/** Một phiên ~3 phút: tối đa 5 keypoint × 2 câu. */
const MAX_KEYPOINTS_PER_SESSION = 5;
const MAX_QUESTIONS_PER_KEYPOINT = 2;
/**
 * Lấy rộng hơn số cần dùng để còn chỗ bỏ qua keypoint không có câu hỏi ôn mà
 * vẫn đủ phiên — chỉ là số dòng lịch đọc lên, không phải nội dung.
 */
const DUE_WINDOW = 30;

type Doc = Record<string, any>;

@Injectable()
export class SpacedReviewService {
  constructor(
    private readonly spacedReviewItemRepository: SpacedReviewItemRepository,
    private readonly userProgressRepository: UserProgressRepository,
    private readonly contentSource: ContentSource,
    private readonly requestService: RequestService,
  ) {}

  private get userId(): string {
    return this.requestService.user.id.toString();
  }

  async getToday(): Promise<ISpacedReviewTodayResponse> {
    const userId = this.userId;
    const now = new Date();

    await this.syncFromProgress(userId);

    const due = await this.spacedReviewItemRepository.findDue(
      userId,
      now,
      DUE_WINDOW,
    );
    if (!due.length) {
      return {
        dueCount: 0,
        keypoints: [],
        nextDueAt: await this.spacedReviewItemRepository.findNextDueAt(userId),
      };
    }

    const dueKeypointIds = due.map(item => item.keypointId);
    const questionsByKeypoint = await this.reviewQuestionsByKeypoint(
      dueKeypointIds,
    );

    // Keypoint đến hạn mà không có câu nào để hỏi thì không ôn được; để yên
    // thì nó nằm mãi đầu hàng đợi (hạn sớm nhất) và lần nào cũng phải bỏ qua.
    const unaskable = dueKeypointIds.filter(
      id => !questionsByKeypoint.get(id)?.length,
    );
    await this.spacedReviewItemRepository.postpone(
      userId,
      unaskable,
      addDays(now, NO_QUESTION_PARK_DAYS),
    );

    const session = due
      .filter(item => questionsByKeypoint.get(item.keypointId)?.length)
      .slice(0, MAX_KEYPOINTS_PER_SESSION);

    const titles = await this.keypointTitles(
      session.map(item => item.keypointId),
    );

    const keypoints: ISpacedReviewKeypoint[] = session.map(item => ({
      keypointId: item.keypointId,
      lessonId: item.lessonId ?? '',
      courseId: item.courseId ?? '',
      title: titles.get(item.keypointId) ?? {},
      questions: pickRandom(
        questionsByKeypoint.get(item.keypointId) ?? [],
        MAX_QUESTIONS_PER_KEYPOINT,
      ),
    }));

    return {
      // Đếm SAU khi đã lùi các keypoint không hỏi được, nên chúng không có ở đây.
      dueCount: await this.spacedReviewItemRepository.countDue(userId, now),
      keypoints,
      nextDueAt: null,
    };
  }

  /**
   * Chỉ dời lịch những keypoint đang đến hạn: gửi lại cùng một kết quả (mạng
   * chập chờn, bấm hai lần) không đẩy keypoint ra xa thêm một bậc nữa.
   */
  async submit(
    dto: SubmitSpacedReviewDto,
  ): Promise<ISpacedReviewSubmitResponse> {
    const userId = this.userId;
    const now = new Date();

    // Một keypoint xuất hiện nhiều lần thì chỉ cần một lần sai là sai.
    const correctByKeypoint = new Map<string, boolean>();
    for (const result of dto.results ?? []) {
      const previous = correctByKeypoint.get(result.keypointId) ?? true;
      correctByKeypoint.set(result.keypointId, previous && result.correct);
    }

    const due = await this.spacedReviewItemRepository.findDueByKeypointIds(
      userId,
      Array.from(correctByKeypoint.keys()),
      now,
    );

    const updates = due.map(item => {
      const correct = correctByKeypoint.get(item.keypointId) ?? false;

      return {
        keypointId: item.keypointId,
        correct,
        ...nextReview(item.step, correct, now),
      };
    });
    await this.spacedReviewItemRepository.applyReviews(userId, updates, now);

    return {
      updated: updates.length,
      nextDueAt: await this.spacedReviewItemRepository.findNextDueAt(userId),
    };
  }

  /** Thêm lịch cho mọi keypoint đã qua mà chưa có lịch. */
  private async syncFromProgress(userId: string): Promise<void> {
    const [passed, known] = await Promise.all([
      this.userProgressRepository.findPassedKeypoints(userId),
      this.spacedReviewItemRepository.findKeypointIds(userId),
    ]);
    const knownIds = new Set(known);
    const now = new Date();

    await this.spacedReviewItemRepository.insertMissing(
      passed
        .filter(row => !knownIds.has(row.keypointId))
        .map(row => ({
          userId,
          keypointId: row.keypointId,
          lessonId: row.lessonId,
          courseId: row.courseId,
          dueAt: firstReviewAt(row.submittedAt ?? now),
        })),
    );
  }

  /**
   * Câu hỏi ôn = các câu admin đã gắn `isDailyWarmUp` (đúng nguồn Warm-up đang
   * dùng), đọc theo tag đang phát hành của từng khoá.
   *
   * Lọc loại item bằng `LearningItemType` chứ không qua `warmUpQuestionsOf`:
   * hàm đó so với `'EXERCISE'` viết hoa, còn item lưu `'exercise'`.
   */
  private async reviewQuestionsByKeypoint(
    keypointIds: string[],
  ): Promise<Map<string, ExerciseInput[]>> {
    const items =
      await this.contentSource.getLearningItemsByKeypointIdsAcrossVersions(
        keypointIds,
        this.requestService.headers,
      );

    const byKeypoint = new Map<string, ExerciseInput[]>();
    const exercises = items
      .filter(
        (item: Doc) =>
          String(item.type ?? '').toLowerCase() === LearningItemType.EXERCISE,
      )
      .sort((a: Doc, b: Doc) => Number(a.index ?? 0) - Number(b.index ?? 0));

    for (const item of exercises) {
      const keypointId = String(item.keypointId ?? '');
      if (!keypointId) continue;
      const questions = ((item.questions ?? []) as Doc[]).filter(
        question => question?.isDailyWarmUp,
      ) as ExerciseInput[];
      if (!questions.length) continue;
      byKeypoint.set(keypointId, [
        ...(byKeypoint.get(keypointId) ?? []),
        ...questions,
      ]);
    }

    return byKeypoint;
  }

  private async keypointTitles(
    keypointIds: string[],
  ): Promise<Map<string, Doc>> {
    const briefs = await this.contentSource.getKeypointBriefsAcrossVersions(
      keypointIds,
      this.requestService.headers,
    );

    return new Map(
      briefs.map(brief => [String(brief._id), (brief.title ?? {}) as Doc]),
    );
  }
}

const pickRandom = <T>(items: T[], limit: number): T[] => {
  if (items.length <= limit) return items;

  const shuffled = [...items];
  for (let i = shuffled.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }

  return shuffled.slice(0, limit);
};
