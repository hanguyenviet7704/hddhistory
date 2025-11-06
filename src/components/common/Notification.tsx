import React, { useEffect } from "react";
import { useDispatch } from "react-redux";
import {
  CheckCircleIcon,
  ExclamationTriangleIcon,
  XMarkIcon,
} from "@heroicons/react/24/outline";
import {
  hideNotification,
  Notification,
} from "../../store/slices/notification.slice";
import { motion, AnimatePresence } from "framer-motion";

interface NotificationItemProps {
  notification: Notification;
}

const NotificationItem: React.FC<NotificationItemProps> = ({
  notification,
}) => {
  const dispatch = useDispatch();

  // Tự động ẩn thông báo sau 3 giây
  useEffect(() => {
    const timer = setTimeout(() => {
      dispatch(hideNotification(notification.id));
    }, 2000);

    return () => clearTimeout(timer);
  }, [dispatch, notification.id]);

  const getStyles = () => {
    switch (notification.type) {
      case "success":
        return "bg-green-50 border-green-200 text-green-800";
      case "error":
        return "bg-red-50 border-red-200 text-red-800";
      default:
        return "bg-blue-50 border-blue-200 text-blue-800";
    }
  };

  const getIcon = () => {
    switch (notification.type) {
      case "success":
        return <CheckCircleIcon className="w-6 h-6 text-green-500" />;
      case "error":
        return <ExclamationTriangleIcon className="w-6 h-6 text-red-500" />;
      default:
        return null;
    }
  };

  return (
    <AnimatePresence>
      {notification.message && (
        <motion.div
          initial={{ opacity: 0, x: 100 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: 100 }}
          className={`fixed top-4 right-4 z-50 flex items-center p-4 rounded-xl shadow-xl ${
            notification.type === "success"
              ? "bg-green-500 text-white"
              : "bg-red-500 text-white"
          }`}
        >
          {notification.type === "success" ? (
            <CheckCircleIcon className="h-6 w-6 mr-2" />
          ) : (
            <ExclamationTriangleIcon className="h-6 w-6 mr-2" />
          )}
          <span className="font-medium">{notification.message}</span>
        </motion.div>
      )}
    </AnimatePresence>
  );
};

export default NotificationItem;
