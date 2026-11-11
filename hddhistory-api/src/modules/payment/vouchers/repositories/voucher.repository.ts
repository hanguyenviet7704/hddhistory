import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DeepPartial, FindOptionsWhere, In, Like, Repository } from 'typeorm';

import { AbstractRepository } from '@base/database/mysql/abstract.repository';

import { GetListVoucherDto } from '../dto/get-voucher.dto';
import { Voucher } from '../entitys/voucher.entity';

@Injectable()
export class VoucherRepository extends AbstractRepository<Voucher> {
  constructor(@InjectRepository(Voucher) repository: Repository<Voucher>) {
    super(repository);
  }

  async findOption(dto: GetListVoucherDto) {
    const { page, take, search, orderBy, order, isActive } = dto;

    const where: FindOptionsWhere<Voucher>[] = [];
    const baseCondition: FindOptionsWhere<Voucher> = {};

    if (isActive !== undefined) baseCondition.isActive = isActive;

    if (search) {
      where.push(
        { ...baseCondition, code: Like(`%${search.toUpperCase()}%`) },
        { ...baseCondition, owner: Like(`%${search}%`) },
      );
    } else {
      where.push(baseCondition);
    }

    const sortField = orderBy ?? 'createdAt';
    const sortDirection =
      (order?.toUpperCase() as 'ASC' | 'DESC') ?? ('DESC' as const);

    return this.paginateQuery<Voucher>({
      where,
      page,
      take,
      orderOptions: { [sortField]: sortDirection },
    });
  }

  async findByCode(code: string): Promise<Voucher | null> {
    return this.repository.findOne({ where: { code } });
  }

  /**
   * Atomically increments usedCount (`UPDATE ... SET used_count = used_count
   * + 1`), so concurrent redemptions never lose an increment to a
   * read-modify-write race. Only call this for a genuinely new, non-renewal
   * purchase row -- see purchases/purchase.service.ts verify().
   */
  async incrementUsedCount(code: string): Promise<void> {
    await this.repository.increment({ code }, 'usedCount', 1);
  }

  async findExistingCodes(codes: string[]): Promise<string[]> {
    if (!codes.length) return [];
    const rows = await this.repository.find({
      where: { code: In(codes) },
      select: ['code'],
    });
    return rows.map((row) => row.code);
  }

  async createMany(
    data: DeepPartial<Voucher>[],
    userId?: string,
  ): Promise<Voucher[]> {
    const withAudit = data.map((item) => ({
      ...item,
      createdBy: userId,
      updatedBy: userId,
    }));
    const entities = this.repository.create(withAudit);
    return this.repository.save(entities);
  }
}
