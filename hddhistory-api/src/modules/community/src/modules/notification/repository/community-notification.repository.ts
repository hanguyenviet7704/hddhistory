import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { OrderType } from '@utils/type/orderByType';

import { CommunityNotificationType } from '../../../enum/community.enum';
import { communityTake } from '../../../helper/community-limit.helper';
import { CommunityNotification } from '../schema/community-notification.schema';

@Injectable()
export class CommunityNotificationRepository extends AbstractRepository<CommunityNotification> {
  protected readonly logger = new Logger(CommunityNotificationRepository.name);

  constructor(
    @InjectModel(CommunityNotification.name) model: Model<CommunityNotification>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async listPage(userId: string, page?: number, take?: number) {
    return this.paginateQuery<CommunityNotification>({
      where: { userId },
      page,
      take: communityTake(take),
      orderBy: 'createdAt',
      order: OrderType.DESC,
    });
  }

  /**
   * One like row per (reader, post), bumped rather than repeated.
   *
   * `actorId` is overwritten with the newest liker so the line reads with a
   * name the reader just saw, and the row goes back to unread and back to the
   * top of the list. Distinctness is by ACTOR, not by call: a reader who
   * unlikes and likes again must not add a second head to the count, so the
   * caller only reaches here when the reaction row was actually created.
   */
  /**
   * Bumps the collapsed "X and N others liked your post" row.
   *
   * Returns the row as it was BEFORE this like (`new: false`), which is what
   * decides whether to push: null means this is the post's first like, and a
   * row that was already read means the author has cleared the last batch and
   * this is news again. Anything else is the second like of a batch they have
   * not looked at yet — the row updates in place and nobody's phone buzzes.
   */
  async upsertLike(params: {
    userId: string;
    postId: string;
    actorId: string;
    /** Which collapsed row — likes by default, weekly answers the other one. */
    type?: CommunityNotificationType;
  }): Promise<CommunityNotification | null> {
    const now = new Date();
    const type = params.type ?? CommunityNotificationType.LIKE_ON_POST;
    return this.model.findOneAndUpdate(
      {
        userId: params.userId,
        postId: params.postId,
        type,
      },
      {
        $set: { actorId: params.actorId, isRead: false, updatedAt: now },
        $inc: { actorCount: 1 },
        $setOnInsert: {
          userId: params.userId,
          postId: params.postId,
          type,
          createdAt: now,
        },
      },
      { upsert: true, new: false, lean: true },
    ) as unknown as CommunityNotification | null;
  }

  async countUnread(userId: string) {
    return this.model.countDocuments({ userId, isRead: false });
  }

  async markRead(userId: string, ids?: string[]) {
    const where = ids?.length
      ? { userId, _id: { $in: ids }, isRead: false }
      : { userId, isRead: false };
    return this.model.updateMany(where, {
      $set: { isRead: true, updatedAt: new Date() },
    });
  }
}
