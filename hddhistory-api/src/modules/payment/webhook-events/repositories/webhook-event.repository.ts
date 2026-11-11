import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { FindOptionsWhere, Repository } from 'typeorm';

import { AbstractRepository } from '@base/database/mysql/abstract.repository';

import { GetListWebhookEventDto } from '../dto/get-webhook-event.dto';
import { WebhookEvent } from '../entities/webhook-event.entity';

@Injectable()
export class WebhookEventRepository extends AbstractRepository<WebhookEvent> {
  constructor(
    @InjectRepository(WebhookEvent) repository: Repository<WebhookEvent>,
  ) {
    super(repository);
  }

  async findOption(dto: GetListWebhookEventDto) {
    const { page, take, orderBy, order } = dto;

    return this.paginateQuery<WebhookEvent>({
      where: {} as FindOptionsWhere<WebhookEvent>,
      page,
      take,
      orderBy,
      order,
    });
  }

  async findByPurchaseId(purchaseId: string) {
    return this.repository.find({
      where: { purchaseId },
      order: { createdAt: 'DESC' },
      select: [
        'id',
        'platform',
        'environment',
        'eventType',
        'processed',
        'processedAt',
        'error',
        'createdAt',
        'updatedAt',
        'purchaseId',
      ],
    });
  }
}
