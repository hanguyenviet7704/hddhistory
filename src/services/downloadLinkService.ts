import {
  DownloadLinkListQuery,
  DownloadLinkPayload,
} from "../types/interface/download-link.interface";
import axiosClient from "./axiosClient";

/**
 * The public link people actually share. Built here rather than returned by
 * the API so the admin never shows a host the app has not claimed: the iOS
 * entitlement is `applinks:meup.training` with no wildcard, so a link on any
 * other host silently stops opening the app.
 */
export const DOWNLOAD_LINK_BASE = "https://meup.training/r";

export const buildDownloadLinkUrl = (slug: string) =>
  `${DOWNLOAD_LINK_BASE}/${slug}`;

export const downloadLinkService = {
  async getList(params?: Partial<DownloadLinkListQuery>) {
    const res = await axiosClient.get("/download-links", { params });
    return res.data;
  },

  async getById(id: string) {
    const res = await axiosClient.get(`/download-links/${id}`);
    return res.data;
  },

  async getStats(id: string, params?: { from?: string; to?: string }) {
    const res = await axiosClient.get(`/download-links/${id}/stats`, {
      params,
    });
    return res.data;
  },

  async create(payload: DownloadLinkPayload) {
    return axiosClient.post("/download-links", payload);
  },

  async update(id: string, payload: Partial<DownloadLinkPayload>) {
    return axiosClient.put(`/download-links/${id}`, payload);
  },

  async remove(id: string) {
    return axiosClient.delete(`/download-links/${id}`);
  },
};
