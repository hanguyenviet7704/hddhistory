import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';
import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import {
  COMMUNITY_BOT_CONFIG_KEY,
  CommunityBotConfig,
} from '../schema/community-bot-config.schema';

@Injectable()
export class CommunityBotConfigRepository extends AbstractRepository<CommunityBotConfig> {
  protected readonly logger = new Logger(CommunityBotConfigRepository.name);

  constructor(
    @InjectModel(CommunityBotConfig.name) model: Model<CommunityBotConfig>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async get(): Promise<CommunityBotConfig | null> {
    return this.model
      .findOne({ configKey: COMMUNITY_BOT_CONFIG_KEY })
      .lean() as unknown as CommunityBotConfig | null;
  }

  async upsert(
    data: Partial<CommunityBotConfig>,
    user?: IUserMeta,
  ): Promise<CommunityBotConfig | null> {
    return this.findOneAndUpdate(
      { configKey: COMMUNITY_BOT_CONFIG_KEY },
      {
        $set: { ...data, updatedAt: new Date(), updatedBy: user },
        $setOnInsert: {
          configKey: COMMUNITY_BOT_CONFIG_KEY,
          createdAt: new Date(),
          createdBy: user,
        },
      },
      { upsert: true, setDefaultsOnInsert: true },
    );
  }
}
