import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { OrderType } from '@utils/type/orderByType';

import { GetNotificationLogDto } from '../dto/notification-log.dto';
import { NotificationLogStatus, NotificationType } from '../notification.enum';
import { NotificationLog } from '../schema/notification-log.schema';

@Injectable()
export class NotificationLogRepository extends AbstractRepository<NotificationLog> {
  protected readonly logger = new Logger(NotificationLogRepository.name);

  constructor(
    @InjectModel(NotificationLog.name) model: Model<NotificationLog>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Everything recorded for this user between two of their own days, inclusive.
   *
   * One read serves both daily rules and the variant cooldown: today's rows are
   * the "once per type, at most N per day" check, and the earlier rows are the
   * "not the same wording as the last three days" memory. Reading them
   * separately would double the per-user query count on every tick for data the
   * same index (`userId` + `localDate`) already returns in one pass.
   */
  async findByUserAndDateRange(
    userId: string,
    fromDate: string,
    toDate: string,
  ) {
    return this.model
      .find({ userId, localDate: { $gte: fromDate, $lte: toDate } })
      .lean();
  }

  /**
   * Claims the (user, type, day) slot BEFORE sending, relying on the unique
   * index: two workers ticking the same cron minute both try, one gets a
   * duplicate-key error, and only the winner sends. Returns false for the loser.
   *
   * Writing the row first means a crash mid-send costs the user one
   * notification, never a duplicate — the safer way round for something that
   * lands on a lock screen.
   */
  async claimSlot(
    userId: string,
    type: NotificationType,
    localDate: string,
  ): Promise<boolean> {
    try {
      await this.model.create({
        userId,
        type,
        localDate,
        status: NotificationLogStatus.SKIPPED,
        reason: 'claimed',
        sentAt: new Date(),
      });
      return true;
    } catch (error: any) {
      // 11000 = duplicate key: somebody else already claimed this slot.
      if (error?.code === 11000) return false;
      throw error;
    }
  }

  async completeSlot(
    userId: string,
    type: NotificationType,
    localDate: string,
    update: Partial<NotificationLog>,
  ) {
    return this.model.updateOne(
      { userId, type, localDate },
      { $set: { ...update, updatedAt: new Date() } },
    );
  }

  /** Admin monitoring list. */
  async findOption(dto: GetNotificationLogDto) {
    const { page, take, userId, type, status, fromDate, toDate } = dto;
    const where: FilterQuery<NotificationLog> = {};

    if (userId) where.userId = userId;
    if (type) where.type = type;
    if (status) where.status = status;
    if (fromDate || toDate) {
      where.localDate = {};
      if (fromDate) where.localDate.$gte = fromDate;
      if (toDate) where.localDate.$lte = toDate;
    }

    return this.paginateQuery<NotificationLog>({
      where,
      page,
      take,
      orderBy: 'sentAt',
      order: OrderType.DESC,
    });
  }

  /** Per-type totals for the admin dashboard, over a local-date range. */
  async summaryByType(fromDate: string, toDate: string) {
    return this.model.aggregate<{
      _id: { type: string; status: string };
      count: number;
    }>([
      { $match: { localDate: { $gte: fromDate, $lte: toDate } } },
      {
        $group: {
          _id: { type: '$type', status: '$status' },
          count: { $sum: 1 },
        },
      },
    ]);
  }
}
