import { forwardRef, Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { ConfigurationProvider } from '@base/config/configuration.provider';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { Subscription } from './entities/subscription.entity';
import { SubscriptionRepository } from './repositories/subscription.repository';
import { SubscriptionController } from './subscription.controller';
import { SubscriptionService } from './subscription.service';
import { ProductsModule } from '../products/products.module';
import { PurchasesModule } from '../purchases/purchases.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Subscription]),
    forwardRef(() => PurchasesModule),
    ProductsModule,
    AuthModule,
  ],
  controllers: [SubscriptionController],
  providers: [
    SubscriptionService,
    SubscriptionRepository,
    ConfigurationProvider,
  ],
  exports: [SubscriptionService, SubscriptionRepository],
})
export class SubscriptionsModule {}
