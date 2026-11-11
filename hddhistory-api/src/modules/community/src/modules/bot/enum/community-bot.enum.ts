export enum CommunityBotKind {
  CHAT = 'CHAT',
  POST = 'POST',
  COMMENT = 'COMMENT',
}

export enum CommunityBotQueueStatus {
  /** Written by a plan, not published yet — the only status admin may edit. */
  PENDING = 'PENDING',
  SENT = 'SENT',
  /**
   * Dropped before publishing: admin cancelled it, or the thing it answers was
   * hidden while the line sat in the queue.
   */
  CANCELLED = 'CANCELLED',
  /**
   * The write itself threw. Not retried — a line that missed its moment no
   * longer fits the conversation it was written for.
   */
  FAILED = 'FAILED',
}
