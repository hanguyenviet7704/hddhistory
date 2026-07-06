import {
  HabitListQuery,
  HabitPayload,
} from "../types/interface/habit.interface";
import axiosClient from "./axiosClient";

export const habitService = {
  async getList(params?: Partial<HabitListQuery>) {
    const res = await axiosClient.get("/habits", { params });
    return res.data;
  },

  async getById(id: string) {
    const res = await axiosClient.get(`/habits/${id}`);
    return res.data;
  },

  async create(payload: HabitPayload) {
    return axiosClient.post(`/habits`, payload);
  },

  async update(id: string, payload: Partial<HabitPayload>) {
    return axiosClient.put(`/habits/${id}`, payload);
  },

  async remove(id: string) {
    return axiosClient.delete(`/habits/${id}`);
  },
};
