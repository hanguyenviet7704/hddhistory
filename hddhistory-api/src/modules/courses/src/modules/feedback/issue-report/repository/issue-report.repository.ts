import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { IssueReport } from '../schema/issue-report.schema';

@Injectable()
export class IssueReportRepository extends AbstractRepository<IssueReport> {
  protected readonly logger = new Logger(IssueReportRepository.name);

  constructor(
    @InjectModel(IssueReport.name) model: Model<IssueReport>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }
}
