import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model, UpdateQuery } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CoachProfile } from '../schema/coach-profile.schema';

@Injectable()
export class CoachProfileRepository extends AbstractRepository<CoachProfile> {
  protected readonly logger = new Logger(CoachProfileRepository.name);

  constructor(
    @InjectModel(CoachProfile.name) model: Model<CoachProfile>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findByUser(userId: string) {
    return this.model.findOne({ userId }).lean();
  }

  /** Upsert so the first session of a reader's life does not need a create step. */
  async upsertForUser(userId: string, update: UpdateQuery<CoachProfile>) {
    return this.model
      .findOneAndUpdate({ userId }, update, {
        upsert: true,
        new: true,
        setDefaultsOnInsert: true,
      })
      .lean();
  }
}
