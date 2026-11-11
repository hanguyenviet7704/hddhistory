import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';

import { assembleChatContextWindow } from './community-chat-context.helper';
import {
  CommunityAuthorType,
  CommunityContentStatus,
  CommunityReactionKind,
  CommunityTargetType,
} from '../../enum/community.enum';
import {
  assertWithinWriteLimit,
  COMMUNITY_AUTO_HIDDEN_REASON,
  COMMUNITY_AUTO_MODERATOR_ID,
  COMMUNITY_CHAT_LIMIT,
} from '../../helper/community-limit.helper';
import { CommunityAuthorService } from '../../service/community-author.service';
import { CommunityReactionRepository } from '../reaction/repository/community-reaction.repository';
import { CommunitySanctionService } from '../sanction/community-sanction.service';
import { GetCommunityChatDto } from './dto/get-community-chat.dto';
import { GetListCommunityChatDto } from './dto/get-list-community-chat.dto';
import { ModerateCommunityChatDto } from './dto/moderate-community-chat.dto';
import { SendCommunityChatDto } from './dto/send-community-chat.dto';
import { UpsertCommunityChatRoomDto } from './dto/upsert-community-chat-room.dto';
import { CommunityChatMembershipRepository } from './repository/community-chat-membership.repository';
import { CommunityChatMessageRepository } from './repository/community-chat-message.repository';
import { CommunityChatRoomRepository } from './repository/community-chat-room.repository';
import { CommunityChatMessage } from './schema/community-chat-message.schema';

/**
 * How recent a heartbeat still counts as "online" (design: "248 đang online").
 *
 * Five minutes, not thirty seconds: the number is a sign of life in the room,
 * not a socket count, and a window this short would make it flicker every time
 * someone locks their phone mid-conversation.
 */
const PRESENCE_WINDOW_MS = 5 * 60 * 1000;

// How many pinned lines page 1 carries back. A room whose admins have pinned
// more than this has a moderation problem, not a paging problem.
const PINNED_CAP = 50;

// How many messages a jump keeps on each side of its target. Enough that the
// landing has context above and below it without pulling half the room.
const CONTEXT_HALF = 20;

@Injectable()
export class CommunityChatService {
  private readonly logger = new Logger(CommunityChatService.name);

  constructor(
    private readonly roomRepository: CommunityChatRoomRepository,
    private readonly messageRepository: CommunityChatMessageRepository,
    private readonly membershipRepository: CommunityChatMembershipRepository,
    private readonly reactionRepository: CommunityReactionRepository,
    private readonly authorService: CommunityAuthorService,
    private readonly sanctionService: CommunitySanctionService,
  ) {}

  /**
   * The room's header: who it is, and how many people are in it right now.
   *
   * Also the heartbeat — asking about the room IS being in it. `readUpTo` is
   * deliberately not set here: the header is fetched to draw the FAB's badge
   * too, and clearing unread from there would erase the badge without the
   * reader ever seeing a message.
   */
  async room(idOrSlug: string, userId: string) {
    const room = await this.requireRoom(idOrSlug);
    const roomId = String(room._id);

    await this.membershipRepository.touch(roomId, userId);

    const membership = await this.membershipRepository.find(roomId, userId);
    const [onlineCount, unreadCount] = await Promise.all([
      this.membershipRepository.countActiveSince(
        roomId,
        new Date(Date.now() - PRESENCE_WINDOW_MS),
      ),
      this.messageRepository.countUnread(
        roomId,
        userId,
        membership?.lastReadAt,
      ),
    ]);

    return {
      id: roomId,
      slug: room.slug,
      name: room.name,
      isOfficial: room.isOfficial,
      onlineCount,
      unreadCount,
    };
  }

