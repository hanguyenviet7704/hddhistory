import {
  BookOpenIcon,
  ClipboardDocumentListIcon,
  PencilSquareIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  ChevronDownIcon,
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
  BellAlertIcon,
  PhotoIcon,
  FireIcon,
  ArrowPathIcon,
  SpeakerWaveIcon,
  SwatchIcon,
  AdjustmentsHorizontalIcon,
  BugAntIcon,
  ChatBubbleLeftRightIcon,
  RocketLaunchIcon,
  LinkIcon,
  FireIcon as StreakIcon,
} from "@heroicons/react/24/outline";
import { useState } from "react";
import { NavLink, useLocation } from "react-router-dom";

interface SidebarProps {
  collapsed: boolean;
  setCollapsed: (value: boolean) => void;
}

// Grouped navigation (collapsible sections). Every item that used to be in the
// flat list still lives here — just organised by domain so the sidebar reads
// like a grouped menu instead of one long list.
const menuGroups = [
  {
    title: "Content",
    items: [
      { name: "Skillset", icon: PuzzlePieceIcon, path: "/skillset" },
      { name: "Course", icon: BookOpenIcon, path: "/course" },
      { name: "Lesson", icon: ClipboardDocumentListIcon, path: "/lesson" },
      { name: "Keypoint", icon: StarIcon, path: "/keypoint" },
      { name: "Theory", icon: DocumentTextIcon, path: "/theory" },
      { name: "Exercise", icon: PencilSquareIcon, path: "/exercise" },
      { name: "Roleplay", icon: ArrowRightOnRectangleIcon, path: "/roleplay" },
      { name: "Video", icon: PlayCircleIcon, path: "/video" },
      { name: "Output", icon: CheckBadgeIcon, path: "/output" },
    ],
  },
  {
    title: "Habits & Personalization",
    items: [
      { name: "Habits", icon: FireIcon, path: "/habits" },
      { name: "Re-anchor reasons", icon: ArrowPathIcon, path: "/reanchor-reasons" },
      { name: "Study Themes", icon: SwatchIcon, path: "/study-themes" },
    ],
  },
  {
    title: "Onboarding",
    items: [
      { name: "Onboarding", icon: SparklesIcon, path: "/onboarding" },
      { name: "Onboarding Branching", icon: SparklesIcon, path: "/onboarding-branching" },
      { name: "Onboarding Config", icon: AdjustmentsHorizontalIcon, path: "/onboarding-config" },
      { name: "Reset Onboarding (QA)", icon: BugAntIcon, path: "/reset-onboarding" },
    ],
  },
  {
    // Feedback surfaces gathered in one place (navigation grouping). Reported
    // Issues + In-App Survey feedback are routable; the per-user keypoint-drop
    // feedback stays under User Progress (it needs a userId, so it can't be a
    // standalone link). Survey Feedback deep-links to the settings survey tab.
    title: "Feedback",
    items: [
      { name: "Reported Issues", icon: ExclamationTriangleIcon, path: "/reports" },
      {
        name: "Survey Feedback",
        icon: ChatBubbleLeftRightIcon,
        path: "/settings?tab=inAppSurvey",
      },
    ],
  },
  {
    title: "Operations",
    items: [
      { name: "Statistics", icon: ChartBarIcon, path: "/statistics" },
      { name: "Payment", icon: CreditCardIcon, path: "/payment" },
      { name: "Cấu hình paywall", icon: RocketLaunchIcon, path: "/paywall-config" },
      { name: "Lồng tiếng", icon: SpeakerWaveIcon, path: "/voiceover" },
      { name: "Link tải app", icon: LinkIcon, path: "/download-links" },
      { name: "Popup streak", icon: StreakIcon, path: "/streak-config" },
      { name: "Thông báo định kỳ", icon: BellAlertIcon, path: "/notifications" },
      { name: "Compress Images", icon: PhotoIcon, path: "/image-compression" },
    ],
  },
];

