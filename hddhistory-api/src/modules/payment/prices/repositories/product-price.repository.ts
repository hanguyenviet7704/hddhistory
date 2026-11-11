import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { FindOptionsWhere, In, Repository } from 'typeorm';

import { AbstractRepository } from '@base/database/mysql/abstract.repository';

import { PaymentPlatform } from '../../enum/payment.enum';
import { GetProductPriceDto } from '../dto/get-product-price.dto';
import { ProductPrice } from '../entitys/product-price.entity';

@Injectable()
export class ProductPriceRepository extends AbstractRepository<ProductPrice> {
  constructor(
    @InjectRepository(ProductPrice) repository: Repository<ProductPrice>,
  ) {
    super(repository);
  }

  async findByFilter(dto: GetProductPriceDto): Promise<ProductPrice[]> {
    const where: FindOptionsWhere<ProductPrice> = {};
    if (dto.productId) where.productId = dto.productId;
    if (dto.platform) where.platform = dto.platform;

    const territories = (dto.territories ?? '')
      .split(',')
      .map(code => code.trim().toUpperCase())
      .filter(Boolean);
    if (territories.length) where.territory = In(territories);

    return this.repository.find({
      where,
      order: { productId: 'ASC', platform: 'ASC', territory: 'ASC' },
    });
  }

  /**
   * Upserts one synced row, keyed on (productId, platform, territory) -- the
   * same triple the DB enforces via a unique index (see the migration).
   * Plain find-then-write rather than a native `INSERT ... ON DUPLICATE KEY`
   * to keep this consistent with the rest of the repo's simple TypeORM style;
   * this only runs on a manual/daily sync, never a request hot path.
   */
  async upsertRow(
    row: {
      productId: string;
      platform: PaymentPlatform;
      territory: string;
      currency: string;
      customerPrice: number;
      source: PaymentPlatform;
      syncedAt: Date;
    },
    userId?: string,
  ): Promise<void> {
    const existing = await this.repository.findOne({
      where: {
        productId: row.productId,
        platform: row.platform,
        territory: row.territory,
      },
    });

    if (existing) {
      await this.repository.update(
        { id: existing.id },
        { ...row, updatedBy: userId },
      );
      return;
    }

    await this.repository.save(
      this.repository.create({
        ...row,
        createdBy: userId,
        updatedBy: userId,
      }),
    );
  }
}
