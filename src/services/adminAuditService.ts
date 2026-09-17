import { AdminAuditQuery } from "../types/interface/adminAudit.interface";
import axiosClient from "./axiosClient";

export const adminAuditService = {
  /** Nhật ký thao tác admin. Chỉ đọc — không có endpoint nào sửa hay xoá nó. */
  async list(params: AdminAuditQuery) {
    const res = await axiosClient.get("/admin-audit", { params });
    return res.data;
  },
};
