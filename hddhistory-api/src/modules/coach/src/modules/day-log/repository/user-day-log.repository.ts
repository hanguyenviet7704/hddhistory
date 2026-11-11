import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { DayLogMoment } from '../enum/day-log.enum';
import { UserDayLog } from '../schema/user-day-log.schema';

@Injectable()
export class UserDayLogRepository extends AbstractRepository<UserDayLog> {
  protected readonly logger = new Logger(UserDayLogRepository.name);

  constructor(
    @InjectModel(UserDayLog.name) model: Model<UserDayLog>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Has the start-of-day mood already been asked today?
   *
   * A row with a null mood does not count: ⑥ writes a note-only row at
   * `START`, and someone who jotted a line has not answered the mood question.
   */
  async hasStartMoodOn(userId: string, date: Date): Promise<boolean> {
    const existing = await this.model.exists({
      userId,
      date,
      moment: DayLogMoment.START,
      mood: { $ne: null },
    });

    return Boolean(existing);
  }

  /** Every log in a date range, for the weekly recap's day strip. */
  async findBetween(userId: string, from: Date, to: Date) {
    return this.model
      .find({ userId, date: { $gte: from, $lte: to } })
      .sort({ date: 1 })
      .lean();
  }
}
