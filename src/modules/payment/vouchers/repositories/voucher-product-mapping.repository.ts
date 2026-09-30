import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DeepPartial, Repository } from 'typeorm';

import { AbstractRepository } from '@base/database/mysql/abstract.repository';

import { PaymentPlatform } from '../../enum/payment.enum';
import { VoucherProductMapping } from '../entitys/voucher-product-mapping.entity';

@Injectable()
export class VoucherProductMappingRepository extends AbstractRepository<VoucherProductMapping> {
  constructor(
    @InjectRepository(VoucherProductMapping)
    repository: Repository<VoucherProductMapping>,
  ) {
    super(repository);
  }

  async findByVoucherId(voucherId: string): Promise<VoucherProductMapping[]> {
    return this.repository.find({ where: { voucherId } });
  }

  async findByVoucherIdAndPlatform(
    voucherId: string,
    platform: PaymentPlatform,
  ): Promise<VoucherProductMapping[]> {
    return this.repository.find({ where: { voucherId, platform } });
  }

  async deleteByVoucherId(voucherId: string) {
    return this.repository.delete({ voucherId });
  }

  async createMany(
    data: DeepPartial<VoucherProductMapping>[],
    userId?: string,
  ): Promise<VoucherProductMapping[]> {
    const withAudit = data.map((item) => ({
      ...item,
      createdBy: userId,
      updatedBy: userId,
    }));
    const entities = this.repository.create(withAudit);
    return this.repository.save(entities);
  }
}
