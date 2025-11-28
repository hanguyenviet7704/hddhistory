import {
  QuoteListQuery,
  QuotePayload,
} from "../types/interface/quote.interface";
import axiosClient from "./axiosClient";

export const quoteService = {
  async getList(params?: Partial<QuoteListQuery>) {
    const res = await axiosClient.get("/courses-quotes", { params });
    return res.data;
  },

  async getById(id: string) {
    const res = await axiosClient.get(`/courses-quotes/${id}`, {});
    return res.data;
  },

  async create(payload: QuotePayload) {
    return axiosClient.post(`/courses-quotes`, payload, {});
  },

  async update(id: string, payload: Partial<QuotePayload>) {
    return axiosClient.put(`/courses-quotes/${id}`, payload, {});
  },

  async remove(id: string) {
    return axiosClient.delete(`/courses-quotes/${id}`);
  },
};
