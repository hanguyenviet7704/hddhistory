/**
 * Chữ và quy tắc hiển thị dùng chung cho mọi màn cộng đồng.
 *
 * Nằm ngoài `lib/community.ts` vì client component cũng cần, còn file kia là
 * `server-only`. Câu chữ chép từ `assets/i18n/vi/community.yaml` của app.
 */
import type {
  CommunityAuthor,
  CommunityNotification,
} from '@/lib/community';

/**
 * Tên tác giả theo đúng thứ tự ưu tiên của `community_avatar.dart`.
 *
 * API cố ý để trống tên (tài khoản đã xoá, bài ẩn danh) để app tự chọn chữ
 * theo ngôn ngữ người đọc — nên phần thay thế phải nằm ở đây.
 */
export function authorName(author: CommunityAuthor | null | undefined): string {
  const name = author?.name?.trim() ?? '';
  if (author?.authorType === 'OFFICIAL') return name || 'Đội ngũ HDDhistory';
  if (author?.authorType === 'ANONYMOUS') return 'Người giấu tên';
  return name || 'Một thành viên HDDhistory';
}

export function authorInitial(author: CommunityAuthor | null | undefined): string {
  if (author?.authorType === 'ANONYMOUS') return '?';
  return authorName(author).trim().charAt(0).toUpperCase() || '?';
}

/** "Vừa xong / N phút trước / … / N tuần trước", rồi ngày tháng. */
export function relativeTime(iso: string | null | undefined): string {
  if (!iso) return '';
  const then = new Date(iso).getTime();
  if (Number.isNaN(then)) return '';
  const minutes = Math.floor((Date.now() - then) / 60000);
  if (minutes < 1) return 'Vừa xong';
  if (minutes < 60) return `${minutes} phút trước`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} giờ trước`;
  const days = Math.floor(hours / 24);
  if (days === 1) return 'Hôm qua';
  if (days < 7) return `${days} ngày trước`;
  if (days < 35) return `${Math.floor(days / 7)} tuần trước`;
  return formatDate(iso);
}

export function formatDate(iso: string | null | undefined): string {
  if (!iso) return '';
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '';
  return date.toLocaleDateString('vi-VN', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    timeZone: 'Asia/Ho_Chi_Minh',
  });
}

export function formatClock(iso: string | null | undefined): string {
  if (!iso) return '';
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '';
  return date.toLocaleTimeString('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
    timeZone: 'Asia/Ho_Chi_Minh',
  });
}

/** Lý do báo cáo — đúng enum `CommunityReportReason` của API, chữ của app. */
export const REPORT_REASONS = [
  { value: 'SPAM', label: 'Spam hoặc rao bán' },
  { value: 'HARASSMENT', label: 'Quấy rối, xúc phạm' },
  { value: 'ADULT', label: 'Nội dung 18+' },
  { value: 'MISINFORMATION', label: 'Thông tin sai' },
  { value: 'PRIVACY', label: 'Tiết lộ danh tính người khác' },
  { value: 'OTHER', label: 'Lý do khác' },
] as const;

export type ReportReason = (typeof REPORT_REASONS)[number]['value'];

/** Giới hạn lấy từ validator DTO của API — form chặn trước cho đỡ một vòng 400. */
export const LIMITS = {
  postSubject: 160,
  postBody: 5000,
  postImages: 4,
  comment: 2000,
  chat: 1000,
  reportNote: 1000,
  roomName: 40,
  roomDescription: 160,
} as const;

/**
 * Câu của một dòng thông báo, tách hai phần: tên người làm (in đậm) và phần
 * còn lại. Thông báo kiểm duyệt nói về CHÍNH người đọc nên không có tên.
 */
export function notificationText(item: CommunityNotification): {
  actor: string | null;
  text: string;
} {
  const others = item.otherActorCount ?? 0;
  const actor = authorName(item.actor);
  switch (item.type) {
    case 'LIKE_ON_POST':
      return {
        actor,
        text: others > 0
          ? `và ${others} người khác đã thích bài viết của bạn`
          : 'đã thích bài viết của bạn',
      };
    case 'COMMENT_ON_POST':
      return { actor, text: 'đã bình luận trong bài viết của bạn' };
    case 'REPLY_TO_COMMENT':
      return { actor, text: 'đã trả lời bình luận của bạn' };
    case 'COMMENT_ON_FOLLOWED_POST':
      return { actor, text: 'đã bình luận trong bài bạn theo dõi' };
    case 'OFFICIAL_REPLY':
      return { actor, text: 'đã trả lời trong bài viết của bạn' };
    case 'ANSWER_ON_WEEKLY':
      return {
        actor,
        text: others > 0
          ? `và ${others} người khác vừa trả lời câu hỏi bạn đã trả lời`
          : 'vừa trả lời câu hỏi bạn đã trả lời',
      };
    case 'MESSAGE_IN_ROOM':
      return { actor, text: 'vừa trả lời trong bàn luận' };
    case 'POST_HIDDEN':
      return { actor: null, text: 'Bài của bạn đã được ẩn' };
    case 'SANCTION_APPLIED':
      return { actor: null, text: 'Quyền đăng của bạn đang tạm khoá' };
    default:
      return { actor: item.actor ? actor : null, text: 'Thông báo' };
  }
}

/** Dòng thông báo dẫn về đâu: phòng chat trước, rồi tới bài viết. */
export function notificationHref(item: CommunityNotification): string | null {
  if (item.roomSlug) return `/cong-dong/tro-chuyen/${encodeURIComponent(item.roomSlug)}`;
  if (item.postId) return `/cong-dong/bai/${encodeURIComponent(item.postId)}`;
  return null;
}

/** "còn N ngày" của câu hỏi tuần; null khi không có hạn hoặc đã qua. */
export function daysLeft(endsAt: string | null | undefined): number | null {
  if (!endsAt) return null;
  const ms = new Date(endsAt).getTime() - Date.now();
  if (Number.isNaN(ms) || ms <= 0) return null;
  return Math.ceil(ms / 86_400_000);
}
