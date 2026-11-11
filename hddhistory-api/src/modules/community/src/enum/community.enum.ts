export enum CommunityPostType {
  POST = 'POST',
  WEEKLY_QUESTION = 'WEEKLY_QUESTION',
}

export enum CommunityAuthorType {
  USER = 'USER',
  // Posts and comments written by the HDDhistory team from the admin panel. Rendered
  // with the team badge and allowed to be pinned.
  OFFICIAL = 'OFFICIAL',
  // The writer asked not to be named. `authorId` still holds the real account:
  // moderation, the report queue and posting bans all need to reach the person,
  // and a truly authorless row would make a ban unenforceable. Only the READER
  // views drop the identity — see CommunityAuthorService.pick.
  ANONYMOUS = 'ANONYMOUS',
}

export enum CommunityContentStatus {
  VISIBLE = 'VISIBLE',
  // Taken down by a moderator; kept in the collection so the report queue and
  // the author's notification still have something to point at.
  HIDDEN = 'HIDDEN',
  // Removed by the author.
  DELETED = 'DELETED',
}

export enum CommunityTargetType {
  POST = 'POST',
  COMMENT = 'COMMENT',
  // A message in a group chat room (design `S-03`). Reactions on one are
  // toggled by the CHAT service, not by CommunityReactionService — the shared
  // `/reactions` endpoint rejects this type on purpose, so the two paths cannot
  // be confused into bumping the wrong collection's counter.
  CHAT_MESSAGE = 'CHAT_MESSAGE',
}

export enum CommunityReactionKind {
  LIKE = 'LIKE',
  // Follow-the-thread, posts only: the bell on a post card. The reader asks to
  // be told when the thread gets a new comment, and the "Đang theo dõi" tab
  // lists exactly these posts. Stored as SAVE for the rows already written when
  // this was a bookmark.
  SAVE = 'SAVE',
}

export enum CommunityReportReason {
  SPAM = 'SPAM',
  HARASSMENT = 'HARASSMENT',
  ADULT = 'ADULT',
  MISINFORMATION = 'MISINFORMATION',
  // Revealing someone else's identity — called out explicitly in the pinned
  // house-rules post.
  PRIVACY = 'PRIVACY',
  OTHER = 'OTHER',
}

export enum CommunityReportStatus {
  PENDING = 'PENDING',
  RESOLVED_HIDDEN = 'RESOLVED_HIDDEN',
  RESOLVED_KEPT = 'RESOLVED_KEPT',
}

export enum CommunityFeedSort {
  // Newest first — the design's "Mới nhất" chip.
  RECENT = 'RECENT',
  // Most recently active thread first — the "Sôi nổi" chip. Reads
  // lastActivityAt, which a new comment bumps.
  ACTIVE = 'ACTIVE',
}

export enum CommunityNotificationType {
  COMMENT_ON_POST = 'COMMENT_ON_POST',
  REPLY_TO_COMMENT = 'REPLY_TO_COMMENT',
  // Someone liked your post. Collapsed to one row per post — see
  // CommunityNotificationService.notifyLike — so a popular post is one line
  // reading "X và N người khác", not N lines.
  LIKE_ON_POST = 'LIKE_ON_POST',
  // A thread the reader is part of got a new comment. Two ways to be part of
  // it: the bell, or having written in the thread at all — commenting
  // auto-follows, and the fan-out also reaches people who answered before that
  // was true. Never to the post's author, who gets COMMENT_ON_POST instead,
  // and never to anyone holding a community_thread_mutes row.
  COMMENT_ON_FOLLOWED_POST = 'COMMENT_ON_FOLLOWED_POST',
  // Somebody else answered the weekly question the reader has answered too.
  // The question is posted by the team, so there is no author to tell and the
  // people who care are the other answerers. Collapsed to one row per question
  // like LIKE_ON_POST — a busy week is one line, not forty.
  ANSWER_ON_WEEKLY = 'ANSWER_ON_WEEKLY',
  // NO LONGER SENT. A chat line used to notify everyone who had answered in
  // the room, rationed to once per burst — and it was still the loudest thing
  // the bell did, because a room is bursty by design and a burst is whatever
  // the throttle says it is. The fan-out was removed rather than tuned again:
  // a room is read by opening it.
  //
  // The member stays because rows written before that are still in the
  // collection and the app still has to render them.
  MESSAGE_IN_ROOM = 'MESSAGE_IN_ROOM',
  OFFICIAL_REPLY = 'OFFICIAL_REPLY',
  POST_HIDDEN = 'POST_HIDDEN',
  SANCTION_APPLIED = 'SANCTION_APPLIED',
}

export enum CommunityRoomSuggestionStatus {
  PENDING = 'PENDING',
  // A moderator opened the room. `topicId` then points at it, so the suggester
  // can be sent there.
  APPROVED = 'APPROVED',
  DECLINED = 'DECLINED',
}