  /**
   * One page of the transcript, newest first, plus everything the design draws
   * around a message: the author, the moderator pill, my own heart, and whether
   * anyone else has read it.
   *
   * Opening the room is what marks it read — and only page 1, the newest page:
   * scrolling up into history must not re-clear a badge that arrived meanwhile.
   */
  async messages(
    idOrSlug: string,
    userId: string,
    dto: GetCommunityChatDto,
  ) {
    const room = await this.requireRoom(idOrSlug);
    const roomId = String(room._id);

    const page = await this.messageRepository.page({
      roomId,
      page: dto.page,
      take: dto.take,
    });

    const isFirstPage = !dto.page || dto.page <= 1;

    // The pins ride on page 1 rather than an endpoint of their own. The screen
    // already re-fetches this page on every poll tick, so the bar follows
    // ANOTHER admin's pin with no extra round trip and no staleness to manage.
    // Page 2 and beyond is history being scrolled into, where the bar is
    // already drawn — asking again there would be pure waste.
    const pinned = isFirstPage
      ? await this.messageRepository.pinnedForRoom(roomId, PINNED_CAP)
      : [];

    const shown = [...page.items, ...pinned];

    // The lines these replies quote. Read back by id rather than copied at
    // write time, so hiding or editing an original reaches every reply to it.
    const replyTargets = await this.resolveReplyTargets(shown);

    // Authors resolved across the page, the pins AND the quoted lines in one
    // query: a pinned or quoted line can be months old and its writer will not
    // appear anywhere on this page.
    const ids = shown.map((message) => String(message._id));
    const [authors, liked, readByOthers] = await Promise.all([
      this.authorService.resolve([
        ...shown.map((m) => m.authorId),
        ...[...replyTargets.values()].map((m) => m.authorId),
      ]),
      this.reactionRepository.targetIdsFor({
        userId,
        kind: CommunityReactionKind.LIKE,
        targetType: CommunityTargetType.CHAT_MESSAGE,
        targetIds: ids,
      }),
      this.membershipRepository.lastReadByOthers(roomId, userId),
    ]);

    if (isFirstPage) {
      const newest = page.items[0]?.createdAt;
      if (newest) {
        await this.membershipRepository.touch(roomId, userId, newest);
      }
    }

    const ctx = { authors, liked, readByOthers, userId, replyTargets };

    return {
      ...page,
      items: page.items.map((message) => this.toView(message, ctx)),
      pinned: pinned.map((message) => this.toView(message, ctx)),
    };
  }

  /**
   * The messages a page's replies point at, keyed by id.
   *
   * Only VISIBLE ones come back: quoting a line a moderator has taken down
   * would put the hidden words back on screen under somebody else's bubble,
   * which is the one thing hiding it was for.
   */
  private async resolveReplyTargets(messages: CommunityChatMessage[]) {
    const ids = [
      ...new Set(messages.map((message) => message.replyToId).filter(Boolean)),
    ] as string[];
    if (!ids.length) return new Map<string, CommunityChatMessage>();

    const rows = await this.messageRepository.findAnyByIds(ids);

    return new Map(
      rows
        .filter((row) => row.status === CommunityContentStatus.VISIBLE)
        .map((row) => [String(row._id), row] as const),
    );
  }

