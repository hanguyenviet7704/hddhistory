import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { FindOptionsWhere, In, Like, Repository } from 'typeorm';

import { AbstractRepository } from '@base/database/mysql/abstract.repository';

import { PaymentPlatform } from '../../enum/payment.enum';
import { GetListProductDto } from '../dto/get-product.dto';
import { Product } from '../entitys/product.entity';

@Injectable()
export class ProductRepository extends AbstractRepository<Product> {
  constructor(@InjectRepository(Product) repository: Repository<Product>) {
    super(repository);
  }

  async findOption(dto: GetListProductDto) {
    const {
      page,
      take,
      search,
      orderBy,
      order,
      type,
      platform,
      isActive,
      isAll,
    } = dto;

    const where: FindOptionsWhere<Product>[] = [];

    // Điều kiện AND chung
    const baseCondition: FindOptionsWhere<Product> = {};

    if (type) baseCondition.type = type;
    if (platform) baseCondition.platform = platform;
    if (!isAll && isActive !== undefined) baseCondition.isActive = isActive;

    // Nếu có search → tạo OR
    if (search) {
      where.push(
        {
          ...baseCondition,
          productId: Like(`%${search}%`),
        },
        {
          ...baseCondition,
          title: Like(`%${search}%`),
        },
      );
    }

    // Nếu không có search → chỉ dùng điều kiện AND
    if (!search) {
      where.push(baseCondition);
    }

    const sortField = orderBy ?? 'createdAt';
    const sortDirection =
      (order?.toUpperCase() as 'ASC' | 'DESC') ?? ('DESC' as const);

    return this.paginateQuery<Product>({
      where,
      page,
      take,
      orderOptions: {
        bestDeal: 'DESC',
        [sortField]: sortDirection,
      },
    });
  }

  /**
   * Lightweight (platform, productId) -> title + salePercent lookup for the
   * affiliate orders export (Part 5). The catalog is small, so one unfiltered
   * fetch is simpler and cheaper than an SQL join per request.
   *
   * `salePercent` rides along because the discount a buyer actually got is a
   * property of the PACKAGE (`meup_sub_1y_30off` is 30% off) far more often
   * than of a voucher — most codes discount by swapping to a cheaper SKU and
   * leave `iap_vouchers.discount_percent` empty.
   */
  async findAllForTitleLookup(): Promise<
    Pick<Product, 'platform' | 'productId' | 'title' | 'salePercent'>[]
  > {
    return this.repository.find({
      select: ['platform', 'productId', 'title', 'salePercent'],
    });
  }

  /**
   * Batch (platform, productId) -> Product for ACTIVE SKUs only, used when
   * resolving an affiliate voucher's discount tiers. One query instead of the
   * per-mapping `findOne` loop this replaced: a code can map several packages
   * at once and each needs both its base and target SKU.
   *
   * Active-only on purpose -- a retired SKU must not be offered, and a target
   * the store no longer lists blanks the Flutter paywall outright.
   */
  async findActiveByProductIds(
    platform: PaymentPlatform,
    productIds: string[],
  ): Promise<Product[]> {
    if (!productIds.length) return [];
    return this.repository.find({
      where: { platform, productId: In(productIds), isActive: true },
    });
  }

  /**
   * Every ACTIVE SKU on `platform` whose `compareAtProductId` is one of
   * `roots` — i.e. the discounted siblings of a full-price plan.
   *
   * Used to build a plan's whole family when a voucher swaps it. The family
   * matters because `compareAtProductId` names the FULL-PRICE reference, not
   * the SKU the paywall happens to be rendering: depending on cohort and
   * impression, the yearly slot can hold `meup_sub_1y`, `meup_sub_1y_20off` or
   * `meup_sub_1y_30off`. The client swaps by exact product id, so a voucher has
   * to offer a swap from every one of them or it silently does nothing for
   * whichever cohort is not covered.
   */
  async findActiveByCompareAtProductIds(
    platform: PaymentPlatform,
    roots: string[],
  ): Promise<Product[]> {
    if (!roots.length) return [];
    return this.repository.find({
      where: { platform, compareAtProductId: In(roots), isActive: true },
    });
  }

  /**
   * Unfiltered-by-default lookup used by the regional price sync (Part 2):
   * "which SKUs should we sync for this platform?" `onlyActive` is left on
   * for a broad sync (don't burn store API calls on retired SKUs) but off
   * when the caller named one exact `productId` -- staff explicitly asking
   * to sync one SKU should work even if it's currently inactive.
   */
  async findManyForSync(filter: {
    platform?: PaymentPlatform;
    productId?: string;
    onlyActive?: boolean;
  }): Promise<Product[]> {
    const where: FindOptionsWhere<Product> = {};
    if (filter.platform) where.platform = filter.platform;
    if (filter.productId) where.productId = filter.productId;
    if (filter.onlyActive) where.isActive = true;

    return this.repository.find({ where });
  }
}
