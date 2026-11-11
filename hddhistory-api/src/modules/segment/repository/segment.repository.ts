import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { Segment } from '../schema/segment.schema';

@Injectable()
export class SegmentRepository extends AbstractRepository<Segment> {
  protected readonly logger = new Logger(SegmentRepository.name);

  constructor(
    @InjectModel(Segment.name) model: Model<Segment>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /** Every segment, newest first. The roster is small — no pagination. */
  async findAll(): Promise<Segment[]> {
    return this.model.find().sort({ createdAt: -1 }).lean<Segment[]>();
  }

  /** The segments of `ids`, unordered; unknown ids are simply absent. */
  async findByIds(ids: string[]): Promise<Segment[]> {
    if (ids.length === 0) return [];

    return this.model.find({ _id: { $in: ids } }).lean<Segment[]>();
  }
}
