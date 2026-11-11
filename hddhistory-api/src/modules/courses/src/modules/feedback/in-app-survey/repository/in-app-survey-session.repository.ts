import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { InAppSurveySession } from '../schema/in-app-survey-session.schema';

@Injectable()
export class InAppSurveySessionRepository extends AbstractRepository<InAppSurveySession> {
  protected readonly logger = new Logger(InAppSurveySessionRepository.name);

  constructor(
    @InjectModel(InAppSurveySession.name) model: Model<InAppSurveySession>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async completeSession(
    id: string,
    update: Pick<
      InAppSurveySession,
      'completedAt' | 'responseId' | 'branchId' | 'ratingScore'
    >,
  ) {
    return this.model
      .findOneAndUpdate(
        { _id: id },
        {
          $set: {
            ...update,
            updatedAt: new Date(),
          },
        },
        { new: true },
      )
      .lean();
  }
}
