import { Injectable } from '@nestjs/common';

import { ImportJobStatus } from './enum/learning-import.enum';
import { LearningImportJobRepository } from './repository/learning-import-job.repository';

/** One bar of the admin panel's status breakdown. */
export interface ImportStatusCount {
  status: string;
  count: number;
}

export interface ImportSourceCount {
  sourceType: string;
  count: number;
}

/** A failure worth naming, with how often it happened. */
export interface ImportErrorCount {
  code: string;
  count: number;
}

export interface LearningImportStats {
  totalJobs: number;
  /** Jobs started in the last 7 days -- the number that says whether anyone is
   *  actually using this. */
  jobsLast7Days: number;
  completedJobs: number;
  failedJobs: number;
  /** Queued or processing as of this request. `interrupted` is deliberately not
   *  counted here: it is DERIVED from a stale heartbeat when a job is read, so
   *  the stored status of an abandoned job is still `processing`. */
  runningJobs: number;
  /**
   * Completed / (completed + failed), as a percentage.
   *
   * Running and queued jobs are excluded on purpose: a job that has not finished
   * is not evidence either way, and counting it as a failure makes the rate
   * lurch every time someone starts an import.
   */
  successRate: number;
  /** Distinct users who have ever started one. */
  uniqueUsers: number;
  /** Sum of `usage.estimatedCostVnd`. Indicative, not a bill -- see the note on
   *  the runner's cost estimate. */
  totalCostVnd: number;
  averageCostVnd: number;
  totalLessons: number;
  byStatus: ImportStatusCount[];
  bySource: ImportSourceCount[];
  topErrors: ImportErrorCount[];
}

/**
 * What the import feature has actually done, for the admin panel.
 *
 * Read straight off the job collection rather than from counters kept up to date
 * by hand: the jobs ARE the record, and a counter that drifts from them is worse
 * than a query that takes 40ms. Every number here answers a question someone
 * asked out loud -- is anyone using it, is it working, what does it cost, and
 * when it fails, what fails.
 */
@Injectable()
export class LearningImportStatsService {
  constructor(private readonly jobRepository: LearningImportJobRepository) {}

  async getStats(): Promise<LearningImportStats> {
    const since = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const raw = await this.jobRepository.aggregateStats(since);

    const byStatus = raw.byStatus;
    const countOf = (status: ImportJobStatus) =>
      byStatus.find(entry => entry.status === status)?.count ?? 0;

    const completed = countOf(ImportJobStatus.COMPLETED);
    const failed = countOf(ImportJobStatus.FAILED);
    const settled = completed + failed;

    return {
      totalJobs: raw.totalJobs,
      jobsLast7Days: raw.jobsLast7Days,
      completedJobs: completed,
      failedJobs: failed,
      runningJobs:
        countOf(ImportJobStatus.QUEUED) + countOf(ImportJobStatus.PROCESSING),
      successRate: settled === 0 ? 0 : Math.round((completed / settled) * 100),
      uniqueUsers: raw.uniqueUsers,
      totalCostVnd: raw.totalCostVnd,
      // Averaged over jobs that actually cost something: a failure before the
      // model call costs nothing and would drag the average of "what one lesson
      // costs" towards zero.
      averageCostVnd:
        raw.chargedJobs === 0
          ? 0
          : Math.round(raw.totalCostVnd / raw.chargedJobs),
      totalLessons: raw.totalLessons,
      byStatus,
      bySource: raw.bySource,
      topErrors: raw.topErrors,
    };
  }
}
