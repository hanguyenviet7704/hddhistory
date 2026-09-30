import { Injectable, Logger } from '@nestjs/common';

import { RequestService } from '@base/service/request.service';
import { ITranslation } from '@utils/interface/common.interface';

import { ICoachQuizQuestion } from './interface/quiz.interface';
import { CoachQuizSeenRepository } from './repository/coach-quiz-seen.repository';
import { CoachQuizSetRepository } from './repository/coach-quiz-set.repository';
import { narratableItemsOf } from '../../../../courses/src/modules/course-version/content-projection';
import { ContentSource } from '../../../../courses/src/modules/course-version/content-source.service';
import { KeypointRepository } from '../../../../courses/src/modules/keypoint/repository/keypoint.repository';
import { LearningItemRepository } from '../../../../courses/src/modules/learning-item/repository/learning-item.repository';
import { HabitLibraryRepository } from '../../../../habit/src/modules/habit-library/repository/habit-library.repository';
import { CoachAi } from '../ai/coach-ai.types';

/** Three per set, as the chat asks them. */
const QUESTIONS_PER_SET = 3;
/** How many stored questions the generator is told to avoid repeating. */
const AVOID_SAMPLE = 12;
/** Material handed to the generator, in characters — a keypoint is short. */
const MATERIAL_MAX_CHARS = 6000;

/**
 * Luồng 5 — the in-chat quiz, generated from the keypoint and kept.
 *
 * The catalogue's authored exercises are written for the deck: five kinds,
 * drag-and-drop and recordings among them, and only one of those kinds can be
 * asked in a chat. So the Coach writes its own single-choice questions from
 * what the keypoint teaches, stores them, and serves a set the reader has not
 * seen before (owner, 2026-09-04: "sau mỗi lần user luyện thì gen lại quizz từ
 * keypoint sau đó lưu vào csdl để lần sau lấy ra").
 *
 * Sets are shared between readers — the questions are about published teaching
 * material, not about anyone — and `coach_quiz_seen` is what keeps one reader
 * from meeting the same set twice.
 */
@Injectable()
export class CoachQuizService {
  private readonly logger = new Logger(CoachQuizService.name);

  constructor(
    private readonly setRepository: CoachQuizSetRepository,
    private readonly seenRepository: CoachQuizSeenRepository,
    private readonly habitLibraryRepository: HabitLibraryRepository,
    private readonly keypointRepository: KeypointRepository,
    private readonly learningItemRepository: LearningItemRepository,
    private readonly ai: CoachAi,
    private readonly contentSource: ContentSource,
    private readonly requestService: RequestService,
  ) {}

  /**
   * A quiz for this habit: the first unseen stored set, or a freshly written
   * one when every set has been seen (or none exists yet).
   *
   * [allowedKeypointIds] is the reader's own studied keypoints — practice only
   * ever asks about what they actually learned, the same rule the deck follows.
   *
   * [write] là quyền GỌI MODEL khi kho đã cạn. Nơi nào người đọc đang chờ màn
   * hình thì truyền `false`: một lượt Gemini trung bình 2.3s trên dev, và ở lối
   * mở phiên nó chỉ để biết CÓ NÊN mời làm quiz hay không — người đọc còn chưa
   * bấm gì. Cạn kho mà không được viết thì trả null, người gọi tự lo đường
   * khác (cửa Thói quen rơi về bộ câu hỏi đã soạn sẵn trong DB).
   */
  async quizForHabit(params: {
    userId: string;
    habitId: string;
    locale: string;
    allowedKeypointIds?: Set<string>;
    write?: boolean;
  }): Promise<{ keypointId: string; setId: string; questions: ICoachQuizQuestion[] } | null> {
    const { userId, habitId, locale, allowedKeypointIds, write = true } = params;
    const keypointIds = await this.keypointsOf(habitId, allowedKeypointIds);
    if (!keypointIds.length) return null;

    const stored = await this.setRepository
      .findForKeypoints(keypointIds, locale)
      .catch(() => []);
    const seen = await this.seenRepository
      .seenSetIds(userId, stored.map((row) => String(row._id)))
      .catch(() => new Set<string>());
    const unseen = stored.filter((row) => !seen.has(String(row._id)));

    if (unseen.length) {
      const chosen = unseen[Math.floor(Math.random() * unseen.length)];

      return this.serve(userId, String(chosen._id), String(chosen.keypointId), chosen.questions as ICoachQuizQuestion[]);
    }

    // Nothing unseen: write one now, about a keypoint chosen at random from the
    // ones this reader has studied.
    const keypointId = keypointIds[Math.floor(Math.random() * keypointIds.length)];
    if (!write) {
      // Không được phép bắt người đọc chờ model: viết bộ kế tiếp ở nền để lần
      // sau có sẵn, còn lần này trả null cho người gọi tự xoay.
      this.replenish({ habitId, locale, allowedKeypointIds });

      return null;
    }
    const written = await this.generateFor(keypointId, locale);
    if (!written) {
      // The generator failed and everything stored has been seen: better an old
      // set than no quiz at all.
      if (!stored.length) return null;
      const fallback = stored[0];

      return this.serve(userId, String(fallback._id), String(fallback.keypointId), fallback.questions as ICoachQuizQuestion[]);
    }

    return this.serve(userId, written.id, keypointId, written.questions);
  }

  /**
   * Những (habit, locale) đang có một lượt viết chạy dở ở nền.
   *
   * Mở lại cửa Thói quen mấy lần liền khi kho đã cạn thì mỗi lần lại xin viết
   * một bộ — cùng một bộ, trả tiền model mấy lần. Khoá này để lượt thứ hai đi
   * qua trong im lặng thay vì xếp hàng sau lượt đầu.
   */
  private readonly writing = new Set<string>();

