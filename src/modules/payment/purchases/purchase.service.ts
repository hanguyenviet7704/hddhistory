import {
  BadRequestException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';
import { DataSource } from 'typeorm';

import { Configuration } from '@base/config/configuration';
import { LoggerService } from '@base/logging/logger.service';
import { RequestService } from '@base/service/request.service';
import { UserRepository } from 'src/modules/user/src/modules/auth/repository/user.repository';

import {
  ProductType,
  PurchaseEventType,
  PurchaseHistorySource,
  PurchaseStatus,
} from '../enum/payment.enum';
import {
  getEnvironment,
  preferHigherStatus,
  resolveSubscriptionStatus,
} from '../helpers/common';
import { buildPriceSnapshot } from '../helpers/store-utils';
import { AffiliateOrderRequestDto } from './dto/affiliate-order-request.dto';
import { AffiliateOrderResponse } from './dto/affiliate-order.response';
import { GetListPurchaseDto } from './dto/get-purchase.dto';
import { GetRevenueListDto } from './dto/get-revenue-list.dto';
import { RevenueStatisticsResponse } from './dto/revenue-statistics.response';
import { UpdatePurchaseStatusDto } from './dto/update-purchase-status.dto';
import { VerifyPurchaseDto } from './dto/verify-purchase.dto';
import { Purchase } from './entities/purchase.entity';
import { mapPurchaseToAffiliateOrder } from './purchase-affiliate.mapper';
import { verifyWithStore, VerifiedPurchaseResult } from './purchase.helper';
import { PurchaseRepository } from './repositories/purchase.repository';
import { ProductRepository } from '../products/repositories/product.repository';
import { Subscription } from '../subscriptions/entities/subscription.entity';
import { CodeAttribution } from '../vouchers/entitys/code-attribution.entity';
import { IVoucherValidateResult } from '../vouchers/interfaces/voucher.interface';
import { CodeAttributionRepository } from '../vouchers/repositories/code-attribution.repository';
import { VoucherService } from '../vouchers/voucher.service';
import { WebhookEventRepository } from '../webhook-events/repositories/webhook-event.repository';

/** Width of `iap_purchases.entered_code`. */
const ENTERED_CODE_MAX_LENGTH = 64;

@Injectable()
export class PurchaseService {
  constructor(
    private readonly purchaseRepository: PurchaseRepository,
    private readonly productRepository: ProductRepository,
    private readonly dataSource: DataSource,
    private readonly logger: LoggerService,
    private readonly requestService: RequestService,
    private readonly configService: Configuration,
    private readonly userRepository: UserRepository,
    private readonly webhookEventRepository: WebhookEventRepository,
    private readonly voucherService: VoucherService,
    private readonly codeAttributionRepository: CodeAttributionRepository,
    private readonly i18n: I18nService,
  ) {}

  private get user() {
    return this.requestService.user;
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  /**
   * Resolves display name/email (from the JWT if present, else Mongo) plus
   * country/language (Task 4: always snapshotted from Mongo -- the JWT never
   * carries them, and they can change over the life of a long-lived token).
   */
  private async resolveUserInfo(
    userId: string,
    fallback: { userName?: string; userEmail?: string },
  ) {
    const user = await this.userRepository.findOne(
      { _id: userId },
      { name: 1, email: 1, country: 1, language: 1 },
    );
    return {
      userName: fallback.userName ?? user?.name,
      userEmail: fallback.userEmail ?? user?.email,
      country: user?.country || undefined,
      language: user?.language || undefined,
    };
  }

  findAll(dto: GetListPurchaseDto) {
    return this.purchaseRepository
      .findOption(dto, dto.environment ?? getEnvironment(this.configService))
      .then(result => ({
        ...result,
        items: this.stripStatusHistory(result.items as Purchase[]),
      }));
  }

  findByUser(userId: string) {
    return this.purchaseRepository
      .findByUser(userId)
      .then(items => this.stripStatusHistory(items));
  }

  async findBySubscriptionId(subscriptionId: string) {
    const subscription = await this.dataSource
      .getRepository(Subscription)
      .findOne({ where: { id: subscriptionId } });
    if (!subscription) {
      throw new NotFoundException('Subscription not found');
    }
    const purchases = await this.purchaseRepository.findBySubscriptionScope({
      userId: subscription.userId,
      productId: subscription.productId,
      platform: subscription.platform,
      environment: subscription.environment,
    });
    return this.stripStatusHistory(purchases);
  }

  getRevenueStatistics(
    dto: GetRevenueListDto,
  ): Promise<RevenueStatisticsResponse> {
    return this.purchaseRepository.getRevenueStatistics(
      dto,
      dto.environment ?? getEnvironment(this.configService),
    );
  }

  getRevenueEntries(dto: GetRevenueListDto) {
    return this.purchaseRepository.getRevenueEntries(
      dto,
      dto.environment ?? getEnvironment(this.configService),
    );
  }

  async findOne(id: string) {
    const purchase = await this.purchaseRepository.findById(id);
    if (!purchase) throw new NotFoundException('Purchase not found');
    return purchase;
  }

  async getHistory(id: string) {
    const purchase = await this.purchaseRepository.findById(id);
    if (!purchase) throw new NotFoundException('Purchase not found');
    const history = Array.isArray(purchase.statusHistory)
      ? [...purchase.statusHistory]
      : [];
    history.sort((a, b) => b.at.localeCompare(a.at));
    return history;
  }

  async updateStatus(id: string, dto: UpdatePurchaseStatusDto) {
    if (!dto?.confirmPassword) {
      throw new BadRequestException('Confirm password is required');
    }

    const adminPassword = 'Meup123456@';
    if (dto.confirmPassword !== adminPassword) {
      throw new UnauthorizedException('Sai mật khẩu');
    }

    const purchase = await this.purchaseRepository.findById(id);
    if (!purchase) throw new NotFoundException('Purchase not found');
    const eventType = this.deriveEventType(dto.status, purchase.isRenewal);
    const now = new Date();
    const updatePayload: Partial<Purchase> = {
      status: dto.status,
      eventType,
      processedAt: now,
    };
    if (dto.status !== purchase.status) {
      const history = Array.isArray(purchase.statusHistory)
        ? [...purchase.statusHistory]
        : [];
      history.unshift({
        at: now.toISOString(),
        status: dto.status,
        source: PurchaseHistorySource.MANUAL,
        purchaseTime: purchase.purchaseTime
          ? purchase.purchaseTime.toISOString()
          : null,
        expiryTime: purchase.expiryTime
          ? purchase.expiryTime.toISOString()
          : null,
      });
      updatePayload.statusHistory = history;
    }
    await this.purchaseRepository.updateOne(
      { id },
      updatePayload,
      this.user?.id,
    );
    return this.purchaseRepository.findById(id);
  }

  async getWebhooksByPurchaseId(purchaseId: string) {
    const purchase = await this.purchaseRepository.findById(purchaseId);
    if (!purchase) throw new NotFoundException('Purchase not found');
    return this.webhookEventRepository.findByPurchaseId(purchaseId);
  }

  private isLifetimeLike(productType?: ProductType) {
    // Non-consumable purchases are lifetime/one-off entitlements.
    return productType === ProductType.NON_CONSUMABLE;
  }

  private deriveEventType(
    status: PurchaseStatus,
    isRenewal: boolean,
  ): PurchaseEventType {
    if (status === PurchaseStatus.REFUNDED) return PurchaseEventType.REFUND;
    if (status === PurchaseStatus.CANCELED) return PurchaseEventType.CANCEL;
    if (isRenewal) return PurchaseEventType.RENEWAL;
    return PurchaseEventType.INITIAL;
  }

  private stripStatusHistory(items: Purchase[]) {
    return items.map(item => {
      const { statusHistory: _statusHistory, ...rest } = item;
      return rest as Purchase;
    });
  }

  private decidePurchaseUpsert(args: {
    forceInsert?: boolean;
    cycleOrderId?: string | null;
    purchaseByToken?: Purchase | null;
    purchaseByOrder?: Purchase | null;
    purchaseByTokenAndOrder?: Purchase | null;
    purchaseByIdempotency?: Purchase | null;
  }): {
    purchase: Purchase | null;
    shouldInsert: boolean;
    isRenewalFlag: boolean;
  } {
    const {
      forceInsert,
      cycleOrderId,
      purchaseByToken,
      purchaseByOrder,
      purchaseByTokenAndOrder,
      purchaseByIdempotency,
    } = args;

    const hasOrderId = Boolean(cycleOrderId);
    const hasSameOrderAndToken = Boolean(purchaseByTokenAndOrder);
    const isRenewalFlag =
      hasOrderId &&
      Boolean((purchaseByOrder || purchaseByToken) && !hasSameOrderAndToken);
    const existingRenewal =
      purchaseByTokenAndOrder?.isRenewal ??
      (!cycleOrderId ? purchaseByToken?.isRenewal : undefined);
    const renewalFlagFinal =
      Boolean(existingRenewal) || isRenewalFlag || Boolean(forceInsert);

    // Đã có đúng kỳ (token + order)
    if (purchaseByTokenAndOrder) {
      // Luôn update bản ghi đúng kỳ, kể cả khi status thay đổi (tránh nhân bản)
      if (forceInsert) {
        return {
          purchase: null,
          shouldInsert: true,
          isRenewalFlag: renewalFlagFinal,
        };
      }
      return {
        purchase: purchaseByTokenAndOrder,
        shouldInsert: false,
        isRenewalFlag: renewalFlagFinal,
      };
    }

    // Idempotency (chỉ khi không có token/order trước đó)
    if (purchaseByIdempotency) {
      return {
        purchase: purchaseByIdempotency,
        shouldInsert: false,
        isRenewalFlag: renewalFlagFinal,
      };
    }

    // Không có orderId, fallback theo token
    if (!cycleOrderId && purchaseByToken) {
      if (forceInsert) {
        return {
          purchase: null,
          shouldInsert: true,
          isRenewalFlag: renewalFlagFinal,
        };
      }
      return {
        purchase: purchaseByToken,
        shouldInsert: false,
        isRenewalFlag: renewalFlagFinal,
      };
    }

    return {
      purchase: null,
      shouldInsert: true,
      isRenewalFlag: renewalFlagFinal,
    };
  }

  /// True if [userId] is an anonymous (guest) account. Used to let the current
  /// real user "reclaim" a store transaction still owned by a guest during
  /// Restore Purchases (guest→real premium recovery), while still refusing to
  /// take a transaction owned by another REAL account.
  private async isAnonymousUser(userId: string): Promise<boolean> {
    if (!userId) return false;
    try {
      const owner = await this.userRepository.findOne(
        { _id: userId },
        { anonymous: 1 },
      );
      return !!owner?.anonymous;
    } catch {
      // Malformed id / lookup failure → treat as NOT reclaimable (safe default).
      return false;
    }
  }

  private async upsertSubscriptionFromPurchase(
    queryRunner: any,
    args: {
      purchase: Purchase;
      anchorId: string;
      now: Date;
      productType?: ProductType;
      autoRenewing?: boolean;
      isTrial?: boolean;
    },
  ) {
    const { purchase, now, productType } = args;

    const subWhere: Partial<Subscription> = {
      anchorId: args.anchorId,
      productId: purchase.productId,
      platform: purchase.platform,
    };
    if (purchase.environment) subWhere.environment = purchase.environment;
    const sub =
      (await queryRunner.manager.findOne(Subscription, {
        where: subWhere,
      })) ||
      (await queryRunner.manager.findOne(Subscription, {
        where: {
          userId: purchase.userId,
          productId: purchase.productId,
          platform: purchase.platform,
          ...(purchase.environment ? { environment: purchase.environment } : {}),
        },
      }));

    // status depends on expiry + purchase.status
    const status = resolveSubscriptionStatus(
      purchase.status,
      purchase.expiryTime,
      now,
    );

    // Guard end-time:
    // - subscriptions should not become "lifetime" by accident when expiry missing
    // - only lifetime-like products are allowed to have null end
    const allowNullEnd = this.isLifetimeLike(productType);
    const nextEnd =
      purchase.expiryTime ??
      sub?.currentPeriodEnd ??
      (allowNullEnd ? null : undefined);

    const payload: Partial<Subscription> = {
      // Follow the purchase's owner. On a Restore-reclaim the purchase was just
      // re-keyed to the current real user, so an existing sub found by anchorId
      // (still under the old guest _id) is moved to the real user here too —
      // otherwise premium would stay stuck on the guest.
      userId: purchase.userId,
      status,
      lastEventAt: now,
      lastVerifiedAt: now,
      currentPeriodStart:
        purchase.purchaseTime ?? sub?.currentPeriodStart ?? now,
      environment: purchase.environment ?? sub?.environment,
      userName: purchase.userName ?? sub?.userName,
      userEmail: purchase.userEmail ?? sub?.userEmail,
    };

    // only overwrite end if we have a real value, OR the product allows null-end
    if (nextEnd !== undefined) {
      payload.currentPeriodEnd = nextEnd as any;
    }

    if (args.autoRenewing !== undefined)
      payload.autoRenewing = args.autoRenewing;
    if (args.isTrial !== undefined) payload.isTrial = args.isTrial;

    if (sub) {
      await queryRunner.manager.update(
        Subscription,
        { id: sub.id },
        { ...payload, updatedBy: this.user?.id },
      );
      return;
    }

    // Insert new subscription
    await queryRunner.manager.insert(Subscription, {
      userId: purchase.userId,
      userName: purchase.userName,
      userEmail: purchase.userEmail,
      platform: purchase.platform,
      productId: purchase.productId,
      anchorId: args.anchorId,
      ...payload,
      currentPeriodEnd:
        nextEnd !== undefined ? (nextEnd as any) : allowNullEnd ? null : null,
      autoRenewing: args.autoRenewing ?? true,
      isTrial: args.isTrial ?? false,
      createdBy: this.user?.id,
    });
  }

  async verify(userId: string, dto: VerifyPurchaseDto) {
    if (!userId) throw new UnauthorizedException('Unauthorized');
    const resolvedProfile = await this.resolveUserInfo(userId, {
      userName: this.user?.name,
      userEmail: this.user?.email,
    });
    const userName = resolvedProfile.userName;
    const userEmail = resolvedProfile.userEmail;
    const userCountry = resolvedProfile.country;
    const userLanguage = resolvedProfile.language;

    // The code in play for this purchase: what the app sent, or -- when it
    // never got to hand one over (killed on the store sheet, a verify that
    // failed and retried, Ask-to-Buy completing hours later) -- what the user
    // applied earlier. Both go through the SAME scope check below; a recovered
    // code gets no easier ride than a sent one.
    const appSentACode = Boolean(dto.voucherCode?.trim());
    const claimedAttribution = appSentACode
      ? undefined
      : await this.findClaimableCode(userId);
    const candidateCode = appSentACode
      ? dto.voucherCode.trim()
      : claimedAttribution?.code;

    // Voucher re-validation (Part 4): NEVER trust that the code was valid
    // when the paywall opened. Re-run the exact same rules the /validate
    // endpoint uses (active window, maxUses, countries, perUserLimit,
    // product mapping). A stale/invalid code must never fail a real
    // purchase -- on any validation error, just proceed without it.
    let voucherRevalidation: IVoucherValidateResult | undefined;
    if (candidateCode) {
      try {
        voucherRevalidation = await this.voucherService.validate({
          code: candidateCode,
          platform: dto.platform,
        });
      } catch (err: any) {
        this.logger.error(
          `Voucher re-validation errored, proceeding without it: ${
            err?.message ?? err
          }`,
          err?.stack,
        );
        voucherRevalidation = undefined;
      }
    }

    // A live code is not automatically THIS sale's code. `validate` answers
    // "is the code alive", and its `products` list is the swap set the code
    // offers -- HDDHISTORYTES swaps the yearly family and nothing else. Without this
    // check a yearly code stamped itself onto a monthly purchase and the feed
    // reported `discount: 50` on an order the store had charged in full.
    //
    // Matched on `targetProductId`, never the base: the discount exists only on
    // the swapped-TO SKU, so a purchase that stayed on the base SKU paid full
    // price even when the code covers its family.
    const voucherCoversPurchase = Boolean(
      voucherRevalidation?.valid &&
        voucherRevalidation.products?.some(
          (swap) => swap.targetProductId === dto.productId,
        ),
    );

    // "The code does not cover that SKU" and "we could not ask" must not be
    // treated alike. On an outage the buyer may well be holding a legitimately
    // swapped SKU, and silently dropping the partner's attribution is worse
    // than the odd over-credit -- so the code is still recorded, but never a
    // discount, which we have no evidence for.
    const revalidationInconclusive =
      Boolean(candidateCode) &&
      (!voucherRevalidation || voucherRevalidation.reason === 'unavailable');

    if (candidateCode && !voucherCoversPurchase && !revalidationInconclusive) {
      // Support will be asked why an order shows no code. Say so once, here,
      // rather than leaving them to infer it from an empty column.
      this.logger.warn(
        `Code ${candidateCode} does not cover ${dto.productId} ` +
          `(${voucherRevalidation?.reason ?? 'no matching swap'}) — recording ` +
          `neither code nor discount on this purchase.`,
      );
    }

    const appliedVoucherCode = voucherCoversPurchase
      ? voucherRevalidation.code
      : undefined;
    const appliedVoucherDiscountPercent = voucherCoversPurchase
      ? voucherRevalidation.discountPercent
      : undefined;

    // What the buyer typed, kept whether or not it resolves to an
    // `iap_vouchers` row -- affiliate codes are handed out without one now, and
    // the old "store it only once it validated" rule reported `code: null` for
    // every single one of them. Truncated to the column width so an oversized
    // paste can never fail the purchase.
    const attributableCode =
      voucherCoversPurchase || revalidationInconclusive
        ? candidateCode.slice(0, ENTERED_CODE_MAX_LENGTH)
        : undefined;
    const sentCode = appSentACode ? attributableCode : undefined;
    const recoveredCode = appSentACode ? undefined : attributableCode;

    const product = await this.productRepository.findOne({
      productId: dto.productId,
      platform: dto.platform,
      isActive: true,
    });
    if (!product) throw new NotFoundException('Product not found');
    if (product.platform !== dto.platform)
      throw new BadRequestException('Product platform mismatch');

    // verify with store
    const verified = await verifyWithStore({
      ...dto,
      productType: product.type,
    });

    if (
      verified.storeProductId &&
      verified.storeProductId !== product.productId
    ) {
      throw new BadRequestException('Product does not match store payload');
    }

    // Normalize verified according to your product type policy
    const normalizedVerified: VerifiedPurchaseResult = { ...verified };

    // Non-consumable purchases are lifetime: enforce null expiry and no auto renew.
    if (this.isLifetimeLike(product.type)) {
      normalizedVerified.expiryTime = null;
      normalizedVerified.autoRenewing = false;
    }

    const now = new Date();
    const priceSnapshot = buildPriceSnapshot(product, {
      rawPrice: normalizedVerified.rawPrice,
      currency: normalizedVerified.currency as any,
      price: normalizedVerified.price,
    });

    const cycleOrderId = normalizedVerified.orderId;

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    // Set inside the transaction once we know this is a genuinely new,
    // non-renewal row; consumed (voucher usedCount incremented) only after
    // a successful commit, outside the transaction, via the repository.
    let voucherConsumed = false;

    try {
      // 1) Upsert Purchase under transaction
      const purchaseByOrder =
        cycleOrderId &&
        (await queryRunner.manager.findOne(Purchase, {
          where: { orderId: cycleOrderId },
          order: { purchaseTime: 'DESC', processedAt: 'DESC', id: 'DESC' },
        }));

      const purchaseByToken = await queryRunner.manager.findOne(Purchase, {
        where: { storeTransactionId: dto.storeTransactionId },
        order: { purchaseTime: 'DESC', processedAt: 'DESC', id: 'DESC' },
      });

      const purchaseByTokenAndOrder =
        cycleOrderId &&
        (await queryRunner.manager.findOne(Purchase, {
          where: {
            storeTransactionId: dto.storeTransactionId,
            orderId: cycleOrderId,
          },
          order: { purchaseTime: 'DESC', processedAt: 'DESC', id: 'DESC' },
        }));

      const purchaseByIdempotency =
        !purchaseByOrder && !purchaseByToken && dto.idempotencyKey
          ? await queryRunner.manager.findOne(Purchase, {
              where: { idempotencyKey: dto.idempotencyKey },
            })
          : null;

      const isCancelOrRefund =
        normalizedVerified.status === PurchaseStatus.CANCELED ||
        normalizedVerified.status === PurchaseStatus.REFUNDED;
      const forceInsert =
        isCancelOrRefund &&
        Boolean(
          purchaseByTokenAndOrder || (!cycleOrderId && purchaseByToken),
        );

      const { purchase, shouldInsert, isRenewalFlag } =
        this.decidePurchaseUpsert({
          forceInsert,
          cycleOrderId,
          purchaseByToken,
          purchaseByOrder,
          purchaseByTokenAndOrder,
          purchaseByIdempotency,
        });

      // Restore Purchases recovery: a store transaction bought while the user
      // was a guest stays linked to that guest's _id. Let the CURRENT real
      // user reclaim it (re-keyed below) — but only when the existing owner is
      // an anonymous guest. Still refuse to take a transaction owned by another
      // REAL account.
      let isReclaimFromGuest = false;
      if (purchase && purchase.userId !== userId) {
        isReclaimFromGuest = await this.isAnonymousUser(purchase.userId);
        if (!isReclaimFromGuest) {
          // Dead end for the buyer unless we say why: one Apple ID holds one
          // subscription, and this one is spoken for. The store already took
          // no money (Apple re-presented the existing transaction), so the
          // only useful thing left is telling them WHICH account to use.
          //
          // Localised message for anyone who just shows it, plus a stable
          // `code` for the app, which localises this case into all five of its
          // languages -- the API only speaks en/vi. Matching on the message
          // text would break the moment either side is reworded.
          this.logger.warn(
            `User ${userId} tried to verify a transaction owned by ` +
              `${purchase.userId} (same store account, different HDDhistory user) — ` +
              `refused.`,
          );
          throw new BadRequestException({
            message: this.i18n.t(
              'error.PAYMENT.TRANSACTION_LINKED_TO_ANOTHER_USER',
              { lang: this.lang },
            ),
            errors: [{ code: 'TRANSACTION_LINKED_TO_ANOTHER_USER' }],
          });
        }
      }

      if (purchase) {
        const shouldOverwrite =
          preferHigherStatus(purchase.status, normalizedVerified.status) ===
          normalizedVerified.status;
        const nextStatus = shouldOverwrite
          ? normalizedVerified.status
          : purchase.status;
        const updatePayload: Partial<Purchase> = shouldOverwrite
          ? {
              status: nextStatus,
              orderId: normalizedVerified.orderId ?? purchase.orderId,
              originalTransactionId:
                normalizedVerified.originalTransactionId ??
                purchase.originalTransactionId,
              purchaseTime:
                normalizedVerified.purchaseTime ?? purchase.purchaseTime,
              expiryTime: normalizedVerified.expiryTime ?? purchase.expiryTime,
              rawPayload: normalizedVerified.rawPayload,
              processedAt: now,
              rawPrice: purchase.rawPrice ?? priceSnapshot.rawPrice,
              currency: purchase.currency ?? priceSnapshot.currency,
              price: purchase.price ?? priceSnapshot.price,
              failureReason:
                normalizedVerified.failureReason ?? purchase.failureReason,
              environment: normalizedVerified.environment ?? purchase.environment,
              country: purchase.country ?? userCountry,
              language: purchase.language ?? userLanguage,
              updatedBy: this.user.id,
              userName: purchase.userName ?? userName,
              userEmail: purchase.userEmail ?? userEmail,
              isRenewal: purchase.isRenewal || isRenewalFlag,
              eventType: this.deriveEventType(
                nextStatus,
                purchase.isRenewal || isRenewalFlag,
              ),
            }
          : {
              processedAt: now,
            };
        const history = Array.isArray(purchase.statusHistory)
          ? [...purchase.statusHistory]
          : [];
        history.unshift({
          at: now.toISOString(),
          status: normalizedVerified.status,
          source: PurchaseHistorySource.VERIFY,
          purchaseTime: normalizedVerified.purchaseTime
            ? normalizedVerified.purchaseTime.toISOString()
            : null,
          expiryTime: normalizedVerified.expiryTime
            ? normalizedVerified.expiryTime.toISOString()
            : null,
        });
        updatePayload.statusHistory = history;
        // Move ownership to the current user when reclaiming a guest-owned
        // transaction (Restore Purchases), so premium follows the real account.
        if (isReclaimFromGuest) {
          updatePayload.userId = userId;
          updatePayload.userName = userName;
          updatePayload.userEmail = userEmail;
        }
        // Deliberately NOT writing `enteredCode` here. This branch runs when
        // the transaction ALREADY exists -- a renewal, a retried verify, a
        // status change -- so a code entered now did not earn that sale.
        // Backfilling it stamped a code onto the next daily renewal of a
        // subscription bought weeks earlier (seen on prod 2026-08-05: four
        // renewals at 02:45:48 with no code, then the fifth carrying one), which
        // is affiliate credit for a sale the code had nothing to do with.
        // Attribution is written once, at INSERT, and never moves.
        await queryRunner.manager.update(
          Purchase,
          { id: purchase.id },
          updatePayload,
        );
      }

      if (shouldInsert || !purchase) {
        // Only a genuinely new, non-renewal purchase row consumes a voucher
        // redemption -- a renewal or a retried/deduped verify() must not
        // increment usedCount again (Part 4).
        voucherConsumed = !isRenewalFlag && Boolean(appliedVoucherCode);

        const eventType = this.deriveEventType(
          normalizedVerified.status,
          isRenewalFlag,
        );
        await queryRunner.manager.insert(Purchase, {
          userId,
          userName,
          userEmail,
          platform: dto.platform,
          storeTransactionId: dto.storeTransactionId,
          productId: dto.productId,
          orderId: normalizedVerified.orderId,
          originalTransactionId: normalizedVerified.originalTransactionId,
          purchaseTime: normalizedVerified.purchaseTime,
          expiryTime: normalizedVerified.expiryTime,
          rawPayload: normalizedVerified.rawPayload,
          status: normalizedVerified.status,
          processedAt: now,
          idempotencyKey: dto.idempotencyKey,
          rawPrice: priceSnapshot.rawPrice,
          currency: priceSnapshot.currency,
          price: priceSnapshot.price,
          failureReason: normalizedVerified.failureReason,
          environment: normalizedVerified.environment,
          country: userCountry,
          language: userLanguage,
          voucherCode: voucherConsumed ? appliedVoucherCode : undefined,
          voucherDiscountPercent: voucherConsumed
            ? appliedVoucherDiscountPercent
            : undefined,
          // A code the app SENT is written unconditionally: attribution must
          // survive a code that matches no voucher, a code whose voucher has
          // expired, and a re-verify that lands as a renewal (which
          // deliberately consumes nothing).
          //
          // A code merely RECOVERED from attribution is held back on renewals.
          // The recovery exists to rescue a new purchase whose code went
          // missing; letting an auto-renewal inside the 7-day window claim a
          // code the user applied afterwards would credit a partner for a sale
          // the code had no part in. The row stays unconsumed either way, so
          // the next genuine purchase can still claim it.
          enteredCode: sentCode ?? (isRenewalFlag ? undefined : recoveredCode),
          // Like a SENT code above: the app only attaches this on the purchase
          // it just made from a LogicSale paywall, so when it is present it is
          // written unconditionally. Renewal/webhook verifies carry none, so a
          // campaign is never credited for a later cycle it had no part in.
          logicSaleId: dto.logicSaleId?.trim().slice(0, 64) || undefined,
          // Same contract as logicSaleId: attached by the app only on the
          // purchase made from the paywall it was assigned on, so a renewal
          // never lands in an arm. Both halves are written together or not at
          // all -- an arm without its run key cannot be read back.
          paywallExperimentKey:
            dto.paywallExperimentKey?.trim().slice(0, 64) || undefined,
          paywallBodyVariant:
            dto.paywallExperimentKey?.trim() &&
            dto.paywallBodyVariant?.trim().slice(0, 16)
              ? dto.paywallBodyVariant.trim().slice(0, 16)
              : undefined,
          createdBy: this.user?.id,
          isRenewal: isRenewalFlag,
          eventType,
          statusHistory: [
            {
              at: now.toISOString(),
              status: normalizedVerified.status,
              source: PurchaseHistorySource.VERIFY,
              purchaseTime: normalizedVerified.purchaseTime
                ? normalizedVerified.purchaseTime.toISOString()
                : null,
              expiryTime: normalizedVerified.expiryTime
                ? normalizedVerified.expiryTime.toISOString()
                : null,
            },
          ],
        });
      }

      const saved =
        (cycleOrderId &&
          (await queryRunner.manager.findOne(Purchase, {
            where: { orderId: cycleOrderId },
            order: { purchaseTime: 'DESC', processedAt: 'DESC', id: 'DESC' },
          }))) ||
        (await queryRunner.manager.findOne(Purchase, {
          where: { storeTransactionId: dto.storeTransactionId },
          order: { purchaseTime: 'DESC', processedAt: 'DESC', id: 'DESC' },
        }));
      if (!saved) throw new Error('Purchase upsert failed');

      // 2) Compute a STABLE anchorId (DO NOT let it jump)
      const anchorLookup: Partial<Subscription> = normalizedVerified.anchorId
        ? {
            anchorId: normalizedVerified.anchorId,
            productId: saved.productId,
            platform: saved.platform,
            ...(saved.environment ? { environment: saved.environment } : {}),
          }
        : {};
      const existingSub =
        (normalizedVerified.anchorId
          ? await queryRunner.manager.findOne(Subscription, {
              where: anchorLookup,
            })
          : null) ||
        (await queryRunner.manager.findOne(Subscription, {
          where: {
            userId,
            productId: saved.productId,
            platform: saved.platform,
            ...(saved.environment ? { environment: saved.environment } : {}),
          },
        }));

      const stableAnchorId =
        existingSub?.anchorId ||
        normalizedVerified.anchorId ||
        dto.storeTransactionId;

      // 3) Upsert Subscription snapshot
      await this.upsertSubscriptionFromPurchase(queryRunner, {
        purchase: saved,
        anchorId: stableAnchorId,
        now,
        productType: product.type,
        autoRenewing: normalizedVerified.autoRenewing,
        isTrial: normalizedVerified.isTrial,
      });

      await queryRunner.commitTransaction();

      // Report the redemption to the affiliate service only after the purchase
      // row is safely committed -- a failure here must never turn an
      // already-successful purchase into a client-facing error, so it is
      // logged and swallowed, not rethrown. Attribution survives a failure
      // regardless: `voucher_code` is on the row above, and
      // POST /purchase/affiliateOrder is the reconciliation path.
      if (voucherConsumed && appliedVoucherCode) {
        try {
          await this.voucherService.reportRedemption({
            code: appliedVoucherCode,
            productId: saved.productId,
            userId: saved.userId,
            email: saved.userEmail,
          });
        } catch (err: any) {
          this.logger.error(
            `Failed to report voucher redemption ${appliedVoucherCode}: ${
              err?.message ?? err
            }`,
            err?.stack,
          );
        }
      }

      // Burn the recovered code now that a row carries it, so the next
      // purchase cannot claim the same one. Only after the commit, and only
      // when we actually used it -- a code sent by the app was never claimed
      // from here in the first place.
      if (claimedAttribution && recoveredCode && saved.enteredCode === recoveredCode) {
        try {
          await this.codeAttributionRepository.markConsumed(
            claimedAttribution.id,
            saved.id,
            now,
          );
        } catch (err: any) {
          this.logger.error(
            `Failed to mark code attribution ${claimedAttribution.id} consumed: ${
              err?.message ?? err
            }`,
            err?.stack,
          );
        }
      }

      return saved;
    } catch (error: any) {
      await queryRunner.rollbackTransaction();
      this.logger.error(
        `Purchase verify failed: ${error?.message ?? error}`,
        error?.stack,
      );
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  /**
   * Part 5 — affiliate orders export. Maps `iap_purchases` rows whose
   * purchaseTime falls in [start_time, end_time] to the external, fixed
   * `{ orders: [...] }` contract. No other filtering (status/voucher) --
   * every purchase in range is included, per the spec's field mapping
   * (status/discount are just 0/false-ish when not applicable).
   */
  async getAffiliateOrders(
    dto: AffiliateOrderRequestDto,
  ): Promise<AffiliateOrderResponse> {
    const startDate = new Date(dto.start_time);
    const endDate = new Date(dto.end_time);
    if (
      Number.isNaN(startDate.getTime()) ||
      Number.isNaN(endDate.getTime()) ||
      startDate.getTime() > endDate.getTime()
    ) {
      throw new BadRequestException('Invalid start_time/end_time range');
    }

    const take = Math.min(dto.limit ?? 100, 500);
    const skip = dto.skip ?? 0;

    const purchases = await this.purchaseRepository.findAffiliateOrders({
      startDate,
      endDate,
      take,
      skip,
    });

    if (!purchases.length) {
      throw new NotFoundException('No purchases found in the given range');
    }

    const productByKey = await this.buildProductLookup();

    return {
      orders: purchases.map(purchase => {
        const product = productByKey.get(
          `${purchase.platform}:${purchase.productId}`,
        );
        return mapPurchaseToAffiliateOrder(
          purchase,
          product?.title,
          product?.salePercent,
        );
      }),
    };
  }

  /**
   * The newest code this user applied that no purchase has taken yet, or
   * undefined. Read-only — the row is marked consumed only once a purchase row
   * actually exists to point at.
   *
   * Never allowed to fail a purchase: attribution is bookkeeping, and money
   * has already changed hands by the time this runs.
   */
  private async findClaimableCode(
    userId: string,
  ): Promise<CodeAttribution | undefined> {
    try {
      return (
        (await this.codeAttributionRepository.findClaimable(
          userId,
          new Date(),
        )) ?? undefined
      );
    } catch (err: any) {
      this.logger.error(
        `Failed to read code attribution for ${userId}: ${err?.message ?? err}`,
        err?.stack,
      );
      return undefined;
    }
  }

  private async buildProductLookup(): Promise<
    Map<string, { title: string; salePercent?: number }>
  > {
    const products = await this.productRepository.findAllForTitleLookup();
    const map = new Map<string, { title: string; salePercent?: number }>();
    for (const product of products) {
      map.set(`${product.platform}:${product.productId}`, {
        title: product.title,
        salePercent: product.salePercent,
      });
    }
    return map;
  }
}
