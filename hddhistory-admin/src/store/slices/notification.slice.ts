import { createSlice, PayloadAction } from "@reduxjs/toolkit";

// Định nghĩa kiểu dữ liệu cho notification
export interface Notification {
  id: string;
  message: string;
  type: "success" | "error" | "info";
}

interface NotificationState {
  notifications: Notification[];
}

const initialState: NotificationState = {
  notifications: [],
};

const notificationSlice = createSlice({
  name: "notifications",
  initialState,
  reducers: {
    // Action để hiển thị một thông báo mới
    showNotification: (
      state,
      action: PayloadAction<Omit<Notification, "id">>
    ) => {
      const newNotification: Notification = {
        id: Date.now().toString(), // Tạo ID duy nhất
        ...action.payload,
      };
      state.notifications.push(newNotification);
    },
    // Action để ẩn một thông báo
    hideNotification: (state, action: PayloadAction<string>) => {
      state.notifications = state.notifications.filter(
        (notification) => notification.id !== action.payload
      );
    },
  },
});

export const { showNotification, hideNotification } = notificationSlice.actions;
export default notificationSlice.reducer;
