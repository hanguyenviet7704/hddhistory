import { forwardRef, Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { ConfigurationProvider } from '@base/config/configuration.provider';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { AffiliateOrderController } from './affiliate-order.controller';
import { Purchase } from './entities/purchase.entity';
import { AffiliateKeyGuard } from './guards/affiliate-key.guard';
import { PurchaseController } from './purchase.controller';
import { PurchaseService } from './purchase.service';
import { PurchaseRepository } from './repositories/purchase.repository';
import { Product } from '../products/entitys/product.entity';
import { ProductRepository } from '../products/repositories/product.repository';
import { SubscriptionsModule } from '../subscriptions/subscriptions.module';
import { VouchersModule } from '../vouchers/vouchers.module';
import { WebhookEvent } from '../webhook-events/entities/webhook-event.entity';
import { WebhookEventRepository } from '../webhook-events/repositories/webhook-event.repository';

@Module({
  imports: [
    TypeOrmModule.forFeature([Purchase, Product, WebhookEvent]),
    forwardRef(() => SubscriptionsModule),
    // VouchersModule registers its own Purchase entity/repository directly
    // (see vouchers.module.ts) rather than importing PurchasesModule, so this
    // import stays one-directional -- no forwardRef needed here.
    VouchersModule,
    AuthModule,
  ],
  controllers: [PurchaseController, AffiliateOrderController],
  providers: [
    PurchaseService,
    PurchaseRepository,
    ProductRepository,
    WebhookEventRepository,
    ConfigurationProvider,
    AffiliateKeyGuard,
  ],
  exports: [PurchaseService, PurchaseRepository],
})
export class PurchasesModule {}
