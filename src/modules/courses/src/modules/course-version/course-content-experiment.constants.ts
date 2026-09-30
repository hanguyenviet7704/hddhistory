/**
 * Phễu của A/B nội dung khoá học. Tên event phải khớp `TrackingKey` trong app
 * TỪNG KÝ TỰ (`lib/core/constants/manual/tracking_key.dart`) — gõ sai không
 * làm gì fail, nó trả về một con số 0 trông rất thật.
 *
 * Chỉ số chốt là **hoàn thành keypoint**: đơn vị nhỏ nhất và dày dữ liệu nhất,
 * nên đủ cỡ mẫu nhanh hơn phễu paywall rất nhiều (tỉ lệ hoàn thành hàng chục %
 * chứ không phải 3%).
 */
export const CONTENT_EXPERIMENT_EVENTS = {
  /** Mẫu số: người mở khoá ra xem. */
  courseView: 'roadmap_scr_view',
  keypointStart: 'keypoint_intro_scr_view',
  /**
   * Bước giữa là ĐỌC NỘI DUNG, không phải "vào bài tập".
   *
   * Hai lý do, và lý do thứ hai mới là lý do thật: với A/B *nội dung* thì "có
   * đọc bài không" gần với thứ đang test hơn; và `keypoint_exercise_scr_view`
   * KHÔNG BAO GIỜ ĐƯỢC GỬI — hằng số có trong `tracking_key.dart` nhưng không
   * chỗ nào trong app gọi tới. Dùng nó là dựng một cột luôn bằng 0 mà trông
   * rất thật.
   */
  keypointRead: 'keypoint_read_scr_view',
  complete: 'keypoint_complete_click',
  // Tín hiệu âm — nội dung nào bị bỏ ít hơn thì tốt hơn. Đứng cạnh phễu dương
  // để một nhánh "hoàn thành cao nhờ dễ hơn" không tự nhận là thắng.
  skip: 'keypoint_complete_skip',
  exit: 'keypoint_exit_popup_view',
  // `keypoint_report_click` cũng không được gửi ở đâu; cái app thật bắn là
  // `keypoint_menu_report_click` qua LessonTracking.
  report: 'keypoint_menu_report_click',
} as const;

/** Param app đóng dấu nhánh lên. */
export const CONTENT_EXPERIMENT_PARAM = 'content_variant';

/** Param app đóng dấu đợt lên, để phễu không trộn hai đợt vào nhau. */
export const CONTENT_EXPERIMENT_KEY_PARAM = 'content_experiment_key';
