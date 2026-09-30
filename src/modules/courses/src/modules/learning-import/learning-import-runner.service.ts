import { Injectable, Logger } from '@nestjs/common';

import { GeminiLessonGeneratorService } from './ai/gemini-lesson-generator.service';
import {
  LessonGenerationError,
  ResolvedSource,
} from './ai/lesson-generation.types';
import { UserLessonVoiceoverService } from './audio/user-lesson-voiceover.service';
import {
  ImportErrorCode,
  ImportJobStage,
  ImportJobStatus,
  ImportSourceType,
  UserLessonContentStatus,
} from './enum/learning-import.enum';
import {
  IImportSource,
  ILessonKeypoint,
} from './interface/learning-import.interface';
import {
  LEARNING_IMPORT_CONFIG,
  LEARNING_IMPORT_QUOTA_CHARGING_ERRORS,
} from './learning-import.config';
import {
  capitalizeFirstLetter,
  countLessonWords,
  estimateReadingMinutes,
  LessonTooShortError,
  normalizeGeneratedLesson,
  pickPoolImage,
} from './learning-import.util';
import { LearningImportConfigRepository } from './repository/learning-import-config.repository';
import { LearningImportJobRepository } from './repository/learning-import-job.repository';
import { UserLessonRepository } from './repository/user-lesson.repository';
import { LearningImportJob } from './schema/learning-import-job.schema';
import { PdfSourceResolver } from './source/pdf-source.resolver';
import { SourceResolutionError } from './source/source-resolution.error';
import { YoutubeSourceResolver } from './source/youtube-source.resolver';
import { UserLessonCompletionService } from './user-lesson-completion.service';

/**
 * Silence past this means the process running the job is gone (deploy, restart,
 * crash) rather than merely busy.
 *
 * Safe only because a heartbeat is written every 30s throughout, including
 * during generation -- see `beat`. Stamping only at stage boundaries would make
 * every generation longer than two minutes look dead, which is most of them.
 */
const HEARTBEAT_STALE_MS = 2 * 60 * 1000;

const HEARTBEAT_INTERVAL_MS = 30 * 1000;

/**
 * Per-token rates behind the cost shown on the admin screen.
 *
 * STALE, and knowingly so: these were the published rates for
 * `gemini-2.0-flash`, which Google has since removed entirely -- the default is
 * now `gemini-flash-latest`, whose rates are different and which, being an
 * alias, can change again. So read the admin's cost column as an order of
 * magnitude, not a bill.
 *
 * Left wrong rather than guessed at: inventing a plausible number would make the
 * column look authoritative while being just as wrong, and there is no way to
 * tell from inside the code what an alias currently resolves to. Replace both
 * constants with the real figures from the pricing page when someone needs the
 * cost to be trustworthy.
 */
const USD_PER_MILLION_INPUT_TOKENS = 0.075;
const USD_PER_MILLION_OUTPUT_TOKENS = 0.3;
const USD_TO_VND = 26_000;

@Injectable()
export class LearningImportRunnerService {
  private readonly logger = new Logger(LearningImportRunnerService.name);

  static readonly HEARTBEAT_STALE_MS = HEARTBEAT_STALE_MS;

  constructor(
    private readonly jobRepository: LearningImportJobRepository,
    private readonly userLessonRepository: UserLessonRepository,
    private readonly pdfResolver: PdfSourceResolver,
    private readonly youtubeResolver: YoutubeSourceResolver,
    private readonly generator: GeminiLessonGeneratorService,
    private readonly userLessonVoiceoverService: UserLessonVoiceoverService,
    private readonly completionService: UserLessonCompletionService,
    private readonly configRepository: LearningImportConfigRepository,
  ) {}

