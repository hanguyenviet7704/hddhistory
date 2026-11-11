import {
  IVoucherBulkCreatePayload,
  IVoucherPayload,
  VoucherListQuery,
} from "../../types/interface/payments/voucher.interface";
import axiosClient from "../axiosClient";

export const voucherService = {
  async getList(params?: Partial<VoucherListQuery>) {
    const res = await axiosClient.get("/payment/vouchers", { params });
    return res.data;
  },

  async getById(id: string) {
    const res = await axiosClient.get(`/payment/vouchers/${id}`);
    return res.data;
  },

  async create(payload: IVoucherPayload) {
    return axiosClient.post(`/payment/vouchers`, payload, {});
  },

  async update(id: string, payload: IVoucherPayload) {
    return axiosClient.put(`/payment/vouchers/${id}`, payload, {});
  },

  async remove(id: string) {
    return axiosClient.delete(`/payment/vouchers/${id}`);
  },

  async bulkCreate(payload: IVoucherBulkCreatePayload) {
    const res = await axiosClient.post(`/payment/vouchers/bulk`, payload, {});
    return res.data;
  },
};
