import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { OrderType } from '@utils/type/orderByType';

import { CommunityRoomSuggestionStatus } from '../../../enum/community.enum';
import { GetListCommunityRoomSuggestionDto } from '../dto/get-list-community-room-suggestion.dto';
import { CommunityRoomSuggestion } from '../schema/community-room-suggestion.schema';

@Injectable()
export class CommunityRoomSuggestionRepository extends AbstractRepository<CommunityRoomSuggestion> {
  protected readonly logger = new Logger(
    CommunityRoomSuggestionRepository.name,
  );

  constructor(
    @InjectModel(CommunityRoomSuggestion.name)
    model: Model<CommunityRoomSuggestion>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  // What else has been asked for in this language: still pending, most wanted
  // first. Approved and declined rows drop out — one is a room you can already
  // open, the other an answer already given.
  async pendingForLocale(
    locale: string,
    take = 20,
  ): Promise<CommunityRoomSuggestion[]> {
    return this.model
      .find({ locale, status: CommunityRoomSuggestionStatus.PENDING })
      .sort({ voteCount: -1, createdAt: 1 })
      .limit(take)
      .lean() as unknown as CommunityRoomSuggestion[];
  }

  // Same name, same language, still open — the duplicate a second reader
  // should be voting on instead of filing again. Matched case-insensitively on
  // the whole trimmed name, not by keyword: "Sống một mình" and "Sống một mình
  // ở thành phố" are two different asks.
  async findOpenByName(
    locale: string,
    name: string,
  ): Promise<CommunityRoomSuggestion | null> {
    const escaped = name.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    return this.model
      .findOne({
        locale,
        status: CommunityRoomSuggestionStatus.PENDING,
        name: { $regex: `^${escaped}$`, $options: 'i' },
      })
      .lean() as unknown as CommunityRoomSuggestion | null;
  }

  async countOpenByAuthor(authorId: string): Promise<number> {
    return this.model.countDocuments({
      authorId,
      status: CommunityRoomSuggestionStatus.PENDING,
    });
  }

  /**
   * Back a suggestion, idempotently.
   *
   * An aggregation-pipeline update so voterIds and voteCount move in the same
   * write: `$setUnion` makes a second tap a no-op, and the count is recomputed
   * from the array rather than incremented, so it can never drift away from it.
   * Returns the row as it now stands.
   */
  async addVote(
    id: string,
    userId: string,
  ): Promise<CommunityRoomSuggestion | null> {
    await this.model.updateOne({ _id: id }, [
      { $set: { voterIds: { $setUnion: [{ $ifNull: ['$voterIds', []] }, [userId]] } } },
      { $set: { voteCount: { $size: '$voterIds' }, updatedAt: new Date() } },
    ]);

    return this.model
      .findById(id)
      .lean() as unknown as CommunityRoomSuggestion | null;
  }

  // The moderation queue.
  async findOption(dto: GetListCommunityRoomSuggestionDto) {
    const { page, take, search, status, locale, order, orderBy } = dto;
    const where: FilterQuery<CommunityRoomSuggestion> = {};

    if (search?.trim()) {
      const escaped = search.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      where.name = { $regex: escaped, $options: 'i' };
    }
    if (status) where.status = status;
    if (locale) where.locale = locale;

    return this.paginateQuery<CommunityRoomSuggestion>({
      where,
      page,
      take,
      orderBy: orderBy || 'voteCount',
      order: order || OrderType.DESC,
    });
  }
}
