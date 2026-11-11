// Onboarding funnel steps, in the order the shipped onboard_v2 flow fires them
// (mirrors the onboardV2P1..P9 constants in
// hddhistory-flutter/lib/core/constants/manual/tracking_key.dart).
//
// The API never knows this order — it only reports when each `obd_*` event was
// first seen. CHANGE THE ONBOARDING FLOW, CHANGE THIS LIST: nothing else can
// derive it, and a missing step just renders as "chưa tới".
export const ONBOARDING_FUNNEL_STEPS: { name: string; label: string }[] = [
  { name: "obd_welcome_scr_view", label: "Welcome" },
  { name: "obd_welcome_get_started", label: "Bấm Get started" },
  { name: "obd_name_scr_view", label: "Nhập tên" },
  { name: "obd_name_continue", label: "Xong tên" },
  { name: "obd_age_scr_view", label: "Chọn tuổi" },
  { name: "obd_age_select", label: "Xong tuổi" },
  { name: "obd_notif_scr_view", label: "Xin quyền thông báo" },
  { name: "obd_paths_scr_view", label: "Chọn hướng học" },
  { name: "obd_paths_select", label: "Xong hướng học" },
  { name: "obd_infor_scr_view", label: "Thông tin thêm" },
  { name: "obd_infor_continue", label: "Xong thông tin" },
  { name: "obd_symptom_scr_view", label: "Chọn vấn đề" },
  { name: "obd_symptom_select", label: "Xong vấn đề" },
  { name: "obd_course_view", label: "Chọn khoá đầu tiên" },
  { name: "obd_course_select", label: "Xong khoá đầu tiên" },
  { name: "obd_theme_scr_view", label: "Chọn theme" },
  { name: "obd_theme_select", label: "Bắt đầu học" },
];

// Quick fills for the "tên event bắt đầu bằng" filter. Prefix match only — it is
// what the index supports, and it keeps the query cheap.
export const EVENT_PREFIX_PRESETS: { value: string; label: string }[] = [
  { value: "", label: "Tất cả event" },
  { value: "obd_", label: "Onboarding" },
  { value: "home_", label: "Home" },
  { value: "explore_", label: "Explore" },
  { value: "course_", label: "Course" },
  { value: "roadmap_", label: "Roadmap" },
  { value: "keypoint_", label: "Keypoint" },
  { value: "roleplay_", label: "Roleplay" },
  { value: "output_", label: "Output practice" },
  { value: "video_", label: "Video" },
  { value: "audio_", label: "Audio" },
  { value: "daily_", label: "Daily warm-up" },
  { value: "habit_", label: "Habit" },
  { value: "paywall_", label: "Paywall" },
  { value: "subscription_", label: "Subscription" },
  { value: "profile_", label: "Profile" },
  { value: "setting_", label: "Setting" },
  { value: "theme_", label: "Study theme" },
];

export const APP_ENV_OPTIONS: { value: string; label: string }[] = [
  { value: "", label: "Tất cả môi trường" },
  { value: "dev", label: "dev" },
  { value: "stg", label: "stg" },
  { value: "prod", label: "prod" },
];

export const RANGE_PRESETS: { value: number; label: string }[] = [
  { value: 7, label: "7 ngày" },
  { value: 30, label: "30 ngày" },
  { value: 90, label: "90 ngày" },
];