  /**
   * The slice of transcript around one message — what a tap on a pin lands in.
   *
   * A pinned line can be five hundred messages back, far outside the thirty the
   * screen holds, so there is nothing to scroll to. Rather than page backwards
   * until it turns up (slow, and unbounded on an old pin), the screen asks for
   * a window centred on it and swaps its list for that.
   *
   * Deliberately does NOT touch the read marker, unlike page 1: arriving in the
   * middle of last week's history is not the same as having caught up.
   */
  async context(idOrSlug: string, messageId: string, userId: string) {
    const room = await this.requireRoom(idOrSlug);
    const roomId = String(room._id);

    const anchor = await this.messageRepository.findVisibleById(messageId);
    if (!anchor || String(anchor.roomId) !== roomId) {
      throw new NotFoundException('Message not found in this room');
    }

    // Both halves over-fetched by one — that extra row is what tells the
    // window "there is more that way" apart from "that is the end of it".
    const [olderNewestFirst, newerOldestFirst] = await Promise.all([
      this.messageRepository.olderThanOrAt(
        roomId,
        anchor.createdAt,
        CONTEXT_HALF + 2,
      ),
      this.messageRepository.newerThan(
        roomId,
        anchor.createdAt,
        CONTEXT_HALF + 1,
      ),
    ]);

    const window = assembleChatContextWindow({
      olderNewestFirst,
      newerOldestFirst,
      half: CONTEXT_HALF,
    });

    const replyTargets = await this.resolveReplyTargets(window.items);

    const ids = window.items.map((message) => String(message._id));
    const [authors, liked, readByOthers] = await Promise.all([
      this.authorService.resolve([
        ...window.items.map((m) => m.authorId),
        ...[...replyTargets.values()].map((m) => m.authorId),
      ]),
      this.reactionRepository.targetIdsFor({
        userId,
        kind: CommunityReactionKind.LIKE,
        targetType: CommunityTargetType.CHAT_MESSAGE,
        targetIds: ids,
      }),
      this.membershipRepository.lastReadByOthers(roomId, userId),
    ]);

    const ctx = { authors, liked, readByOthers, userId, replyTargets };

    return {
      items: window.items.map((message) => this.toView(message, ctx)),
      hasOlder: window.hasOlder,
      // False means the window reaches the live bottom, which is how the screen
      // knows to drop the "về tin mới nhất" button and let polling merge again.
      hasNewer: window.hasNewer,
      anchorId: String(anchor._id),
    };
  }

  /**
   * Pin a line to the top of the room — a moderator action, from the panel.
   *
   * Guarded exactly like the rest of the panel's chat surface, which is to say
   * by `AuthGuard` alone; see the note on CommunityCommentController. There is
   * deliberately no reader-facing route: the app draws pins, it does not make
   * them.
   *
   * Idempotent in the repository: pinning what is already pinned leaves
   * `pinnedAt` alone, so a double click cannot shuffle it to the front of the
   * bar ahead of a pin somebody made after it.
   */
  async pin(messageId: string, moderatorId: string) {
    const message = await this.messageRepository.findVisibleById(messageId);
    if (!message) throw new NotFoundException('Message not found');

    await this.messageRepository.pin(messageId, moderatorId);

    return { pinned: true };
  }

  async unpin(messageId: string) {
    await this.messageRepository.unpin(messageId);

    return { pinned: false };
  }

  async send(
    idOrSlug: string,
    userId: string,
    dto: SendCommunityChatDto,
    meta: IUserMeta,
  ) {
    // The route itself gates nothing beyond a valid token. The mute has to be
    // checked here, exactly as a post or a comment checks it — without this, a
    // suspension silences someone everywhere except the one room where they
    // can talk to everybody at once.
    await this.sanctionService.assertCanWrite(userId);
    await this.assertWithinRate(userId, dto.body);

    const room = await this.requireRoom(idOrSlug);
    const roomId = String(room._id);

    // A reply may only point at a line in THIS room. Without the check, a
    // message id copied from anywhere would quote text the room never saw.
    let replyToId: string | undefined;
    if (dto.replyToId) {
      const target = await this.messageRepository.findVisibleById(dto.replyToId);
      if (!target || String(target.roomId) !== roomId) {
        throw new BadRequestException(
          'Reply target does not belong to this room',
        );
      }
      replyToId = String(target._id);
    }

    const message = await this.messageRepository.create(
      {
        roomId,
        authorId: userId,
        authorType: CommunityAuthorType.USER,
        body: dto.body.trim(),
        replyToId,
      },
      meta,
    );

    await Promise.all([
      this.roomRepository.bumpMessageCount(roomId, 1),
      // Sending is also being present, and it reads everything before it.
      this.membershipRepository.touch(roomId, userId, message.createdAt),
    ]);

    const authors = await this.authorService.resolve([userId]);

    // No notification goes out for a chat line — see the note on
    // MESSAGE_IN_ROOM in the enum. A room is read by opening it.

    return this.toView(message, {
      authors,
      liked: new Set<string>(),
      readByOthers: null,
      userId,
    });
  }

