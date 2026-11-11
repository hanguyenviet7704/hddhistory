import axios, {
  AxiosError,
  InternalAxiosRequestConfig,
  AxiosResponse,
} from "axios";
import { store } from "../store";
import { LangCode } from "../types/enum/common.enum";
import { getClientInfo } from "../utils/device";

export const API_URL_V1 = `${process.env.REACT_APP_BACKEND_URL}/api/v1`;
export const API_URL_V2 = `${process.env.REACT_APP_BACKEND_URL}/api/v2`;
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

      // Tắt lọc theo thị trường cho MỌI request của panel.
      //
      // Course có thể được publish giới hạn theo quốc gia (`countries`), và các
      // endpoint dùng chung với app sẽ lọc theo thị trường của người gọi. Nếu
      // không có header này, một operator ở Việt Nam mở panel sẽ đơn giản là
      // KHÔNG thấy course chỉ publish cho Nhật — không lỗi, không log, chỉ là
      // thiếu. Đặt ở đây vì đây là chỗ duy nhất mọi request đều đi qua: 9 trang
      // admin đọc danh sách course (Courses, Lessons, Roleplays, Output, Video,
      // Habits, Reanchor reasons...), và trang nào tự nhớ thì trang đó sẽ quên.
      //
      // Không phải hàng rào bảo mật và không giả vờ là: nó quyết định course
      // được QUẢNG BÁ ở đâu, không phải ai được mở.
      config.headers["x-ignore-market-targeting"] = "1";

      // Đánh dấu "request này đến từ trang quản trị".
      //
      // Nhật ký thao tác cần biết thao tác nào là của người vận hành, và vai
      // trò KHÔNG trả lời được câu đó: tài khoản dùng panel đang mang
      // `role: USER` trong database, nên lọc theo vai trò thì nhật ký trống
      // trơn. Một dấu hiệu nói thẳng ý định thì đọc được, và hỏng thì hỏng ra
      // mặt — khác với việc mượn nhờ header bên trên, thứ sẽ im lặng ngừng
      // hoạt động vào ngày ai đó dọn nó đi.
      config.headers["x-admin-panel"] = "1";

      // Panel đọc BẢN ĐANG SỬA, app đọc tag đang phát hành. Cùng lý do và
      // cùng chỗ đặt như header trên: `courses`/`lessons`/`keypoints` dùng
      // chung route với app, và `user.role` thì không dùng được — tài khoản
      // admin thật có role USER nên `@Roles(ADMIN)` đã 403 cả panel ba lần.
      //
      // Thiếu header này thì editor mở bài ra sẽ thấy nội dung ĐÃ PHÁT HÀNH
      // trong khi đang sửa bản nháp — không lỗi, không log, chỉ là sai bản.
      // Thêm `?version=v1.0.0` để xem lại một tag cũ, `?version=current` để
      // xem đúng cái user thật đang thấy.
      config.headers["x-ignore-content-version"] = "1";

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