  /**
   * Run one import to completion.
   *
   * Called fire-and-forget from the service, so this method OWNS every failure:
   * anything that escapes lands in an unhandled rejection with the job stuck on
   * `processing` until the heartbeat check quietly calls it interrupted. Hence
   * the single try/catch around the whole body and the deliberately total
   * `classify`.
   */
  async run(jobId: string): Promise<void> {
    const job = await this.jobRepository.findAnyJob(jobId);
    if (!job) {
      this.logger.error(`Import job ${jobId} vanished before it started`);

      return;
    }

    const startedAt = new Date();
    await this.jobRepository.patch(jobId, {
      status: ImportJobStatus.PROCESSING,
      stage: ImportJobStage.FETCHING,
      percent: 5,
      startedAt,
      heartbeatAt: startedAt,
    });

    // Outside the try: the catch must know whether the failure happened before
    // or after the job (and the lesson) already succeeded — a post-completion
    // cleanup hiccup must never stamp FAILED over a completed job.
    let lessonId: string | null = null;
    let jobCompleted = false;

    try {
      const { source, sourceUpdates } = await this.resolveSource(job);

      await this.jobRepository.patch(jobId, {
        stage: ImportJobStage.GENERATING,
        percent: 25,
        heartbeatAt: new Date(),
        // Facts learned while fetching (video title, duration, page count) are
        // written now rather than at the end, so a run that fails during
        // generation still shows the admin what it was working on.
        source: { ...job.source, ...sourceUpdates },
      });

      // ONE streamed generation (plans/260813-progressive-import, streaming
      // addendum): the source is read once; the OUTLINE surfaces first and
      // completes this job (roadmap-first — the reader is looking at every
      // node while the bodies are still being written); each keypoint then
      // lands and is dubbed the moment its object closes in the stream.
      const importConfig = await this.configRepository.findOrCreateDefault();

      let plan: string[] = [];
      /** The art dealt to the outline at birth — see the field's schema doc. */
      let plannedCovers: string[] = [];
      let written: ILessonKeypoint[] = [];
      // Narration starts BEFORE a keypoint finishes: every card's clip is
      // synthesized the moment its text closes in the stream, so the dub run
      // at keypoint-close mostly just merges ready-made clips — "text done"
      // and "audio done" land together (user requirement, 2026-08-13).
      const prefetch = await this.userLessonVoiceoverService.createPrefetcher(
        job.outputLocale,
      );
      // Dub runs are chained, not awaited in the keypoint handler: a merge
      // still takes seconds and awaiting it would backpressure the stream;
      // chaining keeps runs serialized so two never race the same keypoint.
      let dubChain: Promise<void> = Promise.resolve();
      const chainDub = () => {
        if (!lessonId) return;
        const id = lessonId;
        dubChain = dubChain
          .then(() =>
            this.userLessonVoiceoverService.dubMissingKeypoints(
              id,
              prefetch ?? undefined,
            ),
          )
          .catch(() => undefined);
      };

      const streamResult = await this.beat(jobId, () =>
        this.generator.generateLessonStream(
          {
            source,
            outputLocale: job.outputLocale,
            targetWordCount: LEARNING_IMPORT_CONFIG.targetWordCount,
            targetKeypointCount: LEARNING_IMPORT_CONFIG.targetKeypointCount,
            targetCardsPerKeypoint:
              LEARNING_IMPORT_CONFIG.targetCardsPerKeypoint,
            targetWordsPerCard: LEARNING_IMPORT_CONFIG.targetWordsPerCard,
            targetWordsPerShortCard:
              LEARNING_IMPORT_CONFIG.targetWordsPerShortCard,
            hardWordsPerCard: LEARNING_IMPORT_CONFIG.hardWordsPerCard,
          },
          {
            // The outline IS the lesson's birth: create it, put it on the
            // shelf, complete the job. Everything after this callback happens
            // to a lesson the reader may already have open.
            onOutline: async outline => {
              plan = outline.keypointPlan
                .map(title => capitalizeFirstLetter(title.trim()))
                .filter(title => title.length > 0)
                .slice(0, LEARNING_IMPORT_CONFIG.targetKeypointCount.max);
              plannedCovers = plan.map((_, index) =>
                pickPoolImage(importConfig.keypointImageUrls, jobId, index),
              );

              const created = await this.userLessonRepository.create({
                userId: job.userId,
                title:
                  capitalizeFirstLetter(outline.title.trim()) ||
                  plan[0] ||
                  'Untitled',
                description: capitalizeFirstLetter(
                  outline.description.trim(),
                ),
                outputLocale: job.outputLocale,
                source: { ...job.source, ...sourceUpdates },
                // Art is dealt at birth and kept for life; the keypoints get
                // theirs one by one as they land, same seed, same sequence.
                coverUrl: pickPoolImage(importConfig.courseCoverUrls, jobId),
                keypoints: [],
                wordCount: 0,
                estimatedMinutes: 0,
                stopAtKeypointIndex: 0,
                stopAtSectionIndex: 0,
                jobId,
                contentStatus: UserLessonContentStatus.PARTIAL,
                plannedKeypointTitles: plan,
                // The art for every node of the outline, dealt now so a node
                // never changes its picture when its keypoint lands. Same
                // seed and offset scheme used below and by the completion
                // sweep, so these ARE the urls the keypoints end up with.
                plannedKeypointCoverUrls: plannedCovers,
                // Present from birth — marks the lesson as the completion
                // sweep's responsibility (and keeps the sweep off old rows).
                generation: {
                  attempts: 0,
                  lastAttemptAt: null,
                  heartbeatAt: null,
                },
                draft: true,
              });
              lessonId = String(created._id);

              // Hold the background claim for the rest of this stream, so the
              // sweep never starts a second writer against it. Released in
              // the post-stream cleanup; a crash leaves it to go stale, which
              // is exactly the signal the sweep resumes on.
              await this.userLessonRepository.claimGeneration(
                lessonId,
                new Date(),
              );

              await this.userLessonRepository.clearDraft(lessonId);
              await this.jobRepository.patch(jobId, {
                status: ImportJobStatus.COMPLETED,
                stage: null,
                percent: 100,
                userLessonId: lessonId,
                completedAt: new Date(),
                heartbeatAt: new Date(),
                error: null,
              });
              jobCompleted = true;
            },

            // Prefetch feeds: enqueue narration synthesis the moment a card's
            // (or a takeaway's) text is final. Cheap calls — they only queue.
            onKeypointHead: head => {
              prefetch?.ensureTakeaway(head.takeaway);
            },
            onSection: event => {
              prefetch?.ensureSection(event.section);
            },

            onKeypoint: async (keypoint, index) => {
              if (!lessonId) return;

              // Per-keypoint normalization, floor OFF (the floor is a whole-
              // lesson question). An empty keypoint is dropped; the sweep's
              // continuation refills the hole later.
              const normalizedKeypoint = normalizeGeneratedLesson(
                { title: '', description: '', keypoints: [keypoint] },
                { enforceWordFloor: false },
              ).keypoints[0];
              if (!normalizedKeypoint) return;

              // Pin to the plan the reader is already looking at, and deal
              // the node its art.
              normalizedKeypoint.title =
                plan[index] || normalizedKeypoint.title;
              // The picture the roadmap has ALREADY been showing for this node,
              // not a fresh deal: the stream runs for minutes and an admin
              // editing the pool inside that window would otherwise hand the
              // keypoint a different image than the one the reader is looking
              // at. Re-deal only if the outline predates the planned array.
              normalizedKeypoint.coverUrl =
                plannedCovers[index] ||
                pickPoolImage(importConfig.keypointImageUrls, jobId, index) ||
                undefined;

              const next = [...written, normalizedKeypoint];
              const wordCount = countLessonWords(next);
              await this.userLessonRepository.writeBody(
                lessonId,
                next,
                wordCount,
                estimateReadingMinutes(wordCount),
                next.length >= plan.length
                  ? UserLessonContentStatus.COMPLETE
                  : UserLessonContentStatus.PARTIAL,
              );
              written = next;

              this.userLessonRepository
                .beatGeneration(lessonId)
                .catch(() => undefined);
              chainDub();
            },
          },
        ),
      );

      // The generator only returns with an outline seen, so a missing lesson
      // here is a handler failure that already threw — this is belt and
      // braces for the type system.
      if (!lessonId) {
        throw new LessonGenerationError('Lesson was never created');
      }

      // Spend lands late (the job is already completed) but lands: the admin's
      // cost column reads the true figure for the WHOLE stream.
      await this.jobRepository.patch(jobId, {
        usage: {
          inputTokens: streamResult.usage.inputTokens,
          outputTokens: streamResult.usage.outputTokens,
          estimatedCostVnd: this.estimateCostVnd(streamResult.usage),
        },
      });

      const totalWords = countLessonWords(written);
      if (totalWords < LEARNING_IMPORT_CONFIG.minAcceptedWordCount) {
        this.logger.warn(
          `Lesson ${lessonId} streamed in UNDER the word floor (${totalWords} < ${LEARNING_IMPORT_CONFIG.minAcceptedWordCount}) — thin source`,
        );
      }

      // Let the chained dubs drain, then one more pass for any keypoint the
      // chain missed (e.g. two keypoints landing between chain links).
      await dubChain;
      await this.userLessonVoiceoverService.dubMissingKeypoints(
        lessonId,
        prefetch ?? undefined,
      );
      await this.userLessonRepository.releaseGeneration(lessonId);

      // A broken stream leaves the body short of the plan. Hand it straight
      // to the continuation instead of waiting for the sweep's next tick —
      // the reader is likely INSIDE the lesson right now.
      if (written.length < plan.length) {
        this.logger.warn(
          `Lesson ${lessonId} streamed ${written.length}/${plan.length} keypoints — starting continuation immediately`,
        );
        this.completionService
          .continueGeneration(lessonId)
          .catch(() => undefined);
      }
    } catch (error: any) {
      // Post-completion errors (usage patch, dub drain, claim release) belong
      // to the LESSON's background story, not the job's: the sweep picks the
      // lesson up from its stale claim, and the job stays truthfully
      // completed.
      if (jobCompleted && lessonId) {
        this.logger.error(
          `Post-completion cleanup failed for lesson ${lessonId} (sweep will finish it): ${error?.message}`,
          error?.stack,
        );
        await this.userLessonRepository
          .releaseGeneration(lessonId)
          .catch(() => undefined);

        return;
      }
      await this.fail(jobId, error);
    }
  }

