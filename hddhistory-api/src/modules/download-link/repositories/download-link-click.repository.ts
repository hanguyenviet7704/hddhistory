import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Between, DeepPartial, Repository } from 'typeorm';

import { AbstractRepository } from '@base/database/mysql/abstract.repository';

import { DownloadLinkClick } from '../entities/download-link-click.entity';

export interface ClickBucket {
  key: string;
  total: number;
}

@Injectable()
export class DownloadLinkClickRepository extends AbstractRepository<DownloadLinkClick> {
  constructor(
    @InjectRepository(DownloadLinkClick)
    repository: Repository<DownloadLinkClick>,
  ) {
    super(repository);
  }

  async record(data: DeepPartial<DownloadLinkClick>): Promise<void> {
    await this.repository.insert(
      this.repository.create(data) as DownloadLinkClick,
    );
  }

  async countInRange(linkId: string, from: Date, to: Date): Promise<number> {
    return this.repository.count({
      where: { linkId, clickedAt: Between(from, to) },
    });
  }

  /**
   * Distinct ip hashes in the range. Not "unique people" -- a shared NAT or a
   * changed mobile IP both blur it -- but it is the closest signal available
   * without storing anything personal.
   */
  async countUniqueInRange(
    linkId: string,
    from: Date,
    to: Date,
  ): Promise<number> {
    const row = await this.repository
      .createQueryBuilder('click')
      .select('COUNT(DISTINCT click.ip_hash)', 'total')
      .where('click.link_id = :linkId', { linkId })
      .andWhere('click.clicked_at BETWEEN :from AND :to', { from, to })
      .getRawOne<{ total: string }>();

    return Number(row?.total) || 0;
  }

  async groupByDay(
    linkId: string,
    from: Date,
    to: Date,
  ): Promise<ClickBucket[]> {
    return this.groupBy(linkId, from, to, 'DATE(click.clicked_at)');
  }

  async groupByPlatform(
    linkId: string,
    from: Date,
    to: Date,
  ): Promise<ClickBucket[]> {
    return this.groupBy(linkId, from, to, 'click.platform');
  }

  async groupByCountry(
    linkId: string,
    from: Date,
    to: Date,
  ): Promise<ClickBucket[]> {
    return this.groupBy(linkId, from, to, 'click.country');
  }

  async groupBySource(
    linkId: string,
    from: Date,
    to: Date,
  ): Promise<ClickBucket[]> {
    return this.groupBy(linkId, from, to, 'click.source');
  }

  private async groupBy(
    linkId: string,
    from: Date,
    to: Date,
    expression: string,
  ): Promise<ClickBucket[]> {
    const rows = await this.repository
      .createQueryBuilder('click')
      .select(expression, 'bucket')
      .addSelect('COUNT(click.id)', 'total')
      .where('click.link_id = :linkId', { linkId })
      .andWhere('click.clicked_at BETWEEN :from AND :to', { from, to })
      .groupBy('bucket')
      .orderBy('bucket', 'ASC')
      .getRawMany<{ bucket: string | Date | null; total: string }>();

    return rows.map((row) => ({
      key:
        row.bucket instanceof Date
          ? row.bucket.toISOString().slice(0, 10)
          : (row.bucket ?? 'unknown'),
      total: Number(row.total) || 0,
    }));
  }
}
