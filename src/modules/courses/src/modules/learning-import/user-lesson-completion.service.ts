import { Injectable, Logger } from '@nestjs/common';

import { GeminiLessonGeneratorService } from './ai/gemini-lesson-generator.service';
import { ResolvedSource } from './ai/lesson-generation.types';
import { UserLessonVoiceoverService } from './audio/user-lesson-voiceover.service';
import {
  ImportSourceType,
  UserLessonContentStatus,
} from './enum/learning-import.enum';
import { ILessonKeypoint } from './interface/learning-import.interface';
import { LEARNING_IMPORT_CONFIG } from './learning-import.config';
import {
  normalizeGeneratedLesson,
  pickPoolImage,
} from './learning-import.util';
import { LearningImportConfigRepository } from './repository/learning-import-config.repository';
import { UserLessonRepository } from './repository/user-lesson.repository';
import { UserLesson } from './schema/user-lesson.schema';
import { PdfSourceResolver } from './source/pdf-source.resolver';
import { YoutubeSourceResolver } from './source/youtube-source.resolver';

/**
 * Same cadence and staleness window as the import job's own heartbeat: a
 * background run stamps every 30s, and silence past 2 minutes means the process
 * that owned it is gone, not busy.
 */
const GENERATION_HEARTBEAT_MS = 30 * 1000;
export const GENERATION_STALE_MS = 2 * 60 * 1000;

/**
 * Finishes what the import job started (plans/260813-progressive-import).
 *
 * The job ships the first keypoint and completes; this service owns everything
 * after that moment: generating the rest of the outline, dubbing whatever audio
 * is missing, and doing both AGAIN whenever a run dies — it is called
 * fire-and-forget by the runner and on a timer by the sweep, and every entry
 * point goes through the same atomic claim, so "who finishes this lesson" is
 * never two answers at once.
 */
@Injectable()
export class UserLessonCompletionService {
  private readonly logger = new Logger(UserLessonCompletionService.name);

  constructor(
    private readonly userLessonRepository: UserLessonRepository,
    private readonly generator: GeminiLessonGeneratorService,
    private readonly pdfResolver: PdfSourceResolver,
    private readonly voiceoverService: UserLessonVoiceoverService,
    private readonly configRepository: LearningImportConfigRepository,
  ) {}

  /**
   * Write the lesson's remaining keypoints, then top up its narration.
   *
   * Never throws: failures are recorded on the claim (`attempts`,
   * `lastAttemptAt`) and the sweep retries on a backoff. There is deliberately
   * NO attempt ceiling — "a generated lesson always ends up complete, with
   * audio" is the product requirement, so a lesson that keeps failing keeps
   * being retried (ever more slowly) and keeps showing up in the logs until
   * someone looks at why.
   */
  async continueGeneration(lessonId: string): Promise<void> {
    const staleBefore = new Date(Date.now() - GENERATION_STALE_MS);
    const claimed = await this.userLessonRepository.claimGeneration(
      lessonId,
      staleBefore,
    );
    // Someone else is (visibly alive and) on it. Normal, not an error: the
    // runner's fire-and-forget and the sweep race here by design.
    if (!claimed) return;

    const heartbeat = setInterval(() => {
      this.userLessonRepository.beatGeneration(lessonId).catch(() => undefined);
    }, GENERATION_HEARTBEAT_MS);

    try {
      const lesson = await this.userLessonRepository.findAny(lessonId);
      if (!lesson) {
        this.logger.warn(`Completion skipped: lesson ${lessonId} is gone`);

        return;
      }

      if (lesson.contentStatus === UserLessonContentStatus.PARTIAL) {
        await this.writeRemainingKeypoints(lesson);
      }

      // Content first, audio second, always: dubbing reads the keypoints off
      // the document, so it picks up whatever the step above just landed.
      await this.voiceoverService.dubMissingKeypoints(lessonId);
    } catch (error: any) {
      this.logger.error(
        `Completion run failed for lesson ${lessonId} (attempt recorded, sweep will retry): ${error?.message}`,
        error?.stack,
      );
    } finally {
      clearInterval(heartbeat);
      await this.userLessonRepository
        .releaseGeneration(lessonId)
        .catch(() => undefined);
    }
  }

  /**
   * Audio-only pass, for lessons whose body is already complete.
   *
   * Same claim discipline as the full run: dubbing one lesson from two
   * processes at once is wasteful rather than harmful (the union write
   * converges), but the claim keeps retry pacing in one place.
   */
  async topUpAudio(lessonId: string): Promise<void> {
    const staleBefore = new Date(Date.now() - GENERATION_STALE_MS);
    const claimed = await this.userLessonRepository.claimGeneration(
      lessonId,
      staleBefore,
    );
    if (!claimed) return;

    const heartbeat = setInterval(() => {
      this.userLessonRepository.beatGeneration(lessonId).catch(() => undefined);
    }, GENERATION_HEARTBEAT_MS);

    try {
      await this.voiceoverService.dubMissingKeypoints(lessonId);
    } finally {
      clearInterval(heartbeat);
      await this.userLessonRepository
        .releaseGeneration(lessonId)
        .catch(() => undefined);
    }
  }

