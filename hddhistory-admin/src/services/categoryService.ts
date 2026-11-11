import {
  CategoryListQuery,
  CategoryPayload,
} from "../types/interface/category.interface";
import axiosClient from "./axiosClient";

export const categoryService = {
  async getList(params?: Partial<CategoryListQuery>) {
    const res = await axiosClient.get("/categories", { params });
    return res.data;
  },

  async getById(id: string) {
    const res = await axiosClient.get(`/categories/${id}`);
    return res.data;
  },

  async create(payload: CategoryPayload) {
    return axiosClient.post(`/categories`, payload, {});
  },

  async update(id: string, payload: Partial<CategoryPayload>) {
    return axiosClient.put(`/categories/${id}`, payload, {});
  },

  async remove(id: string) {
    return axiosClient.delete(`/categories/${id}`);
  },
};
