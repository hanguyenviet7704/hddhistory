import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CommunityTargetType } from '../../../enum/community.enum';
import { CommunityHiddenItem } from '../schema/community-hidden-item.schema';

@Injectable()
export class CommunityHiddenItemRepository extends AbstractRepository<CommunityHiddenItem> {
  protected readonly logger = new Logger(CommunityHiddenItemRepository.name);

  constructor(
    @InjectModel(CommunityHiddenItem.name) model: Model<CommunityHiddenItem>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async hide(
    userId: string,
    targetType: CommunityTargetType,
    targetId: string,
  ) {
    return this.model.updateOne(
      { userId, targetType, targetId },
      {
        $setOnInsert: {
          userId,
          targetType,
          targetId,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      },
      { upsert: true },
    );
  }

  async hiddenIds(
    userId: string,
    targetType: CommunityTargetType,
  ): Promise<string[]> {
    const rows = await this.model
      .find({ userId, targetType }, { targetId: 1, _id: 0 })
      .lean();
    return rows.map((row) => String(row.targetId));
  }
}