  private async writeRemainingKeypoints(lesson: UserLesson): Promise<void> {
    const lessonId = String(lesson._id);
    const plan = lesson.plannedKeypointTitles ?? [];
    const written = lesson.keypoints ?? [];

    // A plan the body already covers has nothing left to write — flip the
    // status and move on. Happens when a previous run died between landing the
    // keypoints and its dub, or when phase 1's plan was a single keypoint.
    if (plan.length <= written.length) {
      await this.completeWith(lessonId, lesson, written);

      return;
    }

    const source = await this.resolveSource(lesson);

    const { keypoints: generated } = await this.generator.generateContinuation({
      source,
      outputLocale: lesson.outputLocale,
      targetWordCount: LEARNING_IMPORT_CONFIG.targetWordCount,
      targetKeypointCount: LEARNING_IMPORT_CONFIG.targetKeypointCount,
      targetCardsPerKeypoint: LEARNING_IMPORT_CONFIG.targetCardsPerKeypoint,
      targetWordsPerCard: LEARNING_IMPORT_CONFIG.targetWordsPerCard,
      targetWordsPerShortCard: LEARNING_IMPORT_CONFIG.targetWordsPerShortCard,
      hardWordsPerCard: LEARNING_IMPORT_CONFIG.hardWordsPerCard,
      lessonTitle: lesson.title,
      keypointPlan: plan,
      writtenKeypoints: written,
    });

    // The plan's titles win over whatever the model re-imagined: the reader has
    // been looking at those titles on the roadmap since the import finished,
    // and a node quietly renaming itself reads as the app losing its mind.
    // Each appended keypoint is also dealt its node thumbnail here — same seed
    // (jobId) and same offset scheme (absolute keypoint index) as the runner
    // used for keypoint 0, so one lesson walks the pool as one sequence.
    const importConfig = await this.configRepository.findOrCreateDefault();
    const seed = lesson.jobId || lessonId;
    const plannedCovers = lesson.plannedKeypointCoverUrls ?? [];
    const titled = generated.map((keypoint, index) => {
      const absolute = written.length + index;

      return {
        ...keypoint,
        title: plan[absolute] || keypoint.title,
        // The art the roadmap promised for this node when the outline landed
        // wins over a fresh deal. Minutes-to-hours can pass between the two
        // phases, and re-dealing here against an edited pool would change the
        // picture the reader has been looking at. Falls back to the same seed
        // and offset scheme for lessons dealt before the planned array existed.
        coverUrl:
          plannedCovers[absolute] ||
          pickPoolImage(importConfig.keypointImageUrls, seed, absolute) ||
          undefined,
      };
    });

    await this.completeWith(lessonId, lesson, [...written, ...titled]);
  }

  /**
   * Normalize and land the assembled body.
   *
   * The word floor stays OFF here even though the whole lesson is now known:
   * the reader has been inside keypoint 1 for minutes, so "too short" is no
   * longer a rejectable condition — there is no honest way to un-ship what they
   * are reading. It is logged instead, loudly, because a lesson landing under
   * the floor means the SOURCE was thin and the opening phase let it through.
   */
  private async completeWith(
    lessonId: string,
    lesson: UserLesson,
    keypoints: ILessonKeypoint[],
  ): Promise<void> {
    const normalized = normalizeGeneratedLesson(
      {
        title: lesson.title,
        description: lesson.description,
        keypoints,
      },
      { enforceWordFloor: false },
    );

    if (normalized.wordCount < LEARNING_IMPORT_CONFIG.minAcceptedWordCount) {
      this.logger.warn(
        `Lesson ${lessonId} completed UNDER the word floor (${normalized.wordCount} < ${LEARNING_IMPORT_CONFIG.minAcceptedWordCount}) — thin source slipped past the opening phase`,
      );
    }

    await this.userLessonRepository.completeContent(
      lessonId,
      normalized.keypoints,
      normalized.wordCount,
      normalized.estimatedMinutes,
    );

    this.logger.log(
      `Lesson ${lessonId} content complete: ${normalized.keypoints.length} keypoints, ${normalized.wordCount} words`,
    );
  }

  /**
   * Rebuild the generator's source from what the lesson remembers.
   *
   * No length re-check and no availability probe: those gates guarded JOB
   * creation, and this lesson already passed them. A YouTube video that has
   * since been deleted will fail in the provider and surface as a retryable
   * error — which is the truthful outcome, since the material may come back.
   */
  private async resolveSource(lesson: UserLesson): Promise<ResolvedSource> {
    if (lesson.source?.type === ImportSourceType.PDF) {
      return this.pdfResolver.resolve(
        lesson.source?.fileKey ?? '',
        lesson.source?.fileName ?? '',
      );
    }

    // Canonical form, same as the job-time resolver: the stored url is whatever
    // the user pasted (youtu.be shortlink, ?si= tracking), and the provider is
    // handed the shape it is known to fetch reliably.
    const videoId = YoutubeSourceResolver.parseVideoId(
      lesson.source?.url ?? '',
    );

    return {
      kind: 'remoteUri',
      uri: videoId
        ? `https://www.youtube.com/watch?v=${videoId}`
        : (lesson.source?.url ?? ''),
    };
  }
}
