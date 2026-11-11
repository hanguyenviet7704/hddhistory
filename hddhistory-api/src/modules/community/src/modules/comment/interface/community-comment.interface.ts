import {
  CommunityAuthorType,
  CommunityContentStatus,
} from '../../../enum/community.enum';

export interface ICommunityComment {
  postId: string;
  // Null for a top-level comment. A reply always points at a top-level
  // comment — the design nests exactly two levels, never deeper.
  parentId?: string;
  // Drives the "@name" prefix on a reply to a reply.
  replyToUserId?: string;
  authorId: string;
  authorType: CommunityAuthorType;
  body: string;
  status: CommunityContentStatus;
  likeCount: number;
  replyCount: number;
  reportCount: number;
}