  private async resolveSource(job: LearningImportJob): Promise<{
    source: ResolvedSource;
    sourceUpdates: Partial<IImportSource>;
  }> {
    if (job.sourceType === ImportSourceType.PDF) {
      const source = await this.pdfResolver.resolve(
        job.source?.fileKey ?? '',
        job.source?.fileName ?? '',
      );

      return { source, sourceUpdates: {} };
    }

    const resolution = await this.youtubeResolver.resolve(job.source?.url ?? '');

    return {
      source: resolution.source,
      sourceUpdates: {
        videoTitle: resolution.videoTitle,
        videoDurationSeconds: resolution.durationSeconds,
      },
    };
  }

  /**
   * Run `work`, stamping the heartbeat every 30s until it settles.
   *
   * Generation is the one stage that can run for minutes, which makes it the one
   * stage that would otherwise look dead to the staleness check. Without this, a
   * perfectly healthy eight-minute generation would be reported as
   * `INTERRUPTED` to the app about two minutes in, and the user would abandon a
   * run that was about to succeed.
   */
  private async beat<T>(jobId: string, work: () => Promise<T>): Promise<T> {
    const timer = setInterval(() => {
      // Deliberately not awaited and deliberately swallowed: a failed progress
      // write must never take down a run that is otherwise fine, and the next
      // tick writes it again.
      this.jobRepository
        .patch(jobId, { heartbeatAt: new Date() })
        .catch(() => undefined);
    }, HEARTBEAT_INTERVAL_MS);

    try {
      return await work();
    } finally {
      clearInterval(timer);
    }
  }

