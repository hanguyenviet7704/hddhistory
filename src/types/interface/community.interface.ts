import { ITranslation } from "../../utils/translation";

export enum CommunityPostType {
  POST = "POST",
  WEEKLY_QUESTION = "WEEKLY_QUESTION",
}

export enum CommunityAuthorType {
  USER = "USER",
  OFFICIAL = "OFFICIAL",
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
  body: string;
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
  reportCount: number;
  hiddenReason?: string;
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
  createdAt: string;
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
