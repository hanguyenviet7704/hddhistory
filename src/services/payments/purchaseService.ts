import {
  GetRevenueListQuery,
  PurchaseListQuery,
  RevenueStatisticsResponse,
  UpdatePurchasePayload,
} from "../../types/interface/payments/purchase.interface";
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

  async findByUser(userId: string) {
    const res = await axiosClient.get(`/payment/purchases/users/${userId}`);
    return res.data;
  },

  async findByAnchor(anchorId: string) {
    const res = await axiosClient.get(`/payment/purchases/anchors/${anchorId}`);
    return res.data;
  },

  async getWebhooksByPurchaseId(id: string) {
    const res = await axiosClient.get(`/payment/purchases/${id}/webhooks`);
    return res.data;
  },

  async getRevenueStatistics(
    params?: Partial<GetRevenueListQuery>
  ): Promise<RevenueStatisticsResponse> {
    const res = await axiosClient.get("/payment/purchases/revenue/statistics", {
      params,
    });
    return res.data;
  },

  async getRevenueEntries(params?: Partial<GetRevenueListQuery>) {
    const res = await axiosClient.get("/payment/purchases/revenue/entries", {
      params,
    });
    return res.data;
  },

  async update(id: string, payload: Partial<UpdatePurchasePayload>) {
    return axiosClient.patch(`/payment/purchases/${id}`, payload, {});
  },
};
