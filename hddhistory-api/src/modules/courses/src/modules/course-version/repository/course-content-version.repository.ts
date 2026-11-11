import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CourseContentVersion } from '../schema/course-content-version.schema';

@Injectable()
export class CourseContentVersionRepository extends AbstractRepository<CourseContentVersion> {
  protected readonly logger = new Logger(CourseContentVersionRepository.name);

  constructor(
    @InjectModel(CourseContentVersion.name) model: Model<CourseContentVersion>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /** Newest first — the order the admin version table renders. */
  async findByCourse(courseId: string): Promise<CourseContentVersion[]> {
    return this.model.find({ courseId }).sort({ createdAt: -1 }).lean<
      CourseContentVersion[]
    >();
  }

  async findOneByTag(
    courseId: string,
    tag: string,
  ): Promise<CourseContentVersion | null> {
    return this.model.findOne({ courseId, tag }).lean<CourseContentVersion>();
  }

  /** Course ids that already have at least one tag — used by the backfill. */
  async findTaggedCourseIds(): Promise<string[]> {
    return this.model.distinct('courseId');
  }
}
