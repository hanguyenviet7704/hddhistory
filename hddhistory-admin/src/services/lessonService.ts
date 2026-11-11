import axiosClient from "./axiosClient";
import {
  LessonListQuery,
  LessonPayload,
  LessonsIndexPayload,
} from "../types/interface/lesson.interface";

export const lessonService = {
  async getList(params?: Partial<LessonListQuery>) {
    const res = await axiosClient.get("/courses-lessons", { params });
    return res.data;
  },

  async getById(id: string) {
    const res = await axiosClient.get(`/courses-lessons/${id}`, {});
    return res.data;
  },

  async create(payload: LessonPayload) {
    return axiosClient.post(`/courses-lessons`, payload, {});
  },

  async update(id: string, payload: Partial<LessonPayload>) {
    return axiosClient.put(`/courses-lessons/${id}`, payload, {});
  },

  async updateLessonIndex(lessons: LessonsIndexPayload) {
    return axiosClient.put(`/courses-lessons/indexs`, lessons);
  },

  async remove(id: string) {
    return axiosClient.delete(`/courses-lessons/${id}`);
  },

  async downloadTemplate() {
    return axiosClient.get(`/courses-lessons/import/template`, {
      responseType: "blob",
    });
  },

  async exportExcel() {
    return axiosClient.get(`/courses-lessons/export`, {
      responseType: "blob",
    });
  },

  async importExcel(file: File) {
    const formData = new FormData();
    formData.append("file", file);
    return axiosClient.post(`/courses-lessons/import`, formData, {
      responseType: "blob",
      headers: { "Content-Type": "multipart/form-data" },
    });
  },
};
