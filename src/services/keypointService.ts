import {
  KeypointListQuery,
  KeypointPayload,
} from "../types/interface/keypoint.interface";
import axiosClient from "./axiosClient";

export const keypointService = {
  async getList(params: Partial<KeypointListQuery>) {
    const res = await axiosClient.get("/courses-keypoints", { params });
    return res.data;
  },

  async getById(id: string) {
    const res = await axiosClient.get(`/courses-keypoints/${id}`, {});
    return res.data;
  },

  async create(payload: KeypointPayload) {
    return axiosClient.post(`/courses-keypoints`, payload, {});
  },

  async update(id: string, payload: KeypointPayload) {
    return axiosClient.put(`/courses-keypoints/${id}`, payload, {});
  },

  async remove(id: string) {
    return axiosClient.delete(`/courses-keypoints/${id}`);
  },
};
