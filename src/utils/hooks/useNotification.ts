import { useCallback } from "react";
import { useDispatch } from "react-redux";
import { AppDispatch } from "../../store";
import { showNotification } from "../../store/slices/notification.slice";

export const useNotification = () => {
  const dispatch = useDispatch<AppDispatch>();

  const showSuccess = useCallback(
    (message: string) => {
      dispatch(showNotification({ message, type: "success" }));
    },
    [dispatch]
  );

  const showError = useCallback(
    (message: string) => {
      dispatch(showNotification({ message, type: "error" }));
    },
    [dispatch]
  );

  const showInfo = useCallback(
    (message: string) => {
      dispatch(showNotification({ message, type: "info" }));
    },
    [dispatch]
  );

  return { showSuccess, showError, showInfo };
};
