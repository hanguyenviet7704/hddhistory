import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { OrderType } from '@utils/type/orderByType';

import {
  CommunityReactionKind,
  CommunityTargetType,
} from '../../../enum/community.enum';
import { communityTake } from '../../../helper/community-limit.helper';
import { CommunityReaction } from '../schema/community-reaction.schema';

@Injectable()
export class CommunityReactionRepository extends AbstractRepository<CommunityReaction> {
  protected readonly logger = new Logger(CommunityReactionRepository.name);

  constructor(
    @InjectModel(CommunityReaction.name) model: Model<CommunityReaction>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  // Returns true when this call created the reaction, false when it already
  // existed. The caller uses that to decide whether to move the counter, so a
  // double tap cannot inflate it.
  async add(params: {
    targetType: CommunityTargetType;
    targetId: string;
    userId: string;
    kind: CommunityReactionKind;
  }): Promise<boolean> {
    const result = await this.model.updateOne(
      params,
      { $setOnInsert: { ...params, createdAt: new Date(), updatedAt: new Date() } },
      { upsert: true },
    );
    return !!result.upsertedCount;
  }

  // Mirrors add(): true when a row was actually removed.
  async remove(params: {
    targetType: CommunityTargetType;
    targetId: string;
    userId: string;
    kind: CommunityReactionKind;
  }): Promise<boolean> {
    const result = await this.model.deleteOne(params);
    return !!result.deletedCount;
  }

  // "Which of these did I react to?" for one page of the feed — one query,
  // ids only.
  async targetIdsFor(params: {
    userId: string;
    kind: CommunityReactionKind;
    targetType: CommunityTargetType;
    targetIds: string[];
  }): Promise<Set<string>> {
    if (!params.targetIds.length) return new Set();
    const rows = await this.model
      .find(
        {
          userId: params.userId,
          kind: params.kind,
          targetType: params.targetType,
          targetId: { $in: params.targetIds },
        },
        { targetId: 1, _id: 0 },
      )
      .lean();
    return new Set(rows.map((row) => String(row.targetId)));
  }

  /**
   * Every post this reader follows, ids only.
   *
   * Feeds the "Đang theo dõi" tab, which filters the posts collection by these
   * ids rather than paging the reactions and looking each post up: the tab is
   * an ordinary feed, so it has to sort and page by the POST's own dates.
   */
  async followedPostIds(userId: string): Promise<string[]> {
    const rows = await this.model
      .find(
        {
          userId,
          kind: CommunityReactionKind.SAVE,
          targetType: CommunityTargetType.POST,
        },
        { targetId: 1, _id: 0 },
      )
      .lean();
    return rows.map((row) => String(row.targetId));
  }

  /**
   * Who follows this thread, minus one person — the author, who is told about
   * a new comment by COMMENT_ON_POST and must not get both.
   */
  async followerIdsOfPost(
    postId: string,
    excludeUserIds: string[] = [],
  ): Promise<string[]> {
    const rows = await this.model
      .find(
        {
          targetType: CommunityTargetType.POST,
          targetId: postId,
          kind: CommunityReactionKind.SAVE,
          userId: { $nin: excludeUserIds.filter(Boolean) },
        },
        { userId: 1, _id: 0 },
      )
      .lean();
    return [...new Set(rows.map((row) => String(row.userId)))];
  }

  async savedPostsPage(userId: string, page?: number, take?: number) {
    return this.paginateQuery<CommunityReaction>({
      where: {
        userId,
        kind: CommunityReactionKind.SAVE,
        targetType: CommunityTargetType.POST,
      },
      page,
      take: communityTake(take),
      orderBy: 'createdAt',
      order: OrderType.DESC,
    });
  }
}
