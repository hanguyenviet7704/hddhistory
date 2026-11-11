import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CommunityThreadMute } from '../schema/community-thread-mute.schema';

@Injectable()
export class CommunityThreadMuteRepository extends AbstractRepository<CommunityThreadMute> {
  protected readonly logger = new Logger(CommunityThreadMuteRepository.name);

  constructor(
    @InjectModel(CommunityThreadMute.name) model: Model<CommunityThreadMute>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  // Idempotent: tapping the bell off twice is one mute, not two rows.
  async mute(userId: string, postId: string) {
    await this.model.updateOne(
      { userId, postId },
      {
        $setOnInsert: {
          userId,
          postId,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      },
      { upsert: true },
    );
  }

  // Turning the bell back on by hand clears the record — from then on
  // auto-follow is welcome to act for this reader again.
  async unmute(userId: string, postId: string) {
    await this.model.deleteOne({ userId, postId });
  }

  async isMuted(userId: string, postId: string): Promise<boolean> {
    const row = await this.model.exists({ userId, postId });
    return !!row;
  }

  /**
   * Everyone who switched this thread off, ids only.
   *
   * Asked once per new comment and NOT narrowed to the candidate list: a
   * thread's mutes are few, the {postId} index answers it outright, and
   * passing a `$in` of every follower would make the query grow with the
   * thread instead of with the number of people who left it.
   */
  async mutedUserIdsForPost(postId: string): Promise<string[]> {
    const rows = await this.model
      .find({ postId }, { userId: 1, _id: 0 })
      .lean();

    return rows.map((row) => String(row.userId));
  }
}
