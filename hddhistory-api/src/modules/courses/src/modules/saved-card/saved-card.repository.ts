import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { ITranslation } from '@utils/interface/common.interface';
import { IResponseListPage } from '@utils/interface/paging/page.interface';
import { OrderType } from '@utils/type/orderByType';

import { SavedCard } from './schema/saved-card.schema';

@Injectable()
export class SavedCardRepository extends AbstractRepository<SavedCard> {
  protected readonly logger = new Logger(SavedCardRepository.name);

  constructor(
    @InjectModel(SavedCard.name)
    model: Model<SavedCard>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Idempotent. Neither recap field is written when the caller sends an empty
   * one, so re-saving a card from a surface that does not have the recap to
   * hand cannot blank out a snapshot taken earlier.
   */
  async save(
    userId: string,
    data: {
      keypointId: string;
      lessonId?: string;
      courseId?: string;
      recap?: ITranslation;
      recapText?: string;
    },
  ): Promise<void> {
    const set: Record<string, unknown> = {
      userId,
      keypointId: data.keypointId,
    };
    if (data.lessonId) set.lessonId = data.lessonId;
    if (data.courseId) set.courseId = data.courseId;
    if (data.recap && Object.keys(data.recap).length) set.recap = data.recap;
    if (data.recapText) set.recapText = data.recapText;

    await this.model.findOneAndUpdate(
      { userId, keypointId: data.keypointId },
      { $set: set },
      { upsert: true, new: true },
    );
  }

  async remove(userId: string, keypointId: string): Promise<void> {
    await this.model.deleteOne({ userId, keypointId });
  }

  async findKeypointIds(userId: string): Promise<string[]> {
    const docs = await this.model
      .find({ userId })
      .sort({ createdAt: -1 })
      .select('keypointId')
      .lean();

    return docs.map(doc => doc.keypointId);
  }

  async paginateForUser(
    userId: string,
    page?: number,
    take?: number,
  ): Promise<IResponseListPage<SavedCard>> {
    return this.paginateQuery<SavedCard>({
      where: { userId },
      page,
      take,
      orderBy: 'createdAt',
      order: OrderType.DESC,
    });
  }

  async countForUser(userId: string): Promise<number> {
    return this.model.countDocuments({ userId });
  }
}
