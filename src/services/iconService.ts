import { IconListQuery, IconPayload } from "../types/interface/icon.interface";
import axiosClient from "./axiosClient";

export const iconService = {
  async getList(params?: Partial<IconListQuery>) {
    const res = await axiosClient.get("/courses-icons", { params });
    return res.data;
  },

  async getById(id: string) {
    const res = await axiosClient.get(`/courses-icons/${id}`, {});
    return res.data;
  },

  async create(payload: IconPayload) {
    return axiosClient.post(`/courses-icons`, payload, {});
  },

  async update(id: string, payload: Partial<IconPayload>) {
    return axiosClient.put(`/courses-icons/${id}`, payload, {});
  },

  async remove(id: string) {
    return axiosClient.delete(`/courses-icons/${id}`);
  },
};
