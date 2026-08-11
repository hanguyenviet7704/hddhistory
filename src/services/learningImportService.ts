import {
  CreateLearningImportPayload,
  ILearningImportDetail,
  ILearningImportRow,
  ImportQuota,
  LearningImportListQuery,
  LearningImportListResponse,
} from "../types/interface/learningImport.interface";
import axiosClient from "./axiosClient";

/**
 * Read-only view of what users import and what the AI writes back.
 *
 * The API wraps every response as `{ statusCode, message, data }`
 * (ResponseInterceptor), so the payload is one level down; the `?? res.data`
 * fallback matches the other admin services.
 *
 * Nothing here exposes the uploaded file itself — by design, the panel shows the
 * source's NAME and the generated lesson, not the user's original document.
 */
export const learningImportService = {
  async getImports(
    params?: LearningImportListQuery,
  ): Promise<LearningImportListResponse> {
    const res = await axiosClient.get("/admin/learning-imports", { params });
    return res.data?.data ?? res.data;
  },

  async getImportDetail(jobId: string): Promise<ILearningImportDetail> {
    const res = await axiosClient.get(`/admin/learning-imports/${jobId}`);
    return res.data?.data ?? res.data;
  },

  /**
   * Runs a real import as the SIGNED-IN admin.
   *
   * Deliberately the same endpoint the app calls, with the same premium and
   * quota gates — a test tool that skipped them would be exercising a different
   * system than the one users hit. The trade is that the account driving this
   * panel needs an active subscription; a rejection comes back with a `code` in
   * `errors[0]` (NOT_PREMIUM / QUOTA_EXCEEDED / JOB_ALREADY_RUNNING) so the UI
   * can say which gate closed rather than "something went wrong".
   */
  async createImport(
    payload: CreateLearningImportPayload,
  ): Promise<ILearningImportRow> {
    const res = await axiosClient.post("/learning-imports", payload);
    return res.data?.data ?? res.data;
  },

  async getQuota(): Promise<ImportQuota> {
    const res = await axiosClient.get("/learning-imports/quota");
    return res.data?.data ?? res.data;
  },
};
