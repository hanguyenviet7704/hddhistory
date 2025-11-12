import { useState } from "react";
import Header from "./Header";
import Sidebar from "./Sidebar";
import { Outlet } from "react-router-dom";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import NotificationItem from "../common/Notification";

export default function Layout() {
  const [collapsed, setCollapsed] = useState(false);
  const notifications = useSelector(
    (state: RootState) => state.notifications.notifications
  );

  return (
    <div className="flex h-screen">
      <Sidebar collapsed={collapsed} setCollapsed={setCollapsed} />
      {/* Container cho thông báo */}
      <div className="fixed top-4 right-4 z-50 w-80 max-w-sm">
        {notifications.map((notification) => (
          <NotificationItem key={notification.id} notification={notification} />
        ))}
      </div>
      <div className="flex-1 flex flex-col">
        <Header />
        <main className="flex-1 px-6 bg-gray-100 overflow-auto">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
