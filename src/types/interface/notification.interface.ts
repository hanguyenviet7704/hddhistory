// Mirrors meup-api src/modules/notification.
export type NotificationType =
  | "daily_remind"
  | "progress_finish"
  | "progress_start"
  | "habit_tracking"
  | "new_course";

export type NotificationLogStatus = "sent" | "failed" | "skipped";

export type NotificationDeeplink =
  | "home"
  | "resume_lesson"
  | "habit_tracker"
  | "new_course"
  /**
   * The Explore tab. Newer than the others: an app build that predates it treats
   * the value as unknown and does not navigate at all, so only pick this once the
   * release that handles it is live.
   */
  | "explore";

export interface NotificationCopy {
  locale: string;
  title: string;
  body: string;
}

/**
 * One wording of a notification, in every locale it has.
 *
 * `key` comes from the server and must be sent back unchanged when editing:
 * the "not the same wording as the last three days per user" memory is keyed by
 * it, so a new key resets that memory for the sentence.
 */
export interface NotificationVariant {
  key: string;
  copies: Record<string, { title: string; body: string }>;
}

export interface NotificationTemplate {
  _id?: string;
  type: NotificationType;
  enabled: boolean;
  /** Hour of the USER's own day (0-23), not server time. */
  localHour: number;
  /** Minute within [localHour] (0-59). Absent on templates saved before it existed. */
  localMinute?: number;
  deeplink: NotificationDeeplink;
  /**
   * Legacy single wording, kept by the server in step with the first variant.
   * The page reads `variants` and only falls back here for a template saved
   * before variants existed.
   */
  copies: Record<string, { title: string; body: string }>;
  variants?: NotificationVariant[];
}

/** Shape of both `GET templates/export` and `POST templates/import`. */
export interface NotificationTemplateFile {
  templates: {
    type: NotificationType;
    enabled: boolean;
    localHour: number;
    localMinute?: number;
    deeplink: NotificationDeeplink;
    copies?: NotificationCopy[];
    variants?: { key?: string; copies: NotificationCopy[] }[];
  }[];
}

export interface NotificationLog {
  _id: string;
  userId: string;
  type: NotificationType;
  /** The user's own calendar day, `YYYY-MM-DD`. */
  localDate: string;
  status: NotificationLogStatus;
  sentAt: string;
  locale?: string;
  title?: string;
  body?: string;
  deeplink?: string;
  reason?: string;
  deviceCount?: number;
  successCount?: number;
  failureCount?: number;
  meta?: Record<string, unknown>;
}

export interface NotificationLogPage {
  items: NotificationLog[];
  itemsPerPage: number;
  totalPages: number;
  currentPage: number;
}

export interface NotificationSummary {
  fromDate: string;
  toDate: string
  byType: Record<string, Record<NotificationLogStatus, number>>;
}
