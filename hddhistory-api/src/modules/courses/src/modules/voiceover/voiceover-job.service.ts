import { Injectable, Logger } from '@nestjs/common';

import {
  VoiceoverJobMode,
  VoiceoverJobScope,
  VoiceoverJobStatus,
} from './enum/voiceover-job.enum';
import { VoiceoverJobRepository } from './repository/voiceover-job.repository';
import { VoiceoverJob } from './schema/voiceover-job.schema';
import { VoiceoverService } from './voiceover.service';
import { CourseRepository } from '../course/repository/course.repository';
import { KeypointRepository } from '../keypoint/repository/keypoint.repository';
import { LessonRepository } from '../lesson/repository/lesson.repository';

/**
 * A dub run as the admin panel reads it. Dates come out as epoch milliseconds
 * (what the previous in-memory shape used), and two fields are DERIVED rather
 * than stored: `status` can report `interrupted`, and `etaSeconds` is computed
 * from the pace so far.
 */
export interface VoiceoverJobSnapshot {
  scope: VoiceoverJobScope;
  courseId: string;
  status: VoiceoverJobStatus;
  mode: VoiceoverJobMode;
  totalCourses: number;
  processedCourses: number;
  totalKeypoints: number;
  processed: number;
  generated: number;
  skipped: number;
  failed: number;
  currentCourseId: string;
  currentCourseTitle: Record<string, string>;
  currentKeypointId: string;
  currentKeypointTitle: Record<string, string>;
  queuedCourseIds: string[];
  doneCourseIds: string[];
  lastError: string;
  startedAt: number;
  finishedAt?: number;
  heartbeatAt: number;
  etaSeconds: number | null;
}

/** Everything in flight, in one poll: the global run plus per-course runs. */
export interface VoiceoverJobFeed {
  global: VoiceoverJobSnapshot | null;
  courses: VoiceoverJobSnapshot[];
}

/** Running counts of a run, kept in memory and flushed at every keypoint. */
interface RunProgress {
  totalCourses: number;
  processedCourses: number;
  totalKeypoints: number;
  processed: number;
  generated: number;
  skipped: number;
  failed: number;
  doneCourseIds: string[];
  lastError: string;
}

// A run writes its heartbeat at every keypoint. Two minutes is far longer than
// any single keypoint takes, so silence past it means the process is gone
// (deploy, restart, crash) rather than merely busy.
const HEARTBEAT_STALE_MS = 2 * 60 * 1000;

// How long a finished run keeps showing up in the poll, so a course row can
// still report its outcome for a while after a per-course dub ends instead of
// the badge just vanishing.
const RECENT_FINISH_WINDOW_MS = 10 * 60 * 1000;

/**
 * Runs course voiceover generation as a background job so a large course never
 * depends on the HTTP request staying open. `start`/`startGlobal` return
 * immediately with a snapshot; the admin polls for progress.
 *
 * Progress lives in Mongo (`voiceover_jobs`), not in this process. It used to be
 * a `Map` here, which the admin felt in three ways: a deploy mid-run wiped the
 * progress readout while nothing was actually finished, a run under more than
 * one replica could be started on one worker and polled on another (status came
 * back `null`), and a per-course run was invisible to the batch page entirely.
 *
 * The DB (`keypoint.audio`) remains the source of truth for RESULTS — this only
 * tracks a run — so an abandoned document costs nothing but the readout, and
 * re-triggering resumes via the per-keypoint hash skip.
 */
@Injectable()
export class VoiceoverJobService {
  private readonly logger = new Logger(VoiceoverJobService.name);

  constructor(
    private readonly voiceoverService: VoiceoverService,
    private readonly jobRepository: VoiceoverJobRepository,
    private readonly lessonRepository: LessonRepository,
    private readonly keypointRepository: KeypointRepository,
    private readonly courseRepository: CourseRepository,
  ) {}

  async getGlobalJob(): Promise<VoiceoverJobSnapshot | null> {
    const job = await this.jobRepository.findByScope(
      VoiceoverJobScope.GLOBAL,
      '',
    );

    return job ? this.toSnapshot(job) : null;
  }

  async getCourseJob(courseId: string): Promise<VoiceoverJobSnapshot | null> {
    const job = await this.jobRepository.findByScope(
      VoiceoverJobScope.COURSE,
      courseId,
    );

    return job ? this.toSnapshot(job) : null;
  }

