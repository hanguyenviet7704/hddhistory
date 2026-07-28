import {
  IProductPriceQuery,
  IProductPriceSyncPayload,
} from "../../types/interface/payments/product-price.interface";
import axiosClient from "../axiosClient";

export const productPriceService = {
  async getList(params?: IProductPriceQuery) {
    const res = await axiosClient.get("/payment/product-prices", {
      params,
    });
    return res.data;
  },

  async sync(payload?: IProductPriceSyncPayload) {
    const res = await axiosClient.post(
      "/payment/product-prices/sync",
      payload ?? {}
    );
    return res.data;
  },
};
