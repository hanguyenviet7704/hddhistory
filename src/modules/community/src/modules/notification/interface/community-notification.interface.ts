import { CommunityAuthorType, CommunityNotificationType } from '../../../enum/community.enum';

export interface ICommunityNotification {
  // The recipient.
  userId: string;
  type: CommunityNotificationType;
  actorId?: string;
  /**
   * Was `actorId` acting as the team when this fired — an admin's "trả lời
   * với tư cách HDDhistory", not their own account.
   *
   * Read back at LIST time to pick the right identity for `actorId`
   * (`CommunityAuthorService.pick`): without this, a re-read has no way to
   * tell an official reply from an ordinary one and defaults to the real
   * account, which is exactly the leak this field exists to close. `actorId`
   * itself stays the real admin — moderation still needs to know who,
   * `official()` already ignores it for the NAME it shows a reader.
   */
  actorType?: CommunityAuthorType;
  postId?: string;
  commentId?: string;
  /** MESSAGE_IN_ROOM only — the discussion room, and the slug the app routes by. */
  roomId?: string;
  roomSlug?: string;
  actorCount: number;
  isRead: boolean;
}
