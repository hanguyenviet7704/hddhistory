import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { OrderType } from '@utils/type/orderByType';

import {
  CommunityAuthorType,
  CommunityContentStatus,
} from '../../../enum/community.enum';
import { communityTake } from '../../../helper/community-limit.helper';
import { GetListCommunityChatDto } from '../dto/get-list-community-chat.dto';
import { CommunityChatMessage } from '../schema/community-chat-message.schema';

@Injectable()
export class CommunityChatMessageRepository extends AbstractRepository<CommunityChatMessage> {
  protected readonly logger = new Logger(CommunityChatMessageRepository.name);

  constructor(
    @InjectModel(CommunityChatMessage.name) model: Model<CommunityChatMessage>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * One room's transcript, NEWEST first.
   *
   * Newest-first is what pagination needs — page 1 is the bottom of the screen
   * and page 2 is older history above it. The client reverses each page to draw
   * it; sorting oldest-first here would mean page 1 is the start of the room's
   * whole history, which is the wrong end to open on.
   */
  async page(params: {
    roomId: string;
    excludeIds?: string[];
    page?: number;
    take?: number;
  }) {
    const where: FilterQuery<CommunityChatMessage> = {
      roomId: params.roomId,
      status: CommunityContentStatus.VISIBLE,
    };
    if (params.excludeIds?.length) {
      where._id = { $nin: params.excludeIds };
    }

    return this.paginateQuery<CommunityChatMessage>({
      where,
      page: params.page,
      take: communityTake(params.take),
      orderBy: 'createdAt',
      order: OrderType.DESC,
    });
  }

  /**
   * The room's pinned lines, newest PIN first.
   *
   * Capped rather than paginated: the bar draws the first one and the sheet
   * lists the rest, and a room whose admins have pinned more than [cap] lines
   * has a moderation problem, not a paging problem.
   */
  async pinnedForRoom(roomId: string, cap: number): Promise<CommunityChatMessage[]> {
    return this.model
      .find({
        roomId,
        status: CommunityContentStatus.VISIBLE,
        pinnedAt: { $exists: true },
      })
      .sort({ pinnedAt: -1 })
      .limit(cap)
      .lean() as unknown as CommunityChatMessage[];
  }

  // Idempotent on purpose: pinning what is already pinned must not move it to
  // the top of the bar, or a double tap would reorder the room's pins.
  async pin(messageId: string, adminId: string) {
    return this.model.updateOne(
      { _id: messageId, pinnedAt: { $exists: false } },
      { $set: { pinnedAt: new Date(), pinnedBy: adminId } },
    );
  }

  async unpin(messageId: string) {
    return this.model.updateOne(
      { _id: messageId },
      { $unset: { pinnedAt: '', pinnedBy: '' } },
    );
  }

  /**
   * The [take] messages at or before [anchor], newest first — the anchor
   * included.
   *
   * Paired with [newerThan] to build the window a jump lands in. Split in two
   * queries rather than one `$or`: each half runs straight down the
   * {roomId, status, createdAt} index in its own direction, which a combined
   * query cannot do.
   */
  async olderThanOrAt(roomId: string, anchor: Date, take: number) {
    return this.model
      .find({
        roomId,
        status: CommunityContentStatus.VISIBLE,
        createdAt: { $lte: anchor },
      })
      .sort({ createdAt: -1 })
      .limit(take)
      .lean() as unknown as Promise<CommunityChatMessage[]>;
  }

  /** The [take] messages after [anchor], OLDEST first. */
  async newerThan(roomId: string, anchor: Date, take: number) {
    return this.model
      .find({
        roomId,
        status: CommunityContentStatus.VISIBLE,
        createdAt: { $gt: anchor },
      })
      .sort({ createdAt: 1 })
      .limit(take)
      .lean() as unknown as Promise<CommunityChatMessage[]>;
  }

  async findVisibleById(id: string): Promise<CommunityChatMessage | null> {
    return this.model
      .findOne({ _id: id, status: CommunityContentStatus.VISIBLE })
      .lean() as unknown as CommunityChatMessage | null;
  }

  /**
   * Messages in the room since [since] that the reader did not write — what the
   * FAB's badge counts. Their own message arriving back is not news to them.
   */
  async countUnread(roomId: string, userId: string, since?: Date) {
    const where: FilterQuery<CommunityChatMessage> = {
      roomId,
      status: CommunityContentStatus.VISIBLE,
      authorId: { $ne: userId },
    };
    if (since) where.createdAt = { $gt: since };

    return this.model.countDocuments(where);
  }

  /**
   * Everyone who has WRITTEN in this room — the people a new answer concerns.
   *
   * Participation, not attendance: a membership row is created by merely
   * opening the room, so notifying members would reach everyone who ever
   * glanced at the weekly question. Having answered is the closest thing to
   * opting in that this room has.
   */
  async distinctAuthorIds(roomId: string): Promise<string[]> {
    const ids = await this.model.distinct('authorId', {
      roomId,
      status: CommunityContentStatus.VISIBLE,
      authorType: CommunityAuthorType.USER,
    });

    return ids.map((id) => String(id)).filter(Boolean);
  }

  /**
   * When the room last spoke BEFORE [beforeId] — null when this is its first
   * message.
   *
   * One query for the whole fan-out: it is what decides whether a participant
   * was caught up, and therefore whether this message is news to them or just
   * the next line of a burst they have already been told about.
   */
  async previousMessageAt(roomId: string, beforeId: string): Promise<Date | null> {
    const rows = await this.model
      .find({
        roomId,
        status: CommunityContentStatus.VISIBLE,
        _id: { $ne: beforeId },
      })
      .sort({ createdAt: -1 })
      .limit(1)
      .select('createdAt')
      .lean();

    return (rows[0] as unknown as { createdAt?: Date })?.createdAt ?? null;
  }

  /**
   * The moderation table: every status, body searchable.
   *
   * Deliberately NOT filtered to VISIBLE — a moderator has to be able to see
   * what was taken down, and to put it back when the call was wrong.
   */
  async adminPage(dto: GetListCommunityChatDto, roomId?: string) {
    const where: FilterQuery<CommunityChatMessage> = {};

    if (dto.status) where.status = dto.status;
    if (roomId) where.roomId = roomId;
    if (dto.authorId) where.authorId = dto.authorId;

    if (dto.search?.trim()) {
      const escaped = dto.search.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      where.body = { $regex: escaped, $options: 'i' };
    }

    return this.paginateQuery<CommunityChatMessage>({
      where,
      page: dto.page,
      take: dto.take,
      orderBy: dto.orderBy || 'createdAt',
      order: dto.order || OrderType.DESC,
    });
  }

  /**
   * A page of messages by id, ANY status — the moderation queue has to show a
   * reported line whether or not it is still up.
   */
  async findAnyByIds(ids: string[]): Promise<CommunityChatMessage[]> {
    if (!ids.length) return [];

    return this.model
      .find({ _id: { $in: ids } })
      .lean() as unknown as CommunityChatMessage[];
  }

  // Any status: the table still has to show a line that was taken down.
  async findAnyById(id: string): Promise<CommunityChatMessage | null> {
    return this.model
      .findOne({ _id: id })
      .lean() as unknown as CommunityChatMessage | null;
  }

  async bumpCounter(
    messageId: string,
    field: 'likeCount' | 'reportCount',
    delta: number,
  ) {
    return this.model.updateOne(
      { _id: messageId },
      { $inc: { [field]: delta } },
    );
  }

  /**
   * What this author has written since [since]: how many rows, and when the
   * oldest of them landed — the two numbers the write ceiling is checked
   * against.
   *
   * Stops counting at [cap]: past the ceiling the exact number is not
   * interesting, only that it was passed. Every status counts, hidden and
   * deleted included, so deleting one is not a way to buy another.
   */
  async recentWritesByAuthor(authorId: string, since: Date, cap: number) {
    const rows = await this.model
      .find({ authorId, createdAt: { $gte: since } })
      .select('createdAt')
      .sort({ createdAt: 1 })
      .limit(cap)
      .lean();

    return {
      count: rows.length,
      oldestAt: rows[0]?.createdAt ?? null,
    };
  }

  /**
   * Whether this author has already written exactly this, word for word, since
   * [since] — the cheap half of spam detection, and the half that catches the
   * same message pasted into a room twenty times.
   */
  async hasRecentBody(authorId: string, since: Date, body: string) {
    const existing = await this.model.exists({
      authorId,
      createdAt: { $gte: since },
      body,
    });

    return !!existing;
  }
}
