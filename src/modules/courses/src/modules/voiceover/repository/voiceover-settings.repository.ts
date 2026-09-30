import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';
import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import {
  VOICEOVER_SETTINGS_KEY,
  VoiceoverSettings,
} from '../schema/voiceover-settings.schema';

@Injectable()
export class VoiceoverSettingsRepository extends AbstractRepository<VoiceoverSettings> {
  protected readonly logger = new Logger(VoiceoverSettingsRepository.name);

  constructor(
    @InjectModel(VoiceoverSettings.name) model: Model<VoiceoverSettings>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Atomically returns the singleton, creating it on first access. Upsert
   * rather than check-then-create so two concurrent first requests cannot both
   * insert past the unique index.
   */
  async findOrCreateDefault(user?: IUserMeta): Promise<VoiceoverSettings> {
    const now = new Date();

    return this.model
      .findOneAndUpdate(
        { configKey: VOICEOVER_SETTINGS_KEY },
        {
          $setOnInsert: {
            configKey: VOICEOVER_SETTINGS_KEY,
            vbeeVoiceCode: '',
            createdAt: now,
            updatedAt: now,
            ...(user ? { createdBy: user, updatedBy: user } : {}),
          },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .lean();
  }

  async upsertSettings(
    patch: Partial<VoiceoverSettings>,
    user?: IUserMeta,
  ): Promise<VoiceoverSettings> {
    const now = new Date();

    return this.model
      .findOneAndUpdate(
        { configKey: VOICEOVER_SETTINGS_KEY },
        {
          $set: {
            ...patch,
            updatedAt: now,
            ...(user ? { updatedBy: user } : {}),
          },
          $setOnInsert: { configKey: VOICEOVER_SETTINGS_KEY, createdAt: now },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true },
      )
      .lean();
  }
}
