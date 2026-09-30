import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model, Types } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { NotificationCampaignStatus } from '../notification.enum';
import {
  NotificationCampaign,
} from '../schema/notification-campaign.schema';

@Injectable()
export class NotificationCampaignRepository extends AbstractRepository<NotificationCampaign> {
  protected readonly logger = new Logger(NotificationCampaignRepository.name);

  constructor(
    @InjectModel(NotificationCampaign.name) model: Model<NotificationCampaign>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findAllNewestFirst() {
    return this.model.find({}).sort({ createdAt: -1 }).limit(200).lean();
  }

  async findById(id: string) {
    if (!Types.ObjectId.isValid(id)) return null;
    return this.model.findById(id).lean();
  }

  /**
   * Takes ONE campaign the worker may work on and stamps a lease in the same
   * atomic update.
   *
   * `findOneAndUpdate` rather than find-then-update on purpose: two pods ticking
   * the same second would both read the same free campaign and both start
   * sending. Mongo applies this update to one document at a time, so exactly one
   * of them walks away with it.
   */
  async claimNext(now: Date, leaseUntil: Date) {
    return this.model
      .findOneAndUpdate(
        {
          status: {
            $in: [
              NotificationCampaignStatus.QUEUED,
              NotificationCampaignStatus.SENDING,
            ],
          },
          // Free, or leased by a worker that has since died.
          $or: [{ leaseUntil: null }, { leaseUntil: { $lte: now } }],
        },
        {
          $set: {
            leaseUntil,
            status: NotificationCampaignStatus.SENDING,
          },
        },
        { new: true, sort: { createdAt: 1 } },
      )
      .lean();
  }

  async releaseLease(id: Types.ObjectId | string) {
    return this.model.updateOne(
      { _id: id },
      { $set: { leaseUntil: null } },
    );
  }

  async patch(
    id: Types.ObjectId | string,
    set: Record<string, unknown>,
    inc?: Record<string, number>,
  ) {
    return this.model.updateOne(
      { _id: id },
      { ...(Object.keys(set).length ? { $set: set } : {}), ...(inc ? { $inc: inc } : {}) },
    );
  }
}
