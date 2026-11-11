import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';
import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import {
  DEFAULT_AUTO_HIDE_SECONDS,
  DEFAULT_TRIGGER_AFTER_SECONDS,
  STREAK_CONFIG_KEY,
  StreakConfig,
} from '../schema/streak-config.schema';

@Injectable()
export class StreakConfigRepository extends AbstractRepository<StreakConfig> {
  protected readonly logger = new Logger(StreakConfigRepository.name);

  constructor(
    @InjectModel(StreakConfig.name) model: Model<StreakConfig>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Atomically returns the singleton config, creating it with defaults on
   * first access. Upsert rather than check-then-create so two concurrent
   * first requests cannot both insert.
   */
  async findOrCreateDefault(user?: IUserMeta): Promise<StreakConfig> {
    const now = new Date();

    return this.model
      .findOneAndUpdate(
        { configKey: STREAK_CONFIG_KEY },
        {
          $setOnInsert: {
            configKey: STREAK_CONFIG_KEY,
            popupEnabled: true,
            triggerAfterSeconds: DEFAULT_TRIGGER_AFTER_SECONDS,
            autoHideSeconds: DEFAULT_AUTO_HIDE_SECONDS,
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
    patch: Partial<StreakConfig>,
    user?: IUserMeta,
  ): Promise<StreakConfig> {
    const now = new Date();

    return this.model
      .findOneAndUpdate(
        { configKey: STREAK_CONFIG_KEY },
        {
          $set: {
            ...patch,
            updatedAt: now,
            ...(user ? { updatedBy: user } : {}),
          },
          $setOnInsert: { configKey: STREAK_CONFIG_KEY, createdAt: now },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .lean();
  }
}
