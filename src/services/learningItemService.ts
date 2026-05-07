import {
  LearningItemListQuery,
  LearningItemPayload,
  LearningItemsIndexPayload,
} from "../types/interface/learning-item/learning-item.interface";
import axiosClient from "./axiosClient";

export const learningItemService = {
  async getList(params?: Partial<LearningItemListQuery>) {
    const res = await axiosClient.get("/courses-learning-items", { params });
    return res.data;
  },

  async getById(id: string) {
    const res = await axiosClient.get(`/courses-learning-items/${id}`, {});
    return res.data;
  },

  async create(payload: LearningItemPayload) {
    return axiosClient.post(`/courses-learning-items`, payload, {});
  },

  async update(id: string, payload: Partial<LearningItemPayload>) {
    return axiosClient.put(`/courses-learning-items/${id}`, payload, {});
  },

  async updatelearningItemIndex(learningItems: LearningItemsIndexPayload) {
    return axiosClient.put(`/courses-learning-items/indexs`, learningItems);
  },

  async remove(id: string) {
    return axiosClient.delete(`/courses-learning-items/${id}`);
  },

  async importTheories(file: File) {
    const formData = new FormData();
    formData.append("file", file);

    return axiosClient.post(`/courses-learning-items/import-theories`, formData, {
      responseType: "blob",
      headers: {
        "Content-Type": "multipart/form-data",
      },
    });
  },

  async importExercises(file: File) {
    const formData = new FormData();
    formData.append("file", file);

    return axiosClient.post(
      `/courses-learning-items/import-exercises`,
      formData,
      {
        responseType: "blob",
        headers: {
          "Content-Type": "multipart/form-data",
        },
      }
    );
  },
};
