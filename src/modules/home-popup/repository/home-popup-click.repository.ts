import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';
import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { HomePopupClick } from '../schema/home-popup-click.schema';

@Injectable()
export class HomePopupClickRepository extends AbstractRepository<HomePopupClick> {
  protected readonly logger = new Logger(HomePopupClickRepository.name);

  constructor(
    @InjectModel(HomePopupClick.name) model: Model<HomePopupClick>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Records the tap. Idempotent by upsert against the unique (userId,
   * campaignKey) index -- a double tap, or a retry after a dropped response, must
   * not become a duplicate-key error the app has to interpret.
   */
  async markClicked(
    userId: string,
    campaignKey: string,
    user?: IUserMeta,
  ): Promise<void> {
    const now = new Date();

    await this.model.updateOne(
      { userId, campaignKey },
      {
        $setOnInsert: {
          userId,
          campaignKey,
          createdAt: now,
          updatedAt: now,
          ...(user ? { createdBy: user, updatedBy: user } : {}),
        },
      },
      { upsert: true },
    );
  }

  /** Whether this user has already tapped this campaign. One indexed lookup. */
  async hasClicked(userId: string, campaignKey: string): Promise<boolean> {
    const found = await this.model.exists({ userId, campaignKey });

    return Boolean(found);
  }
}
