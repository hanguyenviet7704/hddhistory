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
  HandThumbDownIcon,
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
  ClipboardDocumentCheckIcon,
  FireIcon as StreakIcon,
  MegaphoneIcon,
  UserGroupIcon,
  PresentationChartLineIcon,
  DevicePhoneMobileIcon,
  MapPinIcon,
  ChatBubbleOvalLeftEllipsisIcon,
  HashtagIcon,
  CalendarDaysIcon,
  NoSymbolIcon,
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
    // Product health first: this is the page anyone opening the panel in the
    // morning wants, and it is the only group that answers "how are we doing"
    // rather than "what can I edit".
    title: "Dashboard",
    items: [
      {
        name: "Báo cáo tuần",
        icon: PresentationChartLineIcon,
        path: "/dashboard",
        // Without this, "/dashboard" would also light up on
        // "/dashboard/users" and two items would look selected at once.
        exact: true,
      },
      { name: "Người dùng & Giữ chân", icon: UserGroupIcon, path: "/dashboard/users" },
      { name: "Phiên & Tương tác", icon: DevicePhoneMobileIcon, path: "/dashboard/sessions" },
      { name: "Funnel onboarding", icon: RocketLaunchIcon, path: "/dashboard/onboarding" },
      { name: "Hành vi học", icon: BookOpenIcon, path: "/dashboard/learning" },
      // Gộp trên TOÀN BỘ user — khác trang User progress soi từng người. Trả
      // lời câu hỏi biên tập: khoá nào đang làm rơi người học ở keypoint nào.
      { name: "Điểm dừng khoá học", icon: MapPinIcon, path: "/dashboard/drop-off" },
      // Moved here from Operations: it is the same question as the rest of
      // this group. The route is unchanged so saved links still work.
      { name: "Tiến trình khoá", icon: ChartBarIcon, path: "/statistics" },
    ],
  },
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
      // Habits manages the library (content); Habit check-ins is the read-only
      // view of what users actually do with it, journal text included.
      { name: "Habit check-ins", icon: ClipboardDocumentCheckIcon, path: "/habit-checkins" },
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
        name: "Lesson Feedback",
        icon: ChartBarIcon,
        path: "/lesson-feedback",
      },
      {
        name: "Survey Feedback",
        icon: ChatBubbleLeftRightIcon,
        path: "/settings?tab=inAppSurvey",
      },
    ],
  },
  {
    // The community forum. Moderation comes first because it is the only one of
    // these with a queue: post-moderated content stays up until someone works
    // through the reports.
    title: "Community",
    items: [
      {
        name: "Kiểm duyệt",
        icon: ChatBubbleOvalLeftEllipsisIcon,
        path: "/community/moderation",
      },
      { name: "Chủ đề", icon: HashtagIcon, path: "/community/topics" },
      {
        name: "Câu hỏi của tuần",
        icon: CalendarDaysIcon,
        path: "/community/weekly",
      },
      {
        name: "Khoá quyền đăng",
        icon: NoSymbolIcon,
        path: "/community/sanctions",
      },
    ],
  },
  {
    title: "Operations",
    items: [
      // "Statistics" now lives in the Dashboard group as "Tiến trình khoá".
      { name: "Payment", icon: CreditCardIcon, path: "/payment" },
      { name: "Cấu hình paywall", icon: RocketLaunchIcon, path: "/paywall-config" },
      { name: "Lồng tiếng", icon: SpeakerWaveIcon, path: "/voiceover" },
      { name: "Link tải app", icon: LinkIcon, path: "/download-links" },
      // Cạnh "Link tải app" là có chủ đích: hai việc khác nhau (link tải app vs
      // link dẫn vào một màn trong app) mà tên gần nhau thì thấy được khác biệt
      // ngay tại chỗ chọn, khỏi vào sai trang. Tên khớp tiêu đề trang.
      { name: "Link Builder", icon: LinkIcon, path: "/deeplinks" },
      { name: "Popup streak", icon: StreakIcon, path: "/streak-config" },
      // The three AI Coach surfaces sit together: the switch that turns the
      // feature on, the cache an editor fixes after the fact, and the queue of
      // turns a reader said were wrong. Named to match their page titles.
      { name: "AI Coach", icon: ChatBubbleLeftRightIcon, path: "/coach-config" },
      { name: "Tình huống Coach", icon: SparklesIcon, path: "/coach-situations" },
      { name: "Đánh giá Coach", icon: HandThumbDownIcon, path: "/coach-ratings" },
      { name: "Banner Home", icon: MegaphoneIcon, path: "/home-banner" },
      { name: "Popup Home", icon: MegaphoneIcon, path: "/home-popup" },
      // Audience groups that Banner Home / Popup Home target via `segmentIds`
      // — kept right beside them so the relationship reads at a glance.
      { name: "Phân khúc user", icon: UserGroupIcon, path: "/segments" },
      // Read-only: what users imported (PDF / YouTube) and the lesson the model
      // wrote back. Named to match its page title rather than the Vietnamese
      // labels around it, so nav and heading agree.
      { name: "User imports", icon: SparklesIcon, path: "/learning-imports" },
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
  const isActivePath = (path: string, exact?: boolean) => {
    const currentPath = location.pathname;
    if (currentPath === path) return true;
    // An `exact` item owns only its own path — "/dashboard" must not light up
    // while "/dashboard/users" is open, or two items look selected at once.
    if (exact) return false;
    // "/lesson" also matches "/lesson/123", "/lesson/edit"...
    if (currentPath.startsWith(path + "/")) return true;
    return false;
  };

  const renderItem = (item: {
    name: string;
    icon: typeof BookOpenIcon;
    path: string;
    exact?: boolean;
  }) => {
    const Icon = item.icon;
    const isActive = isActivePath(item.path, item.exact);
    // Dashboard pages keep their period in the query string. Carrying it across
    // means switching sections re-asks the same question of a different page,
    // instead of silently snapping back to the default 7 days.
    const isDashboardHop =
      item.path.startsWith("/dashboard") &&
      location.pathname.startsWith("/dashboard");
    const to = isDashboardHop ? `${item.path}${location.search}` : item.path;
    return (
      <NavLink
        key={item.name}
        to={to}
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