  /**
   * A line written by the team, from the panel.
   *
   * Same room, same collection, same fan-out as a reader's message — only the
   * author differs. Deliberately skips both reader gates: `assertCanWrite`
   * asks whether this account is muted (a moderator is not a member being
   * moderated), and the rate limit exists to stop a flood from one reader,
   * which is not the failure mode of a team account posting from a panel.
   *
   * `isModerator` is stored as well as `authorType` because the app draws the
   * two differently: the badge comes from the type, the "moderator" styling of
   * the bubble from the flag.
   */
  async sendOfficial(
    idOrSlug: string,
    dto: SendCommunityChatDto,
    moderatorId: string,
    meta: IUserMeta,
  ) {
    const room = await this.requireRoom(idOrSlug);
    const roomId = String(room._id);

    const message = await this.messageRepository.create(
      {
        roomId,
        authorId: moderatorId,
        authorType: CommunityAuthorType.OFFICIAL,
        isModerator: true,
        body: dto.body.trim(),
      },
      meta,
    );

    await this.roomRepository.bumpMessageCount(roomId, 1);

    // Silent for the same reason as the reader path above: the team answering
    // in a room is still a chat line, and chat lines stopped notifying.

    return this.toView(message, {
      authors: new Map(),
      liked: new Set<string>(),
      readByOthers: null,
      userId: moderatorId,
    });
  }

  /**
   * The chat ceiling: lines a minute, and no repeating yourself.
   *
   * The window is deliberately short and the count deliberately high — a chat
   * IS bursty, and a limit that punishes enthusiasm would be felt by everyone
   * except the one person it is for. What it stops is the flood: twenty lines
   * buys a minute of silence, which is longer than it takes a moderator to
   * arrive.
   */
  private async assertWithinRate(userId: string, body?: string) {
    const limit = COMMUNITY_CHAT_LIMIT;
    const now = Date.now();
    const text = body?.trim();

    const [stats, isDuplicate] = await Promise.all([
      this.messageRepository.recentWritesByAuthor(
        userId,
        new Date(now - limit.windowMs),
        limit.max,
      ),
      text && text.length >= limit.duplicateMinLength
        ? this.messageRepository.hasRecentBody(
            userId,
            new Date(now - limit.duplicateMs),
            text,
          )
        : Promise.resolve(false),
    ]);

    assertWithinWriteLimit(stats, limit, isDuplicate);
  }

  /**
   * Toggles my heart on one message and returns the new count.
   *
   * Handled here rather than by `CommunityReactionService`: that service reads
   * and bumps the posts and comments collections, and teaching it a third
   * target would mean injecting this module's repository into it for one field.
   * The reaction ROWS are still the shared collection, so a chat heart is the
   * same kind of object as any other.
   */
  async toggleLike(messageId: string, userId: string) {
    const message = await this.messageRepository.findVisibleById(messageId);
    if (!message) throw new NotFoundException('Message not found');

    const params = {
      targetType: CommunityTargetType.CHAT_MESSAGE,
      targetId: messageId,
      userId,
      kind: CommunityReactionKind.LIKE,
    };

    const added = await this.reactionRepository.add(params);
    if (added) {
      await this.messageRepository.bumpCounter(messageId, 'likeCount', 1);
      return { isLiked: true, likeCount: message.likeCount + 1 };
    }

    const removed = await this.reactionRepository.remove(params);
    if (!removed) {
      // Already gone — report the state, do not double-decrement.
      return { isLiked: false, likeCount: message.likeCount };
    }

    await this.messageRepository.bumpCounter(messageId, 'likeCount', -1);
    return { isLiked: false, likeCount: Math.max(0, message.likeCount - 1) };
  }

