import {
  CourseListQuery,
  CoursePayload,
  RoadmapPayload,
} from "../types/interface/course.interface";
import axiosClient from "./axiosClient";

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
};
