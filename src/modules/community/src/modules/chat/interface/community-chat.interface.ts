import {
  CommunityAuthorType,
  CommunityContentStatus,
} from '../../../enum/community.enum';

/**
 * A group chat room (design `S-03 · Hội bàn tròn`).
 *
 * Keyed by its own id from the start even though only one room ships. The FAB
 * opens a named, HDDhistory-hosted room today; giving every topic its own chat later
 * is then a row in this collection and a different id on the client, not a
 * migration.
 */
export interface ICommunityChatRoom {
  name: string;
  // Stable handle the seeder and the client can both name a room by, so the
  // one shipping room does not need its ObjectId hardcoded anywhere.
  slug: string;
  // Hosted by the HDDhistory team: drives the brand tile in the header.
  isOfficial: boolean;
  status: CommunityContentStatus;
  messageCount: number;
}

export interface ICommunityChatMessage {
  roomId: string;
  authorId: string;
  authorType: CommunityAuthorType;
  /**
   * The "Quản trị viên" pill. Stamped ON THE MESSAGE rather than read from the
   * author at render time: someone who was on duty when they wrote it stays
   * marked afterwards, and a moderator who steps down does not silently rewrite
   * the history of the room.
   */
  isModerator: boolean;
  body: string;
  status: CommunityContentStatus;
  likeCount: number;
  reportCount: number;
  /**
   * When this was pinned — the pin bar and the pin sheet both order by it.
   * Absent on an ordinary message, which is what "not pinned" means: there is
   * no separate flag to fall out of step with.
   */
  pinnedAt?: Date;
  /** The admin who pinned it, kept so a pin can be traced back to a person. */
  pinnedBy?: string;
  /**
   * The message this one answers. Flat — a reply points at one line, it does
   * not open a thread — and the quoted text is read back through this id
   * rather than copied, so hiding the original reaches every reply to it.
   */
  replyToId?: string;
}

/**
 * One member's footprint in a room: what they have read, and when they were
 * last here.
 *
 * `lastSeenAt` is what "248 đang online" counts — a heartbeat written when the
 * client opens or polls the room, not a socket connection. A socket count is
 * the truer number but it dies with the process and cannot answer for a reader
 * who is on the feed with the room in the background; this one is honest about
 * what it measures and survives a restart.
 */
export interface ICommunityChatMembership {
  roomId: string;
  userId: string;
  lastSeenAt: Date;
  lastReadAt?: Date;
}
