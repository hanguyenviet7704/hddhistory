import {
  CommunityAuthorType,
  CommunityContentStatus,
  CommunityPostType,
} from '../enum/community.enum';

// The five locales the app ships. A post carries the locale of whoever wrote it
// and the feed only shows posts in the reader's own language, so a Korean
// reader never lands in a wall of Vietnamese.
export const COMMUNITY_LOCALES = ['en', 'vi', 'zh', 'ja', 'ko'] as const;
export type CommunityLocale = (typeof COMMUNITY_LOCALES)[number];

export const DEFAULT_COMMUNITY_LOCALE: CommunityLocale = 'en';

// Per-locale counters kept on a topic. Follower and weekly-post counts are
// counted per locale for the same reason the feed is filtered per locale:
// a shared "12.4k people" next to an empty feed is a lie.
export interface ICommunityTopicLocaleStats {
  followers: number;
  postsThisWeek: number;
}

export type ICommunityTopicStats = Partial<
  Record<CommunityLocale, ICommunityTopicLocaleStats>
>;

// Author identity resolved at read time from the users collection rather than
// copied onto every post, so a profile rename shows up everywhere at once.
export interface ICommunityAuthor {
  id: string;
  name: string;
  avatar?: string;
  authorType: CommunityAuthorType;
}

// A keypoint card the writer attached from their library, copied onto the post
// rather than looked up. The card is a SNAPSHOT on purpose: the feed resolves
// three lookups per page and a fourth into the courses module would cost a
// query per post, and a keypoint later edited or unpublished must not blank out
// a post someone wrote around it.
export interface ICommunityAttachedCard {
  keypointId: string;
  title: string;
  back: string;
  courseName?: string;
}

export interface ICommunityWeeklyWindow {
  weekNumber: number;
  year: number;
  startsAt: Date;
  endsAt: Date;
}

export interface ICommunityViewerFlags {
  isLiked: boolean;
  isSaved: boolean;
  isMine: boolean;
}

export interface ICommunityPostBase {
  type: CommunityPostType;
  authorType: CommunityAuthorType;
  authorId: string;
  status: CommunityContentStatus;
}
