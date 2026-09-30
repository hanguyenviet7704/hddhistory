import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { UserStreak } from '../schema/user-streak.schema';

@Injectable()
export class UserStreakRepository extends AbstractRepository<UserStreak> {
  protected readonly logger = new Logger(UserStreakRepository.name);

  constructor(
    @InjectModel(UserStreak.name) model: Model<UserStreak>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }
}