  /**
   * Write the NEXT set in the background, so the reader who just finished a
   * quiz finds a fresh one waiting rather than a model call.
   */
  replenish(params: { habitId: string; locale: string; allowedKeypointIds?: Set<string> }): void {
    const inFlight = `${params.habitId}:${params.locale}`;
    if (this.writing.has(inFlight)) return;
    this.writing.add(inFlight);
    void (async () => {
      try {
        const keypointIds = await this.keypointsOf(params.habitId, params.allowedKeypointIds);
        if (!keypointIds.length) return;
        const keypointId = keypointIds[Math.floor(Math.random() * keypointIds.length)];
        await this.generateFor(keypointId, params.locale);
      } catch (error: any) {
        this.logger.warn(`Coach could not write the next quiz: ${error?.message}`);
      } finally {
        this.writing.delete(inFlight);
      }
    })();
  }

  /** The keypoints a habit is anchored to, narrowed to what the reader studied. */
  private async keypointsOf(
    habitId: string,
    allowed?: Set<string>,
  ): Promise<string[]> {
    const habits = (await this.habitLibraryRepository
      .findByIds([habitId])
      .catch(() => [])) as Array<{ keypointIds?: unknown[] }>;
    const ids = (habits[0]?.keypointIds ?? [])
      .map((id) => String(id ?? ''))
      .filter(Boolean);

    return allowed ? ids.filter((id) => allowed.has(id)) : ids;
  }

  private async serve(
    userId: string,
    setId: string,
    keypointId: string,
    questions: ICoachQuizQuestion[],
  ) {
    await Promise.all([
      this.seenRepository.markSeen(userId, setId, keypointId).catch(() => undefined),
      this.setRepository.markServed(setId).catch(() => undefined),
    ]);

    return { keypointId, setId, questions: questions.slice(0, QUESTIONS_PER_SET) };
  }

  /** One model call, one stored set. Null when there is nothing to write from. */
  private async generateFor(
    keypointId: string,
    locale: string,
  ): Promise<{ id: string; questions: ICoachQuizQuestion[] } | null> {
    try {
      const material = await this.materialOf(keypointId, locale);
      if (!material.text) return null;

      const stored = await this.setRepository
        .findForKeypoints([keypointId], locale)
        .catch(() => []);
      const avoid = stored
        .flatMap((row) => (row.questions as ICoachQuizQuestion[]) ?? [])
        .map((question) => question.question)
        .filter(Boolean)
        .slice(0, AVOID_SAMPLE);

      const written = await this.ai.makeQuiz({
        locale,
        keypointTitle: material.title,
        material: material.text,
        count: QUESTIONS_PER_SET,
        avoid,
      });
      const questions = written.questions.slice(0, QUESTIONS_PER_SET);
      if (!questions.length) return null;

      const saved = await this.setRepository.create({
        keypointId,
        locale,
        questions,
        servedCount: 0,
      } as never);

      return { id: String((saved as { _id: unknown })._id), questions };
    } catch (error: any) {
      this.logger.warn(`Coach could not generate a quiz: ${error?.message}`);

      return null;
    }
  }

  /**
   * What the keypoint teaches, as plain text: its own title and description,
   * then the theory paragraphs and the authored questions — the questions are
   * MATERIAL here, not questions to reuse.
   */
  private async materialOf(
    keypointId: string,
    locale: string,
  ): Promise<{ title: string; text: string }> {
    const pick = (value?: ITranslation | null): string =>
      (value?.[locale as keyof ITranslation] as string) || (value?.en as string) || '';

    const [keypoints, items] = await Promise.all([
      // Nguyên liệu cho Gemini phải là nội dung ĐÃ PHÁT HÀNH, không phải bản
      // đang sửa. Xem `plans/260907-course-content-versions/README.md`.
      this.contentSource
        .getKeypointBriefsAcrossVersions([keypointId], this.requestService.headers)
        .catch(() => []),
      this.contentSource
        .getLearningItemsByKeypointIdsAcrossVersions(
          [keypointId],
          this.requestService.headers,
        )
        .then(narratableItemsOf)
        .catch(() => []),
    ]);
    const keypoint = (keypoints as Array<{ title?: ITranslation; description?: ITranslation }>)[0];
    const parts: string[] = [pick(keypoint?.title), pick(keypoint?.description)];

    for (const item of items as Array<{
      title?: ITranslation;
      description?: ITranslation;
      documents?: Array<{ data?: { content?: ITranslation } }>;
      questions?: Array<{
        document?: Array<{ data?: { content?: ITranslation } }>;
        options?: Array<{ value?: ITranslation; isCorrect?: boolean }>;
        explanation?: ITranslation;
      }>;
    }>) {
      parts.push(pick(item.title), pick(item.description));
      for (const document of item.documents ?? []) parts.push(pick(document?.data?.content));
      for (const question of item.questions ?? []) {
        for (const document of question.document ?? []) parts.push(pick(document?.data?.content));
        for (const option of question.options ?? []) {
          const text = pick(option?.value);
          if (text) parts.push(option?.isCorrect ? `${text} (đúng)` : text);
        }
        parts.push(pick(question.explanation));
      }
    }

    const text = parts
      .map((part) => part.trim())
      .filter(Boolean)
      .join('\n')
      .slice(0, MATERIAL_MAX_CHARS);

    return { title: pick(keypoint?.title), text };
  }
}
