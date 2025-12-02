import {
  IProduct,
  ProductListQuery,
} from "../../types/interface/payments/product.interface";
import axiosClient from "../axiosClient";

export const productService = {
  async getList(params?: Partial<ProductListQuery>) {
    const res = await axiosClient.get("/payment/products", { params });
    return res.data;
  },

  async getById(id: string) {
    const res = await axiosClient.get(`/payment/products/${id}`);
    return res.data;
  },

  async create(payload: Partial<IProduct>) {
    return axiosClient.post(`/payment/products`, payload, {});
  },

  async update(id: string, payload: Partial<IProduct>) {
    return axiosClient.put(`/payment/products/${id}`, payload, {});
  },

  async remove(id: string) {
    return axiosClient.delete(`/payment/products/${id}`);
  },
};
