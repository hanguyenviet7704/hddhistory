import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { OrderType } from '@utils/type/orderByType';

import { GetListOutputPracticeConversationDto } from '../dto/get-list-output-practice-conversation.dto';
import { OutputPracticeConversation } from '../schema/output-practice-conversation.schema';

@Injectable()
export class OutputPracticeConversationRepository extends AbstractRepository<OutputPracticeConversation> {
  protected readonly logger = new Logger(OutputPracticeConversationRepository.name);

  constructor(
    @InjectModel(OutputPracticeConversation.name)
    model: Model<OutputPracticeConversation>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findOption(
    dto: GetListOutputPracticeConversationDto,
    userId: string,
  ) {
    const { page, take, sectionId, threadId } = dto;
    const where: FilterQuery<OutputPracticeConversation> = { userId };

    if (sectionId) {
      where.sectionId = sectionId;
    }

    if (threadId) {
      where.threadId = threadId;
    }

    return this.paginateQuery<OutputPracticeConversation>({
      where,
      page,
      take,
      orderBy: 'createdAt',
      order: OrderType.DESC,
    });
  }

  async incrementLastSeq(conversationId: string, userId: string) {
    const updated = await this.model
      .findOneAndUpdate(
        { _id: conversationId, userId },
        { $inc: { lastSeq: 1 } },
        {
          new: true,
          projection: { lastSeq: 1 },
        },
      )
      .lean();

    return updated?.lastSeq;
  }

  async findLatestBySectionId(sectionId: string, userId: string) {
    return this.model
      .findOne({ sectionId, userId })
      .sort({ createdAt: -1 })
      .exec();
  }

  async findStaleConversationIds(
    sectionId: string,
    userId: string,
    keepConversationId: string,
  ) {
    const conversations = await this.model
      .find(
        {
          sectionId,
          userId,
          _id: { $ne: keepConversationId },
        },
        { _id: 1 },
        { lean: true },
      )
      .exec();

    return conversations.map(conversation => conversation._id.toString());
  }

  async deleteManyByIds(ids: string[], userId: string) {
    if (!ids.length) {
      return;
    }

    await this.model.deleteMany({
      _id: { $in: ids },
      userId,
    });
  }
}
