/**
 * Cộng đồng (tab "Thảo luận" của app): bảng tin, bài viết, bình luận, phòng,
 * câu hỏi tuần, thông báo và phòng chat nhóm.
 *
 * Hình dạng dữ liệu lấy từ hàm `toViews`/`toView` trong các service của
 * `hddhistory-api/src/modules/community` và đã dò lại trên API local — không
 * suy từ tên endpoint. Bảng tin là `/community/feed`, KHÔNG phải
 * `/community/posts` (đường đó chỉ có `/:id` và POST).
 *
 * Mọi lời gọi ở đây dùng `revalidate: 0`: số thích, bình luận, chấm đỏ thông
 * báo và quyền đăng bài đổi theo từng thao tác, và một bảng tin trễ 30 giây
 * sau khi chính mình vừa thả tim trông như nút bị hỏng.
 */
import 'server-only';

import { request } from './api';

export type AuthorType = 'USER' | 'OFFICIAL' | 'ANONYMOUS';

export interface CommunityAuthor {
  /** Rỗng với bài ẩn danh: API bỏ cả id để không ai ghép được hai bài với nhau. */
  id?: string;
  name?: string;
  avatar?: string;
  authorType?: AuthorType;
}

export interface CommunityTopicRef {
  id: string;
  name?: string;
  imageUrl?: string | null;
}

export interface AttachedCard {
  keypointId: string;
  title?: string;
  back?: string;
  courseName?: string;
}

export interface CommunityPost {
  id: string;
  type?: 'POST' | 'WEEKLY_QUESTION';
  author?: CommunityAuthor;
  topic?: CommunityTopicRef | null;
  subject?: string;
  body?: string;
  images?: string[];
  attachedCourseId?: string | null;
  attachedCard?: AttachedCard | null;
  isPinned?: boolean;
  commentsLocked?: boolean;
  likeCount?: number;
  commentCount?: number;
  /** Số người bấm chuông theo dõi bài (reaction SAVE). */
  saveCount?: number;
  isLiked?: boolean;
  /** Đang theo dõi bài — app gọi là cái chuông, API vẫn lưu là SAVE. */
  isSaved?: boolean;
  isMine?: boolean;
  createdAt?: string;
}

export interface WeeklyQuestion {
  /** Id của bài WEEKLY_QUESTION — câu trả lời là bình luận trên bài này. */
  id: string;
  title?: string;
  note?: string;
  weekNumber?: number | null;
  year?: number | null;
  startsAt?: string | null;
  endsAt?: string | null;
  answerCount?: number;
}

export interface CommunityFeed {
  /** Mốc trang 1 đóng dấu; các trang sau gửi lại để bài mới không chen hàng. */
  anchorAt?: string;
  weekly: WeeklyQuestion | null;
  pinned: CommunityPost[];
  items: CommunityPost[];
  currentPage: number;
  totalPages: number;
}

export type FeedSort = 'RECENT' | 'ACTIVE';

export interface FeedQuery {
  page?: number;
  take?: number;
  topicId?: string;
  /** Tab "Đang theo dõi": chỉ các bài người đọc đã bấm chuông. */
  followedOnly?: boolean;
  sort?: FeedSort;
  anchorAt?: string;
}

export interface CommunityComment {
  id: string;
  author?: CommunityAuthor;
  body?: string;
  likeCount?: number;
  replyCount?: number;
  isLiked?: boolean;
  isMine?: boolean;
  /** Tên người được trả lời, để vẽ "@tên" trước câu trả lời. */
  replyToName?: string | null;
  createdAt?: string;
  /** Chỉ có ở bình luận gốc — luồng sâu đúng hai tầng. */
  replies?: CommunityComment[];
}

export interface CommentPage {
  items: CommunityComment[];
  currentPage: number;
  totalPages: number;
}

export interface CommunityTopic {
  id: string;
  name?: string;
  description?: string;
  slug?: string;
  imageUrl?: string;
  followers?: number;
  postsThisWeek?: number;
  postsToday?: number;
  /** Bài + bình luận mọi thời — thay cho `postsThisWeek` bị quét về 0 mỗi tuần. */
  discussions?: number;
  isFollowing?: boolean;
}

export interface TopicList {
  following: CommunityTopic[];
  all: CommunityTopic[];
}

export interface MemberStatus {
  canPost: boolean;
  requiresLogin?: boolean;
  reason?: string | null;
  mutedUntil?: string | null;
  tourSeen?: boolean;
}

export type NotificationType =
  | 'COMMENT_ON_POST'
  | 'REPLY_TO_COMMENT'
  | 'LIKE_ON_POST'
  | 'COMMENT_ON_FOLLOWED_POST'
  | 'ANSWER_ON_WEEKLY'
  | 'MESSAGE_IN_ROOM'
  | 'OFFICIAL_REPLY'
  | 'POST_HIDDEN'
  | 'SANCTION_APPLIED';

export interface CommunityNotification {
  id: string;
  type?: NotificationType | string;
  actor?: CommunityAuthor | null;
  /** 0 khi chỉ có một người; app đọc thành "và N người khác". */
  otherActorCount?: number;
  postId?: string | null;
  commentId?: string | null;
  roomSlug?: string | null;
  isRead?: boolean;
  createdAt?: string;
}

export interface NotificationPage {
  items: CommunityNotification[];
  currentPage: number;
  totalPages: number;
  unreadCount: number;
}

export interface ChatRoom {
  id: string;
  slug?: string;
  name?: string;
  isOfficial?: boolean;
  onlineCount?: number;
  unreadCount?: number;
}

export interface ChatReplyRef {
  id: string;
  author?: CommunityAuthor | null;
  body?: string;
  /** Tin gốc đã bị gỡ — vẫn vẽ dải trích dẫn, chỉ thay chữ. */
  isRemoved?: boolean;
}

