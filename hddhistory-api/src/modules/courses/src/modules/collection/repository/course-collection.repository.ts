import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model, Types } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { GetListCourseCollectionDto } from '../dto/course-collection.dto';
import {
  CourseCollectionSlot,
  CourseCollectionStatus,
} from '../enum/course-collection.enum';
import { CourseCollection } from '../schema/course-collection.schema';

@Injectable()
export class CourseCollectionRepository extends AbstractRepository<CourseCollection> {
  protected readonly logger = new Logger(CourseCollectionRepository.name);

  constructor(
    @InjectModel(CourseCollection.name) model: Model<CourseCollection>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /** Admin list: every collection, ordered the way the page renders them. */
  async findAllOrdered(dto: GetListCourseCollectionDto) {
    const where: FilterQuery<CourseCollection> = {};
    if (dto.status) where.status = dto.status;
    if (dto.slot) where.slot = dto.slot;

    return this.model.find(where).sort({ slot: 1, index: 1 }).lean().exec();
  }

  /** The Explore read: published rows only, in slot then editor order. */
  async findPublishedOrdered() {
    return this.model
      .find({ status: CourseCollectionStatus.PUBLISHED })
      .sort({ index: 1 })
      .lean()
      .exec();
  }

  async getNextIndex(slot: CourseCollectionSlot) {
    const last = await this.model
      .findOne({ slot }, { index: 1 })
      .sort({ index: -1 })
      .lean()
      .exec();

    return (last?.index ?? -1) + 1;
  }

  /**
   * Writes a whole slot's order in one round trip. Ids not found are skipped
   * rather than failing the batch: a row deleted in another tab must not block
   * the editor from saving the order of the rows that are still there.
   */
  async applyOrder(ids: string[]) {
    const ops = ids
      .filter(id => Types.ObjectId.isValid(id))
      .map((id, index) => ({
        updateOne: {
          filter: { _id: new Types.ObjectId(id) },
          update: { $set: { index } },
        },
      }));

    if (!ops.length) return;
    await this.model.bulkWrite(ops);
  }
}
