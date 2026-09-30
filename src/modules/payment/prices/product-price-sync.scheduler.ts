import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';

import { PriceService } from './price.service';

/**
 * Daily background refresh of `iap_product_prices` (Part 2 of
 * plans/260727-voucher-paywall-config-affiliate/design.md). The manual
 * "Sync now" trigger is `POST /api/v1/payment/products/prices/sync`; this
 * just calls the same service method with no filters (sync every active
 * product on both stores) once a day.
 */
@Injectable()
export class ProductPriceSyncScheduler {
  private readonly logger = new Logger(ProductPriceSyncScheduler.name);

  constructor(private readonly priceService: PriceService) {}

  @Cron(CronExpression.EVERY_DAY_AT_2AM)
  async syncDaily(): Promise<void> {
    try {
      const result = await this.priceService.sync({});
      this.logger.log(
        `Daily price sync -- apple: synced=${result.apple.synced} ` +
          `failed=${result.apple.failed}` +
          (result.apple.skippedReason
            ? ` (${result.apple.skippedReason})`
            : '') +
          `; google: synced=${result.google.synced} ` +
          `failed=${result.google.failed}` +
          (result.google.skippedReason
            ? ` (${result.google.skippedReason})`
            : ''),
      );
    } catch (error: any) {
      // Never let a scheduler tick take anything else down; log and retry on
      // the next run.
      this.logger.error(
        `Daily price sync failed unexpectedly: ${error?.message ?? error}`,
        error?.stack,
      );
    }
  }
}
