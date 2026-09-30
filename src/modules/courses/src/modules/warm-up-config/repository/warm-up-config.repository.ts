import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model, UpdateQuery } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { WARM_UP_CONFIG_KEY, WarmUpConfig } from '../schema/warm-up-config.schema';

@Injectable()
export class WarmUpConfigRepository extends AbstractRepository<WarmUpConfig> {
  protected readonly logger = new Logger(WarmUpConfigRepository.name);

  constructor(
    @InjectModel(WarmUpConfig.name) model: Model<WarmUpConfig>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findDefault() {
    return this.model.findOne({ configKey: WARM_UP_CONFIG_KEY }).lean();
  }

  async upsertDefault(update: UpdateQuery<WarmUpConfig>) {
    return this.model
      .findOneAndUpdate({ configKey: WARM_UP_CONFIG_KEY }, update, {
        upsert: true,
        new: true,
        setDefaultsOnInsert: true,
      })
      .lean();
  }
}
