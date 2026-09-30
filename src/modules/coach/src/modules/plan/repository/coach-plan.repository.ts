import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CoachPlanStatus, CoachReminderDays } from '../enum/plan.enum';
import { CoachPlan } from '../schema/coach-plan.schema';

@Injectable()
export class CoachPlanRepository extends AbstractRepository<CoachPlan> {
  protected readonly logger = new Logger(CoachPlanRepository.name);

  constructor(
    @InjectModel(CoachPlan.name) model: Model<CoachPlan>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * The reader's pending commitments, oldest-asked first.
   *
   * `lastAskedAt: null` sorts ahead of any date in Mongo, which is the order we
   * want without a special case: a plan never asked about outranks one asked
   * last week.
   */
  async findPending(userId: string, limit?: number) {
    const query = this.model
      .find({ userId, status: CoachPlanStatus.PENDING })
      .sort({ lastAskedAt: 1, createdAt: 1 });

    if (limit) query.limit(limit);

    return query.lean();
  }

  async countPending(userId: string): Promise<number> {
    return this.model.countDocuments({
      userId,
      status: CoachPlanStatus.PENDING,
    });
  }

  /**
   * Plans whose reminder is armed for this local hour and minute.
   *
   * Timezone is NOT filtered here — the dispatcher resolves which zones are at
   * this local time first, then passes the resulting user ids in. Keeping the
   * two apart means this query stays on the
   * `(status, reminder.enabled, reminder.hour)` index.
   */
  async findDueReminders(params: {
    userIds: string[];
    hour: number;
    minute: number;
    dayKinds: CoachReminderDays[];
  }) {
    const { userIds, hour, minute, dayKinds } = params;

    if (!userIds.length) return [];

    return this.model
      .find({
        userId: { $in: userIds },
        status: CoachPlanStatus.PENDING,
        'reminder.enabled': true,
        'reminder.hour': hour,
        'reminder.minute': minute,
        'reminder.days': { $in: dayKinds },
      })
      .sort({ createdAt: 1 })
      .lean();
  }

  /** Close every other pending plan for a habit when a newer one supersedes it. */
  async replacePendingForHabit(
    userId: string,
    habitId: string,
    exceptId: string,
  ) {
    return this.model.updateMany(
      {
        userId,
        habitId,
        status: CoachPlanStatus.PENDING,
        _id: { $ne: exceptId },
      },
      { $set: { status: CoachPlanStatus.REPLACED, updatedAt: new Date() } },
    );
  }

  /**
   * The distinct local times that have any armed reminder at all.
   *
   * The dispatcher runs every minute and would otherwise have to ask
   * "which zones are at 00:00? at 00:01? …" 1440 times a tick. Almost every
   * reader picks one of three offered hours, so this collapses the tick to two
   * or three zone reads — and to zero database work on a tick where nobody has
   * a reminder set.
   */
  async distinctArmedReminderTimes(): Promise<
    Array<{ hour: number; minute: number }>
  > {
    return this.model.aggregate<{ hour: number; minute: number }>([
      {
        $match: {
          status: CoachPlanStatus.PENDING,
          'reminder.enabled': true,
        },
      },
      {
        $group: {
          _id: { hour: '$reminder.hour', minute: '$reminder.minute' },
        },
      },
      {
        $project: {
          _id: 0,
          hour: '$_id.hour',
          minute: '$_id.minute',
        },
      },
    ]);
  }

  /** ⑤ "ĐÃ TẬP": how the week's answers were distributed. */
  async findAnsweredBetween(userId: string, from: Date, to: Date) {
    return this.model
      .find({
        userId,
        lastAskedAt: { $gte: from, $lte: to },
        lastAnswer: { $ne: null },
      })
      .lean();
  }
}
