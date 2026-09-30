import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';
import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CommunityContentStatus } from '../../../enum/community.enum';
import { CommunityChatRoom } from '../schema/community-chat-room.schema';

@Injectable()
export class CommunityChatRoomRepository extends AbstractRepository<CommunityChatRoom> {
  protected readonly logger = new Logger(CommunityChatRoomRepository.name);

  constructor(
    @InjectModel(CommunityChatRoom.name) model: Model<CommunityChatRoom>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Resolves a room by ObjectId OR by slug.
   *
   * The client opens the shipping room by slug so its id is not baked into the
   * app; admin surfaces address rooms by id. One lookup answers both rather
   * than making every caller know which it holds.
   *
   * The test is 24 hex characters, NOT `mongoose.isValidObjectId` — that helper
   * accepts any 12-character string, because 12 raw bytes is a legal ObjectId
   * input. `hoi-ban-tron` is exactly 12 characters, so the shipping room's slug
   * was read as an id, cast to the ObjectId those bytes spell, matched nothing,
   * and every chat request answered "Chat room not found" while the row sat
   * there VISIBLE. Two hours of "the room is not seeded" was this line.
   */
  async findVisible(idOrSlug: string): Promise<CommunityChatRoom | null> {
    const where = /^[a-f0-9]{24}$/i.test(idOrSlug)
      ? { _id: idOrSlug }
      : { slug: idOrSlug };

    return this.model
      .findOne({ ...where, status: CommunityContentStatus.VISIBLE })
      .lean() as unknown as CommunityChatRoom | null;
  }

  /**
   * Every room, oldest first — the panel's picker.
   *
   * Unfiltered by status on purpose: a room a moderator closed still has to be
   * visible to them, or closing one is a way to lose it.
   */
  async listAll(): Promise<CommunityChatRoom[]> {
    return this.model
      .find({})
      .sort({ createdAt: 1 })
      .lean() as unknown as CommunityChatRoom[];
  }

  /**
   * Creates the room on this slug, or edits the one already there.
   *
   * Upsert rather than create: the slug is unique and the app compiles one in,
   * so pressing "create" twice has to be the same room twice, not a duplicate
   * key error in a panel nobody can act on.
   */
  async upsertBySlug(
    slug: string,
    data: Partial<CommunityChatRoom>,
    user?: IUserMeta,
  ): Promise<CommunityChatRoom | null> {
    return this.findOneAndUpdate(
      { slug },
      {
        $set: { ...data, updatedAt: new Date(), updatedBy: user },
        // Only on insert: a re-run must not reset the transcript's counter or
        // re-date a room that has been open for a month.
        $setOnInsert: { createdAt: new Date(), createdBy: user, messageCount: 0 },
      },
      { upsert: true, setDefaultsOnInsert: true },
    );
  }

  async bumpMessageCount(roomId: string, delta: number) {
    return this.model.updateOne(
      { _id: roomId },
      { $inc: { messageCount: delta } },
    );
  }
}
