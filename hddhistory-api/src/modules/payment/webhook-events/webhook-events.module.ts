import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { ConfigurationProvider } from '@base/config/configuration.provider';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { WebhookEvent } from './entities/webhook-event.entity';
import { WebhookEventRepository } from './repositories/webhook-event.repository';
import { WebhookEventController } from './webhook-event.controller';
import { WebhookEventService } from './webhook-event.service';
import { Product } from '../products/entitys/product.entity';
import { ProductRepository } from '../products/repositories/product.repository';
import { Purchase } from '../purchases/entities/purchase.entity';
import { PurchaseRepository } from '../purchases/repositories/purchase.repository';

@Module({
  imports: [
    TypeOrmModule.forFeature([WebhookEvent, Product, Purchase]),
    AuthModule,
  ],
  controllers: [WebhookEventController],
  providers: [
    WebhookEventService,
    WebhookEventRepository,
    ProductRepository,
    PurchaseRepository,
    ConfigurationProvider,
  ],
  exports: [WebhookEventService, WebhookEventRepository],
})
export class WebhookEventsModule {}
