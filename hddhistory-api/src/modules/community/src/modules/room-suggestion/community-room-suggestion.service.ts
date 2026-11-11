import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';

import { CreateCommunityRoomSuggestionDto } from './dto/create-community-room-suggestion.dto';
import { GetListCommunityRoomSuggestionDto } from './dto/get-list-community-room-suggestion.dto';
import {
  ApproveCommunityRoomSuggestionDto,
  DeclineCommunityRoomSuggestionDto,
} from './dto/review-community-room-suggestion.dto';
import { CommunityRoomSuggestionRepository } from './repository/community-room-suggestion.repository';
import { CommunityRoomSuggestion } from './schema/community-room-suggestion.schema';
import { CommunityRoomSuggestionStatus } from '../../enum/community.enum';
import { CommunityAuthorService } from '../../service/community-author.service';
import { CommunitySanctionService } from '../sanction/community-sanction.service';

// One person may have this many open asks at a time. Not a spam defence so
// much as a signal one: twenty asks from one reader tells a moderator nothing
// about what the room wants.
const MAX_OPEN_SUGGESTIONS_PER_AUTHOR = 3;

@Injectable()
export class CommunityRoomSuggestionService {
  constructor(
    private readonly suggestionRepository: CommunityRoomSuggestionRepository,
    private readonly sanctionService: CommunitySanctionService,
    private readonly authorService: CommunityAuthorService,
  ) {}

  /**
   * File a new ask, or back the identical one that already exists.
   *
   * The duplicate case returns the EXISTING row with a vote added rather than
   * refusing: from the reader's side "someone already asked for this and you
   * are the fourth to want it" is the outcome they wanted, and an error would
   * just make them retype the name slightly differently.
   */
  async create(
    userId: string,
    locale: string,
    dto: CreateCommunityRoomSuggestionDto,
    user?: IUserMeta,
  ) {
    // A reader banned from posting is banned from filing asks too — otherwise
    // the ask box becomes the way around the ban.
    await this.sanctionService.assertCanWrite(userId);

    const name = dto.name.trim();
    if (!name) throw new BadRequestException('Room name is required');

    const existing = await this.suggestionRepository.findOpenByName(
      locale,
      name,
    );
    if (existing) {
      const voted = await this.suggestionRepository.addVote(
        String(existing._id),
        userId,
      );
      return this.toView(voted ?? existing, userId, { merged: true });
    }

    const openCount = await this.suggestionRepository.countOpenByAuthor(userId);
    if (openCount >= MAX_OPEN_SUGGESTIONS_PER_AUTHOR) {
      throw new BadRequestException('COMMUNITY_TOO_MANY_ROOM_SUGGESTIONS');
    }

    const created = await this.suggestionRepository.create(
      {
        name,
        description: dto.description?.trim() ?? '',
        authorId: userId,
        locale,
        status: CommunityRoomSuggestionStatus.PENDING,
        // The person who asked is the first person who wants it.
        voterIds: [userId],
        voteCount: 1,
      } as Partial<CommunityRoomSuggestion>,
      user,
    );

    return this.toView(created, userId);
  }

  /**
   * What else readers in this language have asked for.
   *
   * Shown under the form so a reader backs an existing ask instead of filing
   * the fifth copy of it.
   */
  async listForReader(userId: string, locale: string) {
    const rows = await this.suggestionRepository.pendingForLocale(locale);
    return { items: rows.map((row) => this.toView(row, userId)) };
  }

  async vote(id: string, userId: string) {
    const suggestion = await this.suggestionRepository.findById(id);
    if (!suggestion) throw new NotFoundException('Suggestion not found');
    if (suggestion.status !== CommunityRoomSuggestionStatus.PENDING) {
      throw new BadRequestException('COMMUNITY_ROOM_SUGGESTION_CLOSED');
    }

    const voted = await this.suggestionRepository.addVote(id, userId);
    return this.toView(voted ?? suggestion, userId);
  }

  // ---------------------------------------------------------------- admin

  async findAllForAdmin(dto: GetListCommunityRoomSuggestionDto) {
    const listed = await this.suggestionRepository.findOption(dto);
    const authors = await this.authorService.resolve(
      listed.items.map((row) => row.authorId),
    );

    return {
      ...listed,
      items: listed.items.map((row) => ({
        id: String(row._id),
        name: row.name,
        description: row.description,
        locale: row.locale,
        status: row.status,
        voteCount: row.voteCount,
        // The moderator needs to know who is asking — a burst of asks from one
        // account reads very differently from the same count across twenty.
        author: this.authorService.pick(authors, row.authorId),
        topicId: row.topicId ?? null,
        reviewNote: row.reviewNote ?? null,
        reviewedAt: row.reviewedAt ?? null,
        createdAt: row.createdAt,
      })),
    };
  }

  async approve(
    id: string,
    moderatorId: string,
    dto: ApproveCommunityRoomSuggestionDto,
  ) {
    return this.review(id, moderatorId, {
      status: CommunityRoomSuggestionStatus.APPROVED,
      topicId: dto.topicId,
      reviewNote: dto.note,
    });
  }

  async decline(
    id: string,
    moderatorId: string,
    dto: DeclineCommunityRoomSuggestionDto,
  ) {
    return this.review(id, moderatorId, {
      status: CommunityRoomSuggestionStatus.DECLINED,
      reviewNote: dto.note,
    });
  }

  private async review(
    id: string,
    moderatorId: string,
    patch: Partial<CommunityRoomSuggestion>,
  ) {
    const suggestion = await this.suggestionRepository.findById(id);
    if (!suggestion) throw new NotFoundException('Suggestion not found');

    await this.suggestionRepository.updateOne(
      { _id: id },
      {
        ...patch,
        reviewedBy: moderatorId,
        reviewedAt: new Date(),
      },
    );

    return { reviewed: true, status: patch.status };
  }

  /**
   * One suggestion as a reader sees it.
   *
   * `voterIds` never leaves the server: who else asked for a room is nobody's
   * business, and the only thing the screen needs from it is whether this
   * reader is in there.
   */
  private toView(
    suggestion: CommunityRoomSuggestion,
    userId: string,
    extra: { merged?: boolean } = {},
  ) {
    return {
      id: String(suggestion._id),
      name: suggestion.name,
      description: suggestion.description,
      status: suggestion.status,
      voteCount: suggestion.voteCount,
      hasVoted: (suggestion.voterIds ?? []).includes(userId),
      isMine: suggestion.authorId === userId,
      topicId: suggestion.topicId ?? null,
      // True when the reader's new ask turned into a vote on one already open,
      // so the app can say so instead of claiming it created something.
      mergedIntoExisting: !!extra.merged,
      createdAt: suggestion.createdAt,
    };
  }
}
