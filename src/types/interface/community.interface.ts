import { ITranslation } from "../../utils/translation";

export enum CommunityPostType {
  POST = "POST",
  WEEKLY_QUESTION = "WEEKLY_QUESTION",
}

export enum CommunityAuthorType {
  USER = "USER",
  OFFICIAL = "OFFICIAL",
  /**
   * Written without a name shown to readers.
   *
   * The admin endpoints still return the real account — a ban has to land on
   * somebody — so `author.name` is filled here even though the app hid it. The
   * queue labels it so a moderator knows the reader could not see who wrote it.
   */
  ANONYMOUS = "ANONYMOUS",
}

export enum CommunityContentStatus {
  VISIBLE = "VISIBLE",
  /** Taken down by a moderator. */
  HIDDEN = "HIDDEN",
  /** Removed by its author. */
  DELETED = "DELETED",
}

export enum CommunityTargetType {
  POST = "POST",
  COMMENT = "COMMENT",
}

export enum CommunityReportReason {
  SPAM = "SPAM",
  HARASSMENT = "HARASSMENT",
  ADULT = "ADULT",
  MISINFORMATION = "MISINFORMATION",
  PRIVACY = "PRIVACY",
  OTHER = "OTHER",
}

export enum CommunityRoomSuggestionStatus {
  PENDING = "PENDING",
  /** A room was opened for it; `topicId` points at that room. */
  APPROVED = "APPROVED",
  DECLINED = "DECLINED",
}

export enum CommunityReportStatus {
  PENDING = "PENDING",
  RESOLVED_HIDDEN = "RESOLVED_HIDDEN",
  RESOLVED_KEPT = "RESOLVED_KEPT",
}

export interface ICommunityAuthor {
  id: string;
  /** Empty for a deleted account — render a placeholder, not the raw id. */
  name: string;
  avatar?: string;
  authorType: CommunityAuthorType;
}

export interface ICommunityTopic {
  _id: string;
  name: ITranslation;
  description?: ITranslation;
  slug: string;
  imageUrl?: string;
  sortOrder: number;
  isActive: boolean;
  /**
   * Counters per locale: `{ vi: { followers, postsThisWeek } }`.
   *
   * Per locale because the app's feed is filtered per locale too — a combined
   * total next to an empty feed would be a lie.
   */
  stats?: Record<string, { followers?: number; postsThisWeek?: number }>;
  createdAt?: string;
}

export interface ICommunityTopicPayload {
  name: ITranslation;
  description?: ITranslation;
  slug: string;
  imageUrl?: string;
  sortOrder?: number;
  isActive?: boolean;
}

export interface ICommunityAdminPost {
  id: string;
  type: CommunityPostType;
  status: CommunityContentStatus;
  locale?: string | null;
  /** The headline above the story. Empty on older posts and on weekly questions. */
  subject?: string;
  body: string;
  /** A saved keypoint card the writer attached, snapshotted at compose time. */
  attachedCard?: ICommunityAttachedCard | null;
  /** A course the writer shared. The app draws it as a card; here it is a link. */
  attachedCourseId?: string | null;
  /** Weekly questions carry translations instead of a body. */
  title?: ITranslation;
  note?: ITranslation;
  /** Weekly questions only — the window the question is open for. */
  weekly?: {
    weekNumber: number;
    year: number;
    startsAt: string;
    endsAt: string;
  };
  images: string[];
  author: ICommunityAuthor;
  topic: { id: string; name: ITranslation | null } | null;
  isPinned: boolean;
  commentsLocked: boolean;
  likeCount: number;
  commentCount: number;
  /** The bell — readers who asked to be told when this thread moves. */
  saveCount?: number;
  reportCount: number;
  hiddenReason?: string;
  /**
   * Taken out of the feed by the report count, not by a moderator — the reports
   * are still open and this row is waiting for a verdict.
   */
  hiddenByReports?: boolean;
  createdAt: string;
}

export interface ICommunityAttachedCard {
  keypointId: string;
  title: string;
  back: string;
  courseName?: string;
}

