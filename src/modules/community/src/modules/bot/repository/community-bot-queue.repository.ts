import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { OrderType } from '@utils/type/orderByType';

import { GetCommunityBotQueueDto } from '../dto/get-community-bot-queue.dto';
import {
  CommunityBotKind,
  CommunityBotQueueStatus,
} from '../enum/community-bot.enum';
import { CommunityBotQueue } from '../schema/community-bot-queue.schema';

@Injectable()
export class CommunityBotQueueRepository extends AbstractRepository<CommunityBotQueue> {
  protected readonly logger = new Logger(CommunityBotQueueRepository.name);

  constructor(
    @InjectModel(CommunityBotQueue.name) model: Model<CommunityBotQueue>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Insert a burst, tolerating the slotKey collision that means somebody got
   * here first.
   *
   * `ordered: false` so one duplicate does not abandon the rest of the burst,
   * and a duplicate-key error (11000) is swallowed: it is not a failure, it is
   * the concurrency guard doing its job.
   */
  async insertBurst(rows: Partial<CommunityBotQueue>[]): Promise<number> {
    if (!rows.length) return 0;

    try {
      const inserted = await this.model.insertMany(rows, { ordered: false });

      return inserted.length;
    } catch (error: any) {
      if (error?.code === 11000 || error?.writeErrors) {
        return error?.insertedDocs?.length ?? 0;
      }
      throw error;
    }
  }

  async findDue(now: Date, cap: number): Promise<CommunityBotQueue[]> {
    return this.model
      .find({ status: CommunityBotQueueStatus.PENDING, dueAt: { $lte: now } })
      .sort({ dueAt: 1 })
      .limit(cap)
      .lean() as unknown as CommunityBotQueue[];
  }

  async markSent(id: string, resultId: string) {
    return this.updateOne(
      { _id: id } as any,
      {
        $set: {
          status: CommunityBotQueueStatus.SENT,
          resultId,
          publishedAt: new Date(),
          updatedAt: new Date(),
        },
      },
    );
  }

  async markFailed(id: string, error: string) {
    return this.updateOne(
      { _id: id } as any,
      {
        $set: {
          status: CommunityBotQueueStatus.FAILED,
          error: error.slice(0, 500),
          updatedAt: new Date(),
        },
      },
    );
  }

  async markCancelled(id: string, reason?: string) {
    return this.updateOne(
      { _id: id } as any,
      {
        $set: {
          status: CommunityBotQueueStatus.CANCELLED,
          error: reason?.slice(0, 500),
          updatedAt: new Date(),
        },
      },
    );
  }

  /** Lines this kind has already PUBLISHED since `since` — the daily ceiling. */
  async countSentSince(kind: CommunityBotKind, since: Date): Promise<number> {
    return this.model.countDocuments({
      kind,
      status: CommunityBotQueueStatus.SENT,
      publishedAt: { $gte: since },
    });
  }

  /**
   * Posts this run cycle has already queued a comment for.
   *
   * Read across every status, not just SENT: a line still waiting in the queue
   * has already claimed its post, and planning the same post twice is how one
   * thread ends up with two strangers saying near-identical things.
   */
  async findClaimedPostIds(since: Date): Promise<string[]> {
    return this.model.distinct('postId', {
      kind: CommunityBotKind.COMMENT,
      createdAt: { $gte: since },
      postId: { $exists: true },
      status: {
        $in: [CommunityBotQueueStatus.PENDING, CommunityBotQueueStatus.SENT],
      },
    }) as unknown as string[];
  }

  async page(dto: GetCommunityBotQueueDto) {
    const where: Record<string, unknown> = {};
    if (dto.status) where.status = dto.status;
    if (dto.kind) where.kind = dto.kind;
    if (dto.runId) where.runId = dto.runId;
    if (dto.roomId) where.roomId = dto.roomId;

    return this.paginateQuery<CommunityBotQueue>({
      where,
      orderBy: 'createdAt',
      order: OrderType.DESC,
      page: dto.page,
      take: dto.take,
    });
  }

  async findPendingById(id: string): Promise<CommunityBotQueue | null> {
    return this.model
      .findOne({ _id: id, status: CommunityBotQueueStatus.PENDING })
      .lean() as unknown as CommunityBotQueue | null;
  }

  async updatePending(
    id: string,
    data: Partial<CommunityBotQueue>,
  ): Promise<CommunityBotQueue | null> {
    return this.findOneAndUpdate(
      { _id: id, status: CommunityBotQueueStatus.PENDING } as any,
      { $set: { ...data, updatedAt: new Date() } },
    );
  }

  async findByRunId(runId: string): Promise<CommunityBotQueue[]> {
    return this.model
      .find({ runId })
      .lean() as unknown as CommunityBotQueue[];
  }
}
