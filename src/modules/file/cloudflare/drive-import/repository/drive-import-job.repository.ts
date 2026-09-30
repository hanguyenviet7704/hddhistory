import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model, UpdateQuery } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { DriveImportJobStatus } from '../enum/drive-import-job-status.enum';
import { DriveImportJob } from '../schema/drive-import-job.schema';

const ACTIVE_STATUSES = [
  DriveImportJobStatus.QUEUED,
  DriveImportJobStatus.PROCESSING,
];

@Injectable()
export class DriveImportJobRepository extends AbstractRepository<DriveImportJob> {
  protected readonly logger = new Logger(DriveImportJobRepository.name);

  constructor(
    @InjectModel(DriveImportJob.name) model: Model<DriveImportJob>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findActiveByUser(createdBy: string) {
    return this.model
      .findOne({
        createdBy,
        status: { $in: ACTIVE_STATUSES },
      })
      .sort({ createdAt: -1 })
      .lean()
      .exec();
  }

  async findByUser(createdBy: string, limit = 20) {
    return this.model
      .find({ createdBy })
      .sort({ createdAt: -1 })
      .limit(limit)
      .lean()
      .exec();
  }

  async findOwnedJob(jobId: string, createdBy: string) {
    return this.model.findOne({ _id: jobId, createdBy }).lean().exec();
  }

  async updateJob(jobId: string, data: UpdateQuery<DriveImportJob>) {
    return this.model
      .findByIdAndUpdate(
        jobId,
        { ...data, updatedAt: new Date() },
        { new: true, lean: true },
      )
      .exec();
  }

  async markCancelled(jobId: string, createdBy: string) {
    return this.model
      .findOneAndUpdate(
        {
          _id: jobId,
          createdBy,
          status: { $in: ACTIVE_STATUSES },
        },
        {
          status: DriveImportJobStatus.CANCELLED,
          cancelledAt: new Date(),
          updatedAt: new Date(),
        },
        { new: true, lean: true },
      )
      .exec();
  }
}
