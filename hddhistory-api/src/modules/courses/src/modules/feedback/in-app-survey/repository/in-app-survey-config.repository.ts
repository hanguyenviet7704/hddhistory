import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model, UpdateQuery } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import {
  IN_APP_SURVEY_CONFIG_KEY,
  InAppSurveyConfig,
} from '../schema/in-app-survey-config.schema';

@Injectable()
export class InAppSurveyConfigRepository extends AbstractRepository<InAppSurveyConfig> {
  protected readonly logger = new Logger(InAppSurveyConfigRepository.name);

  constructor(
    @InjectModel(InAppSurveyConfig.name) model: Model<InAppSurveyConfig>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findDefault() {
    return this.model
      .findOne({ configKey: IN_APP_SURVEY_CONFIG_KEY })
      .lean();
  }

  async upsertDefault(update: UpdateQuery<InAppSurveyConfig>) {
    return this.model
      .findOneAndUpdate(
        { configKey: IN_APP_SURVEY_CONFIG_KEY },
        update,
        {
          upsert: true,
          new: true,
          setDefaultsOnInsert: true,
        },
      )
      .lean();
  }
}
