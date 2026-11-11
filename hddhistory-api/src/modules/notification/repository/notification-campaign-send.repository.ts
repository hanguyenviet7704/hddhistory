import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model, Types } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { NotificationLogStatus } from '../notification.enum';
import { NotificationCampaignSend } from '../schema/notification-campaign-send.schema';

@Injectable()
export class NotificationCampaignSendRepository extends AbstractRepository<NotificationCampaignSend> {
  protected readonly logger = new Logger(
    NotificationCampaignSendRepository.name,
  );

  constructor(
    @InjectModel(NotificationCampaignSend.name)
    model: Model<NotificationCampaignSend>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Claims (campaign, user) BEFORE the push goes out, and reports whether this
   * worker won the claim.
   *
   * Claim-first, not log-after: if the row were written after a successful send,
   * a crash between the two would leave no record and the next tick would send
   * again. Writing first can at worst mark someone as reached when the push
   * failed — recorded as FAILED below, visible in the campaign's counters, and
   * never a duplicate notification on a reader's phone.
   *
   * Returns false when the unique index rejects the insert, which is exactly the
   * "already handled" case.
   */
  async claimUser(campaignId: Types.ObjectId, userId: string): Promise<boolean> {
    try {
      await this.model.create({
        campaignId,
        userId,
        status: NotificationLogStatus.SENT,
        deviceCount: 0,
        successCount: 0,
        failureCount: 0,
      });
      return true;
    } catch (error: any) {
      // 11000 = duplicate key: another tick (or pod) already has this user.
      if (error?.code === 11000) return false;
      throw error;
    }
  }

  async finalize(
    campaignId: Types.ObjectId,
    userId: string,
    update: Partial<NotificationCampaignSend>,
  ) {
    return this.model.updateOne({ campaignId, userId }, { $set: update });
  }

  async listForCampaign(campaignId: string, page: number, take: number) {
    if (!Types.ObjectId.isValid(campaignId)) {
      return { items: [], total: 0 };
    }
    const filter = { campaignId: new Types.ObjectId(campaignId) };
    const [items, total] = await Promise.all([
      this.model
        .find(filter)
        .sort({ sentAt: -1 })
        .skip((page - 1) * take)
        .limit(take)
        .lean(),
      this.model.countDocuments(filter),
    ]);
    return { items, total };
  }
}
