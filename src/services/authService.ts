import { LoginPayload, LogoutPayload } from "../types/interface/user.interface";
import axiosClient from "./axiosClient";

export const authService = {
  login: (data: LoginPayload) => {
    return axiosClient.post("/users/login", data);
  },

  logout: (data: LogoutPayload) => {
    return axiosClient.post("/users/logout", data);
  },
};
