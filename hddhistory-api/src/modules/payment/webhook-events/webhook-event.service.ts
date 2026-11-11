import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';

import { Configuration } from '@base/config/configuration';
import { UserRepository } from 'src/modules/user/src/modules/auth/repository/user.repository';

import {
  buildPriceSnapshot,
  inferEventState,
  normalizeEnvironment,
  parseApplePayload,
  parseGooglePayload,
  unwrapPubSubBody,
  verifyAppleSignedPayload,
  verifyGoogleOidcToken,
} from './webhook-events.helper';
import {
  PaymentEnvironment,
  PaymentPlatform,
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
import { WebhookEventRepository } from './repositories/webhook-event.repository';
import { ProductRepository } from '../products/repositories/product.repository';
import { Purchase } from '../purchases/entities/purchase.entity';
import { PurchaseRepository } from '../purchases/repositories/purchase.repository';
import { Subscription } from '../subscriptions/entities/subscription.entity';

@Injectable()
export class WebhookEventService {
  constructor(
    private readonly webhookRepo: WebhookEventRepository,
    private readonly productRepo: ProductRepository,
    private readonly purchaseRepo: PurchaseRepository,
    private readonly dataSource: DataSource,
    private readonly configService: Configuration,
    private readonly userRepository: UserRepository,
  ) {}

  // ---------------------------------------------------------------------
  // HANDLE WEBHOOK → ALWAYS LOG FIRST → THEN PROCESS
  // ---------------------------------------------------------------------
  async handle(dto: any, headers?: { authorization?: string }) {
    const normalized = unwrapPubSubBody(dto);
    const eventEnvironment =
      normalizeEnvironment(normalized?.payload?.environment) ??
      getEnvironment(this.configService);
    let environmentFromProcess: PaymentEnvironment | undefined;
    let purchaseIdFromProcess: string | undefined;

    if (!normalized.platform) {
      throw new BadRequestException('Missing platform in webhook payload');
    }
    await this.assertSignature(normalized, headers);

    // 1) ALWAYS save event log (never inside transaction)
    const event = await this.webhookRepo.create({
      platform: normalized.platform,
      environment: eventEnvironment,
      rawBody: normalized.rawBody,
      processed: false,
      eventType: normalized.eventType,
      error: null,
    });

    try {
      // 2) Run process logic inside a transaction
      const processResult = await this.processEvent(normalized);
      environmentFromProcess = processResult.environment;
      purchaseIdFromProcess = processResult.purchaseId;

      // 3) Mark event processed
      await this.webhookRepo.updateOne(
        { id: event.id },
        {
          processed: true,
          processedAt: new Date(),
          error: null,
          environment: environmentFromProcess ?? eventEnvironment,
          purchaseId: purchaseIdFromProcess,
        },
      );

      return this.webhookRepo.findById(event.id);
    } catch (err) {
      // Log error without deleting webhook event
      await this.webhookRepo.updateOne(
        { id: event.id },
        {
          processed: false,
          error: (err as Error).message,
          environment: environmentFromProcess ?? eventEnvironment,
          purchaseId: purchaseIdFromProcess,
        },
      );
      throw err;
    }
  }

  private async assertSignature(
    dto: any,
    headers?: { authorization?: string },
  ) {
    // Google: verify JWT in Authorization: Bearer <token> (Pub/Sub authenticated push)
    if (dto.platform === PaymentPlatform.GOOGLE) {
      await verifyGoogleOidcToken(
        headers?.authorization,
        this.configService.getGoogleWebhookAudience,
        this.configService.getGoogleWebhookServiceAccountEmail,
      );
      return;
    }

    // Apple: verify signedPayload JWS (ASSN v2) bằng public key của Apple
    if (dto.platform === PaymentPlatform.APPLE) {
      const signedPayload = this.getAppleSignedPayload(dto);

      if (!signedPayload) {
        throw new UnauthorizedException('Missing Apple signedPayload');
      }
      const verifiedPayload = await verifyAppleSignedPayload(signedPayload, {
        bundleId: this.configService.getAppleBundleId,
      });
      // attach decoded payload for downstream parsing if not already present
      if (!dto.payload) {
        dto.payload = verifiedPayload;
      }
      return;
    }
  }

  private getAppleSignedPayload(dto: any) {
    if (typeof dto?.signedPayload === 'string') return dto.signedPayload;
    if (typeof dto?.payload?.signedPayload === 'string')
      return dto.payload.signedPayload;
    if (dto.rawBody) {
      try {
        const parsed = JSON.parse(dto.rawBody);
        if (typeof parsed?.signedPayload === 'string')
          return parsed.signedPayload;
      } catch {
        // ignore parse error
      }
    }
    return undefined;
  }

  // ---------------------------------------------------------------------
  // INTERNAL: PROCESS PURCHASE + SUBSCRIPTION IN TRANSACTION
  // ---------------------------------------------------------------------
  private async processEvent(dto: any): Promise<{
    environment?: PaymentEnvironment;
    purchaseId?: string;
  }> {
    const { platform } = dto;
    const payload = await this.parsePayload(dto);

    if (!payload.storeTransactionId || !payload.productId) {
      return { environment: payload.environment };
    }

    const payloadAny = payload as any;
    const needsUserInfo =
      !payload.userId || !payloadAny.userName || !payloadAny.userEmail;
    let existing: Purchase | null = null;

    if (needsUserInfo) {
      const existingByOrder = payload.orderId
        ? await this.purchaseRepo.findByOrder(payload.orderId)
        : null;
      existing =
        existingByOrder ||
        (await this.purchaseRepo.findByTransaction(payload.storeTransactionId));
      if (existing) {
        payload.userId = payload.userId ?? existing.userId;
        payload.productId = payload.productId || existing.productId;
        payload.orderId = payload.orderId || existing.orderId;
        payloadAny.userName = payloadAny.userName ?? (existing as any).userName;
        payloadAny.userEmail =
          payloadAny.userEmail ?? (existing as any).userEmail;
      }
    }

    if (!payload.userId) {
      // No way to map webhook to a user yet; keep the event log but skip processing.
      return { environment: payload.environment };
    }

    if (payload.userId && (!payloadAny.userName || !payloadAny.userEmail)) {
      const user = await this.userRepository.findOne(
        { _id: payload.userId },
        { name: 1, email: 1 },
      );
      if (user) {
        payloadAny.userName = payloadAny.userName ?? user.name;
        payloadAny.userEmail = payloadAny.userEmail ?? user.email;
      }
    }

    const now = new Date();
    const product = await this.productRepo.findOne({
      productId: payload.productId,
      platform,
    });

    const priceSnapshot = product
      ? buildPriceSnapshot(product, {
          rawPrice: (payload as any).rawPrice,
          currency: (payload as any).currency,
          price: (payload as any).price,
        })
      : ({} as any);

    const environment =
      normalizeEnvironment(payload.environment) ??
      normalizeEnvironment(dto?.payload?.environment) ??
      getEnvironment(this.configService);

    // Determine anchorId (group for renewals).
    // Apple's per-renewal id now lives in `orderId`, so the stable group id has
    // to come from `originalTransactionId` — using `orderId` here would anchor
    // every renewal to its own subscription.
    const anchorId =
      payload.anchorId ||
      (platform === PaymentPlatform.APPLE
        ? payload.originalTransactionId || payload.storeTransactionId
        : payload.orderId || payload.storeTransactionId);

    const qr = this.dataSource.createQueryRunner();
    await qr.connect();
    await qr.startTransaction();
    let purchaseRecord: Purchase | null = null;

    try {
      // --------------------------------------------------
      // PURCHASE UPSERT
      // --------------------------------------------------
      const purchaseByToken = await qr.manager.findOne(Purchase, {
        where: { storeTransactionId: payload.storeTransactionId },
        order: { purchaseTime: 'DESC', processedAt: 'DESC', id: 'DESC' },
      });
      const purchaseByOrder = payload.orderId
        ? await qr.manager.findOne(Purchase, {
            where: { orderId: payload.orderId },
            order: { purchaseTime: 'DESC', processedAt: 'DESC', id: 'DESC' },
          })
        : null;
      const purchaseByTokenAndOrder =
        payload.orderId &&
        (await qr.manager.findOne(Purchase, {
          where: {
            storeTransactionId: payload.storeTransactionId,
            orderId: payload.orderId,
          },
          order: { purchaseTime: 'DESC', processedAt: 'DESC', id: 'DESC' },
        }));

      const isCancelOrRefund =
        payload.status === PurchaseStatus.CANCELED ||
        payload.status === PurchaseStatus.REFUNDED;
      const forceInsert =
        isCancelOrRefund &&
        Boolean(
          purchaseByTokenAndOrder || (!payload.orderId && purchaseByToken),
        );

      const { purchaseForUpdate, shouldInsert, isRenewalFlag } =
        this.decideWebhookUpsert({
          payload,
          forceInsert,
          purchaseByToken,
          purchaseByOrder,
          purchaseByTokenAndOrder,
        });

      if (purchaseForUpdate) {
        const shouldOverwrite =
          preferHigherStatus(purchaseForUpdate.status, payload.status) ===
          payload.status;
        const nextStatus = shouldOverwrite
          ? payload.status
          : purchaseForUpdate.status;
        const updatePayload: Partial<Purchase> = shouldOverwrite
          ? {
              status: nextStatus,
              orderId: payload.orderId ?? purchaseForUpdate.orderId,
              purchaseTime:
                payload.purchaseTime ?? purchaseForUpdate.purchaseTime,
              expiryTime: payload.expiryTime ?? purchaseForUpdate.expiryTime,
              rawPayload: payload.rawPayload,
              processedAt: now,
              rawPrice: purchaseForUpdate.rawPrice ?? priceSnapshot.rawPrice,
              currency: purchaseForUpdate.currency ?? priceSnapshot.currency,
              price: purchaseForUpdate.price ?? priceSnapshot.price,
              failureReason:
                payload.failureReason ?? purchaseForUpdate.failureReason,
              environment: purchaseForUpdate.environment ?? environment,
              userName:
                purchaseForUpdate.userName ?? (payload as any).userName ?? null,
              userEmail:
                purchaseForUpdate.userEmail ?? (payload as any).userEmail ?? null,
              isRenewal: purchaseForUpdate.isRenewal || isRenewalFlag,
              eventType: this.deriveEventType(
                nextStatus,
                isRenewalFlag || purchaseForUpdate.isRenewal,
              ),
            }
          : {
              processedAt: now,
            };
        const history = Array.isArray(purchaseForUpdate.statusHistory)
          ? [...purchaseForUpdate.statusHistory]
          : [];
        history.unshift({
          at: now.toISOString(),
          status: payload.status,
          source: PurchaseHistorySource.WEBHOOK,
          purchaseTime: payload.purchaseTime
            ? payload.purchaseTime.toISOString()
            : null,
          expiryTime: payload.expiryTime ? payload.expiryTime.toISOString() : null,
        });
        updatePayload.statusHistory = history;
        await qr.manager.update(
          Purchase,
          { id: purchaseForUpdate.id },
          updatePayload,
        );
      }

      if (shouldInsert) {
        const eventType = this.deriveEventType(payload.status, isRenewalFlag);
        await qr.manager.insert(Purchase, {
          userId: payload.userId,
          userName: (payload as any).userName,
          userEmail: (payload as any).userEmail,
          platform,
          productId: payload.productId,
          storeTransactionId: payload.storeTransactionId,
          orderId: payload.orderId,
          // Kept alongside the per-transaction orderId so the stable
          // subscription id survives on the row, same as the verify path.
          originalTransactionId: payload.originalTransactionId,
          purchaseTime: payload.purchaseTime,
          expiryTime: payload.expiryTime,
          rawPayload: payload.rawPayload,
          status: payload.status,
          processedAt: now,
          rawPrice: priceSnapshot.rawPrice,
          currency: priceSnapshot.currency,
          price: priceSnapshot.price,
          failureReason: payload.failureReason,
          environment,
          isRenewal: isRenewalFlag,
          eventType,
          statusHistory: [
            {
              at: now.toISOString(),
              status: payload.status,
              source: PurchaseHistorySource.WEBHOOK,
              purchaseTime: payload.purchaseTime
                ? payload.purchaseTime.toISOString()
                : null,
              expiryTime: payload.expiryTime
                ? payload.expiryTime.toISOString()
                : null,
            },
          ],
        });
      }

      purchaseRecord =
        (payload.orderId &&
          (await qr.manager.findOne(Purchase, {
            where: {
              storeTransactionId: payload.storeTransactionId,
              orderId: payload.orderId,
            },
            order: {
              purchaseTime: 'DESC',
              processedAt: 'DESC',
              id: 'DESC',
            },
          }))) ||
        (payload.orderId
          ? await qr.manager.findOne(Purchase, {
              where: { orderId: payload.orderId },
              order: { purchaseTime: 'DESC', processedAt: 'DESC', id: 'DESC' },
            })
          : await qr.manager.findOne(Purchase, {
              where: { storeTransactionId: payload.storeTransactionId },
              order: { purchaseTime: 'DESC', processedAt: 'DESC', id: 'DESC' },
            }));
      if (!purchaseRecord) throw new Error('Purchase upsert failed');

      // --------------------------------------------------
      // SUBSCRIPTION UPSERT
      // --------------------------------------------------
      const shouldOverwriteSubscription =
        !purchaseForUpdate ||
        preferHigherStatus(purchaseForUpdate.status, payload.status) ===
          payload.status;
      const effectiveStatus = purchaseForUpdate
        ? preferHigherStatus(purchaseForUpdate.status, payload.status)
        : payload.status;
      const subStatus = resolveSubscriptionStatus(
        effectiveStatus,
        payload.expiryTime,
        now,
      );

      const subWhere: Partial<Subscription> = {
        anchorId,
        productId: payload.productId,
        platform,
      };
      if (environment) subWhere.environment = environment;
      let sub = await qr.manager.findOne(Subscription, {
        where: subWhere,
      });

      if (!sub) {
        sub = await qr.manager.findOne(Subscription, {
          where: {
            userId: payload.userId,
            productId: payload.productId,
            platform,
            ...(environment ? { environment } : {}),
          },
        });
      }

      const allowNullEnd = this.isLifetimeLike(product?.type);
      const subUpdate: Partial<Subscription> = {
        lastEventAt: now,
        lastVerifiedAt: now,
        environment: environment ?? sub?.environment,
        userName: (payload as any).userName ?? sub?.userName,
        userEmail: (payload as any).userEmail ?? sub?.userEmail,
      };
      if (shouldOverwriteSubscription) {
        subUpdate.status = subStatus;
        subUpdate.currentPeriodStart =
          payload.purchaseTime ?? sub?.currentPeriodStart ?? now;
        if (payload.expiryTime) {
          subUpdate.currentPeriodEnd = payload.expiryTime;
        } else if (allowNullEnd) {
          subUpdate.currentPeriodEnd = null;
        }
      }

      if (payload.autoRenewing !== undefined) {
        subUpdate.autoRenewing = payload.autoRenewing;
      }

      if (payload.isTrial !== undefined) {
        subUpdate.isTrial = payload.isTrial;
      }

      if (sub) {
        await qr.manager.update(Subscription, { id: sub.id }, subUpdate);
      } else {
        await qr.manager.insert(Subscription, {
          userId: payload.userId,
          platform,
          productId: payload.productId,
          anchorId,
          ...subUpdate,
          autoRenewing:
            payload.autoRenewing !== undefined ? payload.autoRenewing : true,
          isTrial: payload.isTrial ?? false,
          environment,
        });
      }

      // Commit TX
      await qr.commitTransaction();
    } catch (err) {
      await qr.rollbackTransaction();
      throw err;
    } finally {
      await qr.release();
    }

    return { environment, purchaseId: purchaseRecord?.id };
  }

  // ---------------------------------------------------------------------
  // HELPER: Parse Generic Webhook Payload (Google/Apple)
  // ---------------------------------------------------------------------
  private async parsePayload(dto: any) {
    if (dto.platform === PaymentPlatform.GOOGLE) {
      const googlePayload = await parseGooglePayload(dto, {
        productRepo: this.productRepo,
        purchaseRepo: this.purchaseRepo,
      });
      if (googlePayload) return googlePayload;
    }

    if (dto.platform === PaymentPlatform.APPLE) {
      const applePayload = parseApplePayload(dto);
      if (applePayload) return applePayload;
    }

    const body = dto.payload ?? {}; // raw JSON object
    const raw = dto.rawBody;

    const eventState = inferEventState(dto.eventType);
    const envNormalized = normalizeEnvironment(body.environment);
    const anchorId = body.anchorId || body.orderId || body.storeTransactionId;
    return {
      userId: body.userId,
      productId: body.productId,
      storeTransactionId: body.storeTransactionId,
      orderId: body.orderId,
      // Raw-JSON fallback: callers may pass it explicitly, otherwise the
      // Apple anchor falls back to storeTransactionId (see anchorId above).
      originalTransactionId: body.originalTransactionId as string | undefined,
      anchorId,
      purchaseTime: body.purchaseTime ? new Date(body.purchaseTime) : null,
      expiryTime: body.expiryTime ? new Date(body.expiryTime) : null,
      rawPayload: raw,
      status: eventState.status,
      autoRenewing:
        body.autoRenewing !== undefined
          ? Boolean(body.autoRenewing)
          : eventState.autoRenewing,
      isTrial: body.isTrial !== undefined ? Boolean(body.isTrial) : undefined,
      failureReason: body.failureReason,
      rawPrice: body.rawPrice !== undefined ? Number(body.rawPrice) : undefined,
      currency: body.currency,
      price: body.price,
      environment: envNormalized,
    };
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

  private isLifetimeLike(productType?: ProductType) {
    return productType === ProductType.NON_CONSUMABLE;
  }

  private decideWebhookUpsert(args: {
    payload: any;
    forceInsert?: boolean;
    purchaseByToken?: Purchase | null;
    purchaseByOrder?: Purchase | null;
    purchaseByTokenAndOrder?: Purchase | null;
  }): {
    purchaseForUpdate: Purchase | null;
    shouldInsert: boolean;
    isRenewalFlag: boolean;
  } {
    const {
      payload,
      forceInsert,
      purchaseByToken,
      purchaseByOrder,
      purchaseByTokenAndOrder,
    } = args;

    const hasOrderId = Boolean(payload.orderId);
    const hasSameOrderAndToken = Boolean(purchaseByTokenAndOrder);
    const isRenewalFlag =
      hasOrderId &&
      Boolean((purchaseByOrder || purchaseByToken) && !hasSameOrderAndToken);
    const existingRenewal =
      purchaseByTokenAndOrder?.isRenewal ??
      (!payload.orderId ? purchaseByToken?.isRenewal : undefined);
    const renewalFlagFinal =
      Boolean(existingRenewal) || isRenewalFlag || Boolean(forceInsert);
    let purchaseForUpdate: Purchase | null = null;
    let shouldInsert = true;

    if (purchaseByTokenAndOrder) {
      // Luôn update bản ghi đúng kỳ, kể cả khi status khác (tránh tạo bản ghi trùng)
      if (forceInsert) {
        shouldInsert = true;
      } else {
        purchaseForUpdate = purchaseByTokenAndOrder;
        shouldInsert = false;
      }
    } else if (!payload.orderId && purchaseByToken) {
      // Không có orderId → fallback theo token
      if (forceInsert) {
        shouldInsert = true;
      } else {
        purchaseForUpdate = purchaseByToken;
        shouldInsert = false;
      }
    }

    return {
      purchaseForUpdate,
      shouldInsert,
      isRenewalFlag: renewalFlagFinal,
    };
  }
}
