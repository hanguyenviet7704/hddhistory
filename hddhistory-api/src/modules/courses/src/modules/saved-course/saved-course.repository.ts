import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { SavedCourse } from './schema/saved-course.schema';

@Injectable()
export class SavedCourseRepository extends AbstractRepository<SavedCourse> {
  protected readonly logger = new Logger(SavedCourseRepository.name);

  constructor(
    @InjectModel(SavedCourse.name)
    model: Model<SavedCourse>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /** Idempotent: saving an already-saved course only bumps its position. */
  async save(userId: string, courseId: string): Promise<void> {
    await this.model.findOneAndUpdate(
      { userId, courseId },
      { $set: { userId, courseId, updatedAt: new Date() } },
      { upsert: true, new: true },
    );
  }

  async remove(userId: string, courseId: string): Promise<void> {
    await this.model.deleteOne({ userId, courseId });
  }

  /** Saved course ids, most-recently-saved first. */
  async findCourseIds(userId: string): Promise<string[]> {
    const docs = await this.model
      .find({ userId })
      .sort({ updatedAt: -1 })
      .select('courseId')
      .lean();

    return docs.map(doc => doc.courseId);
  }

  async countForUser(userId: string): Promise<number> {
    return this.model.countDocuments({ userId });
  }
}
