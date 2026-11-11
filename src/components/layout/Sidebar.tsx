import {
  BeakerIcon,
  BookOpenIcon,
  ChartBarSquareIcon,
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
  LightBulbIcon,
  SparklesIcon,
  Cog6ToothIcon,
  PuzzlePieceIcon,
  CreditCardIcon,
  ChartBarIcon,
  PlayCircleIcon,
  ExclamationTriangleIcon,
  BellAlertIcon,
  PhotoIcon,
  SpeakerWaveIcon,
  SwatchIcon,
  AdjustmentsHorizontalIcon,
  BugAntIcon,
  ClockIcon,
  ChatBubbleLeftRightIcon,
  RocketLaunchIcon,
  LinkIcon,
  FireIcon as StreakIcon,
  MegaphoneIcon,
  UserGroupIcon,
  PresentationChartLineIcon,
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
    title: "Content",
    items: [
      { name: "Category", icon: PuzzlePieceIcon, path: "/category" },
      { name: "Course", icon: BookOpenIcon, path: "/course" },
      {
        // A/B nội dung khoá học: cấu hình đợt + bảng kết quả phễu theo người.
        name: "A/B nội dung",
        icon: BeakerIcon,
        path: "/content-experiments",
      },
      {
        // Đối chiếu các tag nội dung của MỘT khoá theo cửa sổ phát hành —
        // khác trang trên: chỗ kia là một đợt A/B đang chạy, chỗ này là lịch
        // sử phiên bản của khoá.
        name: "So sánh phiên bản",
        icon: ChartBarSquareIcon,
        path: "/version-comparison",
      },
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
    title: "Personalization",
    items: [
      { name: "Study Themes", icon: SwatchIcon, path: "/study-themes" },
    ],
  },
  {
    title: "Onboarding",
    items: [
      // { name: "Onboarding", icon: SparklesIcon, path: "/onboarding" },
      // { name: "Onboarding Branching", icon: SparklesIcon, path: "/onboarding-branching" },
      { name: "Onboarding Config", icon: AdjustmentsHorizontalIcon, path: "/onboarding-config" },
      { name: "Onboarding Taxonomy", icon: AdjustmentsHorizontalIcon, path: "/onboarding-taxonomy" },
      // { name: "Reset Onboarding (QA)", icon: BugAntIcon, path: "/reset-onboarding" },
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
    title: "Confession",
    items: [
      {
        name: "Kiểm duyệt",
        icon: ChatBubbleOvalLeftEllipsisIcon,
        path: "/community/moderation",
      },
      { name: "Phòng", icon: HashtagIcon, path: "/community/topics" },
      // The team's own identity — the name and picture on every official post.
      {
        name: "Đội ngũ HDDhistory",
        icon: CheckBadgeIcon,
        path: "/community/official-profile",
      },
      {
        name: "Đề xuất phòng",
        icon: LightBulbIcon,
        path: "/community/room-suggestions",
      },
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
      // The sheet behind the info button at the top of the chat room.
      {
        name: "Nội quy nhóm chat",
        icon: BookOpenIcon,
        path: "/community/chat-guide",
      },
    ],
  },
  {
    // The Coach's own section rather than three rows inside Operations. It is a
    // product surface with three moving parts — the switch that turns it on, the
    // cache an editor fixes after the fact, and the queue of turns a reader said
    // were wrong — and buried in a list of twelve unrelated tools they read as
    // three settings pages that happen to share a word.
    //
    // Items drop the "Coach" suffix now the header carries it, the same way
    // nothing under Confession repeats "Confession".
    title: "AI Coach",
    items: [
      { name: "Cấu hình", icon: ChatBubbleLeftRightIcon, path: "/coach-config" },
      { name: "Tình huống", icon: SparklesIcon, path: "/coach-situations" },
      { name: "Đánh giá", icon: HandThumbDownIcon, path: "/coach-ratings" },
      {
        name: "Nội dung user",
        icon: ChatBubbleLeftRightIcon,
        path: "/coach-contents",
      },
      {
        // The Coach's numbers live with the Coach, so the people who author it
        // read them without leaving the section they work in.
        name: "Thống kê",
        icon: PresentationChartLineIcon,
        path: "/coach-stats",
      },
      { name: "Chi phí AI", icon: SparklesIcon, path: "/coach-ai-usage" },
    ],
  },
  {
    title: "Operations",
    items: [
      { name: "Payment", icon: CreditCardIcon, path: "/payment" },
      { name: "Cấu hình paywall", icon: RocketLaunchIcon, path: "/paywall-config" },
      { name: "Lồng tiếng", icon: SpeakerWaveIcon, path: "/voiceover" },
      { name: "Link tải app", icon: LinkIcon, path: "/download-links" },
      // Cạnh "Link tải app" là có chủ đích: hai việc khác nhau (link tải app vs
      // link dẫn vào một màn trong app) mà tên gần nhau thì thấy được khác biệt
      // ngay tại chỗ chọn, khỏi vào sai trang. Tên khớp tiêu đề trang.
      { name: "Link Builder", icon: LinkIcon, path: "/deeplinks" },
      { name: "Popup streak", icon: StreakIcon, path: "/streak-config" },
      // Beside the other Explore-surface editors: a collection IS a strip on
      // the Khám phá tab, and it targets by the same `segmentIds` as the two
      // below it.
      { name: "Bộ sưu tập khoá học", icon: MegaphoneIcon, path: "/collections" },
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
      // Cuối nhóm, và chỉ đọc: đây là chỗ để TRA khi có gì đó vừa đổi mà không
      // ai nhận, chứ không phải một việc người ta vào đây để làm.
      { name: "Nhật ký thao tác", icon: ClockIcon, path: "/admin-audit" },
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

  const renderItem = (item: {
    name: string;
    icon: typeof BookOpenIcon;
    path: string;
  }) => {
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
          ${isActive
            ? "bg-brand-50 text-brand-800 shadow-sm border-l-4 border-brand-500"
            : "text-stone-600 hover:bg-brand-50/60 hover:text-stone-900"
          }
        `}
      >
        <div
          className={`
            flex items-center justify-center
            ${collapsed ? "w-8 h-8" : "w-9 h-9"}
            rounded-md
            ${isActive ? "bg-brand-100 text-brand-700" : "bg-stone-100 text-stone-500"}
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
        h-screen bg-white shadow-lg border-r border-stone-200
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
            bg-stone-100 hover:bg-brand-100
            transition-all duration-300 ease-in-out
            shadow-sm hover:shadow-md
            ${collapsed ? "ml-auto" : "mr-auto"}
          `}
        >
          {collapsed ? (
            <ChevronRightIcon className="h-4 w-4 text-stone-600" />
          ) : (
            <ChevronLeftIcon className="h-4 w-4 text-stone-600" />
          )}
        </button>
      </div>

      {/* Logo */}
      <div
        className={`flex items-center mb-5 transition-all duration-300 ${collapsed ? "justify-center px-0" : "gap-3 px-5"
          }`}
      >
        <img
          src="/logo-trong-dong.svg"
          alt="HDDhistory"
          className={`shrink-0 transition-all duration-300 ${collapsed ? "w-9 h-9" : "w-11 h-11"}`}
        />
        {!collapsed && (
          <div className="min-w-0 leading-tight">
            <div className="font-display text-lg font-bold tracking-tight text-brand-900">
              HDDhistory
            </div>
            <div className="text-xs font-medium text-brand-700/80">
              Trang quản trị
            </div>
          </div>
        )}
      </div>

      {/* Grouped menu */}
      <nav className="flex-1 min-h-0 overflow-y-auto px-2 pb-24">
        {menuGroups.map((group, groupIndex) => {
          const isOpen = openGroups[group.title];
          return (
            <div key={group.title} className={groupIndex > 0 ? "mt-3" : ""}>
              {collapsed ? (
                // Collapsed: no headers — separate groups with a thin divider.
                groupIndex > 0 && <div className="mx-2 mb-2 border-t border-stone-100" />
              ) : (
                <button
                  onClick={() => toggleGroup(group.title)}
                  className="flex items-center justify-between w-full px-3 py-1.5 text-[11px] font-semibold uppercase tracking-wider text-stone-400 hover:text-brand-700 transition-colors"
                >
                  <span>{group.title}</span>
                  <ChevronDownIcon
                    className={`h-3.5 w-3.5 transition-transform duration-200 ${isOpen ? "" : "-rotate-90"
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
      <div className="absolute bottom-0 left-0 right-0 z-20 border-t border-stone-200 bg-white px-4 py-1.5">
        <NavLink
          to="/settings"
          title={collapsed ? "Setting" : undefined}
          className={`
            flex items-center
            ${collapsed ? "justify-center" : "justify-start"}
            px-4 py-1.5 my-0.5 rounded-xl
            transition-all duration-300 ease-in-out
            text-stone-700 hover:bg-brand-50 hover:text-brand-900
          `}
        >
          <Cog6ToothIcon className="h-6 w-6" />
          {!collapsed && <span className="ml-2">Setting</span>}
        </NavLink>
      </div>
    </aside>
  );
}
