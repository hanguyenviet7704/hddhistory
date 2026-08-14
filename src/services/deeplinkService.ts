import { IDeeplinkDestination } from "../types/interface/deeplink.interface";
import axiosClient from "./axiosClient";

export const deeplinkService = {
  async getDestinations(): Promise<IDeeplinkDestination[]> {
    const res = await axiosClient.get("/deeplink/destinations");
    return res.data;
  },
};
