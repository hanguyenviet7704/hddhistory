import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { UserProgressExport } from '../schema/user-progress-export.schema';

@Injectable()
export class UserProgressExportRepository extends AbstractRepository<UserProgressExport> {
  protected readonly logger = new Logger(UserProgressExportRepository.name);
  constructor(
    @InjectModel(UserProgressExport.name)
    model: Model<UserProgressExport>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }
}
