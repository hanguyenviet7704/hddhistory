import {
  AvatarListQuery,
  AvatarPayload,
} from "../types/interface/avatar.interface";
import axiosClient from "./axiosClient";

export const avatarService = {
  async getList(params?: Partial<AvatarListQuery>) {
    const res = await axiosClient.get("/courses-avatars", { params });
    return res.data;
  },

  async getById(id: string) {
    const res = await axiosClient.get(`/courses-avatars/${id}`, {});
    return res.data;
  },

  async create(payload: AvatarPayload) {
    return axiosClient.post(`/courses-avatars`, payload, {});
  },

  async update(id: string, payload: Partial<AvatarPayload>) {
    return axiosClient.put(`/courses-avatars/${id}`, payload, {});
  },

  async remove(id: string) {
    return axiosClient.delete(`/courses-avatars/${id}`);
  },
};
