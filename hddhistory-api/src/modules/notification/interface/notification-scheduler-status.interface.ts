/**
 * Health of the notification cron inside the CURRENT process.
 *
 * Deliberately not persisted: the question it answers — "did the tick run at
 * all" — is the one Mongo cannot answer, because a tick that never fires, or one
 * that throws before it reaches the users query, writes nothing. Every field
 * resets on restart, which is honest: a fresh process has ticked zero times.
 */
export interface INotificationSchedulerStatus {
  /** When this process started ticking. `tickCount` is counted from here. */
  startedAt: Date;

  /** Server time when the status was read, so a stale `lastTickAt` is obvious. */
  now: Date;

  isRunning: boolean;

  tickCount: number;

  /** Null means the cron has never fired in this process. */
  lastTickAt: Date | null;

  /** Last tick where some template's local send time had come round somewhere. */
  lastDueAt: Date | null;

  /** Last tick that actually delivered to at least one device. */
  lastSentAt: Date | null;

  /** Per-type send counts from the most recent tick that had anything due. */
  lastResults: Record<string, number> | null;

  lastError: string | null;
  lastErrorAt: Date | null;
}
