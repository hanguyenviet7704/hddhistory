// Mirrors meup-api src/modules/notification.
export type NotificationType =
  | "daily_remind"
  | "progress_finish"
  | "habit_tracking";

export type NotificationLogStatus = "sent" | "failed" | "skipped";

export type NotificationDeeplink = "home" | "resume_lesson" | "habit_tracker";

export interface NotificationCopy {
  locale: string;
  title: string;
  body: string;
}

export interface NotificationTemplate {
  _id?: string;
  type: NotificationType;
  enabled: boolean;
  /** Hour of the USER's own day (0-23), not server time. */
  localHour: number;
  deeplink: NotificationDeeplink;
  /** Keyed by locale on the wire; the page works with the array form. */
  copies: Record<string, { title: string; body: string }>;
}

/** Shape of both `GET templates/export` and `POST templates/import`. */
export interface NotificationTemplateFile {
  templates: {
    type: NotificationType;
    enabled: boolean;
    localHour: number;
    deeplink: NotificationDeeplink;
    copies: NotificationCopy[];
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
