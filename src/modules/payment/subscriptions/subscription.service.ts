import { randomUUID } from 'crypto';

import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
  OnModuleDestroy,
  OnModuleInit,
  UnauthorizedException,
} from '@nestjs/common';
import { Brackets, DataSource } from 'typeorm';

import { Configuration } from '@base/config/configuration';

import {
  ProductType,
  PurchaseHistorySource,
  PurchaseStatus,
  SubscriptionStatus,
} from '../enum/payment.enum';
import { getEnvironment, resolveSubscriptionStatus } from '../helpers/common';
import { DeleteSubscriptionDto } from './dto/delete-subscription.dto';
import { GetListSubscriptionDto } from './dto/get-subscription.dto';
import { ManualSubscriptionDto } from './dto/manual-subscription.dto';
import { UpdateManualSubscriptionDto } from './dto/update-manual-subscription.dto';
import { Subscription } from './entities/subscription.entity';
import { SubscriptionRepository } from './repositories/subscription.repository';
import { ProductRepository } from '../products/repositories/product.repository';
import { Purchase } from '../purchases/entities/purchase.entity';

@Injectable()
export class SubscriptionService implements OnModuleInit, OnModuleDestroy {
  private manualStatusTimer?: NodeJS.Timeout;
  private readonly logger = new Logger(SubscriptionService.name);

  constructor(
    private readonly subscriptionRepository: SubscriptionRepository,
    private readonly configService: Configuration,
    private readonly dataSource: DataSource,
    private readonly productRepository: ProductRepository,
  ) {}

  onModuleInit() {
    this.startManualStatusJob();
  }

  onModuleDestroy() {
    if (this.manualStatusTimer) {
      clearInterval(this.manualStatusTimer);
    }
  }

  findAll(dto: GetListSubscriptionDto) {
    return this.subscriptionRepository.findOption(
      dto,
      dto.environment ?? getEnvironment(this.configService),
    );
  }

  async findOne(id: string) {
    const subscription = await this.subscriptionRepository.findById(id);
    if (!subscription) throw new NotFoundException('Subscription not found');
    return subscription;
  }

  async findActivePremiumForUser(userId: string) {
    const subscription =
      await this.subscriptionRepository.findActivePremiumForUser(userId);
    return subscription;
  }

  /**
   * Every user holding an active premium right now, flagged lifetime or not.
   * Exists for segment counting (admin path) — see the repository method.
   */
  async findAllActivePremiumUsers() {
    return this.subscriptionRepository.findAllActivePremiumUsers();
  }

