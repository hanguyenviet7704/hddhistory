/**
 * Who hears that a thread they are part of has moved on.
 *
 * Two halves, because "part of" means two different things. The FOLLOWERS put
 * the bell on the post and asked in so many words. The COMMENTERS never
 * touched the bell — they just answered — and until auto-follow started
 * writing a SAVE row for them, they were told nothing at all: you could write
 * the first reply in a thread and never learn that eleven more had arrived.
 * Auto-follow fixes that going forward, but only forward, so the commenter
 * half is also what covers everyone who had already written before it shipped
 * — the alternative was a backfill that would have invented a follow for tens
 * of thousands of old rows and inflated every old post's follower count.
 *
 * [alreadyNotified] is whoever the caller has already told about this exact
 * comment by name — the post's author, the parent comment's author, the person
 * answered with an "@". One comment is worth at most one notification per
 * person; three is how a badge stops meaning anything.
 *
 * [mutedUserIds] is what keeps the bell honest. Turning it off deletes the
 * SAVE row, which is enough to drop someone from the follower half but nothing
 * at all to the commenter half — they would keep hearing about a thread they
 * had explicitly asked to be left out of, and the button would look broken.
 *
 * Followers come before commenters only so the result is stable and a test can
 * assert on it; nothing downstream reads the order.
 */
export function threadFollowUpRecipients(params: {
  followerIds: string[];
  commenterIds: string[];
  alreadyNotified: Iterable<string>;
  mutedUserIds?: Iterable<string>;
}): string[] {
  const notified = new Set(params.alreadyNotified);
  const muted = new Set(params.mutedUserIds ?? []);
  const seen = new Set<string>();

  return [...params.followerIds, ...params.commenterIds].filter((userId) => {
    if (!userId || seen.has(userId)) return false;
    seen.add(userId);

    return !notified.has(userId) && !muted.has(userId);
  });
}
