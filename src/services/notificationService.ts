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
      deeplink?: string;
      copies?: { locale: string; title: string; body: string }[];
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

  /** Fires one notification at one user, ignoring schedule/condition/caps. */
  async sendTest(
    type: NotificationType,
    userId: string
  ): Promise<{ sent: boolean; reason?: string; conditionMet?: boolean }> {
    const res = await axiosClient.post(
      "/notifications/test-send",
      { type, userId },
      {}
    );
    return unwrapData<{ sent: boolean; reason?: string }>(res.data);
  },
};
