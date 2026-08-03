import {
  DiscountTierListQuery,
  IDiscountTierPayload,
} from "../../types/interface/payments/discount-tier.interface";
import axiosClient from "../axiosClient";

export const discountTierService = {
  async getList(params?: Partial<DiscountTierListQuery>) {
    const res = await axiosClient.get("/payment/vouchers/tiers", { params });
    return res.data;
  },

  async create(payload: IDiscountTierPayload) {
    return axiosClient.post(`/payment/vouchers/tiers`, payload, {});
  },

  async update(id: string, payload: IDiscountTierPayload) {
    return axiosClient.put(`/payment/vouchers/tiers/${id}`, payload, {});
  },

  async remove(id: string) {
    return axiosClient.delete(`/payment/vouchers/tiers/${id}`);
  },
};
