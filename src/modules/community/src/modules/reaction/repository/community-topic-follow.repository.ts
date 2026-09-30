import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CommunityTopicFollow } from '../schema/community-topic-follow.schema';

@Injectable()
export class CommunityTopicFollowRepository extends AbstractRepository<CommunityTopicFollow> {
  protected readonly logger = new Logger(CommunityTopicFollowRepository.name);

  constructor(
    @InjectModel(CommunityTopicFollow.name) model: Model<CommunityTopicFollow>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  // True when the follow was newly created, so the follower counter only moves
  // on a real change.
  async follow(topicId: string, userId: string, locale: string) {
    const result = await this.model.updateOne(
      { topicId, userId },
      {
        $setOnInsert: {
          topicId,
          userId,
          locale,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      },
      { upsert: true },
    );
    return !!result.upsertedCount;
  }

  async unfollow(topicId: string, userId: string) {
    const result = await this.model.deleteOne({ topicId, userId });
    return !!result.deletedCount;
  }

  async followedTopicIds(userId: string): Promise<string[]> {
    const rows = await this.model
      .find({ userId }, { topicId: 1, _id: 0 })
      .lean();
    return rows.map((row) => String(row.topicId));
  }
}
