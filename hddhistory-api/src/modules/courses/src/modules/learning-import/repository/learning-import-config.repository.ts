import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';
import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import {
  LEARNING_IMPORT_CONFIG_KEY,
  LearningImportConfig,
} from '../schema/learning-import-config.schema';

@Injectable()
export class LearningImportConfigRepository extends AbstractRepository<LearningImportConfig> {
  protected readonly logger = new Logger(LearningImportConfigRepository.name);

  constructor(
    @InjectModel(LearningImportConfig.name) model: Model<LearningImportConfig>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * The singleton config, created with defaults on first access.
   *
   * Upsert rather than check-then-create: this is read on the create path of a
   * feature several users can hit at once, and two concurrent first requests
   * must not both insert.
   */
  async findOrCreateDefault(user?: IUserMeta): Promise<LearningImportConfig> {
    const now = new Date();

    return this.model
      .findOneAndUpdate(
        { configKey: LEARNING_IMPORT_CONFIG_KEY },
        {
          $setOnInsert: {
            configKey: LEARNING_IMPORT_CONFIG_KEY,
            enabled: true,
            disabledNote: '',
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
    patch: Partial<LearningImportConfig>,
    user?: IUserMeta,
  ): Promise<LearningImportConfig> {
    const now = new Date();

    return this.model
      .findOneAndUpdate(
        { configKey: LEARNING_IMPORT_CONFIG_KEY },
        {
          $set: {
            ...patch,
            updatedAt: now,
            ...(user ? { updatedBy: user } : {}),
          },
          $setOnInsert: {
            configKey: LEARNING_IMPORT_CONFIG_KEY,
            createdAt: now,
          },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .lean();
  }
}
