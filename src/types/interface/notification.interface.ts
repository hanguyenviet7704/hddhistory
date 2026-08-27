// Mirrors meup-api src/modules/notification.
export type NotificationType =
  | "daily_remind"
  | "progress_finish"
  | "progress_start"
  | "habit_tracking"
  | "new_course"
  | "weekly_recap_ready"
  | "weekly_recap_reminder"
  | "coach_plan_reminder";

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
  | "explore"
  /**
   * The week-recap poster. Same caveat as `explore`: only app builds that ship
   * the week-recap feature route it; older ones just open the app.
   */
  | "week_recap"
  /**
   * The AI Coach sheet, opened on the commitment a ④ push is about. Same
   * caveat again — an older build logs it and just opens the app, which is the
   * right degradation here since the bubble is on Home anyway.
   */
  | "coach";

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
   * Ảnh kèm noti, dùng chung cho mọi locale. `null`/absent = noti chỉ có chữ.
   *
   * Android hiện ảnh ở mọi trạng thái app. iOS chỉ hiện khi bản app có
   * NotificationService extension — bản cũ hơn vẫn nhận noti, chỉ mất ảnh.
   */
  imageUrl?: string | null;
  /**
   * Target segments (OR). Empty/absent = send to everybody, which is what every
   * type did before targeting existed.
   */
  segmentIds?: string[];
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
    imageUrl?: string | null;
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

/**
 * `byType[type].clicks` là số lần CHẠM vào noti loại đó, đọc từ event `noti_tap`
 * app bắn lên (`user_events`) — collection khác với chỗ ghi số gửi, join với nhau
 * chỉ bằng loại noti. Nên nó chính xác theo khoảng ngày và mờ ở từng ngày lẻ:
 * người nhận push 21:00 rồi chạm 8:00 sáng hôm sau sẽ tính vào ngày hôm sau.
 * Chỉ có dữ liệu từ 2026-08-08 (bản app đầu tiên bắn event này) và event tự xoá
 * sau 90 ngày.
 */
export interface NotificationSummary {
  fromDate: string;
  toDate: string
  /** Môi trường app mà số CLICK được đếm trong đó (số gửi không có env). */
  appEnv?: string;
  byType: Record<
    string,
    Record<NotificationLogStatus, number> & { clicks?: number }
  >;
}

// ---------------------------------------------------------------------------
// Manual campaigns (thủ công theo segment)
// ---------------------------------------------------------------------------

export type NotificationCampaignSendMode = "now" | "local_hour";

export type NotificationCampaignStatus =
  | "draft"
  | "queued"
  | "sending"
  | "sent"
  | "cancelled"
  | "failed";

export interface NotificationCampaignCopy {
  locale: string;
  title: string;
  body: string;
}

export interface NotificationCampaign {
  _id: string;
  name: string;
  /** `{ locale: { title, body } }` as stored; the editor works on a list. */
  copies: Record<string, { title: string; body: string }>;
  /**
   * Khoá màn đích. KHÔNG phải `NotificationDeeplink`: campaign trỏ được tới cả
   * khoá của danh mục deeplink (`library`, `paywall`, `daily-warm-up`…) — API
   * validate bằng `CAMPAIGN_DEEPLINK_KEYS`, hợp của hai họ khoá.
   */
  deeplink: string;
  /**
   * Ảnh kèm noti, dùng chung cho mọi locale. `null`/absent = noti chỉ có chữ.
   *
   * Android hiện ảnh ở mọi trạng thái app. iOS chỉ hiện khi bản app có
   * NotificationService extension — bản cũ hơn vẫn nhận noti, chỉ mất ảnh.
   */
  imageUrl?: string | null;
  segmentIds?: string[];
  sendMode: NotificationCampaignSendMode;
  localHour: number;
  localMinute: number;
  scheduledDate?: string | null;
  status: NotificationCampaignStatus;
  sentCount: number;
  failedCount: number;
  /** Reached but not sent to (no live token / already handled). */
  skippedCount: number;
  startedAt?: string | null;
  finishedAt?: string | null;
  lastError?: string | null;
  createdAt?: string;
  /**
   * Số LẦN chạm vào push của campaign này, đếm từ event `noti_tap` app bắn lên
   * kèm `campaign_id`. Chỉ tính app build từ 25/08/2026 trở đi và event tự xoá
   * sau 90 ngày, nên đây là con số sàn chứ không phải tổng.
   */
  clicks?: number;
  /** Số NGƯỜI đã chạm — mẫu số an toàn cho CTR, mở lại 3 lần vẫn là 1 người. */
  clickedUsers?: number;
}

export interface NotificationCampaignSendRow {
  userId: string;
  status: string;
  sentAt: string;
  deviceCount: number;
  successCount: number;
  failureCount: number;
  reason?: string | null;
  locale?: string | null;
}
