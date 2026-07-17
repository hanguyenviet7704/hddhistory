import {
  BookOpenIcon,
  ClipboardDocumentListIcon,
  PencilSquareIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  StarIcon,
  ArrowRightOnRectangleIcon,
  CheckBadgeIcon,
  DocumentTextIcon,
  SparklesIcon,
  Cog6ToothIcon,
  PuzzlePieceIcon,
  CreditCardIcon,
  ChartBarIcon,
  PlayCircleIcon,
  ExclamationTriangleIcon,
  PhotoIcon,
  FireIcon,
  ArrowPathIcon,
  SpeakerWaveIcon,
} from "@heroicons/react/24/outline";
import { NavLink, useLocation } from "react-router-dom";

interface SidebarProps {
  collapsed: boolean;
  setCollapsed: (value: boolean) => void;
}

const menuItems = [
  { name: "Skillset", icon: PuzzlePieceIcon, path: "/skillset" },
  { name: "Habits", icon: FireIcon, path: "/habits" },
  {
    name: "Re-anchor reasons",
    icon: ArrowPathIcon,
    path: "/reanchor-reasons",
  },
  { name: "Course", icon: BookOpenIcon, path: "/course" },
  { name: "Roleplay", icon: ArrowRightOnRectangleIcon, path: "/roleplay" },
  { name: "Lesson", icon: ClipboardDocumentListIcon, path: "/lesson" },
  { name: "Video", icon: PlayCircleIcon, path: "/video" },
  { name: "Output", icon: CheckBadgeIcon, path: "/output" },
  { name: "Keypoint", icon: StarIcon, path: "/keypoint" },
  { name: "Theory", icon: DocumentTextIcon, path: "/theory" },
  { name: "Exercise", icon: PencilSquareIcon, path: "/exercise" },
  { name: "Onboarding", icon: SparklesIcon, path: "/onboarding" },
  {
    name: "Onboarding Branching",
    icon: SparklesIcon,
    path: "/onboarding-branching",
  },
  { name: "Statistics", icon: ChartBarIcon, path: "/statistics" },
  { name: "Payment", icon: CreditCardIcon, path: "/payment" },
  { name: "Lồng tiếng", icon: SpeakerWaveIcon, path: "/voiceover" },
  { name: "Reported Issues", icon: ExclamationTriangleIcon, path: "/reports" },
  { name: "Compress Images", icon: PhotoIcon, path: "/image-compression" },
];

export default function Sidebar({ collapsed, setCollapsed }: SidebarProps) {
  const location = useLocation();

  // Hàm kiểm tra path có khớp với menu item hoặc các path con
  const isActivePath = (path: string) => {
    // Lấy path hiện tại
    const currentPath = location.pathname;

    // Nếu path hiện tại khớp với path của menu item
    if (currentPath === path) {
      return true;
    }

    // Nếu path hiện tại bắt đầu bằng path của menu item và có thêm các phần sau
    // Ví dụ: "/lesson" sẽ khớp với "/lesson/123", "/lesson/edit"...
    if (currentPath.startsWith(path + "/")) {
      return true;
    }

    return false;
  };

  return (
    <aside
      className={`
        ${collapsed ? "w-16" : "w-64"}
        h-screen bg-white shadow-lg border-r border-gray-200
        relative flex flex-col transition-all duration-300 ease-in-out
      `}
    >
      {/* Toggle button - Đổi vị trí và icon */}
      <div
        className={`
        flex justify-end px-2 mb-6
        ${collapsed ? "mb-4" : "mb-8"}
      `}
      >
        <button
          onClick={() => setCollapsed(!collapsed)}
          className={`
            flex items-center justify-center
            w-9 h-9 rounded-lg
            bg-gray-100 hover:bg-gray-200
            transition-all duration-300 ease-in-out
            shadow-sm hover:shadow-md
            ${collapsed ? "ml-auto" : "mr-auto"}
          `}
        >
          {collapsed ? (
            <ChevronRightIcon className="h-4 w-4 text-gray-600" />
          ) : (
            <ChevronLeftIcon className="h-4 w-4 text-gray-600" />
          )}
        </button>
      </div>

      {/* Logo */}
      <div
        className={`
        flex items-center justify-center mb-6 transition-all duration-300
        ${collapsed ? "px-0" : "px-4"}
      `}
      >
        <div
          className={`
          flex items-center justify-center
          ${collapsed ? "w-10 h-8" : "w-24 h-16"}
          rounded-lg shadow-md transition-all duration-300
        `}
        >
          <img
            src="https://i.pinimg.com/736x/f9/5d/b0/f95db029418c8d27375b6851060d6f0c.jpg"
            alt="Logo"
            className={`
              transition-all duration-300
              w-full h-full max-w-full max-h-full object-fill rounded-xl
            `}
          />
        </div>
      </div>

      {/* Menu */}
      <nav className="space-y-1 flex-1 min-h-0 overflow-y-auto px-2 pb-24">
        {menuItems.map((item) => {
          const Icon = item.icon;
          const isActive = isActivePath(item.path);

          return (
            <NavLink
              key={item.name}
              to={item.path}
              className={`
                flex items-center
                ${collapsed ? "justify-center" : "justify-start"}
                px-3 py-1.5 my-1 rounded-lg
                transition-all duration-300 ease-in-out
                ${
                  isActive
                    ? "bg-blue-50 text-blue-600 shadow-sm border-l-4 border-blue-500"
                    : "text-gray-600 hover:bg-gray-50 hover:text-gray-900"
                }
              `}
            >
              <div
                className={`
                flex items-center justify-center
                ${collapsed ? "w-8 h-8" : "w-10 h-10"}
                rounded-md
                ${
                  isActive
                    ? "bg-blue-100 text-blue-600"
                    : "bg-gray-100 text-gray-500"
                }
                transition-all duration-300
              `}
              >
                <Icon className="h-5 w-5" />
              </div>
              {!collapsed && (
                <span className="ml-3 text-sm font-medium">{item.name}</span>
              )}
            </NavLink>
          );
        })}
      </nav>

      {/* Settings Button - Larger and more colorful */}
      <div className="absolute bottom-0 left-0 right-0 z-20 border-t border-gray-300 bg-white px-4 py-1.5">
        <NavLink
          to="/settings"
          className={`
            flex items-center justify-start
            px-4 py-1.5 my-0.5 rounded-xl
            transition-all duration-300 ease-in-out
            text-gray-800 hover:bg-gray-200 hover:text-gray-950
          `}
        >
          <Cog6ToothIcon className="h-6 w-6" />
          <span className="ml-2">Setting</span>
        </NavLink>
      </div>
    </aside>
  );
}
