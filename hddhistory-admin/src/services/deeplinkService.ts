import { IDeeplinkDestination } from "../types/interface/deeplink.interface";
import axiosClient from "./axiosClient";

/**
 * hddhistory-api bọc MỌI response trong `{statusCode, message, data}` (ResponseInterceptor
 * global, xem main.ts) và axiosClient không tự bóc, nên phải bóc ở đây — nếu
 * không thì trang admin nhận được cái phong bì và hiện danh mục trống mà không
 * báo lỗi gì. `?? payload` để nếu sau này endpoint trả thẳng mảng thì vẫn chạy
 * (mirror `warmUpConfigService`).
 */
const unwrapData = <T>(payload: any): T => payload?.data ?? payload;

export const deeplinkService = {
  async getDestinations(): Promise<IDeeplinkDestination[]> {
    const res = await axiosClient.get("/deeplink/destinations");
    return unwrapData<IDeeplinkDestination[]>(res.data) ?? [];
  },
};
