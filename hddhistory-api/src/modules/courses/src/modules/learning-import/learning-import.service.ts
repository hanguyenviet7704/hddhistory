import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';

import { RequestService } from '@base/service/request.service';
import { IResponseListPage } from '@utils/interface/paging/page.interface';

import { GeminiLessonGeneratorService } from './ai/gemini-lesson-generator.service';
import { CreateLearningImportDto } from './dto/create-learning-import.dto';
import {
  ListLearningImportAdminDto,
  ListUserLessonDto,
} from './dto/list-learning-import.dto';
import {
  ImportJobStatus,
  ImportRejectionCode,
  ImportSourceType,
} from './enum/learning-import.enum';
import { IImportSource } from './interface/learning-import.interface';
import { LearningImportConfigService } from './learning-import-config.service';
import { LearningImportQuotaService } from './learning-import-quota.service';
import { LearningImportRunnerService } from './learning-import-runner.service';
import { LearningImportJobRepository } from './repository/learning-import-job.repository';
import { UserLessonRepository } from './repository/user-lesson.repository';
import { LearningImportJob } from './schema/learning-import-job.schema';
import { YoutubeSourceResolver } from './source/youtube-source.resolver';

/**
 * What the app polls. A flattened view of the job, never the document itself:
 * `status` here can be `interrupted`, which is derived rather than stored.
 */
export interface ImportJobSnapshot {
  id: string;
  status: ImportJobStatus;
  stage: string | null;
  percent: number;
  sourceType: ImportSourceType;
  sourceLabel: string;
  outputLocale: string;
  userLessonId: string | null;
  errorCode: string | null;
  createdAt: Date;
  completedAt: Date | null;
}

@Injectable()
export class LearningImportService {
  private readonly logger = new Logger(LearningImportService.name);

  constructor(
    private readonly jobRepository: LearningImportJobRepository,
    private readonly userLessonRepository: UserLessonRepository,
    private readonly quotaService: LearningImportQuotaService,
    private readonly runner: LearningImportRunnerService,
    private readonly generator: GeminiLessonGeneratorService,
    private readonly configService: LearningImportConfigService,
    private readonly requestService: RequestService,
  ) {}

  private get userId(): string {
    return this.requestService.user?.id?.toString?.();
  }

  /**
   * Accept an import and start it in the background.
   *
   * Every gate is checked BEFORE a job document exists, so a rejected request
   * leaves nothing behind to explain, and the four walls fail in the order that
   * gives the most useful message: configuration (ours), then entitlement, then
   * allowance, then concurrency.
   */
  async create(dto: CreateLearningImportDto): Promise<ImportJobSnapshot> {
    const userId = this.userId;
    const source = this.buildSource(dto);

    // The admin's switch comes first: when the feature is off, nothing else
    // about this request matters, and a reader should be told it is closed
    // rather than that their quota ran out.
    const config = await this.configService.getConfig();
    if (!config.enabled) {
      throw new ServiceUnavailableException({
        message:
          config.disabledNote?.trim() ||
          'Lesson generation is currently turned off',
        errors: [{ code: ImportRejectionCode.FEATURE_DISABLED }],
      });
    }

    // Checked next because it is our fault, not the user's: without a key every
    // job would be accepted and then fail identically two minutes later.
    if (!this.generator.isConfigured()) {
      throw new ServiceUnavailableException({
        message: 'Lesson generation is not configured on this server',
        errors: [{ code: 'AI_NOT_CONFIGURED' }],
      });
    }

    const quota = await this.quotaService.getQuota(userId);

    // No premium GATE any more: a reader without a subscription gets one
    // lifetime ticket (`freeQuotaLifetime`), so the only thing standing between
    // them and an import is the count below. `isPremium` still rides along on the
    // quota response, because it decides which allowance applies and what the
    // app's upsell line says.
    if (quota.remaining <= 0) {
      throw new ForbiddenException({
        message: quota.isPremium
          ? `Weekly import limit reached (${quota.limit})`
          : `Free import limit reached (${quota.limit})`,
        errors: [
          {
            code: ImportRejectionCode.QUOTA_EXCEEDED,
            resetsAt: quota.resetsAt,
            isPremium: quota.isPremium,
          },
        ],
      });
    }

    const active = await this.jobRepository.findActiveByUser(
      userId,
      new Date(Date.now() - LearningImportRunnerService.HEARTBEAT_STALE_MS),
    );
    if (active) {
      throw new ConflictException({
        message: 'You already have an import in progress',
        errors: [
          {
            code: ImportRejectionCode.JOB_ALREADY_RUNNING,
            jobId: String(active._id),
          },
        ],
      });
    }

    const job = await this.jobRepository.create({
      userId,
      sourceType: dto.sourceType,
      source,
      outputLocale: dto.outputLocale,
      status: ImportJobStatus.QUEUED,
      percent: 0,
      heartbeatAt: new Date(),
      countsTowardQuota: true,
    });

    const jobId = String(job._id);

    // Fire-and-forget: the HTTP response must not wait on a multi-minute
    // generation. `run` owns its own failures; the catch here only exists so a
    // throw escaping it cannot become an unhandled rejection.
    setImmediate(() => {
      this.runner.run(jobId).catch(error => {
        this.logger.error(
          `Import job ${jobId} crashed outside its own handler: ${error?.message}`,
          error?.stack,
        );
      });
    });

    return this.toSnapshot(job);
  }

  async getJob(jobId: string): Promise<ImportJobSnapshot> {
    const job = await this.jobRepository.findOwnedJob(jobId, this.userId);
    if (!job) throw new NotFoundException('Import job not found');

    return this.toSnapshot(job);
  }

