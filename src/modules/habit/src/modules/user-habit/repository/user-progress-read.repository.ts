import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { UserProgress } from 'src/modules/courses/src/modules/progress/src/modules/user-progress/schema/user-progress.schema';

/**
 * Read-only access to `user_progress` from the habit feature — used by the
 * Weekly recap summary to count how many lessons the user has passed. Kept as a
 * thin local repository (registering only the UserProgress model) rather than
 * importing the courses/progress module, which carries a heavy dependency graph
 * we don't need here.
 */
@Injectable()
export class UserProgressReadRepository extends AbstractRepository<UserProgress> {
  protected readonly logger = new Logger(UserProgressReadRepository.name);

  constructor(
    @InjectModel(UserProgress.name) model: Model<UserProgress>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /** Number of lessons the user has passed (LessonResult.passed) across all
   * of their courses. */
  async countPassedLessons(userId: string): Promise<number> {
    const result = await this.model.aggregate<{ total: number }>([
      { $match: { userId } },
      { $unwind: '$lessonsResult' },
      { $match: { 'lessonsResult.passed': true } },
      { $count: 'total' },
    ]);
    return result[0]?.total ?? 0;
  }

  /** Lessons the user passed in [from, toExclusive) by `submittedAt` — used by
   * the Weekly recap so "Total lessons" reflects the recapped week, not the
   * user's lifetime. Results with no `submittedAt` (legacy rows) are excluded,
   * which is correct: they aren't part of this week. */
  async countPassedLessonsInRange(
    userId: string,
    from: Date,
    toExclusive: Date,
  ): Promise<number> {
    // Filter BEFORE unwinding: `$elemMatch` (index-assisted via {userId:1})
    // skips whole user_progress docs with no qualifying lesson, then `$filter`
    // + `$size` counts the matching subdocuments per doc without exploding the
    // user's entire lifetime lessonsResult array into a stream first (the old
    // `$unwind`-then-`$match` scaled with total lesson history, not the week).
    const result = await this.model.aggregate<{ total: number }>([
      {
        $match: {
          userId,
          lessonsResult: {
            $elemMatch: {
              passed: true,
              submittedAt: { $gte: from, $lt: toExclusive },
            },
          },
        },
      },
      {
        $group: {
          _id: null,
          total: {
            $sum: {
              $size: {
                $filter: {
                  input: '$lessonsResult',
                  as: 'lr',
                  cond: {
                    $and: [
                      { $eq: ['$$lr.passed', true] },
                      { $gte: ['$$lr.submittedAt', from] },
                      { $lt: ['$$lr.submittedAt', toExclusive] },
                    ],
                  },
                },
              },
            },
          },
        },
      },
    ]);
    return result[0]?.total ?? 0;
  }
}
