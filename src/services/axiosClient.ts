import axios, {
  AxiosError,
  InternalAxiosRequestConfig,
  AxiosResponse,
} from "axios";
import { store } from "../store";
import { LangCode } from "../types/enum/common.enum";
import { getClientInfo } from "../utils/device";

export const API_URL_V1 = `${process.env.REACT_APP_BACKEND_AI_TUTOR}/api/v1`;
export const API_URL_V2 = `${process.env.REACT_APP_BACKEND_AI_TUTOR}/api/v2`;
const device = getClientInfo();
const getAccessToken = () => localStorage.getItem("accessToken");
const getRefreshToken = () => localStorage.getItem("refreshToken");
const getUserId = () => localStorage.getItem("userId");

const createAxiosClient = (baseURL: string) => {
  const client = axios.create({
    baseURL,
    headers: {
      "Content-Type": "application/json",
    },
  });

  // Request Interceptor
  client.interceptors.request.use(
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
  client.interceptors.response.use(
    (response: AxiosResponse) => response,
    async (error: AxiosError) => {
      const originalRequest: any = error.config;

      if (error.response?.status === 401 && !originalRequest._retry) {
        originalRequest._retry = true;

        try {
          const refreshToken = getRefreshToken();
          const userId = getUserId();
          const res = await axios.post(
            `${baseURL}/users/${userId}/refresh-token`,
            {
              refreshToken,
              device: {
                deviceId: device.userAgent,
                deviceName: device.platform,
              },
            }
          );

          const newAccessToken = (res.data?.data?.token as any).accessToken;
          localStorage.setItem("accessToken", newAccessToken);

          originalRequest.headers.Authorization = `Bearer ${newAccessToken}`;
          return client(originalRequest);
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

  return client;
};

const axiosClient = createAxiosClient(API_URL_V1);
export const axiosClientV2 = createAxiosClient(API_URL_V2);

export default axiosClient;
