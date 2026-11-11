import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import {
  Between,
  FindOptionsWhere,
  In,
  Like,
  LessThanOrEqual,
  MoreThanOrEqual,
  Repository,
  SelectQueryBuilder,
} from 'typeorm';

import { AbstractRepository } from '@base/database/mysql/abstract.repository';

import {
  PaymentEnvironment,
  PaymentPlatform,
  PurchaseStatus,
} from '../../enum/payment.enum';
import { GetListPurchaseDto } from '../dto/get-purchase.dto';
import { GetRevenueListDto } from '../dto/get-revenue-list.dto';
import { RevenueStatisticsResponse } from '../dto/revenue-statistics.response';
import { Purchase } from '../entities/purchase.entity';

@Injectable()
export class PurchaseRepository extends AbstractRepository<Purchase> {
  constructor(@InjectRepository(Purchase) repository: Repository<Purchase>) {
    super(repository);
  }

  async findOption(dto: GetListPurchaseDto, environment?: PaymentEnvironment) {
    const { page, take, search, orderBy, order, platform, status } = dto;

    const where: FindOptionsWhere<Purchase>[] = [];

    // Điều kiện AND chung
    const baseCondition: FindOptionsWhere<Purchase> = {};

    if (status) baseCondition.status = status;
    if (platform) baseCondition.platform = platform;
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
          storeTransactionId: Like(`%${search}%`),
        },
        {
          ...baseCondition,
          orderId: Like(`%${search}%`),
        },
      );
    }

    // Nếu không có search → chỉ dùng điều kiện AND
    if (!search) {
      where.push(baseCondition);
    }

    return this.paginateQuery<Purchase>({
      where,
      page,
      take,
      orderBy,
      order,
    });
  }

  async findByIdempotency(id: string) {
    return this.repository.findOne({ where: { idempotencyKey: id } });
  }

  async findByTransaction(id: string) {
    return this.repository.findOne({ where: { storeTransactionId: id } });
  }

  async findByOrder(orderId: string) {
    return this.repository.findOne({ where: { orderId } });
  }

  async findByUser(userId: string) {
    return this.repository.find({ where: { userId } });
  }

  /**
   * Count of this user's PAID purchases already carrying this voucher code --
   * used to enforce Voucher.perUserLimit. Only PAID counts as a genuine
   * redemption (pending/failed/canceled/refunded do not consume the cap).
   */
  async countPaidByUserAndVoucherCode(
    userId: string,
    voucherCode: string,
  ): Promise<number> {
    return this.repository.count({
      where: { userId, voucherCode, status: PurchaseStatus.PAID },
    });
  }

  /**
   * Affiliate orders export (Part 5): all purchases whose purchaseTime falls
   * in [startDate, endDate], newest-range-independent (ascending by time),
   * paginated via take/skip. No other filtering -- the affiliate contract
   * maps every row (voucher or not, any status) through `status`/`discount`.
   */
  async findAffiliateOrders(args: {
    startDate: Date;
    endDate: Date;
    take: number;
    skip: number;
  }): Promise<Purchase[]> {
    return this.repository.find({
      where: { purchaseTime: Between(args.startDate, args.endDate) },
      order: { purchaseTime: 'ASC', id: 'ASC' },
      take: args.take,
      skip: args.skip,
    });
  }

  async findBySubscriptionScope(args: {
    userId: string;
    productId: string;
    platform: PaymentPlatform;
    environment?: PaymentEnvironment;
  }) {
    const where: FindOptionsWhere<Purchase> = {
      userId: args.userId,
      productId: args.productId,
      platform: args.platform,
    };
    if (args.environment) where.environment = args.environment;
    return this.repository.find({
      where,
      order: { purchaseTime: 'DESC', processedAt: 'DESC', id: 'DESC' },
    });
  }

  /**
   * Orders and revenue attributed to one LogicSale campaign, per plan and
   * currency — the numbers behind the admin's "Statistics" block on a
   * LogicSale row.
   *
   * Same status universe as [[getRevenueStatistics]]: PAID counts as an order
   * and as revenue, REFUNDED is summed separately so the panel can show net.
   * Grouped by currency because rawPrice sums across currencies are fiction.
   * Renewals never carry a logicSaleId (see the verify insert), so these are
   * first-purchase numbers by construction.
   */
  async logicSaleStats(logicSaleId: string): Promise<
    Array<{
      productId: string;
      currency: string | null;
      orders: number;
      paidRevenue: number;
      refundedRevenue: number;
    }>
  > {
    const rows = await this.repository
      .createQueryBuilder('p')
      .select('p.productId', 'productId')
      .addSelect('p.currency', 'currency')
      .addSelect('COUNT(CASE WHEN p.status = :paid THEN 1 END)', 'orders')
      .addSelect(
        'COALESCE(SUM(CASE WHEN p.status = :paid THEN p.rawPrice ELSE 0 END),0)',
        'paidRevenue',
      )
      .addSelect(
        'COALESCE(SUM(CASE WHEN p.status = :refunded THEN p.rawPrice ELSE 0 END),0)',
        'refundedRevenue',
      )
      .where('p.logicSaleId = :logicSaleId', { logicSaleId })
      .andWhere('p.status IN (:...statuses)', {
        statuses: [PurchaseStatus.PAID, PurchaseStatus.REFUNDED],
        paid: PurchaseStatus.PAID,
        refunded: PurchaseStatus.REFUNDED,
      })
      .groupBy('p.productId')
      .addGroupBy('p.currency')
      .orderBy('p.productId', 'ASC')
      .addOrderBy('p.currency', 'ASC')
      .getRawMany();

    return rows.map(row => ({
      productId: String(row.productId),
      currency: row.currency ?? null,
      orders: Number(row.orders ?? 0),
      paidRevenue: Number(row.paidRevenue ?? 0),
      refundedRevenue: Number(row.refundedRevenue ?? 0),
    }));
  }

  /**
   * Verified orders and revenue per ARM of one paywall body A/B run, per
   * currency — the numbers behind the experiment readout.
   *
   * Deliberately the same status universe and the same per-currency grouping
   * as [[logicSaleStats]]: an experiment scored on a different definition of
   * "a sale" than the rest of the panel would invite two answers to one
   * question. Buyers are counted DISTINCT as well as orders, because the arms
   * are sized in people and a conversion rate over orders would quietly reward
   * whichever arm happened to catch a repeat buyer.
   */
  async paywallExperimentStats(experimentKey: string): Promise<
    Array<{
      variant: string;
      currency: string | null;
      orders: number;
      buyers: number;
      paidRevenue: number;
      refundedRevenue: number;
    }>
  > {
    const rows = await this.repository
      .createQueryBuilder('p')
      .select('p.paywallBodyVariant', 'variant')
      .addSelect('p.currency', 'currency')
      .addSelect('COUNT(CASE WHEN p.status = :paid THEN 1 END)', 'orders')
      .addSelect(
        'COUNT(DISTINCT CASE WHEN p.status = :paid THEN p.createdBy END)',
        'buyers',
      )
      .addSelect(
        'COALESCE(SUM(CASE WHEN p.status = :paid THEN p.rawPrice ELSE 0 END),0)',
        'paidRevenue',
      )
      .addSelect(
        'COALESCE(SUM(CASE WHEN p.status = :refunded THEN p.rawPrice ELSE 0 END),0)',
        'refundedRevenue',
      )
      .where('p.paywallExperimentKey = :experimentKey', { experimentKey })
      .andWhere('p.status IN (:...statuses)', {
        statuses: [PurchaseStatus.PAID, PurchaseStatus.REFUNDED],
        paid: PurchaseStatus.PAID,
        refunded: PurchaseStatus.REFUNDED,
      })
      .groupBy('p.paywallBodyVariant')
      .addGroupBy('p.currency')
      .orderBy('p.paywallBodyVariant', 'ASC')
      .addOrderBy('p.currency', 'ASC')
      .getRawMany();

    return rows.map(row => ({
      variant: String(row.variant ?? ''),
      currency: row.currency ?? null,
      orders: Number(row.orders ?? 0),
      buyers: Number(row.buyers ?? 0),
      paidRevenue: Number(row.paidRevenue ?? 0),
      refundedRevenue: Number(row.refundedRevenue ?? 0),
    }));
  }

  async getRevenueStatistics(
    dto: GetRevenueListDto,
    environment?: PaymentEnvironment,
  ): Promise<RevenueStatisticsResponse> {
    const statuses = [PurchaseStatus.PAID, PurchaseStatus.REFUNDED];

    const qb: SelectQueryBuilder<Purchase> = this.repository
      .createQueryBuilder('p')
      .select(
        'COALESCE(SUM(CASE WHEN p.status = :paid THEN p.rawPrice ELSE 0 END),0)',
        'totalRevenue',
      )
      .addSelect(
        'COALESCE(SUM(CASE WHEN p.status = :refunded THEN p.rawPrice ELSE 0 END),0)',
        'refundedRevenue',
      )
      .addSelect('p.currency', 'currency')
      .addSelect('COUNT(*)', 'totalPurchases')
      .where('p.status IN (:...statuses)', {
        statuses,
        paid: PurchaseStatus.PAID,
        refunded: PurchaseStatus.REFUNDED,
      });

    if (dto.platform) {
      qb.andWhere('p.platform = :platform', { platform: dto.platform });
    }

    if (environment) {
      qb.andWhere('p.environment = :environment', { environment });
    }

    if (dto.currency) {
      qb.andWhere('p.currency = :currency', { currency: dto.currency });
    }

    if (dto.productId) {
      qb.andWhere('p.productId = :productId', { productId: dto.productId });
    }

    if (dto.eventType) {
      qb.andWhere('p.eventType = :eventType', { eventType: dto.eventType });
    }

    if (dto.from) {
      qb.andWhere('p.purchaseTime >= :from', { from: dto.from });
    }

    if (dto.to) {
      qb.andWhere('p.purchaseTime <= :to', { to: dto.to });
    }

    qb.groupBy('p.currency').orderBy('p.currency', 'ASC');

    const rows = await qb.getRawMany();

    return {
      items: rows.map(row => ({
        currency: row?.currency ?? null,
        totalRevenue: Number(row?.totalRevenue ?? 0),
        refundedRevenue: Number(row?.refundedRevenue ?? 0),
        totalPurchases: Number(row?.totalPurchases ?? 0),
      })),
    };
  }

  async getRevenueEntries(
    dto: GetRevenueListDto,
    environment?: PaymentEnvironment,
  ) {
    const {
      platform,
      productId,
      from,
      to,
      search,
      eventType,
      currency,
      order,
      orderBy,
      page,
      take,
    } = dto;

    const fromDate = from ? new Date(from) : undefined;
    const toDate = to ? new Date(to) : undefined;
    const baseCondition: FindOptionsWhere<Purchase> = {
      status: In([PurchaseStatus.PAID, PurchaseStatus.REFUNDED]),
    };

    if (platform) baseCondition.platform = platform;
    if (productId) baseCondition.productId = productId;
    if (environment) baseCondition.environment = environment;
    if (eventType) baseCondition.eventType = eventType;
    if (currency) baseCondition.currency = currency;

    if (fromDate && toDate) {
      baseCondition.purchaseTime = Between(fromDate, toDate);
    } else if (fromDate) {
      baseCondition.purchaseTime = MoreThanOrEqual(fromDate);
    } else if (toDate) {
      baseCondition.purchaseTime = LessThanOrEqual(toDate);
    }

    const where: FindOptionsWhere<Purchase>[] = [];

    if (search) {
      where.push(
        { ...baseCondition, productId: Like(`%${search}%`) },
        { ...baseCondition, storeTransactionId: Like(`%${search}%`) },
        { ...baseCondition, orderId: Like(`%${search}%`) },
      );
    } else {
      where.push(baseCondition);
    }

    return this.paginateQuery<Purchase>({
      where,
      page,
      take,
      order,
      orderBy: orderBy ?? 'createdAt',
    });
  }
}
