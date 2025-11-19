import {
  IRoleplayColorTemplate,
  RoleplayColorTemplateListQuery,
} from "../types/interface/learning-item/roleplays/color-template.interface";
import axiosClient from "./axiosClient";

export const roleplayColorTemplateService = {
  async getList(params?: Partial<RoleplayColorTemplateListQuery>) {
    const res = await axiosClient.get("/courses-roleplay-colors", { params });
    return res.data;
  },

  async getById(id: string) {
    const res = await axiosClient.get(`/courses-roleplay-colors/${id}`, {});
    return res.data;
  },

  async create(payload: IRoleplayColorTemplate) {
    return axiosClient.post(`/courses-roleplay-colors`, payload, {});
  },

  async update(id: string, payload: Partial<IRoleplayColorTemplate>) {
    return axiosClient.put(`/courses-roleplay-colors/${id}`, payload, {});
  },

  async remove(id: string) {
    return axiosClient.delete(`/courses-roleplay-colors/${id}`);
  },
};