  // ------------------------------------------------------------------- admin

  /**
   * The rooms, for the panel's picker and for opening a new one.
   *
   * `messageCount` rather than a live count: it is what the row already carries,
   * and the number is there to tell a busy room from a dead one, not to be
   * exact.
   */
  async listRoomsForAdmin() {
    const rooms = await this.roomRepository.listAll();

    return rooms.map((room) => ({
      id: String(room._id),
      slug: room.slug,
      name: room.name,
      isOfficial: room.isOfficial,
      status: room.status,
      messageCount: room.messageCount,
      createdAt: room.createdAt,
    }));
  }

  /**
   * Opens a room, or edits the one already on that slug.
   *
   * This is the only way to create one outside a script with direct database
   * access — which is why it exists: the app opens `hoi-ban-tron` by name, and
   * without a row on that slug the whole feature is a 404 behind a button on
   * every environment nobody has a Mongo shell into.
   */
  async upsertRoom(dto: UpsertCommunityChatRoomDto, user: IUserMeta) {
    const room = await this.roomRepository.upsertBySlug(
      dto.slug,
      {
        name: dto.name.trim(),
        isOfficial: dto.isOfficial ?? true,
        status: dto.status ?? CommunityContentStatus.VISIBLE,
      },
      user,
    );

    return {
      id: String(room._id),
      slug: room.slug,
      name: room.name,
      isOfficial: room.isOfficial,
      status: room.status,
      messageCount: room.messageCount,
      createdAt: room.createdAt,
    };
  }

  /**
   * The moderation table (hddhistory-admin → "Chat nhóm").
   *
   * Reveals the account behind an ANONYMOUS line, like every other admin view:
   * a ban cannot be enforced against nobody. Readers still never see it.
   */
  async findAllForAdmin(dto: GetListCommunityChatDto) {
    const room = dto.room
      ? await this.roomRepository.findVisible(dto.room)
      : null;

    const listed = await this.messageRepository.adminPage(
      dto,
      room ? String(room._id) : undefined,
    );
    const authors = await this.authorService.resolve(
      listed.items.map((message) => message.authorId),
    );

    return {
      ...listed,
      items: listed.items.map((message) => ({
        id: String(message._id),
        roomId: message.roomId,
        status: message.status,
        body: message.body,
        author: this.authorService.pick(
          authors,
          message.authorId,
          message.authorType,
          true,
        ),
        isModerator: message.isModerator,
        // The panel is where pinning happens now, so the table has to show
        // which lines are already up there.
        isPinned: !!message.pinnedAt,
        pinnedAt: message.pinnedAt ?? null,
        likeCount: message.likeCount,
        reportCount: message.reportCount,
        hiddenReason: message.hiddenReason ?? null,
        moderatedBy: message.moderatedBy ?? null,
        moderatedAt: message.moderatedAt ?? null,
        createdAt: message.createdAt,
      })),
    };
  }

  /**
   * Hide, restore, or delete one line.
   *
   * Hiding does not remove the row: the report queue and the author's own
   * history still need something to point at, and a restore has to be possible.
   * The room's `messageCount` follows the line out and back so the counter
   * never drifts from what is actually readable.
   */
  /**
   * Pulled out of the room by weight of reports, with nobody's name on it.
   *
   * Mirrors the comment path: only a VISIBLE line, never the team's own — a
   * brigade reporting a moderator has to reach a person, not a threshold.
   *
   * Deliberately does NOT unpin. `pinnedForRoom` only returns VISIBLE rows, so
   * a hidden line leaves the bar on its own; keeping `pinnedAt` means restoring
   * the message restores its pin too, instead of silently losing it.
   */
  async autoHideByReports(id: string) {
    const message = await this.messageRepository.findAnyById(id);
    if (!message) return false;
    if (message.status !== CommunityContentStatus.VISIBLE) return false;
    if (message.authorType === CommunityAuthorType.OFFICIAL) return false;

    await this.messageRepository.updateOne({ _id: id }, {
      status: CommunityContentStatus.HIDDEN,
      hiddenReason: COMMUNITY_AUTO_HIDDEN_REASON,
      moderatedBy: COMMUNITY_AUTO_MODERATOR_ID,
      moderatedAt: new Date(),
    } as Partial<CommunityChatMessage>);

    await this.roomRepository.bumpMessageCount(message.roomId, -1);

    return true;
  }

