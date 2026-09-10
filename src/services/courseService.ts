import {
  CourseListQuery,
  CoursePayload,
  RoadmapPayload,
} from "../types/interface/course.interface";
import axiosClient from "./axiosClient";
import { unwrapApi } from "../utils/unwrapApi";

export interface DriveSyncEntityStats {
  created: number;
  updated: number;
}

export interface DriveSyncResult {
  fileId: string;
  fileName: string;
  courseId?: string;
  /** Tag được phát hành cho khoá này nếu bật autoTag, null nếu không. */
  autoTaggedAs?: string | null;
  action: "created" | "updated" | "noop" | "failed";
  stats?: Record<string, DriveSyncEntityStats>;
  errorCount: number;
  errors: Array<{
    sheet: string;
    row: number;
    column?: string;
    message: string;
  }>;
}

export const courseService = {
  async getList(params?: Partial<CourseListQuery>) {
    const res = await axiosClient.get("/courses", { params });
    return res.data;
  },

  async getById(id: string) {
    const res = await axiosClient.get(`/courses/${id}`);
    return res.data;
  },

  async getRoadmap(id: string) {
    const res = await axiosClient.get(`/courses/${id}/roadmap`);
    return res.data;
  },

  async create(payload: Partial<CoursePayload>) {
    return axiosClient.post(`/courses`, payload, {});
  },

  async update(id: string, payload: Partial<CoursePayload>) {
    return axiosClient.put(`/courses/${id}`, payload, {});
  },

  async updateRoadmap(id: string, payload: Partial<RoadmapPayload>) {
    return axiosClient.put(`/courses/${id}/roadmap`, payload, {});
  },

  async remove(id: string) {
    return axiosClient.delete(`/courses/${id}`);
  },

  async downloadTemplate() {
    return axiosClient.get(`/courses/import/template`, {
      responseType: "blob",
    });
  },

  async exportExcel() {
    return axiosClient.get(`/courses/export`, {
      responseType: "blob",
    });
  },

  /**
   * `version` xuất một tag đã đóng băng thay vì bản đang sửa ("v1.0.0" hoặc
   * "current"). Id trong tag là id thật, nên import lại workbook đó chính là
   * cách khôi phục nội dung của tag đó lên bản đang sửa.
   */
  async exportCourseFull(courseId: string, version?: string) {
    return axiosClient.get(`/course-content-transfers/${courseId}/export`, {
      responseType: "blob",
      params: version ? { version } : undefined,
    });
  },

  async downloadFullTemplate() {
    return axiosClient.get(`/course-content-transfers/template`, {
      responseType: "blob",
    });
  },

  async importCourseContent(file: File) {
    const formData = new FormData();
    formData.append("file", file);
    return axiosClient.post(`/course-content-transfers/import`, formData, {
      responseType: "blob",
      headers: { "Content-Type": "multipart/form-data" },
    });
  },

  async pushCourseToDrive(courseId: string) {
    const res = await axiosClient.post(
      `/course-content-transfers/${courseId}/push-to-drive`
    );
    return res.data as { fileId: string; webViewLink?: string };
  },

  /**
   * Kéo về ĐÚNG MỘT khoá — nửa lẻ của [syncFromDrive], cùng luồng import và
   * cùng kiểu kết quả, chỉ khác là không đụng tới các khoá khác trong folder.
   */
  async pullCourseFromDrive(courseId: string, autoTag = false) {
    const res = await axiosClient.post(
      `/course-content-transfers/${courseId}/pull-from-drive`,
      { autoTag }
    );
    return unwrapApi<DriveSyncResult>(res.data);
  },

  /**
   * `autoTag` phát hành luôn: mỗi khoá import sạch lỗi sẽ được đánh tag patch
   * kế tiếp và trỏ current sang đó. Mặc định tắt — sync chỉ ghi vào bản đang
   * sửa, nên nếu không bật thì app vẫn phát tag cũ.
   */
  async syncFromDrive(fileId?: string, autoTag = false) {
    const res = await axiosClient.post(`/course-content-transfers/drive-sync`, {
      fileId,
      autoTag,
    });
    // Bị bọc phong bì như mọi response JSON khác; trả thẳng `res.data` thì
    // `syncResults.map` trong CourseList nổ và trắng cả trang.
    return unwrapApi<DriveSyncResult[]>(res.data);
  },

  async importExcel(file: File) {
    const formData = new FormData();
    formData.append("file", file);
    return axiosClient.post(`/courses/import`, formData, {
      responseType: "blob",
      headers: { "Content-Type": "multipart/form-data" },
    });
  },
};
