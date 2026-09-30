import { HttpException, HttpStatus } from '@nestjs/common';

/**
 * The most rows any reader-facing community list hands back in one page.
 *
 * The shared `PageOptionsDto` caps nothing — its `minimum`/`default` are Swagger
 * metadata, not validators — so `?take=100000` is otherwise one request that
 * reads the whole forum out of Mongo. 50 is comfortably above the biggest page
 * the app actually asks for (the chat's 30).
 */
export const COMMUNITY_MAX_TAKE = 50;

export function communityTake(take?: number) {
  if (!take || take < 1) return 10;

  return Math.min(take, COMMUNITY_MAX_TAKE);
}

/**
 * How many DIFFERENT readers have to report one item before it leaves the feed
 * on its own.
 *
 * Reports are one per reader per item, so this is a count of people, not of
 * taps. Five is high enough that a disagreement between two readers cannot take
 * a post down and low enough that genuine spam is gone in minutes rather than
 * whenever a moderator next opens the panel.
 *
 * What it does is PROVISIONAL: the reports stay open, the queue still shows the
 * item, and a moderator either confirms the hide or puts it back. Auto-hiding is
 * the fast half of moderation, never the verdict — brigading a post you dislike
 * has to cost the brigade something, and here it costs them a moderator reading
 * the post they reported.
 */
export const COMMUNITY_AUTO_HIDE_REPORTS = 5;

/**
 * Stamped as the hidden reason when the report count did it rather than a
 * person. Bookkeeping, not a sentence for anyone to read — the panel turns it
 * into a flag, exactly like the comment cascade marker.
 */
export const COMMUNITY_AUTO_HIDDEN_REASON = '__AUTO_REPORTED__';

/** Stands in for the moderator id on an action nobody took by hand. */
export const COMMUNITY_AUTO_MODERATOR_ID = '__AUTO__';

/**
 * How much one account may write, per kind of write.
 *
 * Per account, not per IP: the whole forum sits behind `AuthGuard`, a phone's IP
 * changes on the walk out of the house, and an office NAT would otherwise put a
 * whole team on one budget. Counted from the content itself rather than from an
 * in-memory counter, so the ceiling survives a restart and holds identically in
 * every process the API runs in.
 */
export interface ICommunityWriteLimit {
  /** The rolling window the ceiling is counted over. */
  windowMs: number;

  /** Writes of this kind one account may make inside that window. */
  max: number;

  /** How long the same text, word for word, is refused after it first landed. */
  duplicateMs: number;

  /**
   * The shortest text the duplicate rule applies to.
   *
   * Short repeats are how people actually talk: "ok", "cảm ơn bạn", "haha" go
   * into a chat room and under two different threads within the same minute, and
   * refusing the second one would be the app calling a normal conversation spam.
   * Above this length, saying exactly the same thing twice is a choice.
   */
  duplicateMinLength: number;
}

/**
 * Posts: generous by the hour, strict about repetition.
 *
 * Someone with a lot to say writes three or four threads in a sitting; eight is
 * clear of that and well under what a script needs to bury the feed. The
 * duplicate window is a day, because the spam that actually hurts a small forum
 * is the same post pushed back to the top.
 */
export const COMMUNITY_POST_LIMIT: ICommunityWriteLimit = {
  windowMs: 60 * 60 * 1000,
  max: 8,
  duplicateMs: 24 * 60 * 60 * 1000,
  // Low, because a post is a story with a headline over it: nobody opens two
  // threads a day whose whole body is the same eight words by accident.
  duplicateMinLength: 8,
};

/** Comments: a busy reader in one thread, not a bot walking every thread. */
export const COMMUNITY_COMMENT_LIMIT: ICommunityWriteLimit = {
  windowMs: 10 * 60 * 1000,
  max: 30,
  duplicateMs: 10 * 60 * 1000,
  // "Cảm ơn bạn đã chia sẻ" under three posts in ten minutes is a kind reader,
  // not a bot.
  duplicateMinLength: 30,
};

/**
 * Chat: the one place a fast burst is normal.
 *
 * Twenty lines a minute is a heated conversation; it is also slow enough that
 * flooding the room takes longer than a moderator needs to get there. What gets
 * caught here is repetition, not speed.
 */
export const COMMUNITY_CHAT_LIMIT: ICommunityWriteLimit = {
  windowMs: 60 * 1000,
  max: 20,
  duplicateMs: 60 * 1000,
  // The highest of the three: a chat is mostly short lines, and half of them
  // repeat inside a minute by the ordinary rules of conversation.
  duplicateMinLength: 40,
};

/** What a repository reports back about one author's recent writes. */
export interface ICommunityWriteStats {
  count: number;

  /**
   * The oldest write still inside the window — when the ceiling starts lifting.
   */
  oldestAt: Date | null;
}

/**
 * Refuses a write that is over the ceiling, or that says word for word what
 * this author has just said.
 *
 * 429 with a stable code, not 403: the muted case (`COMMUNITY_MUTED`) has to
 * stay distinguishable from this one, because one lifts by itself in a minute
 * and the other needs a moderator.
 */
export function assertWithinWriteLimit(
  stats: ICommunityWriteStats,
  limit: ICommunityWriteLimit,
  isDuplicate = false,
) {
  if (isDuplicate) {
    throw new HttpException(
      { message: 'COMMUNITY_DUPLICATE_CONTENT' },
      HttpStatus.TOO_MANY_REQUESTS,
    );
  }

  if (stats.count < limit.max) return;

  // The window rolls, so the ceiling lifts when the oldest write inside it ages
  // out. Quoting the whole window instead would tell a reader who is one post
  // over to come back in an hour.
  const liftsAt = (stats.oldestAt?.getTime() ?? Date.now()) + limit.windowMs;
  const retryAfterSeconds = Math.max(
    1,
    Math.ceil((liftsAt - Date.now()) / 1000),
  );

  // In `meta`, not at the top level: the global exception filter forwards
  // `message`, `errors` and `meta`, and drops everything else.
  throw new HttpException(
    { message: 'COMMUNITY_RATE_LIMITED', meta: { retryAfterSeconds } },
    HttpStatus.TOO_MANY_REQUESTS,
  );
}
