import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model, UpdateQuery } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { HABIT_CONFIG_KEY, HabitConfig } from '../schema/habit-config.schema';

@Injectable()
export class HabitConfigRepository extends AbstractRepository<HabitConfig> {
  protected readonly logger = new Logger(HabitConfigRepository.name);

  constructor(
    @InjectModel(HabitConfig.name) model: Model<HabitConfig>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findDefault() {
    return this.model.findOne({ configKey: HABIT_CONFIG_KEY }).lean();
  }

  async upsertDefault(update: UpdateQuery<HabitConfig>) {
    return this.model
      .findOneAndUpdate({ configKey: HABIT_CONFIG_KEY }, update, {
        upsert: true,
        new: true,
        setDefaultsOnInsert: true,
      })
      .lean();
  }
}
