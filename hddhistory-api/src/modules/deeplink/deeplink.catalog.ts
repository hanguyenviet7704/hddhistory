/**
 * Danh mục màn mà một link `https://meup.training/open/<key>` có thể dẫn tới.
 *
 * Một HẰNG SỐ phục vụ qua HTTP: không entity, không repository, không migration.
 * Đặt ở API chứ không hardcode trong admin vì API được deploy dày hơn admin
 * nhiều -- thêm một màn không phải chờ release admin -- và vì giai đoạn 2 (đích
 * cho `/r/<slug>`) sẽ validate bằng đúng danh mục này. Một nguồn sự thật.
 *
 * `key` là hợp đồng công khai: nó nằm trong link đã gửi push, đã in QR. Phải
 * khớp TỪNG KÝ TỰ với `enum DeeplinkDestination` bên hddhistory-flutter
 * (`lib/src/common/domain/entities/deeplink_target.dart`). Thêm khoá thì được;
 * đổi hoặc xoá khoá cũ là làm chết link đã phát ra.
 */
export enum DeeplinkParamPicker {
  COURSE = 'course',
  CATEGORY = 'category',
  KEYPOINT = 'keypoint',
  SELECT = 'select',
  TEXT = 'text',
}

export interface DeeplinkParamDef {
  name: string;
  required: boolean;
  picker: DeeplinkParamPicker;
  /** Chỉ có với picker SELECT. */
  options?: string[];
}

export interface DeeplinkDestinationDef {
  key: string;
  label: string;
  group: string;
  /**
   * Build number nhỏ nhất của app hiểu được khoá này.
   *
   * Không phải trang trí: thiếu nó thì marketer gửi link tới màn mới cho phần
   * lớn người đang dùng bản cũ, tất cả rơi về Home, và không ai hiểu tại sao.
   * `home` và `paywall` đã chạy từ 1.5.2+129; mọi khoá còn lại cần bản 130.
   */
  minAppBuild: number;
  note?: string;
  params: DeeplinkParamDef[];
}

const NO_PARAMS: DeeplinkParamDef[] = [];

