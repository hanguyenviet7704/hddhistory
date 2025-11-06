import { configureStore } from "@reduxjs/toolkit";

import langSlice from "./slices/lang.slice";
import notificationReducer from "./slices/notification.slice";

export const store = configureStore({
  reducer: {
    lang: langSlice,
    notifications: notificationReducer,
  },
});

// Types
export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
