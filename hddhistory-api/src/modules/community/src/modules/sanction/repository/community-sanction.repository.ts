import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { OrderType } from '@utils/type/orderByType';

import { CommunitySanction } from '../schema/community-sanction.schema';

@Injectable()
export class CommunitySanctionRepository extends AbstractRepository<CommunitySanction> {
  protected readonly logger = new Logger(CommunitySanctionRepository.name);

  constructor(
    @InjectModel(CommunitySanction.name) model: Model<CommunitySanction>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  // The sanction in force right now: not revoked, and either indefinite
  // (mutedUntil unset) or still inside its window.
  async findActive(userId: string, now: Date): Promise<CommunitySanction | null> {
    return this.model
      .findOne({
        userId,
        revokedAt: null,
        $or: [{ mutedUntil: null }, { mutedUntil: { $gt: now } }],
      })
      .sort({ createdAt: -1 })
      .lean() as unknown as CommunitySanction | null;
  }

  // Every sanction ever applied to one reader, newest first — the violation
  // history a moderator reads before choosing the next duration.
  async historyFor(userId: string): Promise<CommunitySanction[]> {
    return this.model
      .find({ userId })
      .sort({ createdAt: -1 })
      .lean() as unknown as CommunitySanction[];
  }

  async listPage(params: { page?: number; take?: number; userId?: string }) {
    return this.paginateQuery<CommunitySanction>({
      where: params.userId ? { userId: params.userId } : {},
      page: params.page,
      take: params.take,
      orderBy: 'createdAt',
      order: OrderType.DESC,
    });
  }

  async revoke(id: string, moderatorId: string) {
    return this.model.updateOne(
      { _id: id, revokedAt: null },
      {
        $set: {
          revokedAt: new Date(),
          revokedByUserId: moderatorId,
          updatedAt: new Date(),
        },
      },
    );
  }
}