export interface ChatMessage {
  id: string;
  author?: CommunityAuthor;
  isModerator?: boolean;
  body?: string;
  likeCount?: number;
  isLiked?: boolean;
  isMine?: boolean;
  isPinned?: boolean;
  pinnedAt?: string | null;
  replyTo?: ChatReplyRef | null;
  /** Chỉ có nghĩa trên tin của chính mình: đã có người khác đọc qua nó. */
  isSeen?: boolean;
  createdAt?: string;
}

export interface ChatPage {
  /** Mới nhất trước — trang 1 là đáy màn hình. */
  items: ChatMessage[];
  pinned?: ChatMessage[];
  currentPage: number;
  totalPages: number;
}

export interface ChatContext {
  /** Mới nhất trước, như một trang thường. */
  items: ChatMessage[];
  hasOlder: boolean;
  /** false = cửa sổ đã chạm đáy trực tiếp, polling được nối lại. */
  hasNewer: boolean;
  anchorId: string;
}

export interface ChatGuide {
  title?: string;
  intro?: string;
  dos?: string[];
  donts?: string[];
  starters?: string[];
}

export interface RoomSuggestion {
  id: string;
  name?: string;
  description?: string;
  status?: 'PENDING' | 'APPROVED' | 'DECLINED';
  voteCount?: number;
  hasVoted?: boolean;
  isMine?: boolean;
  topicId?: string | null;
  /** Tên trùng một đề xuất đang mở: API đổi thành một phiếu ủng hộ. */
  mergedIntoExisting?: boolean;
  createdAt?: string;
}

/** Phòng chat duy nhất app đang mở, gọi bằng slug (`communityDefaultChatRoom`). */
export const DEFAULT_CHAT_ROOM = 'hoi-ban-tron';

/**
 * Lệch múi giờ (phút về phía đông UTC) gửi cho các endpoint phòng.
 *
 * App gửi giờ của máy; máy chủ web không biết giờ của trình duyệt, còn app chỉ
 * phục vụ người đọc tiếng Việt — nên cố định UTC+7 để "N bài hôm nay" đếm theo
 * ngày ở Việt Nam thay vì ngày UTC.
 */
const TZ_OFFSET = 420;

const BASE = '/api/v1/community';
const fresh = { revalidate: 0 } as const;

function query(params: Record<string, string | number | boolean | undefined>) {
  const search = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value !== undefined && value !== '' && value !== false) {
      search.set(key, String(value));
    }
  }
  return search.toString();
}

export function getCommunityFeed(q: FeedQuery = {}): Promise<CommunityFeed> {
  return request<CommunityFeed>(
    `${BASE}/feed?${query({
      page: q.page ?? 1,
      take: q.take ?? 10,
      topicId: q.topicId,
      followedOnly: q.followedOnly,
      sort: q.sort,
      anchorAt: q.anchorAt,
    })}`,
    fresh,
  );
}

/** `data` là null khi tuần này chưa có câu hỏi — trạng thái thật, không phải lỗi. */
export const getWeekly = () =>
  request<WeeklyQuestion | null>(`${BASE}/weekly`, fresh);

export const getPost = (id: string) =>
  request<CommunityPost>(`${BASE}/posts/${encodeURIComponent(id)}`, fresh);

export const getComments = (postId: string, page = 1, take = 10) =>
  request<CommentPage>(
    `${BASE}/posts/${encodeURIComponent(postId)}/comments?page=${page}&take=${take}`,
    fresh,
  );

export const getTopics = () =>
  request<TopicList>(`${BASE}/topics?tzOffset=${TZ_OFFSET}`, fresh);

export const getTopic = (id: string) =>
  request<CommunityTopic>(
    `${BASE}/topics/${encodeURIComponent(id)}?tzOffset=${TZ_OFFSET}`,
    fresh,
  );

export const getMemberStatus = () =>
  request<MemberStatus>(`${BASE}/me/status`, fresh);

export const getUnreadCount = () =>
  request<{ count: number }>(`${BASE}/notifications/unread-count`, fresh).then(
    (data) => data?.count ?? 0,
  );

export const getNotifications = (page = 1, take = 20) =>
  request<NotificationPage>(
    `${BASE}/notifications?page=${page}&take=${take}`,
    fresh,
  );

/**
 * Đầu phòng chat: tên, số người online, số tin chưa đọc.
 *
 * Gọi endpoint này CŨNG là báo "mình đang ở trong phòng" (API ghi nhịp tim),
 * y như nút chat nổi của app — nên chỉ gọi ở nơi app cũng gọi.
 */
export const getChatRoom = (room: string) =>
  request<ChatRoom>(`${BASE}/chat/rooms/${encodeURIComponent(room)}`, fresh);

/** Trang 1 cũng đánh dấu đã đọc tới tin mới nhất — giống mở phòng trên app. */
export const getChatMessages = (room: string, page = 1, take = 30) =>
  request<ChatPage>(
    `${BASE}/chat/rooms/${encodeURIComponent(room)}/messages?page=${page}&take=${take}`,
    fresh,
  );

export const getChatContext = (room: string, messageId: string) =>
  request<ChatContext>(
    `${BASE}/chat/rooms/${encodeURIComponent(room)}/messages/${encodeURIComponent(messageId)}/context`,
    fresh,
  );

/** null khi chưa ai viết nội quy — app ẩn luôn nút thông tin. */
export const getChatGuide = () =>
  request<ChatGuide | null>(`${BASE}/chat/guide`, fresh);

export const getRoomSuggestions = () =>
  request<{ items: RoomSuggestion[] }>(`${BASE}/room-suggestions`, fresh).then(
    (data) => data?.items ?? [],
  );