  /**
   * The cheap endpoint behind the admin's 3-second poll: one query, one
   * document per run. The batch page used to poll the full coverage scan for
   * this, which walked the whole catalogue on every tick — the monitoring was
   * competing with the dubbing it was monitoring.
   */
  async getFeed(): Promise<VoiceoverJobFeed> {
    const windowStart = Date.now() - RECENT_FINISH_WINDOW_MS;
    const jobs = await this.jobRepository.findLive(new Date(windowStart));
    const snapshots = jobs.map((job) => this.toSnapshot(job));

    return {
      global:
        snapshots.find((job) => job.scope === VoiceoverJobScope.GLOBAL) ?? null,
      courses: snapshots.filter(
        (job) =>
          job.scope === VoiceoverJobScope.COURSE &&
          // A per-course run whose process died keeps `running` in the document
          // forever, so drop it from the table once it has gone quiet: the row's
          // own coverage chips already tell the real story, and a badge stuck on
          // a run from days ago reads worse than no badge. The GLOBAL job is
          // deliberately NOT dropped — an unfinished catalogue run stays
          // actionable ("chạy tiếp") however long it has been sitting there.
          (job.status !== VoiceoverJobStatus.INTERRUPTED ||
            job.heartbeatAt >= windowStart),
      ),
    };
  }

  /**
   * Start a background run over one course's keypoints. A run already in flight
   * for that course is returned as-is (no double-start).
   */
  async start(
    courseId: string,
    force = false,
  ): Promise<VoiceoverJobSnapshot | null> {
    const keypointCounts = await this.lessonRepository.countKeypointsByCourse();
    const titles = await this.courseTitles([courseId]);

    const claimed = await this.claim(VoiceoverJobScope.COURSE, courseId, {
      mode: force ? VoiceoverJobMode.FORCE : VoiceoverJobMode.NEEDED,
      totalCourses: 1,
      totalKeypoints: keypointCounts[courseId] ?? 0,
      queuedCourseIds: [courseId],
      doneCourseIds: [],
    });
    if (!claimed) return this.getCourseJob(courseId);

    // Fire-and-forget: do NOT await, so the HTTP request returns immediately.
    void this.runScope(VoiceoverJobScope.COURSE, courseId, {
      courseIds: [courseId],
      titles,
      force,
      totalCourses: 1,
      totalKeypoints: keypointCounts[courseId] ?? 0,
      doneCourseIds: [],
    });

    return this.toSnapshot(claimed);
  }

  /**
   * Start the single GLOBAL run: every keypoint of every course. `force`
   * re-synthesises even unchanged languages; otherwise `generateForKeypoint`'s
   * per-language hash skip means only missing/stale/failed languages are
   * actually re-synthesised.
   *
   * `resume` continues an interrupted run, skipping the courses it had already
   * finished. It is opt-in rather than automatic on purpose: a course marked
   * done may have been edited since, and silently skipping it would leave the
   * new content undubbed with the report claiming otherwise. A plain re-run
   * therefore walks everything and lets the hash skip decide.
   */
  async startGlobal(
    force: boolean,
    resume = false,
  ): Promise<VoiceoverJobSnapshot | null> {
    const courses = await this.courseRepository.findAllBriefTitles();
    const courseIds = (courses as any[]).map((course) => course._id.toString());
    const titles = new Map<string, Record<string, string>>(
      (courses as any[]).map((course) => [
        course._id.toString(),
        course.title ?? {},
      ]),
    );

    const previous = await this.jobRepository.findByScope(
      VoiceoverJobScope.GLOBAL,
      '',
    );
    const doneCourseIds = resume ? previous?.doneCourseIds ?? [] : [];
    const pending = courseIds.filter((id) => !doneCourseIds.includes(id));

    const keypointCounts = await this.lessonRepository.countKeypointsByCourse();
    // Counted up front, over the courses this run will actually walk, so the
    // progress bar and the ETA share one denominator that doesn't move.
    const totalKeypoints = pending.reduce(
      (sum, id) => sum + (keypointCounts[id] ?? 0),
      0,
    );

    const claimed = await this.claim(VoiceoverJobScope.GLOBAL, '', {
      mode: force ? VoiceoverJobMode.FORCE : VoiceoverJobMode.NEEDED,
      totalCourses: courseIds.length,
      processedCourses: doneCourseIds.length,
      totalKeypoints,
      queuedCourseIds: pending,
      doneCourseIds,
    });
    if (!claimed) return this.getGlobalJob();

    // Fire-and-forget: do NOT await, so the HTTP request returns immediately.
    void this.runScope(VoiceoverJobScope.GLOBAL, '', {
      courseIds: pending,
      titles,
      force,
      // The claim's number, not pending + done: a course deleted since the run
      // being resumed would otherwise push the total above the catalogue.
      totalCourses: courseIds.length,
      totalKeypoints,
      doneCourseIds,
    });

    return this.toSnapshot(claimed);
  }

