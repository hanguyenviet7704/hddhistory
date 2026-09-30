import { forwardRef, Module } from '@nestjs/common';

import { UserProgressModule } from 'src/modules/courses/src/modules/progress/src/modules/user-progress/user-progress.module';
import { SubscriptionsModule } from 'src/modules/payment/subscriptions/subscriptions.module';
import { PaywallConfigModule } from 'src/modules/paywall-config/paywall-config.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { KeypointAccessController } from './keypoint-access.controller';
import { KeypointAccessService } from './keypoint-access.service';
import { KeypointQuotaLedgerModule } from './keypoint-quota-ledger.module';

@Module({
  imports: [
    // AuthGuard's own dependencies resolve in the module whose controllers use it,
    // not where the guard is declared — without this the whole app crash-loops on
    // boot, and neither tsc nor `nest build` can see it.
    forwardRef(() => AuthModule),
    // The quota block lives in paywall_config.
    forwardRef(() => PaywallConfigModule),
    // SubscriptionService, for the server-side premium check.
    forwardRef(() => SubscriptionsModule),
    // Which keypoints this reader finished today. Shared with the progress write
    // that records them; see KeypointQuotaLedgerModule for why it is a leaf.
    KeypointQuotaLedgerModule,
    // `findPassedKeypointIds` — revision is free, so a keypoint finished on an
    // earlier day is never capped and spends nothing.
    forwardRef(() => UserProgressModule),
  ],
  controllers: [KeypointAccessController],
  providers: [KeypointAccessService],
  exports: [KeypointAccessService],
})
export class KeypointAccessModule {}
