import axios, {
  AxiosError,
  InternalAxiosRequestConfig,
  AxiosResponse,
} from "axios";
import { store } from "../store";
import { LangCode } from "../types/enum/common.enum";
import { getClientInfo } from "../utils/device";

const API_URL = `${process.env.REACT_APP_BACKEND_AI_TUTOR}/api/v1`;
const device = getClientInfo();
const getAccessToken = () => localStorage.getItem("accessToken");
const getRefreshToken = () => localStorage.getItem("refreshToken");
const getUserId = () => localStorage.getItem("userId");

const axiosClient = axios.create({
  baseURL: API_URL,
  headers: {
    "Content-Type": "application/json",
  },
});

// Request Interceptor
axiosClient.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = getAccessToken();
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    // Thêm lang vào header
    const lang = store.getState().lang.code || LangCode.EN;
    config.headers["lang"] = lang;

    return config;
  },
  (error: AxiosError) => {
    return Promise.reject(error);
  }
);

// Response Interceptor
axiosClient.interceptors.response.use(
  (response: AxiosResponse) => response,
  async (error: AxiosError) => {
    const originalRequest: any = error.config;

    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      try {
        const refreshToken = getRefreshToken();
        const userId = getUserId();
        const res = await axios.post(
          `${API_URL}/users/${userId}/refresh-token`,
          {
            refreshToken,
            device: { deviceId: device.userAgent, deviceName: device.platform },
          }
        );

        const newAccessToken = (res.data?.data?.token as any).accessToken;
        localStorage.setItem("accessToken", newAccessToken);

        originalRequest.headers.Authorization = `Bearer ${newAccessToken}`;
        return axiosClient(originalRequest);
      } catch (err) {
        console.error("Refresh token failed:", err);
        localStorage.removeItem("accessToken");
        localStorage.removeItem("refreshToken");
        localStorage.removeItem("userId");
        window.location.href = "/login";
      }
    }

    return Promise.reject(error);
  }
);

export default axiosClient;
