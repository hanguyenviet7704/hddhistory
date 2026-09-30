import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';

import { CommunityTopicService } from '../modules/topic/community-topic.service';

@Injectable()
export class CommunityTopicStatsScheduler {
  private readonly logger = new Logger(CommunityTopicStatsScheduler.name);

  constructor(private readonly topicService: CommunityTopicService) {}

  /**
   * Zero every topic's "N bài tuần này" counter at the week boundary.
   *
   * The counter is maintained by $inc on each post rather than counted live, so
   * something has to reset it. Monday 00:00 UTC matches startOfWeekUtc(), which
   * is what decides whether deleting a post decrements the counter — the two
   * have to agree or the number drifts.
   */
  @Cron('0 0 * * 1', { name: 'community-weekly-post-counts' })
  async resetWeeklyPostCounts() {
    const result = await this.topicService.resetWeeklyPostCounts();
    this.logger.log(
      `Reset weekly community post counts on ${result.modifiedCount} topics`,
    );
  }
}