  async createManual(dto: ManualSubscriptionDto) {
    if (!dto?.confirmPassword) {
      throw new BadRequestException('Confirm password is required');
    }

    const deletePassword = 'Meup123456@';
    if (dto.confirmPassword !== deletePassword) {
      throw new UnauthorizedException('Sai mật khẩu');
    }

    const purchaseTime = new Date(dto.purchaseTime);
    const expiryTimeInput =
      dto.expiryTime === undefined || dto.expiryTime === null
        ? null
        : new Date(dto.expiryTime);
    if (Number.isNaN(purchaseTime.getTime())) {
      throw new BadRequestException('Invalid purchaseTime');
    }

    const now = new Date();
    const qr = this.dataSource.createQueryRunner();
    await qr.connect();
    await qr.startTransaction();

    try {
      const product = await this.productRepository.findOne({
        productId: dto.productId,
      });
      const platform = product?.platform;
      const isLifetime = product?.type === ProductType.NON_CONSUMABLE;
      if (!platform) {
        throw new BadRequestException('Platform not found for product');
      }

      const expiryTime = isLifetime ? null : expiryTimeInput;
      if (expiryTime) {
        if (Number.isNaN(expiryTime.getTime())) {
          throw new BadRequestException('Invalid expiryTime');
        }
        if (expiryTime.getTime() <= purchaseTime.getTime()) {
          throw new BadRequestException('expiryTime must be after purchaseTime');
        }
      }

      const existingSub = await qr.manager.findOne(Subscription, {
        where: {
          userId: dto.userId,
          productId: dto.productId,
          platform,
        },
      });

      const anchorId = existingSub?.anchorId ?? `manual-${randomUUID()}`;
      const storeTransactionId = `manual-${randomUUID()}`;

      const purchase = await qr.manager.save(Purchase, {
        userId: dto.userId,
        userName: dto.userName,
        userEmail: dto.userEmail,
        platform,
        environment: dto.environment,
        productId: dto.productId,
        storeTransactionId,
        orderId: anchorId,
        purchaseTime,
        expiryTime,
        status: PurchaseStatus.PAID,
        processedAt: now,
        rawPrice: dto.rawPrice,
        currency: dto.currency,
        price: `${dto.currency} ${dto.rawPrice}`,
        rawPayload: JSON.stringify({ source: 'manual' }),
        isManual: true,
        statusHistory: [
          {
            at: now.toISOString(),
            status: PurchaseStatus.PAID,
            source: PurchaseHistorySource.MANUAL,
            purchaseTime: purchaseTime.toISOString(),
            expiryTime: expiryTime ? expiryTime.toISOString() : null,
          },
        ],
      });

      const status = resolveSubscriptionStatus(
        PurchaseStatus.PAID,
        expiryTime,
        now,
      );
      const baseSubPayload: Partial<Subscription> = {
        status,
        lastEventAt: now,
        lastVerifiedAt: now,
        currentPeriodStart: purchaseTime,
        currentPeriodEnd: expiryTime,
        environment: dto.environment,
        userName: dto.userName,
        userEmail: dto.userEmail,
        autoRenewing: false,
        isTrial: false,
        isManual: true,
      };

      const subscription = existingSub
        ? await qr.manager.save(Subscription, {
            ...existingSub,
            ...baseSubPayload,
          })
        : await qr.manager.save(Subscription, {
            userId: dto.userId,
            platform,
            productId: dto.productId,
            anchorId,
            ...baseSubPayload,
          });

      await qr.commitTransaction();

      return {
        subscriptionId: subscription.id,
        purchaseId: purchase.id,
        anchorId,
        storeTransactionId,
      };
    } catch (error) {
      await qr.rollbackTransaction();
      throw error;
    } finally {
      await qr.release();
    }
  }

  async remove(id: string, dto: DeleteSubscriptionDto) {
    if (!dto?.confirmPassword) {
      throw new BadRequestException('Confirm password is required');
    }

    const deletePassword = 'Meup123456@';
    if (dto.confirmPassword !== deletePassword) {
      throw new UnauthorizedException('Sai mật khẩu');
    }

    const subscription = await this.subscriptionRepository.findById(id);
    if (!subscription) throw new NotFoundException('Subscription not found');

    const qr = this.dataSource.createQueryRunner();
    await qr.connect();
    await qr.startTransaction();

    try {
      const anchorId = subscription.anchorId;

      const deletePurchasesQb = qr.manager
        .createQueryBuilder()
        .delete()
        .from(Purchase)
        .where('user_id = :userId', { userId: subscription.userId })
        .andWhere('product_id = :productId', {
          productId: subscription.productId,
        })
        .andWhere('platform = :platform', {
          platform: subscription.platform,
        })
        .andWhere(
          new Brackets(qb => {
            qb.where('order_id = :anchorId', { anchorId })
              .orWhere('order_id LIKE :anchorPrefix', {
                anchorPrefix: `${anchorId}%`,
              })
              .orWhere('store_transaction_id = :anchorId', { anchorId });
          }),
        );

      if (subscription.environment) {
        deletePurchasesQb.andWhere('environment = :environment', {
          environment: subscription.environment,
        });
      }

      const purchaseDeleteResult = await deletePurchasesQb.execute();

      await qr.manager.delete(Subscription, { id: subscription.id });

      await qr.commitTransaction();

      return {
        deletedSubscriptionId: subscription.id,
        deletedPurchases: purchaseDeleteResult.affected ?? 0,
      };
    } catch (error) {
      await qr.rollbackTransaction();
      throw error;
    } finally {
      await qr.release();
    }
  }

