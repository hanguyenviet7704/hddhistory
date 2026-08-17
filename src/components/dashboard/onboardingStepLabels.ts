// Human names for the onboarding funnel's steps.
//
// The API deliberately does not own this map: onboarding screens are reordered
// and renamed often, and that must never need an API deploy. It sends the raw
// event names ordered by how many people reached them; the panel names them.
//
// An event missing from this map still renders — `labelForStep` falls back to a
// readable form of the event name, so a new screen appears in the funnel the
// day it ships rather than disappearing until someone updates this file.

const STEP_LABELS: Record<string, string> = {
  obd_intro1_scr_view: "Giới thiệu 1",
  obd_intro2_scr_view: "Giới thiệu 2",
  obd_welcome_scr_view: "Màn chào mừng",
  obd_language_popup_view: "Chọn ngôn ngữ",
  obd_name_scr_view: "Nhập tên",
  obd_gender_scr_view: "Giới tính",
  obd_age_scr_view: "Độ tuổi",
  obd_infor_scr_view: "Thông tin cá nhân",
  obd_skillset_scr_view: "Chọn nhóm kỹ năng",
  obd_learning_goal_scr_view: "Mục tiêu học",
  obd_struggles_scr_view: "Khó khăn đang gặp",
  obd_symptom_scr_view: "Biểu hiện",
  obd_motivation1_scr_view: "Động lực 1",
  obd_motivation2_scr_view: "Động lực 2",
  obd_motivation3_scr_view: "Động lực 3",
  obd_how_to_learn_scr_view: "Cách học",
  obd_paths_scr_view: "Lộ trình gợi ý",
  obd_daily_time_scr_view: "Thời gian mỗi ngày",
  obd_learning_time_scr_view: "Khung giờ học",
  obd_notif_scr_view: "Bật thông báo",
  obd_theme_scr_view: "Chọn giao diện",
  obd_feedback_scr_view: "Đánh giá",
  obd_complete_scr_view: "Hoàn tất onboarding",
};

/** `obd_daily_time_scr_view` → "Thời gian mỗi ngày", or "Daily time" if unknown. */
export const labelForStep = (event: string): string => {
  if (STEP_LABELS[event]) return STEP_LABELS[event];

  const cleaned = event
    .replace(/^obd_/, "")
    .replace(/_scr_view$/, "")
    .replace(/_/g, " ")
    .trim();

  return cleaned ? cleaned.charAt(0).toUpperCase() + cleaned.slice(1) : event;
};
