import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { OrderType } from '@utils/type/orderByType';

import {
  CommunityReportStatus,
  CommunityTargetType,
} from '../../../enum/community.enum';
import { GetListCommunityReportDto } from '../dto/get-list-community-report.dto';
import { CommunityReport } from '../schema/community-report.schema';

@Injectable()
export class CommunityReportRepository extends AbstractRepository<CommunityReport> {
  protected readonly logger = new Logger(CommunityReportRepository.name);

  constructor(
    @InjectModel(CommunityReport.name) model: Model<CommunityReport>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  // True when this reader had not already reported the item — the caller only
  // moves reportCount on a first report.
  async report(data: {
    targetType: CommunityTargetType;
    targetId: string;
    reporterId: string;
    reason: string;
    note?: string;
  }): Promise<boolean> {
    const result = await this.model.updateOne(
      {
        targetType: data.targetType,
        targetId: data.targetId,
        reporterId: data.reporterId,
      },
      {
        $setOnInsert: {
          ...data,
          status: CommunityReportStatus.PENDING,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      },
      { upsert: true },
    );
    return !!result.upsertedCount;
  }

  async findOption(dto: GetListCommunityReportDto) {
    const where: FilterQuery<CommunityReport> = {};
    if (dto.status) where.status = dto.status;
    if (dto.targetType) where.targetType = dto.targetType;
    if (dto.reason) where.reason = dto.reason;

    return this.paginateQuery<CommunityReport>({
      where,
      page: dto.page,
      take: dto.take,
      orderBy: dto.orderBy || 'createdAt',
      order: dto.order || OrderType.DESC,
    });
  }

  // When a moderator acts on one item, every pending report on it is closed
  // with the same verdict — otherwise the queue keeps showing work already done.
  async resolveAllForTarget(
    targetType: CommunityTargetType,
    targetId: string,
    status: CommunityReportStatus,
    moderatorId: string,
  ) {
    return this.model.updateMany(
      { targetType, targetId, status: CommunityReportStatus.PENDING },
      {
        $set: {
          status,
          resolvedBy: moderatorId,
          resolvedAt: new Date(),
          updatedAt: new Date(),
        },
      },
    );
  }

  async countPendingByTarget(
    targetType: CommunityTargetType,
    targetIds: string[],
  ): Promise<Map<string, number>> {
    if (!targetIds.length) return new Map();
    const rows = await this.model.aggregate<{ _id: string; count: number }>([
      {
        $match: {
          targetType,
          targetId: { $in: targetIds },
          status: CommunityReportStatus.PENDING,
        },
      },
      { $group: { _id: '$targetId', count: { $sum: 1 } } },
    ]);
    return new Map(rows.map((row) => [String(row._id), row.count]));
  }
}
