import { forwardRef, Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AnalyticsModule } from 'src/modules/analytics/analytics.module';
import { ProductsModule } from 'src/modules/payment/products/products.module';
import { PurchasesModule } from 'src/modules/payment/purchases/purchases.module';
import { SegmentModule } from 'src/modules/segment/segment.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { PaywallConfig } from './entity/paywall-config.entity';
import { PaywallConfigController } from './paywall-config.controller';
import { PaywallConfigService } from './paywall-config.service';
import { PaywallConfigRepository } from './repository/paywall-config.repository';

@Module({
  // TypeOrmModule.forFeature: registers `paywall_configs`, now the source of
  // truth (see the entity + 1785232800000-AddPaywallConfigsTable migration).
  // ProductsModule: reuse the existing ProductRepository for the
  // product-existence guard (no second data path to iap_products).
  // AuthModule: AuthGuard's own dependencies (JwtUtil, UserRepository, ...)
  // AND exports FirebaseService, which PaywallConfigRepository still injects
  // for the one-time Remote Config cutover seed -- it must NOT be
  // re-provided here, or firebase-admin's `admin.initializeApp()` would run
  // twice and throw.
  // PurchasesModule (forwardRef — it already reaches back into payment
  // siblings): PurchaseRepository for the LogicSale statistics.
  // SegmentModule: per-viewer LogicSale targeting.
  // AnalyticsModule: UserEventRepository for the body-experiment funnel, read
  // from the same user_events the behaviour tab reads.
  imports: [
    TypeOrmModule.forFeature([PaywallConfig]),
    ProductsModule,
    forwardRef(() => PurchasesModule),
    SegmentModule,
    AnalyticsModule,
    AuthModule,
  ],
  controllers: [PaywallConfigController],
  providers: [PaywallConfigService, PaywallConfigRepository],
  exports: [PaywallConfigService],
})
export class PaywallConfigModule {}
