import { TagListQuery, TagPayload } from "../types/interface/tag.interface";
import axiosClient from "./axiosClient";

export const tagService = {
  async getList(params?: Partial<TagListQuery>) {
    const res = await axiosClient.get("/courses-tags", { params });
    return res.data;
  },

  async getById(id: string) {
    const res = await axiosClient.get(`/courses-tags/${id}`, {});
    return res.data;
  },

  async create(payload: TagPayload) {
    return axiosClient.post(`/courses-tags`, payload, {});
  },

  async update(id: string, payload: Partial<TagPayload>) {
    return axiosClient.put(`/courses-tags/${id}`, payload, {});
  },

  async remove(id: string) {
    return axiosClient.delete(`/courses-tags/${id}`);
  },
};
