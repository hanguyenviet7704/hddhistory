import {
  ReanchorReasonListQuery,
  ReanchorReasonPayload,
} from "../types/interface/reanchor-reason.interface";
import axiosClient from "./axiosClient";

export const reanchorReasonService = {
  async getList(params?: Partial<ReanchorReasonListQuery>) {
    const res = await axiosClient.get("/reanchor-reasons", { params });
    return res.data;
  },

  async getById(id: string) {
    const res = await axiosClient.get(`/reanchor-reasons/${id}`);
    return res.data;
  },

  async create(payload: ReanchorReasonPayload) {
    return axiosClient.post(`/reanchor-reasons`, payload);
  },

  async update(id: string, payload: Partial<ReanchorReasonPayload>) {
    return axiosClient.put(`/reanchor-reasons/${id}`, payload);
  },

  async remove(id: string) {
    return axiosClient.delete(`/reanchor-reasons/${id}`);
  },

  // Portable rows keyed by course.title.en — see utils/habitContentXlsx.
  async exportData() {
    const res = await axiosClient.get("/reanchor-reasons/export");
    return res.data?.data ?? [];
  },

  async importData(rows: unknown[]) {
    const res = await axiosClient.post("/reanchor-reasons/import", {
      mode: "replace",
      rows,
    });
    return res.data?.data;
  },
};
