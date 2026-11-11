import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CommunityChatMembership } from '../schema/community-chat-membership.schema';

@Injectable()
export class CommunityChatMembershipRepository extends AbstractRepository<CommunityChatMembership> {
  protected readonly logger = new Logger(
    CommunityChatMembershipRepository.name,
  );

  constructor(
    @InjectModel(CommunityChatMembership.name)
    model: Model<CommunityChatMembership>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async find(roomId: string, userId: string) {
    return this.model
      .findOne({ roomId, userId })
      .lean() as unknown as CommunityChatMembership | null;
  }

  /**
   * The presence heartbeat. Upserted so a member's first visit creates the row.
   *
   * [readUpTo] is passed when the reader is looking AT the room, which is the
   * only moment "read" can be claimed truthfully — a heartbeat from the feed
   * must not clear their unread badge.
   */
  async touch(roomId: string, userId: string, readUpTo?: Date) {
    const now = new Date();
    const set: Record<string, Date> = { lastSeenAt: now, updatedAt: now };
    if (readUpTo) set.lastReadAt = readUpTo;

    return this.model.updateOne(
      { roomId, userId },
      { $set: set, $setOnInsert: { roomId, userId, createdAt: now } },
      { upsert: true },
    );
  }

  /**
   * The membership rows for a set of users in one room, in ONE query.
   *
   * The push fan-out needs every recipient's read and presence state at once;
   * asking per user would be one round trip per participant on a write path a
   * reader is waiting through.
   */
  async findManyForRoom(roomId: string, userIds: string[]) {
    if (!userIds.length) return [];

    return this.model
      .find({ roomId, userId: { $in: userIds } })
      .lean() as unknown as CommunityChatMembership[];
  }

  // "N đang online": members whose heartbeat is inside the window.
  async countActiveSince(roomId: string, since: Date) {
    return this.model.countDocuments({ roomId, lastSeenAt: { $gte: since } });
  }

  /**
   * The newest `lastReadAt` among everyone EXCEPT [userId] — what turns the
   * writer's own message into "Đã xem". Their own read state cannot vouch for
   * anyone having seen it.
   */
  async lastReadByOthers(roomId: string, userId: string): Promise<Date | null> {
    const rows = await this.model
      .find({ roomId, userId: { $ne: userId }, lastReadAt: { $ne: null } })
      .sort({ lastReadAt: -1 })
      .limit(1)
      .lean();

    return (rows[0] as unknown as CommunityChatMembership)?.lastReadAt ?? null;
  }
}