  /**
   * Claim the run slot, seeding a fresh document. Returns `null` when a live run
   * already holds it — see `VoiceoverJobRepository.claim` for why this is one
   * atomic operation rather than a read followed by a write.
   */
  private async claim(
    scope: VoiceoverJobScope,
    courseId: string,
    seed: Partial<VoiceoverJob>,
  ): Promise<VoiceoverJob | null> {
    const now = new Date();

    return this.jobRepository.claim(
      scope,
      courseId,
      {
        scope,
        courseId,
        status: VoiceoverJobStatus.RUNNING,
        processedCourses: 0,
        processed: 0,
        generated: 0,
        skipped: 0,
        failed: 0,
        currentCourseId: '',
        currentCourseTitle: {},
        currentKeypointId: '',
        currentKeypointTitle: {},
        lastError: '',
        startedAt: now,
        heartbeatAt: now,
        ...seed,
      },
      new Date(now.getTime() - HEARTBEAT_STALE_MS),
    );
  }

  /**
   * Walk a list of courses, dubbing every keypoint of each.
   *
   * One code path for both scopes: a per-course run is simply this over a
   * single-course list, which is what makes a row's "Dub" report progress the
   * same way the catalogue-wide run does.
   */
  private async runScope(
    scope: VoiceoverJobScope,
    scopeId: string,
    run: {
      courseIds: string[];
      titles: Map<string, Record<string, string>>;
      force: boolean;
      totalCourses: number;
      totalKeypoints: number;
      doneCourseIds: string[];
    },
  ): Promise<void> {
    const progress: RunProgress = {
      totalCourses: run.totalCourses,
      processedCourses: run.doneCourseIds.length,
      totalKeypoints: run.totalKeypoints,
      processed: 0,
      generated: 0,
      skipped: 0,
      failed: 0,
      doneCourseIds: [...run.doneCourseIds],
      lastError: '',
    };

    // ONE allowance for the whole run, not one per course: the cap exists so a
    // single click cannot drain a prepaid Vbee balance, and a per-course cap
    // would let a catalogue-wide run spend it forty times over.
    const budget = this.voiceoverService.newVbeeBudget();

    try {
      for (let index = 0; index < run.courseIds.length; index++) {
        const courseId = run.courseIds[index];
        // Read once per course. Only courses explicitly switched to Vbee in
        // admin cost anything; every other course in a catalogue-wide run keeps
        // dubbing on the free voices exactly as before.
        const viProvider = await this.voiceoverService.resolveCourseViProvider(
          courseId,
        );
        const keypointIds = await this.lessonRepository.findKeypointIdsByCourse(
          courseId,
        );
        const keypointTitles = await this.keypointTitles(keypointIds);

        await this.flush(scope, scopeId, progress, {
          currentCourseId: courseId,
          currentCourseTitle: run.titles.get(courseId) ?? {},
          // What is left AFTER this course — the "Đang chờ" rows.
          queuedCourseIds: run.courseIds.slice(index + 1),
        });

        for (const keypointId of keypointIds) {
          // Written BEFORE the keypoint is dubbed: this is the "đang dub" the
          // admin reads, and it carries the counts as of the previous keypoint
          // (this one isn't processed yet).
          await this.flush(scope, scopeId, progress, {
            currentKeypointId: keypointId,
            currentKeypointTitle: keypointTitles.get(keypointId) ?? {},
          });

          try {
            const result = await this.voiceoverService.generateForKeypoint(
              keypointId,
              { force: run.force, viProvider, budget },
            );
            progress.generated += result.generated.length;
            progress.skipped += result.skipped.length;
            progress.failed += result.failed.length;
          } catch (err: any) {
            progress.failed += 1;
            progress.lastError = err?.message ?? 'error';
            this.logger.error(
              `Voiceover job (${scope}): keypoint ${keypointId} of course ${courseId} failed: ${err?.message}`,
              err?.stack,
            );
          }
          progress.processed += 1;
        }

        progress.processedCourses += 1;
        progress.doneCourseIds.push(courseId);
      }

      await this.finish(scope, scopeId, progress, VoiceoverJobStatus.DONE);
    } catch (err: any) {
      progress.lastError = err?.message ?? 'error';
      this.logger.error(
        `Voiceover job (${scope}) failed: ${err?.message}`,
        err?.stack,
      );
      await this.finish(scope, scopeId, progress, VoiceoverJobStatus.FAILED);
    }
  }

