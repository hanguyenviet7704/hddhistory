import {
  CourseListQuery,
  CoursePayload,
  RoadmapPayload,
} from "../types/interface/course.interface";
import axiosClient from "./axiosClient";

export interface DriveSyncEntityStats {
  created: number;
  updated: number;
}

export interface DriveSyncResult {
  fileId: string;
  fileName: string;
  courseId?: string;
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

  async exportCourseFull(courseId: string) {
    return axiosClient.get(`/course-content-transfers/${courseId}/export`, {
      responseType: "blob",
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

  async syncFromDrive(fileId?: string) {
    const res = await axiosClient.post(`/course-content-transfers/drive-sync`, {
      fileId,
    });
    return res.data as DriveSyncResult[];
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
