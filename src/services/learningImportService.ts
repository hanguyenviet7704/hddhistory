import {
  ILearningImportDetail,
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
};