  async updateManual(id: string, dto: UpdateManualSubscriptionDto) {
    if (!dto?.confirmPassword) {
      throw new BadRequestException('Confirm password is required');
    }

    const deletePassword = 'Meup123456@';
    if (dto.confirmPassword !== deletePassword) {
      throw new UnauthorizedException('Sai mật khẩu');
    }

    const subscription = await this.subscriptionRepository.findById(id);
    if (!subscription) throw new NotFoundException('Subscription not found');
    if (!subscription.isManual) {
      throw new BadRequestException('Only manual subscriptions can be updated');
    }

    const product = await this.productRepository.findOne({
      productId: subscription.productId,
      platform: subscription.platform,
    });
    const isLifetime = product?.type === ProductType.NON_CONSUMABLE;
    const expiryTimeInput = isLifetime ? null : new Date(dto.expiryTime);
    if (expiryTimeInput && Number.isNaN(expiryTimeInput.getTime())) {
      throw new BadRequestException('Invalid expiryTime');
    }

    const qr = this.dataSource.createQueryRunner();
    await qr.connect();
    await qr.startTransaction();

    try {
      const now = new Date();
      const status = resolveSubscriptionStatus(
        PurchaseStatus.PAID,
        expiryTimeInput,
        now,
      );

      const manualPurchase = await qr.manager.findOne(Purchase, {
        where: { orderId: subscription.anchorId, isManual: true },
        order: {
          purchaseTime: 'DESC',
          processedAt: 'DESC',
          id: 'DESC',
        },
      });

      await qr.manager.update(
        Subscription,
        { id },
        {
          currentPeriodEnd: expiryTimeInput,
          status,
          lastEventAt: now,
          lastVerifiedAt: now,
        },
      );

      const purchaseUpdate: Partial<Purchase> = {
        expiryTime: expiryTimeInput,
        status: PurchaseStatus.PAID,
        processedAt: now,
      };

      if (dto.rawPrice !== undefined) {
        purchaseUpdate.rawPrice = dto.rawPrice;
        if (manualPurchase?.currency) {
          purchaseUpdate.currency = manualPurchase.currency;
          purchaseUpdate.price = `${manualPurchase.currency} ${dto.rawPrice}`;
        }
      }

      await qr.manager
        .createQueryBuilder()
        .update(Purchase)
        .set(purchaseUpdate)
        .where('order_id = :orderId', { orderId: subscription.anchorId })
        .andWhere('is_manual = :isManual', { isManual: true })
        .execute();

      await qr.commitTransaction();

      return {
        subscriptionId: id,
        newExpiryTime: expiryTimeInput
          ? expiryTimeInput.toISOString()
          : null,
      };
    } catch (error) {
      await qr.rollbackTransaction();
      throw error;
    } finally {
      await qr.release();
    }
  }

  private startManualStatusJob() {
    const intervalMs = 5 * 60 * 1000;
    const run = async () => {
      try {
        const now = new Date();
        await this.subscriptionRepository
          .getRepo()
          .createQueryBuilder()
          .update(Subscription)
          .set({
            status: SubscriptionStatus.EXPIRED,
            lastEventAt: now,
            lastVerifiedAt: now,
          })
          .where('is_manual = :isManual', { isManual: true })
          .andWhere('current_period_end <= :now', { now })
          .andWhere('status != :expired', {
            expired: SubscriptionStatus.EXPIRED,
          })
          .execute();
      } catch (error) {
        this.logger.error(
          'Manual subscription status job failed',
          (error as Error)?.stack,
        );
      }
    };

    void run();
    this.manualStatusTimer = setInterval(() => void run(), intervalMs);
  }
}
