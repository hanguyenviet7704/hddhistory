import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { FindOptionsWhere, Like, Repository } from 'typeorm';

import { AbstractRepository } from '@base/database/mysql/abstract.repository';

import { GetListDownloadLinkDto } from '../dto/get-download-link.dto';
import { DownloadLink } from '../entities/download-link.entity';

@Injectable()
export class DownloadLinkRepository extends AbstractRepository<DownloadLink> {
  constructor(
    @InjectRepository(DownloadLink) repository: Repository<DownloadLink>,
  ) {
    super(repository);
  }

  async findOption(dto: GetListDownloadLinkDto) {
    const { page, take, search, orderBy, order, isActive } = dto;

    const where: FindOptionsWhere<DownloadLink>[] = [];
    const baseCondition: FindOptionsWhere<DownloadLink> = {};
    if (isActive !== undefined) baseCondition.isActive = isActive;

    if (search) {
      where.push(
        { ...baseCondition, slug: Like(`%${search.toLowerCase()}%`) },
        { ...baseCondition, name: Like(`%${search}%`) },
      );
    } else {
      where.push(baseCondition);
    }

    const sortField = orderBy ?? 'createdAt';
    const sortDirection =
      (order?.toUpperCase() as 'ASC' | 'DESC') ?? ('DESC' as const);

    return this.paginateQuery<DownloadLink>({
      where,
      page,
      take,
      orderOptions: { [sortField]: sortDirection },
    });
  }

  async findBySlug(slug: string): Promise<DownloadLink | null> {
    return this.repository.findOne({ where: { slug } });
  }

  async findById(id: string): Promise<DownloadLink | null> {
    return this.repository.findOne({ where: { id } });
  }

  async updateById(
    id: string,
    data: Partial<DownloadLink>,
    userId?: string,
  ): Promise<void> {
    await this.repository.update(id, { ...data, updatedBy: userId });
  }

  /** Soft delete -- keeps the link's click history intact. */
  async softDeleteById(id: string): Promise<void> {
    await this.repository.softDelete(id);
  }

  /**
   * Total clicks per link, for the list screen. One grouped query instead of
   * N+1 counts, keyed by link id.
   */
  async countClicksByLinkIds(ids: string[]): Promise<Map<string, number>> {
    if (!ids.length) return new Map();

    const rows = await this.repository
      .createQueryBuilder('link')
      .select('link.id', 'id')
      .addSelect('COUNT(click.id)', 'total')
      .leftJoin(
        'app_download_link_clicks',
        'click',
        'click.link_id = link.id',
      )
      .where('link.id IN (:...ids)', { ids })
      .groupBy('link.id')
      .getRawMany<{ id: string; total: string }>();

    return new Map(rows.map((row) => [row.id, Number(row.total) || 0]));
  }
}
