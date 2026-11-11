import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { KeypointQuotaLedgerService } from './keypoint-quota-ledger.service';
import { KeypointDailyClaimRepository } from './repository/keypoint-daily-claim.repository';
import {
  KeypointDailyClaim,
  KeypointDailyClaimSchema,
} from './schema/keypoint-daily-claim.schema';

/**
 * The daily-ledger collection and nothing else.
 *
 * Imported by BOTH `KeypointAccessModule` (reads it) and `UserProgressModule`
 * (writes it when a keypoint is finished). It therefore has to stay a leaf: it
 * imports no other feature module, so neither side can pull a cycle through it.
 * The quota's RULES — the config block and the premium check — live in
 * `KeypointAccessService`, which already sits next to `PaywallConfigModule` and
 * `SubscriptionsModule`.
 */
@Module({
  imports: [
    MongooseModule.forFeature([
      { name: KeypointDailyClaim.name, schema: KeypointDailyClaimSchema },
    ]),
  ],
  providers: [KeypointQuotaLedgerService, KeypointDailyClaimRepository],
  exports: [KeypointQuotaLedgerService],
})
export class KeypointQuotaLedgerModule {}
