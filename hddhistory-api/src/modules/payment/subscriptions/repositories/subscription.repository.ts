import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Brackets, FindOptionsWhere, Like, Repository } from 'typeorm';

import { AbstractRepository } from '@base/database/mysql/abstract.repository';

import {
  PaymentEnvironment,
  ProductType,
  SubscriptionStatus,
} from '../../enum/payment.enum';
import { Product } from '../../products/entitys/product.entity';
import { GetListSubscriptionDto } from '../dto/get-subscription.dto';
import { Subscription } from '../entities/subscription.entity';

@Injectable()
export class SubscriptionRepository extends AbstractRepository<Subscription> {
  constructor(
    @InjectRepository(Subscription) repository: Repository<Subscription>,
  ) {
    super(repository);
  }

  async findOption(
    dto: GetListSubscriptionDto,
    environment?: PaymentEnvironment,
  ) {
    const { page, take, search, orderBy, order, status, platform, userId } =
      dto;

    const where: FindOptionsWhere<Subscription>[] = [];

    // Điều kiện AND chung
    const baseCondition: FindOptionsWhere<Subscription> = {};

    if (status) baseCondition.status = status;
    if (platform) baseCondition.platform = platform;
    if (userId) baseCondition.userId = userId;
    if (environment) baseCondition.environment = environment;

    // Nếu có search → tạo OR
    if (search) {
      where.push(
        {
          ...baseCondition,
          productId: Like(`%${search}%`),
        },
        {
          ...baseCondition,
          userId: Like(`%${search}%`),
        },
      );
    }

    // Nếu không có search → chỉ dùng điều kiện AND
    if (!search) {
      where.push(baseCondition);
    }

    return this.paginateQuery<Subscription>({
      where,
      page,
      take,
      orderBy,
      order,
    });
  }

  async findByAnchor(anchorId: string) {
    return this.repository.findOne({ where: { anchorId } });
  }

  async findActivePremiumForUser(userId: string) {
    const now = new Date();

    const qb = this.repository
      .createQueryBuilder('s')
      .leftJoin(
        Product,
        'p',
        'p.productId = s.productId AND p.platform = s.platform',
      )
      .where('s.userId = :userId', { userId })
      .andWhere('s.status IN (:...statuses)', {
        statuses: [
          SubscriptionStatus.ACTIVE,
          SubscriptionStatus.GRACE,
          SubscriptionStatus.ON_HOLD,
        ],
      })
      .andWhere(
        new Brackets(qb => {
          qb.where('s.status = :activeStatus', {
            activeStatus: SubscriptionStatus.ACTIVE,
          })
            .orWhere('s.currentPeriodEnd > :now', { now })
            .orWhere(
              '(s.currentPeriodEnd IS NULL AND p.type = :lifetimeType)',
              { lifetimeType: ProductType.NON_CONSUMABLE },
            );
        }),
      );

    return qb
      .orderBy('CASE WHEN s.currentPeriodEnd IS NULL THEN 1 ELSE 0 END', 'DESC')
      .addOrderBy('s.currentPeriodEnd', 'DESC')
      .addOrderBy('s.lastEventAt', 'DESC')
      .getOne();
  }

  /**
   * Every user holding an active premium right now, with whether it is a
   * lifetime unlock — the same activity rules as [[findActivePremiumForUser]],
   * grouped per user.
   *
   * Exists for SEGMENT counting (the admin's "how many users match" number),
   * which needs the whole premium population at once: per-user lookups would be
   * one MySQL round-trip per Mongo user. Admin-path only — the serve path keeps
   * using the single-user query.
   */
  async findAllActivePremiumUsers(): Promise<
    Array<{ userId: string; lifetime: boolean }>
  > {
    const now = new Date();

    const rows = await this.repository
      .createQueryBuilder('s')
      .leftJoin(
        Product,
        'p',
        'p.productId = s.productId AND p.platform = s.platform',
      )
      .select('s.userId', 'userId')
      .addSelect(
        'MAX(CASE WHEN s.currentPeriodEnd IS NULL AND p.type = :lifetimeType THEN 1 ELSE 0 END)',
        'lifetime',
      )
      .where('s.status IN (:...statuses)', {
        statuses: [
          SubscriptionStatus.ACTIVE,
          SubscriptionStatus.GRACE,
          SubscriptionStatus.ON_HOLD,
        ],
      })
      .andWhere(
        new Brackets(qb => {
          qb.where('s.status = :activeStatus', {
            activeStatus: SubscriptionStatus.ACTIVE,
          })
            .orWhere('s.currentPeriodEnd > :now', { now })
            .orWhere(
              '(s.currentPeriodEnd IS NULL AND p.type = :lifetimeType)',
              { lifetimeType: ProductType.NON_CONSUMABLE },
            );
        }),
      )
      .setParameter('lifetimeType', ProductType.NON_CONSUMABLE)
      .groupBy('s.userId')
      .getRawMany<{ userId: string; lifetime: string | number }>();

    return rows.map(row => ({
      userId: row.userId,
      lifetime: Number(row.lifetime) === 1,
    }));
  }
}