  /**
   * Record why a run failed, and whether it costs the user a slot.
   *
   * Every failure is recorded with a code the app can turn into its own
   * sentence, and -- today -- none of them charges the user, because none of them
   * left the user with a lesson. `LEARNING_IMPORT_QUOTA_CHARGING_ERRORS` is the
   * one place that policy is written down.
   */
  private async fail(jobId: string, error: any): Promise<void> {
    const code = this.classify(error);

    if (code === ImportErrorCode.INTERNAL) {
      this.logger.error(
        `Import job ${jobId} failed: ${error?.message}`,
        error?.stack,
      );
    } else {
      this.logger.warn(`Import job ${jobId} failed (${code}): ${error?.message}`);
    }

    try {
      await this.jobRepository.patch(jobId, {
        status: ImportJobStatus.FAILED,
        stage: null,
        completedAt: new Date(),
        heartbeatAt: new Date(),
        countsTowardQuota: LEARNING_IMPORT_QUOTA_CHARGING_ERRORS.has(code),
        error: {
          code,
          // The message is for the admin screen and the logs. The app renders
          // from `code` alone, so nothing here reaches an end user -- which is
          // what lets it carry provider detail without leaking it.
          message: error?.message ?? 'Unknown error',
        },
      });
    } catch (patchError: any) {
      // If even this write fails the job stays `processing` and the heartbeat
      // check will report it interrupted, which is the correct outcome anyway.
      this.logger.error(
        `Could not record failure for import job ${jobId}: ${patchError?.message}`,
      );
    }
  }

  private classify(error: any): ImportErrorCode {
    if (error instanceof SourceResolutionError) return error.code;
    if (error instanceof LessonTooShortError) {
      return ImportErrorCode.CONTENT_TOO_SHORT;
    }
    if (error instanceof LessonGenerationError) {
      return error.timedOut
        ? ImportErrorCode.AI_TIMEOUT
        : ImportErrorCode.AI_FAILED;
    }

    return ImportErrorCode.INTERNAL;
  }

  private estimateCostVnd(usage: {
    inputTokens: number;
    outputTokens: number;
  }): number {
    const usd =
      (usage.inputTokens / 1_000_000) * USD_PER_MILLION_INPUT_TOKENS +
      (usage.outputTokens / 1_000_000) * USD_PER_MILLION_OUTPUT_TOKENS;

    return Math.round(usd * USD_TO_VND);
  }
}
