import { Injectable } from '@nestjs/common';

import { Configuration } from '@base/config/configuration';
import { LoggerService } from '@base/logging/logger.service';
import { RequestService } from '@base/service/request.service';

import { GetProductPriceDto } from './dto/get-product-price.dto';
import { SyncProductPriceDto } from './dto/sync-product-price.dto';
import { fetchAppleTerritoryPrices } from './helpers/apple-price.helper';
import { fetchGoogleTerritoryPrices } from './helpers/google-price.helper';
import { IPlatformSyncResult, ISyncPricesResult } from './interfaces/product-price.interface';
import { ProductPriceRepository } from './repositories/product-price.repository';
import { PaymentPlatform, ProductType } from '../enum/payment.enum';
import { Product } from '../products/entitys/product.entity';
import { ProductRepository } from '../products/repositories/product.repository';

@Injectable()
export class PriceService {
  constructor(
    private readonly productPriceRepository: ProductPriceRepository,
    private readonly productRepository: ProductRepository,
    private readonly configService: Configuration,
    private readonly logger: LoggerService,
    private readonly requestService: RequestService,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  findAll(dto: GetProductPriceDto) {
    return this.productPriceRepository.findByFilter(dto);
  }

  /**
   * Syncs both stores independently -- a Google failure (e.g. the
   * monetization permission not being granted yet, see design.md Part 2 risk
   * note) never prevents the Apple rows from being fetched and persisted,
   * and vice versa. Every per-product store call is individually try/caught
   * inside `syncPlatform`, so this method itself never throws.
   */
  async sync(dto: SyncProductPriceDto): Promise<ISyncPricesResult> {
    const result: ISyncPricesResult = {
      apple: { synced: 0, failed: 0 },
      google: { synced: 0, failed: 0 },
    };

    if (!dto.platform || dto.platform === PaymentPlatform.APPLE) {
      await this.syncPlatform(PaymentPlatform.APPLE, dto.productId, result.apple);
    } else {
      result.apple.skippedReason = 'excluded by platform filter';
    }

    if (!dto.platform || dto.platform === PaymentPlatform.GOOGLE) {
      await this.syncPlatform(PaymentPlatform.GOOGLE, dto.productId, result.google);
    } else {
      result.google.skippedReason = 'excluded by platform filter';
    }

    return result;
  }

  private async syncPlatform(
    platform: PaymentPlatform,
    productId: string | undefined,
    result: IPlatformSyncResult,
  ): Promise<void> {
    const products = await this.productRepository.findManyForSync({
      platform,
      productId,
      onlyActive: !productId,
    });

    if (!products.length) {
      result.skippedReason = `no matching ${platform} products`;
      return;
    }

    if (platform === PaymentPlatform.GOOGLE) {
      const packageName = this.configService.getGooglePackageName;
      if (!packageName) {
        result.skippedReason = 'GOOGLE_PACKAGE_NAME is not configured';
        this.logger.warn(
          'Skipping Google price sync: GOOGLE_PACKAGE_NAME not configured',
        );
        return;
      }
      for (const product of products) {
        await this.syncOneGoogleProduct(packageName, product, result);
      }
      return;
    }

    // Same precheck Google gets above. Without it a missing credential
    // surfaces as an opaque per-product failure count, when the real answer
    // ("nobody set the env vars") is something the operator can act on.
    if (
      !this.configService.getAppleAscKeyId ||
      !this.configService.getAppleAscIssuerId ||
      !this.configService.getAppleAscPrivateKey
    ) {
      result.skippedReason =
        'APPLE_ASC_KEY_ID / APPLE_ASC_ISSUER_ID / APPLE_ASC_PRIVATE_KEY are not configured';
      this.logger.warn(
        'Skipping Apple price sync: App Store Connect credentials not configured',
      );
      return;
    }

    for (const product of products) {
      await this.syncOneAppleProduct(product, result);
    }
  }

  private async syncOneAppleProduct(
    product: Product,
    result: IPlatformSyncResult,
  ): Promise<void> {
    // The Apple adapter resolves prices through subscription groups, which only
    // contain auto-renewable subscriptions. One-time IAPs (hddhistory_iap_lifetime,
    // hddhistory_sample_iap) live under a different App Store Connect endpoint, so
    // attempting them here would report a permanent, misleading failure.
    if (product.type !== ProductType.SUBSCRIPTION_AUTO_RENEW) {
      result.skippedProducts = (result.skippedProducts ?? 0) + 1;
      this.logger.log(
        `Skipping Apple price sync for ${product.productId}: ` +
          `type "${product.type}" is not an auto-renewable subscription`,
      );
      return;
    }

    try {
      const rows = await fetchAppleTerritoryPrices(
        product.productId,
        this.configService,
      );
      await this.persistRows(product.productId, PaymentPlatform.APPLE, rows);
      result.synced += rows.length;
    } catch (error: any) {
      result.failed += 1;
      this.logger.error(
        `Apple price sync failed for ${product.productId}: ${
          error?.message ?? error
        }`,
        error?.stack,
      );
    }
  }

  private async syncOneGoogleProduct(
    packageName: string,
    product: Product,
    result: IPlatformSyncResult,
  ): Promise<void> {
    try {
      const rows = await fetchGoogleTerritoryPrices(
        packageName,
        product.productId,
      );
      await this.persistRows(product.productId, PaymentPlatform.GOOGLE, rows);
      result.synced += rows.length;
    } catch (error: any) {
      result.failed += 1;
      this.logger.error(
        `Google price sync failed for ${product.productId}: ${
          error?.message ?? error
        }`,
        error?.stack,
      );
      // Reading *monetization* data needs a Play Console permission distinct
      // from the purchase-verification scope the service account already
      // has (design.md Part 2 risk note) -- a 401/403 here almost certainly
      // means that permission hasn't been granted yet, not a code bug.
      if (this.isAuthError(error)) {
        result.skippedReason =
          'Google monetization API unauthorized -- check Play Console ' +
          'permission (separate from purchase verification)';
      }
    }
  }

  private isAuthError(error: any): boolean {
    const status = error?.response?.status;
    return status === 401 || status === 403;
  }

  private async persistRows(
    productId: string,
    platform: PaymentPlatform,
    rows: { territory: string; currency: string; customerPrice: number }[],
  ): Promise<void> {
    const syncedAt = new Date();
    for (const row of rows) {
      await this.productPriceRepository.upsertRow(
        {
          productId,
          platform,
          territory: row.territory,
          currency: row.currency,
          customerPrice: row.customerPrice,
          source: platform,
          syncedAt,
        },
        this.user?.id,
      );
    }
  }
}
