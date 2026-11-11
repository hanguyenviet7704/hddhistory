/**
 * Chữ của tính năng tạo bài, chép từ `assets/i18n/vi/learning_import.yaml`.
 *
 * Module thường (không `server-only`) vì cả trang máy chủ lẫn màn chờ phía
 * client cùng cần biến mã lỗi thành câu.
 */

export const STAGE_LABEL: Record<string, string> = {
  fetching: 'Đang đọc tài liệu…',
  generating: 'Đang soạn bài…',
  validating: 'Đang kiểm tra lại…',
  saving: 'Sắp xong…',
  dubbing: 'Đang lồng tiếng…',
};

const ERROR_TEXT: Record<string, string> = {
  PDF_UNREADABLE: 'Không đọc được nội dung tệp PDF này. Thử tệp khác nhé.',
  PDF_TOO_LARGE: 'Tài liệu quá lớn. Thử tài liệu dưới 300 trang.',
  YOUTUBE_NO_TRANSCRIPT:
    'Video này không có phụ đề nên không có gì để đọc. Thử video khác nhé.',
  YOUTUBE_UNAVAILABLE:
    'Không mở được video này. Có thể video ở chế độ riêng tư hoặc đã bị xoá.',
  YOUTUBE_TOO_LONG: 'Video quá dài. Thử video dưới 3 tiếng.',
  YOUTUBE_TOO_SHORT:
    'Video quá ngắn. Chọn video dài hơn 10 phút để đủ nội dung cho một bài học.',
  CONTENT_TOO_SHORT: 'Tài liệu này không đủ nội dung để soạn thành bài học.',
  AI_TIMEOUT: 'Quá trình mất nhiều thời gian hơn dự kiến. Thử lại nhé.',
  AI_FAILED: 'Có trục trặc khi soạn bài. Thử lại nhé.',
  AI_NOT_CONFIGURED: 'Có trục trặc khi soạn bài. Thử lại nhé.',
  SOURCE_FETCH_FAILED: 'Có trục trặc khi soạn bài. Thử lại nhé.',
  INTERNAL: 'Có trục trặc khi soạn bài. Thử lại nhé.',
  NOT_PREMIUM: 'Tạo bài học từ tài liệu của bạn là tính năng Premium.',
  QUOTA_EXCEEDED: 'Bạn đã dùng hết lượt tạo bài trong tuần này.',
  JOB_ALREADY_RUNNING:
    'Bạn đang có một bài đang được tạo. Đợi xong rồi tạo tiếp nhé.',
  INTERRUPTED: 'Quá trình bị gián đoạn. Thử lại nhé — lượt của bạn chưa bị trừ.',
};

/**
 * Mã lỗi → câu. Dựa vào MÃ chứ không vào `message` của API: message là tiếng
 * Anh, viết cho admin và log, không phải cho người học.
 */
export function importErrorText(code?: string | null): string {
  return (code && ERROR_TEXT[code]) || 'Có gì đó không ổn. Thử lại nhé.';
}

export const FEATURE_OFF_TITLE = 'Tạm dừng tạo bài học';
export const FEATURE_OFF_BODY =
  'Tính năng đang tắt một lát. Bài học của bạn vẫn còn nguyên, chỉ là chưa tạo mới được thôi.';

/** Trần PDF của API (`maxPdfBytes`) — chặn trước để khỏi tải 50MB lên rồi mới bị từ chối. */
export const MAX_PDF_MB = 20;