export interface ICommunityRoomSuggestion {
  id: string;
  name: string;
  description: string;
  locale: string;
  status: CommunityRoomSuggestionStatus;
  /** How many readers backed it, the person who asked included. */
  voteCount: number;
  author: ICommunityAuthor;
  /** Set once approved: the room that was opened for this ask. */
  topicId: string | null;
  reviewNote: string | null;
  reviewedAt: string | null;
  createdAt: string;
}

export interface ICommunityAdminComment {
  id: string;
  postId: string;
  parentId: string | null;
  status: CommunityContentStatus;
  body: string;
  author: ICommunityAuthor;
  likeCount: number;
  replyCount: number;
  reportCount: number;
  hiddenReason?: string | null;
  /** Hidden only because its post was hidden — restoring the post restores it. */
  hiddenWithPost?: boolean;
  /** Hidden by the report count; still waiting for a moderator's verdict. */
  hiddenByReports?: boolean;
  createdAt: string;
}

/**
 * The team's identity in the forum.
 *
 * Both fields may be empty, and empty is meaningful: the app then falls back to
 * its own localised "Đội ngũ MeUp" and the generated "M" disc.
 */
export interface ICommunityOfficialProfile {
  name: string;
  avatar: string;
}

/**
 * "Hướng dẫn & nội quy nhóm" — one row per language.
 *
 * Authored here rather than shipped in the app's translation files: the rules
 * are what gets reworded after an incident, and that must not wait for a
 * release.
 *
 * Three fixed lists, not free-form sections, because the sheet draws each one
 * differently: a green "Nên" block, a red "Không" block, and tappable openers.
 */
export interface ICommunityChatGuide {
  locale: string;
  title: string;
  intro: string;
  dos: string[];
  donts: string[];
  starters: string[];
}


/** A group chat room, as the panel manages it. */
export interface ICommunityChatRoom {
  id: string;
  slug: string;
  name: string;
  isOfficial: boolean;
  status: CommunityContentStatus;
  messageCount: number;
  createdAt: string;
}

/**
 * One line in a group chat room, as the moderation table sees it.
 *
 * The author is the REAL account even for an anonymous line — a ban cannot be
 * enforced against nobody. Readers in the app still never see it.
 */
export interface ICommunityAdminChatMessage {
  id: string;
  roomId: string;
  status: CommunityContentStatus;
  body: string;
  author: ICommunityAuthor;
  /** Written while the author was on duty — the "Quản trị viên" pill. */
  isModerator: boolean;
  /** Pinned to the top of its room. Pinning is a panel action. */
  isPinned: boolean;
  pinnedAt?: string | null;
  likeCount: number;
  reportCount: number;
  hiddenReason?: string | null;
  moderatedBy?: string | null;
  moderatedAt?: string | null;
  createdAt: string;
}

export interface ICommunityChatQuery {
  page: number;
  take: number;
  status?: CommunityContentStatus;
  /** Room id or slug. */
  room?: string;
  authorId?: string;
  search?: string;
}

export interface ICommunityReport {
  id: string;
  targetType: CommunityTargetType;
  targetId: string;
  reason: CommunityReportReason;
  note: string | null;
  status: CommunityReportStatus;
  reporter: ICommunityAuthor;
  /** Null when the author had already deleted it. */
  target: {
    body: string;
    status: CommunityContentStatus;
    author: ICommunityAuthor;
    reportCount: number;
    /**
     * Hidden by the report count rather than by a moderator. Keeping it puts it
     * back; keeping something a moderator hid does not.
     */
    hiddenByReports?: boolean;
  } | null;
  createdAt: string;
}

export interface ICommunitySanction {
  _id: string;
  userId: string;
  /** Null means indefinite. */
  mutedUntil?: string | null;
  reason: string;
  createdByUserId: string;
  revokedAt?: string | null;
  createdAt: string;
}

export interface ICommunityWeeklyPayload {
  title: ITranslation;
  note?: ITranslation;
  weekNumber: number;
  year: number;
  startsAt: string;
  endsAt: string;
}

export interface ICommunityOfficialPostPayload {
  subject?: string;
  body: string;
  locale: string;
  topicId?: string;
  images?: string[];
  attachedCourseId?: string;
  isPinned?: boolean;
}

export interface IPagedResponse<T> {
  items: T[];
  currentPage: number;
  totalPages: number;
  itemsPerPage: number;
}
