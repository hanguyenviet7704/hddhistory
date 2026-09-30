import {
  CommunityReactionKind,
  CommunityTargetType,
} from '../../../enum/community.enum';

export interface ICommunityReaction {
  targetType: CommunityTargetType;
  targetId: string;
  userId: string;
  kind: CommunityReactionKind;
}

export interface ICommunityTopicFollow {
  topicId: string;
  userId: string;
  // Copied from the user at follow time so follower counts can be reported per
  // locale without joining the users collection.
  locale: string;
}

export interface ICommunityHiddenItem {
  userId: string;
  targetType: CommunityTargetType;
  targetId: string;
}

export interface ICommunityThreadMute {
  userId: string;
  /**
   * The thread this reader switched off. Written only when the bell is tapped
   * off by hand — commenting auto-follows, and this row is what stops that
   * from overriding a deliberate "leave me out of it".
   */
  postId: string;
}
