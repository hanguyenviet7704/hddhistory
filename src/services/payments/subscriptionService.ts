import { SubscriptionListQuery } from "../../types/interface/payments/subscription.interface";
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
};