  /**
   * Write the current counts plus whatever changed, and stamp the heartbeat.
   *
   * Never throws: a Mongo blip must not abandon a run that has hours of
   * synthesis behind it. Losing a progress write costs one stale readout, and
   * the next keypoint writes it again.
   */
  private async flush(
    scope: VoiceoverJobScope,
    scopeId: string,
    progress: RunProgress,
    extra: Partial<VoiceoverJob> = {},
  ): Promise<void> {
    try {
      await this.jobRepository.patch(scope, scopeId, {
        totalCourses: progress.totalCourses,
        processedCourses: progress.processedCourses,
        totalKeypoints: progress.totalKeypoints,
        processed: progress.processed,
        generated: progress.generated,
        skipped: progress.skipped,
        failed: progress.failed,
        doneCourseIds: progress.doneCourseIds,
        lastError: progress.lastError,
        heartbeatAt: new Date(),
        ...extra,
      });
    } catch (err: any) {
      this.logger.warn(
        `Could not write voiceover job progress (${scope}): ${err?.message}`,
      );
    }
  }

  private async finish(
    scope: VoiceoverJobScope,
    scopeId: string,
    progress: RunProgress,
    status: VoiceoverJobStatus,
  ): Promise<void> {
    await this.flush(scope, scopeId, progress, {
      status,
      currentCourseId: '',
      currentCourseTitle: {},
      currentKeypointId: '',
      currentKeypointTitle: {},
      queuedCourseIds: [],
      finishedAt: new Date(),
    });
  }

  private async courseTitles(
    courseIds: string[],
  ): Promise<Map<string, Record<string, string>>> {
    const courses = await this.courseRepository.findAllBriefTitles();

    return new Map(
      (courses as any[])
        .filter((course) => courseIds.includes(course._id.toString()))
        .map((course) => [course._id.toString(), course.title ?? {}]),
    );
  }

  // One query per course, so the readout can name the keypoint being dubbed
  // BEFORE it is dubbed (the alternative — reading the title off the dub result
  // — would always name the previous one).
  private async keypointTitles(
    keypointIds: string[],
  ): Promise<Map<string, Record<string, string>>> {
    if (!keypointIds.length) return new Map();

    const keypoints = await this.keypointRepository.findBriefByIds(keypointIds);

    return new Map(
      (keypoints as any[]).map((keypoint) => [
        keypoint._id.toString(),
        keypoint.title ?? {},
      ]),
    );
  }

  private toSnapshot(job: VoiceoverJob): VoiceoverJobSnapshot {
    const status = this.derivedStatus(job);

    return {
      scope: job.scope,
      courseId: job.courseId ?? '',
      status,
      mode: job.mode,
      totalCourses: job.totalCourses ?? 0,
      processedCourses: job.processedCourses ?? 0,
      totalKeypoints: job.totalKeypoints ?? 0,
      processed: job.processed ?? 0,
      generated: job.generated ?? 0,
      skipped: job.skipped ?? 0,
      failed: job.failed ?? 0,
      currentCourseId: job.currentCourseId ?? '',
      currentCourseTitle: job.currentCourseTitle ?? {},
      currentKeypointId: job.currentKeypointId ?? '',
      currentKeypointTitle: job.currentKeypointTitle ?? {},
      queuedCourseIds: job.queuedCourseIds ?? [],
      doneCourseIds: job.doneCourseIds ?? [],
      lastError: job.lastError ?? '',
      startedAt: job.startedAt?.getTime() ?? 0,
      finishedAt: job.finishedAt?.getTime(),
      heartbeatAt: job.heartbeatAt?.getTime() ?? 0,
      etaSeconds: status === VoiceoverJobStatus.RUNNING ? this.eta(job) : null,
    };
  }

  /**
   * `RUNNING` is only true while someone is still writing heartbeats. A run
   * killed mid-dub leaves `RUNNING` in the document forever — nothing is alive
   * to write a final status — so a quiet heartbeat is reported as
   * `INTERRUPTED` rather than letting the banner insist a dead run is working.
   */
  private derivedStatus(job: VoiceoverJob): VoiceoverJobStatus {
    if (job.status !== VoiceoverJobStatus.RUNNING) return job.status;

    const lastBeat = (job.heartbeatAt ?? job.startedAt)?.getTime() ?? 0;

    return Date.now() - lastBeat > HEARTBEAT_STALE_MS
      ? VoiceoverJobStatus.INTERRUPTED
      : VoiceoverJobStatus.RUNNING;
  }

  /**
   * Seconds left at the pace measured so far. Deliberately paced off
   * `heartbeatAt` rather than the wall clock, so a run that stalled doesn't
   * quietly inflate its own estimate while nothing is happening.
   */
  private eta(job: VoiceoverJob): number | null {
    const processed = job.processed ?? 0;
    const remaining = (job.totalKeypoints ?? 0) - processed;
    if (!processed || remaining <= 0) return null;

    const elapsedMs =
      ((job.heartbeatAt ?? job.startedAt)?.getTime() ?? 0) -
      (job.startedAt?.getTime() ?? 0);
    if (elapsedMs <= 0) return null;

    return Math.round(((elapsedMs / processed) * remaining) / 1000);
  }
}
