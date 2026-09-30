import { CommunityRoomSuggestionStatus } from '../../../enum/community.enum';

export interface ICommunityRoomSuggestion {
  name: string;
  description: string;
  // Who asked for it. Kept so the suggester can be told when the room opens,
  // and so one person cannot flood the queue.
  authorId: string;
  // The suggester's language. A room is opened per language demand: "Sống một
  // mình ở thành phố" asked for in Vietnamese says nothing about whether a
  // Korean room is wanted.
  locale: string;
  status: CommunityRoomSuggestionStatus;
  voterIds: string[];
  // How many readers backed it, the suggester included.
  voteCount: number;
  // Set when approved: the topic that was opened, so the suggester's
  // notification can point at a real room.
  topicId?: string;
  reviewedBy?: string;
  reviewedAt?: Date;
  reviewNote?: string;
}
