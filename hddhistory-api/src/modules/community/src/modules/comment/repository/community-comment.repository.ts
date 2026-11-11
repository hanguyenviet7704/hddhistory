import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { OrderType } from '@utils/type/orderByType';

import {
  CommunityAuthorType,
  CommunityContentStatus,
} from '../../../enum/community.enum';
import { communityTake } from '../../../helper/community-limit.helper';
import { GetListCommunityCommentDto } from '../dto/get-list-community-comment.dto';
import { CommunityComment } from '../schema/community-comment.schema';

// How many replies are returned inline under one top-level comment. replyCount
// still reports the true total, so the UI can say "xem thêm" honestly.
const MAX_INLINE_REPLIES = 20;

// Marks a comment hidden only because its post was hidden, so restoring the
// post can bring back exactly those and leave individually-moderated comments
// down.
export const CASCADE_HIDDEN_REASON = '__POST_HIDDEN__';

@Injectable()
export class CommunityCommentRepository extends AbstractRepository<CommunityComment> {
  protected readonly logger = new Logger(CommunityCommentRepository.name);

  constructor(
    @InjectModel(CommunityComment.name) model: Model<CommunityComment>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  // Top-level comments only, newest first — the order the design shows.
  async topLevelPage(params: {
    postId: string;
    excludeIds?: string[];
    page?: number;
    take?: number;
  }) {
    const where: FilterQuery<CommunityComment> = {
      postId: params.postId,
      parentId: null,
      status: CommunityContentStatus.VISIBLE,
    };
    if (params.excludeIds?.length) {
      where._id = { $nin: params.excludeIds };
    }

    return this.paginateQuery<CommunityComment>({
      where,
      page: params.page,
      take: communityTake(params.take),
      orderBy: 'createdAt',
      order: OrderType.DESC,
    });
  }

  // Replies for a whole page of parents in one query, oldest first so a thread
  // reads top to bottom.
  async repliesForParents(
    parentIds: string[],
    excludeIds?: string[],
  ): Promise<CommunityComment[]> {
    if (!parentIds.length) return [];
    const where: FilterQuery<CommunityComment> = {
      parentId: { $in: parentIds },
      status: CommunityContentStatus.VISIBLE,
    };
    if (excludeIds?.length) {
      where._id = { $nin: excludeIds };
    }

    return this.model
      .find(where)
      .sort({ createdAt: 1 })
      .limit(parentIds.length * MAX_INLINE_REPLIES)
      .lean() as unknown as CommunityComment[];
  }

  /**
   * Admin moderation table: hidden and deleted comments included, body
   * searchable.
   */
  async adminPage(dto: GetListCommunityCommentDto) {
    const where: FilterQuery<CommunityComment> = {};

    if (dto.status) where.status = dto.status;
    if (dto.postId) where.postId = dto.postId;
    if (dto.authorId) where.authorId = dto.authorId;

    if (dto.search?.trim()) {
      const escaped = dto.search.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      where.body = { $regex: escaped, $options: 'i' };
    }

    return this.paginateQuery<CommunityComment>({
      where,
      page: dto.page,
      take: dto.take,
      orderBy: dto.orderBy || 'createdAt',
      order: dto.order || OrderType.DESC,
    });
  }

  async findVisibleById(id: string): Promise<CommunityComment | null> {
    return this.model
      .findOne({ _id: id, status: CommunityContentStatus.VISIBLE })
      .lean() as unknown as CommunityComment | null;
  }

  // Any status: the moderation queue still shows a comment that was taken down.
  async findAnyByIds(ids: string[]): Promise<CommunityComment[]> {
    if (!ids.length) return [];
    return this.model
      .find({ _id: { $in: ids } })
      .lean() as unknown as CommunityComment[];
  }

  async bumpCounter(
    commentId: string,
    field: 'likeCount' | 'replyCount' | 'reportCount',
    delta: number,
  ) {
    return this.model.updateOne(
      { _id: commentId },
      { $inc: { [field]: delta } },
    );
  }

  async countVisibleForPost(postId: string) {
    return this.model.countDocuments({
      postId,
      status: CommunityContentStatus.VISIBLE,
    });
  }

  /**
   * Everyone who has written a visible comment on a post.
   *
   * The weekly question's answerers, so a new answer can reach the people who
   * already answered — the question itself is posted by the team and has no
   * author to notify.
   */
  async distinctAuthorIdsForPost(postId: string): Promise<string[]> {
    const ids = await this.model.distinct('authorId', {
      postId,
      status: CommunityContentStatus.VISIBLE,
      authorType: CommunityAuthorType.USER,
    });

    return ids.map((id) => String(id)).filter(Boolean);
  }

  /**
   * Used when a post is taken down: its whole thread goes with it.
   *
   * Stamped with [CASCADE_HIDDEN_REASON] so restoring the post can restore
   * exactly these comments — and not the ones a moderator had hidden on their
   * own merits before that.
   */
  async hideAllForPost(postId: string, moderatorId: string) {
    return this.model.updateMany(
      { postId, status: CommunityContentStatus.VISIBLE },
      {
        $set: {
          status: CommunityContentStatus.HIDDEN,
          hiddenReason: CASCADE_HIDDEN_REASON,
          moderatedBy: moderatorId,
          moderatedAt: new Date(),
          updatedAt: new Date(),
        },
      },
    );
  }

  // Mirror of hideAllForPost: only the comments that went down WITH the post.
  async restoreCascadedForPost(postId: string, moderatorId: string) {
    return this.model.updateMany(
      {
        postId,
        status: CommunityContentStatus.HIDDEN,
        hiddenReason: CASCADE_HIDDEN_REASON,
      },
      {
        $set: {
          status: CommunityContentStatus.VISIBLE,
          moderatedBy: moderatorId,
          moderatedAt: new Date(),
          updatedAt: new Date(),
        },
        $unset: { hiddenReason: '' },
      },
    );
  }

  /**
   * What this author has written since [since]: how many rows, and when the
   * oldest of them landed — the two numbers the write ceiling is checked
   * against.
   *
   * Stops counting at [cap]: past the ceiling the exact number is not
   * interesting, only that it was passed. Every status counts, hidden and
   * deleted included, so deleting one is not a way to buy another.
   */
  async recentWritesByAuthor(authorId: string, since: Date, cap: number) {
    const rows = await this.model
      .find({ authorId, createdAt: { $gte: since } })
      .select('createdAt')
      .sort({ createdAt: 1 })
      .limit(cap)
      .lean();

    return {
      count: rows.length,
      oldestAt: rows[0]?.createdAt ?? null,
    };
  }

  /**
   * Whether this author has already written exactly this, word for word, since
   * [since] — the cheap half of spam detection, and the half that catches the
   * same message pasted into a room twenty times.
   */
  async hasRecentBody(authorId: string, since: Date, body: string) {
    const existing = await this.model.exists({
      authorId,
      createdAt: { $gte: since },
      body,
    });

    return !!existing;
  }
}