export default function Sidebar({ collapsed, setCollapsed }: SidebarProps) {
  const location = useLocation();

  // Every group starts expanded; the header chevron toggles it.
  const [openGroups, setOpenGroups] = useState<Record<string, boolean>>(() =>
    Object.fromEntries(menuGroups.map((group) => [group.title, true]))
  );

  const toggleGroup = (title: string) =>
    setOpenGroups((prev) => ({ ...prev, [title]: !prev[title] }));

  // Hàm kiểm tra path có khớp với menu item hoặc các path con
  const isActivePath = (path: string) => {
    const currentPath = location.pathname;
    if (currentPath === path) return true;
    // "/lesson" also matches "/lesson/123", "/lesson/edit"...
    if (currentPath.startsWith(path + "/")) return true;
    return false;
  };

  const renderItem = (item: { name: string; icon: typeof BookOpenIcon; path: string }) => {
    const Icon = item.icon;
    const isActive = isActivePath(item.path);
    return (
      <NavLink
        key={item.name}
        to={item.path}
        title={collapsed ? item.name : undefined}
        className={`
          flex items-center
          ${collapsed ? "justify-center" : "justify-start"}
          px-3 py-1.5 my-0.5 rounded-lg
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
            ${collapsed ? "w-8 h-8" : "w-9 h-9"}
            rounded-md
            ${isActive ? "bg-blue-100 text-blue-600" : "bg-gray-100 text-gray-500"}
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
  };

  return (
    <aside
      className={`
        ${collapsed ? "w-16" : "w-64"}
        h-screen bg-white shadow-lg border-r border-gray-200
        relative flex flex-col transition-all duration-300 ease-in-out
      `}
    >
      {/* Toggle button */}
      <div className={`flex justify-end px-2 ${collapsed ? "mb-4" : "mb-6"}`}>
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
        className={`flex items-center justify-center mb-4 transition-all duration-300 ${
          collapsed ? "px-0" : "px-4"
        }`}
      >
        <div
          className={`flex items-center justify-center rounded-lg shadow-md transition-all duration-300 ${
            collapsed ? "w-10 h-8" : "w-24 h-16"
          }`}
        >
          <img
            src="https://i.pinimg.com/736x/f9/5d/b0/f95db029418c8d27375b6851060d6f0c.jpg"
            alt="Logo"
            className="transition-all duration-300 w-full h-full max-w-full max-h-full object-fill rounded-xl"
          />
        </div>
      </div>

      {/* Grouped menu */}
      <nav className="flex-1 min-h-0 overflow-y-auto px-2 pb-24">
        {menuGroups.map((group, groupIndex) => {
          const isOpen = openGroups[group.title];
          return (
            <div key={group.title} className={groupIndex > 0 ? "mt-3" : ""}>
              {collapsed ? (
                // Collapsed: no headers — separate groups with a thin divider.
                groupIndex > 0 && <div className="mx-2 mb-2 border-t border-gray-100" />
              ) : (
                <button
                  onClick={() => toggleGroup(group.title)}
                  className="flex items-center justify-between w-full px-3 py-1.5 text-[11px] font-semibold uppercase tracking-wider text-gray-400 hover:text-gray-600 transition-colors"
                >
                  <span>{group.title}</span>
                  <ChevronDownIcon
                    className={`h-3.5 w-3.5 transition-transform duration-200 ${
                      isOpen ? "" : "-rotate-90"
                    }`}
                  />
                </button>
              )}

              {(collapsed || isOpen) && (
                <div className="space-y-0.5">{group.items.map(renderItem)}</div>
              )}
            </div>
          );
        })}
      </nav>

      {/* Settings */}
      <div className="absolute bottom-0 left-0 right-0 z-20 border-t border-gray-300 bg-white px-4 py-1.5">
        <NavLink
          to="/settings"
          title={collapsed ? "Setting" : undefined}
          className={`
            flex items-center
            ${collapsed ? "justify-center" : "justify-start"}
            px-4 py-1.5 my-0.5 rounded-xl
            transition-all duration-300 ease-in-out
            text-gray-800 hover:bg-gray-200 hover:text-gray-950
          `}
        >
          <Cog6ToothIcon className="h-6 w-6" />
          {!collapsed && <span className="ml-2">Setting</span>}
        </NavLink>
      </div>
    </aside>
  );
}
