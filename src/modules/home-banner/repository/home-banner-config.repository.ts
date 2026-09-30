import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';
import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import {
  HOME_BANNER_CONFIG_KEY,
  HomeBannerConfig,
} from '../schema/home-banner-config.schema';

@Injectable()
export class HomeBannerConfigRepository extends AbstractRepository<HomeBannerConfig> {
  protected readonly logger = new Logger(HomeBannerConfigRepository.name);

  constructor(
    @InjectModel(HomeBannerConfig.name) model: Model<HomeBannerConfig>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Atomically returns the singleton config, creating it with defaults on
   * first access. Upsert rather than check-then-create so two concurrent
   * first requests cannot both insert.
   */
  async findOrCreateDefault(user?: IUserMeta): Promise<HomeBannerConfig> {
    const now = new Date();

    return this.model
      .findOneAndUpdate(
        { configKey: HOME_BANNER_CONFIG_KEY },
        {
          $setOnInsert: {
            configKey: HOME_BANNER_CONFIG_KEY,
            enabled: false,
            imageUrl: '',
            linkUrl: '',
            createdAt: now,
            updatedAt: now,
            ...(user ? { createdBy: user, updatedBy: user } : {}),
          },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .lean();
  }

  async upsertConfig(
    patch: Partial<HomeBannerConfig>,
    user?: IUserMeta,
  ): Promise<HomeBannerConfig> {
    const now = new Date();

    return this.model
      .findOneAndUpdate(
        { configKey: HOME_BANNER_CONFIG_KEY },
        {
          $set: {
            ...patch,
            updatedAt: now,
            ...(user ? { updatedBy: user } : {}),
          },
          $setOnInsert: { configKey: HOME_BANNER_CONFIG_KEY, createdAt: now },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .lean();
  }
}
