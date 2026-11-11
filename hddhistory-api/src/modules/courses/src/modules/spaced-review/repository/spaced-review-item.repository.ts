import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { SpacedReviewItem } from '../schema/spaced-review-item.schema';

const DUPLICATE_KEY = 11000;

@Injectable()
export class SpacedReviewItemRepository extends AbstractRepository<SpacedReviewItem> {
  protected readonly logger = new Logger(SpacedReviewItemRepository.name);

  constructor(
    @InjectModel(SpacedReviewItem.name)
    model: Model<SpacedReviewItem>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findKeypointIds(userId: string): Promise<string[]> {
    const ids = await this.model.distinct('keypointId', { userId });

    return ids.map(id => String(id));
  }

  /**
   * Thêm lịch cho các keypoint chưa có. Hai lần mở song song có thể cùng thêm
   * một keypoint — index unique chặn bản thứ hai, và lỗi trùng khoá đó là kết
   * quả đúng chứ không phải sự cố, nên nuốt đi.
   */
  async insertMissing(
    rows: Pick<
      SpacedReviewItem,
      'userId' | 'keypointId' | 'lessonId' | 'courseId' | 'dueAt'
    >[],
  ): Promise<void> {
    if (!rows.length) return;

    try {
      await this.model.insertMany(
        rows.map(row => ({ ...row, step: 0, reviewCount: 0, lapses: 0 })),
        { ordered: false },
      );
    } catch (error: any) {
      const writeErrors: any[] = error?.writeErrors ?? [];
      const onlyDuplicates =
        error?.code === DUPLICATE_KEY ||
        (writeErrors.length > 0 &&
          writeErrors.every(item => (item?.code ?? item?.err?.code) === DUPLICATE_KEY));
      if (!onlyDuplicates) throw error;
    }
  }

  async countDue(userId: string, now: Date): Promise<number> {
    return this.model.countDocuments({ userId, dueAt: { $lte: now } });
  }

  /** Keypoint đến hạn của người này, hạn sớm nhất trước. */
  async findDue(
    userId: string,
    now: Date,
    limit: number,
  ): Promise<SpacedReviewItem[]> {
    return this.model
      .find({ userId, dueAt: { $lte: now } })
      .sort({ dueAt: 1 })
      .limit(limit)
      .lean() as unknown as Promise<SpacedReviewItem[]>;
  }

  async findDueByKeypointIds(
    userId: string,
    keypointIds: string[],
    now: Date,
  ): Promise<SpacedReviewItem[]> {
    if (!keypointIds.length) return [];

    return this.model
      .find({ userId, keypointId: { $in: keypointIds }, dueAt: { $lte: now } })
      .lean() as unknown as Promise<SpacedReviewItem[]>;
  }

  async findNextDueAt(userId: string): Promise<Date | null> {
    const row = await this.model
      .findOne({ userId }, { dueAt: 1, _id: 0 })
      .sort({ dueAt: 1 })
      .lean<{ dueAt?: Date }>();

    return row?.dueAt ?? null;
  }

  async applyReviews(
    userId: string,
    updates: {
      keypointId: string;
      step: number;
      dueAt: Date;
      correct: boolean;
    }[],
    now: Date,
  ): Promise<void> {
    if (!updates.length) return;

    await this.model.bulkWrite(
      updates.map(update => ({
        updateOne: {
          filter: { userId, keypointId: update.keypointId },
          update: {
            $set: {
              step: update.step,
              dueAt: update.dueAt,
              lastReviewedAt: now,
            },
            $inc: { reviewCount: 1, lapses: update.correct ? 0 : 1 },
          },
        },
      })),
      { ordered: false },
    );
  }

  /** Lùi hạn mà không đổi bậc — cho keypoint chưa có câu hỏi ôn. */
  async postpone(
    userId: string,
    keypointIds: string[],
    dueAt: Date,
  ): Promise<void> {
    if (!keypointIds.length) return;

    await this.model.updateMany(
      { userId, keypointId: { $in: keypointIds } },
      { $set: { dueAt } },
    );
  }
}
