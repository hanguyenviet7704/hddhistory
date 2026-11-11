import { DEEPLINK_DESTINATIONS } from 'src/modules/deeplink/deeplink.catalog';

import { NotificationDeeplink } from '../notification.enum';

/**
 * `noti_type` mà app gắn vào event `noti_tap` khi người dùng chạm một campaign
 * gửi thủ công.
 *
 * Campaign không thuộc `NotificationType` nào — nó không có lịch, không có điều
 * kiện — nên không hiện trên các card "Theo dõi gửi", vốn chỉ đọc các loại có
 * lịch. Vẫn phải có một giá trị: app CHỈ bắn `noti_tap` khi payload có `type`
 * (xem `_handleScheduledNotificationTap` bên hddhistory-flutter), nên thiếu nó là mất
 * trắng số click của mọi campaign.
 */
export const CAMPAIGN_NOTI_TYPE = 'campaign';

/**
 * Đích mà một campaign gửi thủ công được phép trỏ tới: mọi khoá trong danh mục
 * deeplink dùng chung với link marketing (`deeplink.catalog.ts`), cộng các giá
 * trị `NotificationDeeplink` của những loại có lịch.
 *
 * Hai họ khoá cùng tồn tại là có lý do, không phải nợ kỹ thuật:
 * - `NotificationDeeplink` là đích của 8 loại có lịch. Vài cái chỉ có nghĩa khi
 *   bộ gửi bơm thêm dữ liệu vào payload (`new_course` cần `courseId`,
 *   `week_recap` cần `recapId`, `coach` cần `planId`) — campaign không có gì để
 *   bơm, nên màn soạn không mời chọn chúng. Vẫn NHẬN ở đây để campaign nháp tạo
 *   trước ngày này còn sửa và gửi được, và vì `home` với `resume_lesson` là hai
 *   đích campaign dùng nhiều nhất.
 * - Danh mục deeplink là đích của link marketing, app route đủ qua
 *   `enum DeeplinkDestination`. Dùng lại nó nghĩa là thêm một màn sau này chỉ
 *   cần deploy API — không release admin, không release app.
 *
 * Danh sách này là biên VALIDATE, không phải danh sách hiện trong dropdown: màn
 * soạn campaign tự lọc bỏ khoá cần tham số bắt buộc (`lesson`,
 * `category-courses`) vì ở đó không có picker chọn khoá học/bài.
 */
export const CAMPAIGN_DEEPLINK_KEYS: string[] = Array.from(
  new Set<string>([
    ...Object.values(NotificationDeeplink),
    ...DEEPLINK_DESTINATIONS.map(destination => destination.key),
  ]),
);
