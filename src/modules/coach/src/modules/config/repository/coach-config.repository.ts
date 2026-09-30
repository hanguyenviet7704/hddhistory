import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model, UpdateQuery } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { COACH_CONFIG_KEY, CoachConfig } from '../schema/coach-config.schema';

@Injectable()
export class CoachConfigRepository extends AbstractRepository<CoachConfig> {
  protected readonly logger = new Logger(CoachConfigRepository.name);

  constructor(
    @InjectModel(CoachConfig.name) model: Model<CoachConfig>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findDefault() {
    return this.model.findOne({ configKey: COACH_CONFIG_KEY }).lean();
  }

  async upsertDefault(update: UpdateQuery<CoachConfig>) {
    return this.model
      .findOneAndUpdate({ configKey: COACH_CONFIG_KEY }, update, {
        upsert: true,
        new: true,
        setDefaultsOnInsert: true,
      })
      .lean();
  }
}
