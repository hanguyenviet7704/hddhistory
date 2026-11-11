import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model, UpdateQuery } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CourseImportJob } from '../schema/course-import-job.schema';

@Injectable()
export class CourseImportJobRepository extends AbstractRepository<CourseImportJob> {
  protected readonly logger = new Logger(CourseImportJobRepository.name);

  constructor(
    @InjectModel(CourseImportJob.name) model: Model<CourseImportJob>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findOwnedJob(jobId: string, createdBy: string) {
    return this.model.findOne({ _id: jobId, createdBy }).lean().exec();
  }

  async updateJob(jobId: string, data: UpdateQuery<CourseImportJob>) {
    return this.model
      .findByIdAndUpdate(
        jobId,
        { ...data, updatedAt: new Date() },
        { new: true, lean: true },
      )
      .exec();
  }
}
