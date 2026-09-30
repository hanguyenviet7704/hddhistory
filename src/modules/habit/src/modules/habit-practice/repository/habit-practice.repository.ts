import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { HabitPracticeStatus } from '../enum/habit-practice.enum';
import { HabitPractice } from '../schema/habit-practice.schema';

@Injectable()
export class HabitPracticeRepository extends AbstractRepository<HabitPractice> {
  protected readonly logger = new Logger(HabitPracticeRepository.name);

  constructor(
    @InjectModel(HabitPractice.name) model: Model<HabitPractice>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /** The app's read: published practices for one habit, in author order. */
  async findPublishedForHabit(habitId: string) {
    return this.model
      .find({ habitId, status: HabitPracticeStatus.PUBLISHED })
      .sort({ order: 1, createdAt: 1 })
      .lean();
  }

  /** Admin read: every practice on a habit whatever its status. */
  async findAllForHabit(habitId: string) {
    return this.model
      .find({ habitId })
      .sort({ order: 1, createdAt: 1 })
      .lean();
  }

  async findByHabitIds(habitIds: string[]) {
    if (!habitIds.length) return [];
    return this.model
      .find({
        habitId: { $in: habitIds },
        status: HabitPracticeStatus.PUBLISHED,
      })
      .sort({ order: 1 })
      .lean();
  }

  async deleteById(id: string) {
    return this.model.deleteOne({ _id: id });
  }

  /**
   * Clear every practice pointing at a learning item. Called when that item is
   * deleted — otherwise the habit keeps offering a practice whose content is
   * gone, which surfaces as an empty screen with no error anywhere.
   */
  async deleteByLearningItemId(learningItemId: string) {
    return this.model.deleteMany({ learningItemId });
  }
}
