import { PurchaseListQuery } from "../../types/interface/payments/purchase.interface";
import axiosClient from "../axiosClient";

export const purchaseService = {
  async getList(params?: Partial<PurchaseListQuery>) {
    const res = await axiosClient.get("/payment/purchases", { params });
    return res.data;
  },

  async getById(id: string) {
    const res = await axiosClient.get(`/payment/purchases/${id}`);
    return res.data;
  },
};
