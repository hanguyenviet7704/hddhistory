import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { OrderType } from '@utils/type/orderByType';

import { GetListOutputPracticeMessageDto } from '../dto/get-list-output-practice-message.dto';
import { OutputPracticeMessage } from '../schema/output-practice-message.schema';

@Injectable()
export class OutputPracticeMessageRepository extends AbstractRepository<OutputPracticeMessage> {
  protected readonly logger = new Logger(OutputPracticeMessageRepository.name);

  constructor(
    @InjectModel(OutputPracticeMessage.name)
    model: Model<OutputPracticeMessage>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findOption(dto: GetListOutputPracticeMessageDto) {
    const { page, take, conversationId, seq } = dto;
    const where: FilterQuery<OutputPracticeMessage> = { conversationId };

    if (typeof seq === 'number') {
      where.seq = { $lt: seq };
    }

    return this.paginateQuery<OutputPracticeMessage>({
      where,
      page,
      take,
      orderBy: 'seq',
      order: OrderType.DESC,
    });
  }

  async deleteManyByConversationIds(conversationIds: string[]) {
    if (!conversationIds.length) {
      return;
    }

    await this.model.deleteMany({
      conversationId: { $in: conversationIds },
    });
  }
}
