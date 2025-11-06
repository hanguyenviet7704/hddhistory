import {
  SkillsetListQuery,
  SkillsetPayload,
} from "../types/interface/skillset.interface";
import axiosClient from "./axiosClient";

export const skillsetService = {
  async getList(params?: Partial<SkillsetListQuery>) {
    const res = await axiosClient.get("/skillsets", { params });
    return res.data;
  },

  async getById(id: string) {
    const res = await axiosClient.get(`/skillsets/${id}`);
    return res.data;
  },

  async create(payload: SkillsetPayload) {
    return axiosClient.post(`/skillsets`, payload, {});
  },

  async update(id: string, payload: Partial<SkillsetPayload>) {
    return axiosClient.put(`/skillsets/${id}`, payload, {});
  },

  async remove(id: string) {
    return axiosClient.delete(`/skillsets/${id}`);
  },
};
