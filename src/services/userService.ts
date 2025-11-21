import { IUser, UserListQuery } from "../types/interface/user.interface";
import axiosClient from "./axiosClient";

export const userService = {
  async getList(params?: Partial<UserListQuery>) {
    const res = await axiosClient.get("/users", { params });
    return res.data;
  },

  async getById(id: string) {
    const res = await axiosClient.get(`/users/${id}`, {});
    return res.data;
  },

  async create(payload: IUser) {
    return axiosClient.post(`/users/register`, payload, {});
  },

  async update(id: string, payload: Partial<IUser>) {
    return axiosClient.put(`/users/${id}`, payload, {});
  },

  async remove(id: string) {
    return axiosClient.delete(`/users/${id}`);
  },
};