export const DEEPLINK_DESTINATIONS: DeeplinkDestinationDef[] = [
  {
    key: 'home',
    label: 'Trang chủ',
    group: 'Tab',
    minAppBuild: 129,
    params: NO_PARAMS,
  },
  {
    key: 'explore',
    label: 'Khám phá',
    group: 'Tab',
    minAppBuild: 130,
    params: NO_PARAMS,
  },
  {
    key: 'habit',
    label: 'Thói quen',
    group: 'Tab',
    minAppBuild: 130,
    params: NO_PARAMS,
  },
  {
    key: 'profile',
    label: 'Trang cá nhân',
    group: 'Tab',
    minAppBuild: 130,
    params: NO_PARAMS,
  },
  {
    key: 'library',
    label: 'Thư viện',
    group: 'Tab',
    minAppBuild: 130,
    params: NO_PARAMS,
  },
  {
    key: 'course-roadmap',
    label: 'Lộ trình khoá học',
    group: 'Học',
    minAppBuild: 130,
    note: 'Không chọn khoá học thì mở lộ trình của khoá người dùng đang học.',
    params: [
      { name: 'courseId', required: false, picker: DeeplinkParamPicker.COURSE },
    ],
  },
  {
    key: 'lesson',
    label: 'Bài học cụ thể',
    group: 'Học',
    minAppBuild: 130,
    note: 'Đi qua lộ trình rồi mở bài. Bài premium vẫn hiện khoá/paywall như bình thường.',
    params: [
      { name: 'courseId', required: true, picker: DeeplinkParamPicker.COURSE },
      {
        name: 'keypointId',
        required: false,
        picker: DeeplinkParamPicker.KEYPOINT,
      },
    ],
  },
  {
    key: 'category-courses',
    label: 'Tất cả khoá của một chủ đề',
    group: 'Học',
    minAppBuild: 130,
    params: [
      {
        name: 'categoryId',
        required: true,
        picker: DeeplinkParamPicker.CATEGORY,
      },
    ],
  },
  {
    key: 'paywall',
    label: 'Màn mua gói',
    group: 'Tiền',
    minAppBuild: 129,
    note: 'Không chọn biến thể thì dùng bảng entry-point trong Cấu hình paywall.',
    params: [
      {
        name: 'variant',
        required: false,
        picker: DeeplinkParamPicker.SELECT,
        options: ['full', 'compact'],
      },
    ],
  },
  {
    key: 'manage-subscription',
    label: 'Quản lý gói đăng ký',
    group: 'Tiền',
    minAppBuild: 130,
    params: NO_PARAMS,
  },
  {
    key: 'daily-warm-up',
    label: 'Khởi động mỗi ngày',
    group: 'Engagement',
    minAppBuild: 130,
    params: NO_PARAMS,
  },
  {
    key: 'learning-streak',
    label: 'Chuỗi ngày học',
    group: 'Engagement',
    minAppBuild: 130,
    params: NO_PARAMS,
  },
  {
    key: 'daily-check-in',
    label: 'Điểm danh thói quen',
    group: 'Engagement',
    minAppBuild: 130,
    params: NO_PARAMS,
  },
  {
    key: 'my-lessons',
    label: 'Bài của tôi',
    group: 'Nội dung riêng',
    minAppBuild: 130,
    params: NO_PARAMS,
  },
  {
    key: 'import-lesson',
    label: 'Tạo bài học từ tài liệu',
    group: 'Nội dung riêng',
    minAppBuild: 130,
    params: NO_PARAMS,
  },
  {
    key: 'notification-setting',
    label: 'Cài đặt thông báo',
    group: 'Cài đặt',
    minAppBuild: 130,
    params: NO_PARAMS,
  },
  {
    key: 'change-language',
    label: 'Đổi ngôn ngữ',
    group: 'Cài đặt',
    minAppBuild: 130,
    params: NO_PARAMS,
  },
  {
    key: 'community',
    label: 'Cộng đồng',
    group: 'Tab',
    // Tab Cộng đồng có từ 1.5.8+141; khoá này là đích của push diễn đàn.
    minAppBuild: 141,
    params: NO_PARAMS,
  },
  {
    key: 'community-post',
    label: 'Bài viết cộng đồng',
    group: 'Cộng đồng',
    minAppBuild: 141,
    note: 'Mở thẳng một bài trong diễn đàn. Thiếu postId thì chỉ mở tab Cộng đồng.',
    params: [
      {
        name: 'postId',
        required: true,
        picker: DeeplinkParamPicker.TEXT,
      },
    ],
  },
  {
    key: 'community-chat',
    label: 'Bàn luận cộng đồng',
    group: 'Cộng đồng',
    // Đích của push "có người trả lời trong bàn luận" (câu hỏi của tuần).
    minAppBuild: 145,
    note: 'Mở thẳng một phòng bàn luận. `room` là SLUG của phòng, không phải id.',
    params: [
      {
        name: 'room',
        required: true,
        picker: DeeplinkParamPicker.TEXT,
      },
    ],
  },
  {
    key: 'coach',
    label: 'AI Coach',
    group: 'Engagement',
    // Bản đầu tiên có đích này trong enum Flutter (1.6.0+145). Bản cũ hơn rơi
    // về Home như mọi khoá lạ.
    minAppBuild: 145,
    note: 'Mở sheet AI Coach trên Home — đúng chỗ push nhắc hẹn dẫn tới. Cửa vào (điểm danh / hỏi lại hẹn / kể chuyện) do server quyết.',
    params: NO_PARAMS,
  },
];

/**
 * Lọc bộ tham số của một campaign về đúng thứ danh mục cho phép ở đích đó.
 *
 * Ba việc, và cả ba đều cần thiết vì bộ tham số này được BƠM THẲNG vào payload
 * push: chỉ nhận tên tham số mà đích đó khai (khoá lạ bị bỏ, nên không ai gắn
 * được `deeplink` hay `type` để đè khoá điều khiển của lớp thông báo), chỉ nhận
 * giá trị nằm trong `options` với picker SELECT (sai giá trị thì app rơi về bảng
 * entry-point, im lặng — đúng thứ phải chặn ở đây chứ không phải ngoài đó), và
 * bỏ chuỗi rỗng vì "có truyền nhưng bỏ trống" đọc như thiếu tham số.
 *
 * Trả về object rỗng khi không còn gì hợp lệ — người gọi lưu nguyên, và đích
 * chạy đúng như trước khi có tham số.
 */
export function sanitizeDeeplinkParams(
  key: string,
  params?: Record<string, string> | null,
): Record<string, string> {
  if (!params) return {};

  const destination = DEEPLINK_DESTINATIONS.find(item => item.key === key);
  if (!destination) return {};

  const clean: Record<string, string> = {};

  for (const def of destination.params) {
    const raw = params[def.name];
    if (typeof raw !== 'string') continue;

    const value = raw.trim();
    if (!value) continue;

    if (
      def.picker === DeeplinkParamPicker.SELECT &&
      !(def.options ?? []).includes(value)
    ) {
      continue;
    }

    clean[def.name] = value;
  }

  return clean;
}
