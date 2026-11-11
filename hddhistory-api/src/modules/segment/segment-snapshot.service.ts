import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';

import { SegmentSnapshotRepository } from './repository/segment-snapshot.repository';
import { SegmentRepository } from './repository/segment.repository';
import { SegmentService } from './segment.service';

/**
 * The nightly counter behind the admin's growth chart.
 *
 * Membership is computed live from `users`, so history exists only if someone
 * writes it down as it happens — that someone is this cron. One row per
 * segment per day; a re-run overwrites the same day rather than duplicating.
 *
 * Failures are per-segment and logged, never thrown: one segment with a bad
 * criteria must not cost every other segment its data point for the day.
 */
@Injectable()
export class SegmentSnapshotService {
  private readonly logger = new Logger(SegmentSnapshotService.name);

  constructor(
    private readonly segmentRepository: SegmentRepository,
    private readonly snapshotRepository: SegmentSnapshotRepository,
    private readonly segmentService: SegmentService,
  ) {}

  // 00:15 server time: past midnight so the row's UTC day is unambiguous, and
  // off the hour so it does not pile onto whatever else runs at 00:00.
  @Cron('15 0 * * *')
  async snapshotAll(): Promise<void> {
    const segments = await this.segmentRepository.findAll();
    if (segments.length === 0) return;

    const date = new Date().toISOString().slice(0, 10);
    for (const segment of segments) {
      try {
        const count = await this.segmentService.countMembers(segment.criteria);
        await this.snapshotRepository.record(String(segment._id), date, count);
      } catch (error: any) {
        this.logger.error(
          `Snapshot failed for segment ${segment._id} (${segment.name}): ${error?.message}`,
        );
      }
    }

    this.logger.log(`Snapshotted ${segments.length} segment(s) for ${date}`);
  }
}
