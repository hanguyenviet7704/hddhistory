import {
  DeleteSubscriptionPayload,
  ManualSubscriptionPayload,
  SubscriptionListQuery,
} from "../../types/interface/payments/subscription.interface";
import axiosClient from "../axiosClient";

export const subscriptionService = {
  async getList(params?: Partial<SubscriptionListQuery>) {
    const res = await axiosClient.get("/payment/subscriptions", { params });
    return res.data;
  },

  async getById(id: string) {
    const res = await axiosClient.get(`/payment/subscriptions/${id}`);
    return res.data;
  },

  async getActivePremiumForUser(userId: string) {
    const res = await axiosClient.get(
      `/payment/subscriptions/users/${userId}/active-premium`
    );
    return res.data;
  },

  async createManual(payload: Partial<ManualSubscriptionPayload>) {
    return axiosClient.post(`/payment/subscriptions/manual`, payload, {});
  },

  async updateManual(id: string, payload: Partial<ManualSubscriptionPayload>) {
    return axiosClient.put(`/payment/subscriptions/${id}/manual`, payload, {});
  },

  async remove(id: string, payload: Partial<DeleteSubscriptionPayload>) {
    return axiosClient.delete(`/payment/subscriptions/${id}`, {
      data: payload,
    });
  },
};