  async moderate(
    id: string,
    dto: ModerateCommunityChatDto,
    moderatorId: string,
    user?: IUserMeta,
  ) {
    const message = await this.messageRepository.findAnyById(id);
    if (!message) throw new NotFoundException('Message not found');

    if (dto.status && dto.status !== message.status) {
      await this.messageRepository.updateOne(
        { _id: id },
        {
          status: dto.status,
          hiddenReason: dto.hiddenReason,
          moderatedBy: moderatorId,
          moderatedAt: new Date(),
        } as Partial<CommunityChatMessage>,
        user,
      );

      const wasVisible = message.status === CommunityContentStatus.VISIBLE;
      const isVisible = dto.status === CommunityContentStatus.VISIBLE;
      if (wasVisible !== isVisible) {
        await this.roomRepository.bumpMessageCount(
          message.roomId,
          isVisible ? 1 : -1,
        );
      }
    }

    return this.messageRepository.findAnyById(id);
  }

  private async requireRoom(idOrSlug: string) {
    const room = await this.roomRepository.findVisible(idOrSlug);
    if (!room) throw new NotFoundException('Chat room not found');

    return room;
  }

  private toView(
    message: CommunityChatMessage,
    ctx: {
      authors: Map<string, ReturnType<CommunityAuthorService['official']>>;
      liked: Set<string>;
      readByOthers: Date | null;
      userId: string;
      replyTargets?: Map<string, CommunityChatMessage>;
    },
  ) {
    const id = String(message._id);
    const isMine = message.authorId === ctx.userId;

    return {
      id,
      author: this.authorService.pick(
        ctx.authors,
        message.authorId,
        message.authorType,
      ),
      isModerator: message.isModerator,
      body: message.body,
      likeCount: message.likeCount,
      isLiked: ctx.liked.has(id),
      isMine,
      // The purple shadow and the pin glyph on the bubble. `pinnedAt` travels
      // too because the bar and the sheet order by PIN time, not message time.
      isPinned: !!message.pinnedAt,
      pinnedAt: message.pinnedAt ?? null,
      // The quote strip above this bubble. Null when it answers nothing.
      replyTo: this.toReplyView(message, ctx),
      // "Đã xem", and only on my own message: it means somebody ELSE has read
      // past it. On a stranger's message the flag would be meaningless.
      isSeen:
        isMine &&
        !!ctx.readByOthers &&
        ctx.readByOthers >= message.createdAt,
      createdAt: message.createdAt,
    };
  }

  /**
   * The quoted line above a reply.
   *
   * `isRemoved` rather than a bare null when the original is gone: the reply
   * still visibly answers SOMETHING, and drawing nothing at all makes it read
   * as a non-sequitur. The app says "tin nhắn đã bị gỡ" and keeps the shape.
   */
  private toReplyView(
    message: CommunityChatMessage,
    ctx: {
      authors: Map<string, ReturnType<CommunityAuthorService['official']>>;
      replyTargets?: Map<string, CommunityChatMessage>;
    },
  ) {
    if (!message.replyToId) return null;

    const target = ctx.replyTargets?.get(String(message.replyToId));
    if (!target) {
      return {
        id: String(message.replyToId),
        author: null,
        body: '',
        isRemoved: true,
      };
    }

    return {
      id: String(target._id),
      author: this.authorService.pick(
        ctx.authors,
        target.authorId,
        target.authorType,
      ),
      body: target.body,
      isRemoved: false,
    };
  }
}
