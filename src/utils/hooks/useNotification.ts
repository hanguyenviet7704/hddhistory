import { useDispatch } from "react-redux";
import { AppDispatch } from "../../store";
import { showNotification } from "../../store/slices/notification.slice";

export const useNotification = () => {
  const dispatch = useDispatch<AppDispatch>();

  const showSuccess = (message: string) => {
    dispatch(showNotification({ message, type: "success" }));
  };

  const showError = (message: string) => {
    dispatch(showNotification({ message, type: "error" }));
  };

  const showInfo = (message: string) => {
    dispatch(showNotification({ message, type: "info" }));
  };

  return { showSuccess, showError, showInfo };
};
