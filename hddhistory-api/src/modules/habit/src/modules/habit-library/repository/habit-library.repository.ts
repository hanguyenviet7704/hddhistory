import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { HabitLibraryStatus } from '../enum/habit-library.enum';
import { HabitLibrary } from '../schema/habit-library.schema';

@Injectable()
export class HabitLibraryRepository extends AbstractRepository<HabitLibrary> {
  protected readonly logger = new Logger(HabitLibraryRepository.name);

  constructor(
    @InjectModel(HabitLibrary.name) model: Model<HabitLibrary>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findPublished(categoryId?: string, keypointId?: string) {
    return this.model
      .find({
        status: HabitLibraryStatus.PUBLISHED,
        ...(categoryId ? { categoryId } : {}),
        ...(keypointId ? { keypointIds: keypointId } : {}),
      })
      .sort({ order: 1 })
      .lean();
  }

  async findList(filter: {
    categoryId?: string;
    keypointId?: string;
    /**
     * Any-of match. An empty array means "a course was asked for and it owns
     * no keypoints", which must return nothing — not everything — so the
     * caller passes it through rather than treating it as absent.
     */
    keypointIds?: string[];
    status?: HabitLibraryStatus;
  }) {
    return this.model
      .find({
        ...(filter.status ? { status: filter.status } : {}),
        ...(filter.categoryId ? { categoryId: filter.categoryId } : {}),
        ...(filter.keypointId ? { keypointIds: filter.keypointId } : {}),
        ...(filter.keypointIds
          ? { keypointIds: { $in: filter.keypointIds } }
          : {}),
      })
      .sort({ order: 1, createdAt: -1 })
      .lean();
  }

  async findByIds(ids: string[]) {
    if (!ids.length) return [];
    return this.model.find({ _id: { $in: ids } }).lean();
  }

  // Every published habit across all keypoints, for export.
  async findAllPublished() {
    return this.model
      .find({ status: HabitLibraryStatus.PUBLISHED })
      .sort({ order: 1 })
      .lean();
  }

  async deleteById(id: string) {
    return this.model.deleteOne({ _id: id });
  }

  // Remove a single keypoint from a habit shared across keypoints (so we never
  // orphan a habit still referenced by other keypoints during a replace).
  async pullKeypoint(id: string, keypointId: string) {
    return this.model.updateOne(
      { _id: id },
      { $pull: { keypointIds: keypointId } },
    );
  }

  async insertManyDocs(docs: Partial<HabitLibrary>[]) {
    if (!docs.length) return [];
    return this.model.insertMany(docs);
  }
}
