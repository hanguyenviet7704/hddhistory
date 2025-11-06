import { UploadFileToCloudflare } from "../types/interface/files/cloudflare.interface";
import axiosClient from "./axiosClient";

export const cloudflareService = {
  async download(key: string) {
    const res = await axiosClient.get(`/cloudflares/download/${key}`);
    return res.data;
  },

  async upload(file: File, payload?: UploadFileToCloudflare) {
    const formData = new FormData();
    formData.append("file", file);
    if (payload?.prefix) formData.append("prefix", payload?.prefix);
    if (payload?.folder) formData.append("folder", payload?.folder);

    return axiosClient.post(`/cloudflares/upload`, formData, {
      headers: {
        "Content-Type": "multipart/form-data",
      },
    });
  },

  async remove(key: string) {
    return axiosClient.delete(`/cloudflares/${key}`);
  },
};
