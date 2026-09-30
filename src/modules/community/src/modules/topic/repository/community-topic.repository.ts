import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { GetListCommunityTopicDto } from '../dto/get-list-community-topic.dto';
import { CommunityTopic } from '../schema/community-topic.schema';

@Injectable()
export class CommunityTopicRepository extends AbstractRepository<CommunityTopic> {
  protected readonly logger = new Logger(CommunityTopicRepository.name);

  constructor(
    @InjectModel(CommunityTopic.name) model: Model<CommunityTopic>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  // App catalogue: active topics in display order.
  async findActive(): Promise<CommunityTopic[]> {
    return this.model
      .find({ isActive: true })
      .sort({ sortOrder: 1, createdAt: 1 })
      .lean() as unknown as CommunityTopic[];
  }

  async findByIds(ids: string[]): Promise<CommunityTopic[]> {
    if (!ids.length) return [];
    return this.model
      .find({ _id: { $in: ids } })
      .lean() as unknown as CommunityTopic[];
  }

  // Admin table: includes inactive topics, searchable across all five locales.
  async findOption(dto: GetListCommunityTopicDto) {
    const { page, take, search, order, orderBy, isActive } = dto;
    const where: FilterQuery<CommunityTopic> = {};

    if (search?.trim()) {
      const escaped = search.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const rx = { $regex: escaped, $options: 'i' };
      where.$or = [
        { slug: rx },
        { 'name.en': rx },
        { 'name.vi': rx },
        { 'name.zh': rx },
        { 'name.ja': rx },
        { 'name.ko': rx },
      ];
    }
    if (isActive !== undefined) where.isActive = isActive;

    return this.paginateQuery<CommunityTopic>({
      where,
      page,
      take,
      orderBy: orderBy || 'sortOrder',
      order,
    });
  }

  // Locale-scoped counters live under stats.<locale>. $inc creates the nested
  // object on first use, so a brand-new locale needs no backfill.
  async bumpStat(
    topicId: string,
    locale: string,
    field: 'followers' | 'postsThisWeek',
    delta: number,
  ) {
    return this.model.updateOne(
      { _id: topicId },
      { $inc: { [`stats.${locale}.${field}`]: delta } },
    );
  }

  async resetWeeklyPostCounts() {
    return this.model.updateMany({}, [
      {
        $set: {
          stats: {
            $arrayToObject: {
              $map: {
                input: { $objectToArray: { $ifNull: ['$stats', {}] } },
                as: 'entry',
                in: {
                  k: '$$entry.k',
                  v: {
                    followers: { $ifNull: ['$$entry.v.followers', 0] },
                    postsThisWeek: 0,
                  },
                },
              },
            },
          },
        },
      },
    ]);
  }
}
