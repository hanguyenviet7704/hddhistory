/**
 * The slice of transcript a jump lands in.
 *
 * Tapping a pinned line has to work when that line is five hundred messages
 * back — far outside the thirty the screen is holding. Rather than page
 * backwards until it turns up, the server answers with a WINDOW centred on the
 * message, and the screen swaps its list for that window.
 *
 * The two halves arrive from separate queries, each running straight down the
 * {roomId, status, createdAt} index in its own direction, and each over-fetched
 * by one. That extra row is the whole point of [hasOlder] / [hasNewer]: without
 * it, a half that comes back exactly full is indistinguishable from the end of
 * the room, and the screen would either hide the way back to the live bottom or
 * offer it on a window that is already there.
 *
 * [olderNewestFirst] starts AT the anchor and walks back; [newerOldestFirst]
 * starts just after it and walks forward. The result is newest-first — the
 * same shape page 1 comes back in, so the client swaps one for the other
 * without reversing anything differently.
 */
export function assembleChatContextWindow<T>(params: {
  olderNewestFirst: T[];
  newerOldestFirst: T[];
  /** How many messages to keep on each side of the anchor. */
  half: number;
}): { items: T[]; hasOlder: boolean; hasNewer: boolean } {
  // +1 because this half carries the anchor itself.
  const older = params.olderNewestFirst.slice(0, params.half + 1);
  const newer = params.newerOldestFirst.slice(0, params.half);

  return {
    items: [...newer].reverse().concat(older),
    hasOlder: params.olderNewestFirst.length > params.half + 1,
    hasNewer: params.newerOldestFirst.length > params.half,
  };
}
