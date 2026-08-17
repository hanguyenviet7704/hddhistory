import {
  NotificationLogPage,
  NotificationLogStatus,
  NotificationSummary,
  NotificationTemplate,
  NotificationTemplateFile,
  NotificationType,
} from "../types/interface/notification.interface";
import axiosClient from "./axiosClient";

// The API wraps everything in { statusCode, message, data } and the axios client
// does not unwrap it (mirrors habitConfigService).
const unwrapData = <T>(payload: any): T => payload?.data ?? payload;

export interface NotificationLogQuery {
  page?: number;
  take?: number;
  userId?: string;
  type?: NotificationType;
  status?: NotificationLogStatus;
  fromDate?: string;
  toDate?: string;
}

export const notificationService = {
  async getTemplates(): Promise<NotificationTemplate[]> {
    const res = await axiosClient.get("/notifications/templates", {});
    return unwrapData<NotificationTemplate[]>(res.data) ?? [];
  },

  async updateTemplate(
    type: NotificationType,
    payload: {
      enabled?: boolean;
      localHour?: number;
      localMinute?: number;
      deeplink?: string;
      /**
       * Target segments (OR). `[]` clears targeting — the API only leaves
       * targeting alone when the field is absent entirely.
       */
      segmentIds?: string[];
      /** Legacy single-wording form; ignored by the API when `variants` is sent. */
      copies?: { locale: string; title: string; body: string }[];
      /**
       * The whole list, every time — a variant left out is deleted server-side,
       * which is how the page removes one. Omit `key` for a new variant.
       */
      variants?: {
        key?: string;
        copies: { locale: string; title: string; body: string }[];
      }[];
    }
  ): Promise<NotificationTemplate> {
    const res = await axiosClient.put(
      `/notifications/templates/${type}`,
      payload,
      {}
    );
    return unwrapData<NotificationTemplate>(res.data);
  },

  /** Round-trips with `exportTemplates` — same shape both ways. */
  async importTemplates(
    file: NotificationTemplateFile
  ): Promise<{ imported: NotificationType[] }> {
    const res = await axiosClient.post(
      "/notifications/templates/import",
      file,
      {}
    );
    return unwrapData<{ imported: NotificationType[] }>(res.data);
  },

  async exportTemplates(): Promise<NotificationTemplateFile> {
    const res = await axiosClient.get("/notifications/templates/export", {});
    return unwrapData<NotificationTemplateFile>(res.data);
  },

  async getLogs(query: NotificationLogQuery): Promise<NotificationLogPage> {
    const res = await axiosClient.get("/notifications/logs", {
      params: query,
    });
    return unwrapData<NotificationLogPage>(res.data);
  },

  async getSummary(range: {
    fromDate?: string;
    toDate?: string;
  }): Promise<NotificationSummary> {
    const res = await axiosClient.get("/notifications/logs/summary", {
      params: range,
    });
    return unwrapData<NotificationSummary>(res.data);
  },

  /**
   * Fires one notification at one user, ignoring schedule/condition/caps.
   * `variantKey` pins the wording; omitted, the server picks as it would in
   * production and reports which one it used.
   */
  async sendTest(
    type: NotificationType,
    userId: string,
    variantKey?: string
  ): Promise<{
    sent: boolean;
    reason?: string;
    conditionMet?: boolean;
    variantKey?: string;
  }> {
    const res = await axiosClient.post(
      "/notifications/test-send",
      { type, userId, ...(variantKey ? { variantKey } : {}) },
      {}
    );
    return unwrapData<{
      sent: boolean;
      reason?: string;
      conditionMet?: boolean;
      variantKey?: string;
    }>(res.data);
  },
};
