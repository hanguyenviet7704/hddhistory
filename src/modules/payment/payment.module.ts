import { Module } from '@nestjs/common';

import { MysqlModule } from '@base/database/mysql/mysql.module';

import { PricesModule } from './prices/prices.module';
import { ProductsModule } from './products/products.module';
import { PurchasesModule } from './purchases/purchases.module';
import { SubscriptionsModule } from './subscriptions/subscriptions.module';
import { VouchersModule } from './vouchers/vouchers.module';
import { WebhookEventsModule } from './webhook-events/webhook-events.module';

@Module({
  imports: [
    MysqlModule,
    ProductsModule,
    PurchasesModule,
    SubscriptionsModule,
    VouchersModule,
    WebhookEventsModule,
    PricesModule,
  ],
})
export class PaymentModule {}
