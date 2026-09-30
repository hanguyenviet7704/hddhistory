import { ITranslation } from '@utils/interface/common.interface';

import {
  CommunityAuthorType,
  CommunityContentStatus,
  CommunityFeedSort,
  CommunityPostType,
} from '../../../enum/community.enum';
import {
  ICommunityAttachedCard,
  ICommunityWeeklyWindow,
} from '../../../interface/community.interface';

export interface ICommunityPost {
  type: CommunityPostType;
  authorType: CommunityAuthorType;
  authorId: string;
  topicId?: string;
  // Null for a WEEKLY_QUESTION: the team authors it in all five languages, so
  // it is shown to every reader and rendered in their own.
  locale?: string;
  // The headline the writer types above the story. Plain text, in the writer's
  // own language — unlike `title`, which is the team's five-language field on a
  // WEEKLY_QUESTION.
  subject: string;
  body: string;
  images: string[];
  attachedCourseId?: string;
  attachedCard?: ICommunityAttachedCard;
  status: CommunityContentStatus;
  hiddenReason?: string;
  moderatedBy?: string;
  moderatedAt?: Date;
  isPinned: boolean;
  pinnedAt?: Date;
  commentsLocked: boolean;
  likeCount: number;
  commentCount: number;
  saveCount: number;
  reportCount: number;
  lastActivityAt: Date;
  weekly?: ICommunityWeeklyWindow;
  title?: ITranslation;
  note?: ITranslation;
}

// One reader's view of the feed, resolved by the service before it reaches the
// repository: their locale, the topic scope, and the ids they have hidden.
export interface IFeedQuery {
  locale: string;
  topicId?: string;
  // Set (possibly empty) for the "following only" tab. Undefined means no
  // topic restriction at all.
  topicIds?: string[];
  // Set (possibly empty) for the "Đang theo dõi" tab: the posts this reader
  // put the bell on. Undefined means no restriction.
  includeIds?: string[];
  excludeIds?: string[];
  sort?: CommunityFeedSort;
  anchorAt?: Date;
  page?: number;
  take?: number;
}
