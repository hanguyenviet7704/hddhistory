import {
  NotificationCampaign,
  NotificationCampaignCopy,
  NotificationCampaignSendMode,
  NotificationCampaignSendRow,
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

/**
 * Những gì `POST /notifications/test-send` thật sự trả về.
 *
 * `reason` KHÔNG nằm trong đó — nhưng UI lại đọc đúng field đó, nên mọi lần
 * gửi thử hỏng đều hiện "Không gửi: không rõ" dù server đã nói rõ vì sao.
 * `failures` là mã lỗi FCM cho từng token (`messaging/...`), thứ phân biệt
 * token hết hạn với khoá APNs chưa cấu hình.
 */
export interface TestSendResult {
  sent: boolean;
  conditionMet?: boolean;
  variantKey?: string;
  successCount?: number;
  failureCount?: number;
  failures?: string[];
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
       * Ảnh kèm noti. Chuỗi rỗng xoá ảnh — API chỉ để nguyên ảnh cũ khi field
       * này vắng mặt hoàn toàn.
       */
      imageUrl?: string;
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
    /** Chỉ ảnh hưởng số click. Bỏ trống thì API dùng `prod`. */
    appEnv?: string;
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
  ): Promise<TestSendResult> {
    const res = await axiosClient.post(
      "/notifications/test-send",
      { type, userId, ...(variantKey ? { variantKey } : {}) },
      {}
    );
    return unwrapData<TestSendResult>(res.data);
  },

  // ------------------------------------------------------- manual campaigns

  /**
   * `appEnv` chỉ lọc phần CLICK — số gửi là sổ sách của chính API, không gắn môi
   * trường nào. Đọc campaign bắn cho user thật bằng `dev` sẽ ra số gửi đúng nằm
   * cạnh 0 click, nên mặc định để server quyết (`prod`).
   */
  async listCampaigns(appEnv?: string): Promise<NotificationCampaign[]> {
    const res = await axiosClient.get("/notifications/campaigns", {
      params: appEnv ? { appEnv } : undefined,
    });
    return unwrapData<NotificationCampaign[]>(res.data);
  },

  /** How many push-reachable users the targeting would hit, before sending. */
  async previewCampaign(segmentIds: string[]): Promise<{
    reach: number;
    targeted: boolean;
  }> {
    const res = await axiosClient.post("/notifications/campaigns/preview", {
      segmentIds,
    });
    return unwrapData<{ reach: number; targeted: boolean }>(res.data);
  },

  async createCampaign(payload: {
    name: string;
    copies: NotificationCampaignCopy[];
    deeplink: string;
    /** Tham số tuỳ chọn của đích (ví dụ `{ variant: "full" }` cho paywall). */
    deeplinkParams?: Record<string, string>;
    /** Ảnh kèm noti, dùng chung cho mọi locale. Chuỗi rỗng = không có ảnh. */
    imageUrl?: string;
    segmentIds: string[];
    sendMode: NotificationCampaignSendMode;
    localHour?: number;
    localMinute?: number;
    scheduledDate?: string;
  }): Promise<NotificationCampaign> {
    const res = await axiosClient.post("/notifications/campaigns", payload);
    return unwrapData<NotificationCampaign>(res.data);
  },

  /**
   * Sửa một campaign NHÁP. API từ chối mọi trạng thái khác (`queued` có thể đã
   * gửi được một nửa, chữ đã nằm trên máy người ta), nên nút Sửa chỉ hiện ở dòng
   * nháp — lỗi 400 ở đây là đã có ai đó bấm Gửi trong lúc mình đang soạn.
   */
  async updateCampaign(
    id: string,
    payload: {
      name?: string;
      copies?: NotificationCampaignCopy[];
      deeplink?: string;
      /** Gửi cùng `deeplink`: đổi đích thì API lọc lại bộ này theo đích mới. */
      deeplinkParams?: Record<string, string>;
      /** Chuỗi rỗng xoá ảnh; vắng mặt thì giữ ảnh cũ. */
      imageUrl?: string;
      segmentIds?: string[];
      sendMode?: NotificationCampaignSendMode;
      localHour?: number;
      localMinute?: number;
      scheduledDate?: string;
    },
  ): Promise<NotificationCampaign> {
    const res = await axiosClient.put(`/notifications/campaigns/${id}`, payload);
    return unwrapData<NotificationCampaign>(res.data);
  },

  async queueCampaign(id: string): Promise<NotificationCampaign> {
    const res = await axiosClient.post(`/notifications/campaigns/${id}/queue`);
    return unwrapData<NotificationCampaign>(res.data);
  },

  async cancelCampaign(id: string): Promise<NotificationCampaign> {
    const res = await axiosClient.post(`/notifications/campaigns/${id}/cancel`);
    return unwrapData<NotificationCampaign>(res.data);
  },

  async campaignSends(
    id: string,
    page = 1,
    take = 20,
  ): Promise<{
    items: NotificationCampaignSendRow[];
    currentPage: number;
    totalPages: number;
    totalItems: number;
  }> {
    const res = await axiosClient.get(
      `/notifications/campaigns/${id}/sends`,
      { params: { page, take } },
    );
    return unwrapData<{
      items: NotificationCampaignSendRow[];
      currentPage: number;
      totalPages: number;
      totalItems: number;
    }>(res.data);
  },
};
