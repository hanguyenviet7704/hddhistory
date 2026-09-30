import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { ReanchorReasonStatus } from '../enum/reanchor-reason.enum';
import { ReanchorReason } from '../schema/reanchor-reason.schema';

@Injectable()
export class ReanchorReasonRepository extends AbstractRepository<ReanchorReason> {
  protected readonly logger = new Logger(ReanchorReasonRepository.name);

  constructor(
    @InjectModel(ReanchorReason.name) model: Model<ReanchorReason>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findList(filter: {
    courseId?: string;
    status?: ReanchorReasonStatus;
  }) {
    return this.model
      .find({
        ...(filter.status ? { status: filter.status } : {}),
        ...(filter.courseId ? { courseId: filter.courseId } : {}),
      })
      .sort({ order: 1, createdAt: -1 })
      .lean();
  }

  // Every published reason across all courses, for export.
  async findAllPublished() {
    return this.model
      .find({ status: ReanchorReasonStatus.PUBLISHED })
      .sort({ courseId: 1, order: 1 })
      .lean();
  }

  async deleteByCourseId(courseId: string) {
    return this.model.deleteMany({ courseId });
  }

  async insertManyDocs(docs: Partial<ReanchorReason>[]) {
    if (!docs.length) return [];
    return this.model.insertMany(docs);
  }
}