  async listJobs(
    dto: ListUserLessonDto,
  ): Promise<IResponseListPage<ImportJobSnapshot>> {
    const page = await this.jobRepository.findPaginatedByUser(
      this.userId,
      dto.page ?? 1,
      dto.take ?? 10,
    );

    return { ...page, items: page.items.map(job => this.toSnapshot(job)) };
  }

  /**
   * The allowance, plus whether the feature is open at all.
   *
   * Folded into the quota call rather than given its own endpoint: the app
   * already asks for this before showing the import screen, and a second request
   * to learn the same thing would just be a slower way to draw the same screen.
   */
  async getQuota() {
    const [quota, config] = await Promise.all([
      this.quotaService.getQuota(this.userId),
      this.configService.getConfig(),
    ]);

    return {
      ...quota,
      enabled: config.enabled,
      disabledNote: config.disabledNote ?? '',
    };
  }

  // ---------------------------------------------------------------- admin

  async listJobsForAdmin(dto: ListLearningImportAdminDto) {
    const page = await this.jobRepository.findPaginatedForAdmin({
      page: dto.page ?? 1,
      take: dto.take ?? 20,
      status: dto.status,
      search: dto.search,
    });

    return {
      ...page,
      items: page.items.map(job => ({
        ...this.toSnapshot(job),
        userId: job.userId,
        source: job.source,
        usage: job.usage,
        errorMessage: job.error?.message ?? null,
      })),
    };
  }

  /**
   * One import plus the lesson it produced.
   *
   * The lesson body is the point: reading what the model actually wrote is how
   * anyone judges whether the prompt is working, and doing it from the admin
   * beats asking a user to screenshot their lesson.
   */
  async getJobForAdmin(jobId: string) {
    const job = await this.jobRepository.findAnyJob(jobId);
    if (!job) throw new NotFoundException('Import job not found');

    const lesson = job.userLessonId
      ? await this.userLessonRepository.findAny(job.userLessonId)
      : await this.userLessonRepository.findByJobId(jobId);

    return {
      ...this.toSnapshot(job),
      userId: job.userId,
      source: job.source,
      usage: job.usage,
      errorMessage: job.error?.message ?? null,
      startedAt: job.startedAt ?? null,
      heartbeatAt: job.heartbeatAt ?? null,
      lesson: lesson
        ? {
            id: String(lesson._id),
            title: lesson.title,
            description: lesson.description,
            wordCount: lesson.wordCount,
            estimatedMinutes: lesson.estimatedMinutes,
            // Same back-compat wrap the reader's endpoint applies, so the admin
            // never has to know two body shapes ever existed.
            keypoints:
              lesson.keypoints?.length > 0
                ? lesson.keypoints
                : (lesson.sections ?? []).length > 0
                  ? [{ title: lesson.title || '', sections: lesson.sections }]
                  : [],
          }
        : null,
    };
  }

  // ---------------------------------------------------------------- internals

  /**
   * Turn the request into a stored source, rejecting shapes that cannot work.
   *
   * The YouTube link is parsed HERE rather than in the runner so a typo is a
   * 400 the user sees immediately, instead of a job that spends a slot in the
   * queue to tell them the same thing a minute later.
   */
  private buildSource(dto: CreateLearningImportDto): IImportSource {
    if (dto.sourceType === ImportSourceType.PDF) {
      if (!dto.fileKey) {
        throw new BadRequestException('fileKey is required for a PDF import');
      }

      return {
        type: ImportSourceType.PDF,
        fileKey: dto.fileKey,
        fileName: dto.fileName ?? dto.fileKey.split('/').pop() ?? 'document.pdf',
      };
    }

    if (!dto.url) {
      throw new BadRequestException('url is required for a YouTube import');
    }
    if (!YoutubeSourceResolver.parseVideoId(dto.url)) {
      throw new BadRequestException('That is not a valid YouTube link');
    }

    return { type: ImportSourceType.YOUTUBE, url: dto.url };
  }

  private toSnapshot(job: LearningImportJob): ImportJobSnapshot {
    return {
      id: String(job._id),
      status: this.derivedStatus(job),
      stage: job.stage ?? null,
      percent: job.percent ?? 0,
      sourceType: job.sourceType,
      sourceLabel:
        job.source?.videoTitle ||
        job.source?.fileName ||
        job.source?.url ||
        '',
      outputLocale: job.outputLocale,
      userLessonId: job.userLessonId || null,
      errorCode: job.error?.code ?? null,
      createdAt: job.createdAt,
      completedAt: job.completedAt ?? null,
    };
  }

  /**
   * `PROCESSING` is only true while something is still writing heartbeats.
   *
   * A run killed mid-generation leaves `PROCESSING` in the document forever --
   * nothing is alive to write a final status -- so a quiet heartbeat is reported
   * as `INTERRUPTED`. Without this the app would show a progress screen that
   * never moves and never fails, and the user's only option would be to wait.
   */
  private derivedStatus(job: LearningImportJob): ImportJobStatus {
    if (
      job.status !== ImportJobStatus.PROCESSING &&
      job.status !== ImportJobStatus.QUEUED
    ) {
      return job.status;
    }

    const lastBeat = (job.heartbeatAt ?? job.createdAt)?.getTime() ?? 0;

    return Date.now() - lastBeat > LearningImportRunnerService.HEARTBEAT_STALE_MS
      ? ImportJobStatus.INTERRUPTED
      : job.status;
  }
}
