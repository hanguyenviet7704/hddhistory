'use server';

/**
 * Mọi thao tác ghi của cộng đồng.
 *
 * Gọi từ client component; không bao giờ ném — lỗi trả về thành câu tiếng
 * Việt. Các mã lỗi riêng của cộng đồng (bị khoá, viết quá nhanh, trùng nội
 * dung) được dịch TRƯỚC `describeError`: nó đổi mọi 403 thành "không có
 * quyền" và mọi 429 thành "thao tác quá nhanh", trong khi app nói rõ hơn.
 *
 * Dùng `refresh()` chứ không `revalidatePath`: mọi lần đọc trong
 * `lib/community.ts` đều `revalidate: 0`, nên không có cache dữ liệu nào để
 * xoá — chỉ cần dựng lại trang đang xem. Chỉ thao tác đổi cấu trúc trang
 * (bình luận, xoá bình luận, theo dõi phòng, đề xuất phòng) mới `refresh()`.
 * Đăng bài thì `redirect` sang bài mới, vốn đã là một lần đọc mới.
 *
 * Thả tim, poll chat, tải thêm trang thì không: client đã giữ trạng thái của
 * chúng, và dựng lại cả trang mỗi lần thả tim là phí một vòng render phía máy
 * chủ cho một con số. Ẩn và xoá BÀI cũng không: `refresh()` dựng lại trang
 * hiện tại ngay trong phản hồi, và nếu đó là trang chi tiết của chính bài vừa
 * xoá thì trang 404 loé lên trước khi client kịp đưa người đọc về bảng tin.
 */
import { refresh } from 'next/cache';
import { redirect } from 'next/navigation';

import { describeError, type ActionResult } from '../action-result';
import { ApiError, request } from '../api';
import {
  getChatContext,
  getChatMessages,
  getComments,
  getCommunityFeed,
  getNotifications,
  type ChatContext,
  type ChatMessage,
  type ChatPage,
  type CommentPage,
  type CommunityPost,
  type FeedQuery,
  type NotificationPage,
  type RoomSuggestion,
} from '../community';

type TargetType = 'POST' | 'COMMENT' | 'CHAT_MESSAGE';
type ReactionKind = 'LIKE' | 'SAVE';

const BASE = '/api/v1/community';
const MONGO_ID = /^[a-f0-9]{24}$/i;
const ROOM = /^(?:[a-z0-9]+(?:-[a-z0-9]+)*|[a-f0-9]{24})$/i;
const REASONS = new Set([
  'SPAM',
  'HARASSMENT',
  'ADULT',
  'MISINFORMATION',
  'PRIVACY',
  'OTHER',
]);

/** Mã lỗi ổn định API trả về → câu của app (`community.yaml`). */
function communityError(error: unknown): string {
  if (error instanceof ApiError) {
    switch (error.message) {
      case 'COMMUNITY_MUTED':
        // Lý do và hạn khoá nằm trong `meta`, nhưng `request()` chỉ giữ
        // `message` — trang đã đọc `/me/status` để hiện đủ lý do từ trước.
        return 'Quyền đăng của bạn đang tạm khoá do vi phạm nội quy cộng đồng.';
      case 'COMMUNITY_RATE_LIMITED':
        // `retryAfterSeconds` cũng nằm trong `meta` nên không nói được số giây.
        return 'Bạn viết nhanh quá. Chờ một lát rồi thử lại nhé.';
      case 'COMMUNITY_DUPLICATE_CONTENT':
        return 'Nội dung này bạn vừa gửi rồi. Viết khác đi một chút nhé.';
      case 'COMMUNITY_TOO_MANY_ROOM_SUGGESTIONS':
        return 'Bạn đang có 3 đề xuất chờ xử lý. Đợi tụi mình trả lời rồi gửi thêm nhé.';
      case 'COMMUNITY_ROOM_SUGGESTION_CLOSED':
        return 'Đề xuất này đã được xử lý.';
      case 'Comments are locked on this post':
        return 'Bài này đã đóng bình luận.';
      case 'Topic not available':
        return 'Phòng này hiện không nhận bài mới.';
      case 'Chat room not found':
        return 'Phòng chat này không còn mở.';
    }
  }
  return describeError(error);
}

async function run<T>(fn: () => Promise<T>): Promise<ActionResult<T>> {
  try {
    return { ok: true, data: await fn() };
  } catch (error) {
    return { ok: false, error: communityError(error) };
  }
}

function invalid<T>(message = 'Yêu cầu không hợp lệ.'): ActionResult<T> {
  return { ok: false, error: message };
}

// ------------------------------------------------------------------ bảng tin

export async function loadFeedPage(
  q: FeedQuery,
): Promise<ActionResult<{ items: CommunityPost[]; currentPage: number; totalPages: number }>> {
  if (q.topicId && !MONGO_ID.test(q.topicId)) return invalid();
  return run(async () => {
    const feed = await getCommunityFeed({
      page: Math.max(1, Math.floor(q.page ?? 1)),
      take: 10,
      topicId: q.topicId,
      followedOnly: q.followedOnly,
      sort: q.sort === 'ACTIVE' ? 'ACTIVE' : 'RECENT',
      anchorAt: q.anchorAt,
    });
    return {
      items: feed.items ?? [],
      currentPage: feed.currentPage,
      totalPages: feed.totalPages,
    };
  });
}

export async function setReaction(input: {
  targetType: 'POST' | 'COMMENT';
  targetId: string;
  kind: ReactionKind;
  active: boolean;
}): Promise<ActionResult<{ active: boolean }>> {
  if (!MONGO_ID.test(input.targetId)) return invalid();
  if (input.targetType !== 'POST' && input.targetType !== 'COMMENT') return invalid();
  // Bình luận chỉ có tim; API từ chối SAVE trên bình luận.
  if (input.kind !== 'LIKE' && !(input.kind === 'SAVE' && input.targetType === 'POST')) {
    return invalid();
  }
  return run(() =>
    // DELETE có body: một reaction định danh bằng đích + loại, không có id riêng.
    request<{ active: boolean }>(`${BASE}/reactions`, {
      method: input.active ? 'POST' : 'DELETE',
      body: {
        targetType: input.targetType,
        targetId: input.targetId,
        kind: input.kind,
      },
    }),
  );
}

/** "Ẩn nội dung này" — chỉ ẩn với chính người đọc, không phải kiểm duyệt. */
export async function hideItem(
  targetType: 'POST' | 'COMMENT',
  targetId: string,
): Promise<ActionResult<{ hidden: boolean }>> {
  if (!MONGO_ID.test(targetId)) return invalid();
  if (targetType !== 'POST' && targetType !== 'COMMENT') return invalid();
  const result = await run(() =>
    request<{ hidden: boolean }>(`${BASE}/hidden`, {
      method: 'POST',
      body: { targetType, targetId },
    }),
  );
  return result;
}

export async function reportItem(input: {
  targetType: TargetType;
  targetId: string;
  reason: string;
  note?: string;
}): Promise<ActionResult<{ reported: boolean }>> {
  if (!MONGO_ID.test(input.targetId) || !REASONS.has(input.reason)) return invalid();
  if (!['POST', 'COMMENT', 'CHAT_MESSAGE'].includes(input.targetType)) return invalid();
  const note = input.note?.trim().slice(0, 1000) || undefined;
  return run(() =>
    request<{ reported: boolean }>(`${BASE}/reports`, {
      method: 'POST',
      body: {
        targetType: input.targetType,
        targetId: input.targetId,
        reason: input.reason,
        note,
      },
    }),
  );
}

export async function deletePost(id: string): Promise<ActionResult<{ deleted: boolean }>> {
  if (!MONGO_ID.test(id)) return invalid();
  const result = await run(() =>
    request<{ deleted: boolean }>(`${BASE}/posts/${id}`, { method: 'DELETE' }),
  );
  return result;
}

// ------------------------------------------------------------------ bài viết

export interface CreatePostState {
  error?: string;
}

export async function createPost(
  _prev: CreatePostState | null,
  formData: FormData,
): Promise<CreatePostState> {
  const subject = String(formData.get('subject') ?? '').trim();
  const body = String(formData.get('body') ?? '').trim();
  const topicId = String(formData.get('topicId') ?? '').trim();
  const isAnonymous = formData.get('isAnonymous') === 'on';
  const images = formData
    .getAll('images')
    .map((value) => String(value).trim())
    .filter((url) => /^https:\/\//.test(url));

  if (!body) return { error: 'Viết vài dòng trước khi đăng nhé.' };
  if (body.length > 5000) return { error: 'Bài viết dài quá 5000 ký tự.' };
  if (subject.length > 160) return { error: 'Tiêu đề dài quá 160 ký tự.' };
  if (topicId && !MONGO_ID.test(topicId)) return { error: 'Phòng không hợp lệ.' };
  if (images.length > 4) return { error: 'Mỗi bài tối đa 4 ảnh.' };

  const result = await run(() =>
    request<CommunityPost>(`${BASE}/posts`, {
      method: 'POST',
      body: {
        subject: subject || undefined,
        body,
        topicId: topicId || undefined,
        images: images.length ? images : undefined,
        isAnonymous: isAnonymous || undefined,
      },
    }),
  );
  if (!result.ok) return { error: result.error };

  redirect(`/cong-dong/bai/${encodeURIComponent(result.data.id)}`);
}

/**
 * Tải một ảnh cho bài viết lên R2 qua API, trả về URL để hiển thị.
 *
 * Tự đặt `key` duy nhất: API dùng nguyên `key` làm tên object ở GỐC bucket,
 * nên gửi tên tệp như app (`fileNameFromPath`) thì hai người cùng tải
 * "image.jpg" sẽ ghi đè ảnh của nhau.
 */
export async function uploadCommunityImage(
  formData: FormData,
): Promise<ActionResult<{ url: string }>> {
  const file = formData.get('file');
  if (!(file instanceof File) || file.size === 0) {
    return invalid('Chọn một tệp ảnh.');
  }
  if (!file.type.startsWith('image/')) return invalid('Chỉ đính kèm được ảnh.');

  const ext =
    (file.name.split('.').pop() ?? '').toLowerCase().replace(/[^a-z0-9]/g, '') ||
    'jpg';
  const upload = new FormData();
  upload.append('file', file, file.name);
  upload.append('key', `community/${crypto.randomUUID()}.${ext}`);

  return run(async () => {
    const data = await request<{ url: string }>('/api/v1/cloudflares/upload', {
      method: 'POST',
      body: upload,
    });
    return { url: data.url };
  });
}

// ------------------------------------------------------------------ bình luận

export async function loadComments(
  postId: string,
  page: number,
): Promise<ActionResult<CommentPage>> {
  if (!MONGO_ID.test(postId)) return invalid();
  return run(() => getComments(postId, Math.max(1, Math.floor(page)), 10));
}

/** Trả về trang 1 của luồng — API tự trả đúng thứ đó sau khi tạo. */
export async function addComment(input: {
  postId: string;
  body: string;
  parentId?: string;
  replyToUserId?: string;
}): Promise<ActionResult<CommentPage>> {
  const body = input.body.trim();
  if (!MONGO_ID.test(input.postId)) return invalid();
  if (!body) return invalid('Viết gì đó trước khi gửi nhé.');
  if (body.length > 2000) return invalid('Bình luận dài quá 2000 ký tự.');
  if (input.parentId && !MONGO_ID.test(input.parentId)) return invalid();
  // Người viết ẩn danh không có id — khi đó bỏ "@tên" chứ không gửi rác.
  const replyToUserId =
    input.replyToUserId && MONGO_ID.test(input.replyToUserId)
      ? input.replyToUserId
      : undefined;

  const result = await run(() =>
    request<CommentPage>(`${BASE}/posts/${input.postId}/comments`, {
      method: 'POST',
      body: { body, parentId: input.parentId, replyToUserId },
    }),
  );
  if (result.ok) refresh();
  return result;
}

export async function deleteComment(id: string): Promise<ActionResult<{ deleted: boolean }>> {
  if (!MONGO_ID.test(id)) return invalid();
  const result = await run(() =>
    request<{ deleted: boolean }>(`${BASE}/comments/${id}`, { method: 'DELETE' }),
  );
  if (result.ok) refresh();
  return result;
}

// ------------------------------------------------------------------ phòng

export async function setTopicFollow(
  topicId: string,
  follow: boolean,
): Promise<ActionResult<{ isFollowing: boolean }>> {
  if (!MONGO_ID.test(topicId)) return invalid();
  const result = await run(() =>
    request<{ isFollowing: boolean }>(`${BASE}/topics/${topicId}/follow`, {
      method: follow ? 'POST' : 'DELETE',
    }),
  );
  if (result.ok) refresh();
  return result;
}

export interface SuggestionState {
  error?: string;
  success?: string;
}

export async function createRoomSuggestion(
  _prev: SuggestionState | null,
  formData: FormData,
): Promise<SuggestionState> {
  const name = String(formData.get('name') ?? '').trim();
  const description = String(formData.get('description') ?? '').trim();
  if (!name) return { error: 'Đặt tên cho phòng bạn muốn mở.' };
  if (name.length > 40) return { error: 'Tên phòng tối đa 40 ký tự.' };
  if (description.length > 160) return { error: 'Mô tả tối đa 160 ký tự.' };

  const result = await run(() =>
    request<RoomSuggestion>(`${BASE}/room-suggestions`, {
      method: 'POST',
      body: { name, description: description || undefined },
    }),
  );
  if (!result.ok) return { error: result.error };

  refresh();
  return {
    success: result.data.mergedIntoExisting
      ? 'Có người đã đề xuất phòng này rồi — đã tính bạn là một người ủng hộ.'
      : 'Đã gửi đề xuất. Tụi mình sẽ xem sớm.',
  };
}

export async function voteRoomSuggestion(id: string): Promise<ActionResult<RoomSuggestion>> {
  if (!MONGO_ID.test(id)) return invalid();
  return run(() =>
    request<RoomSuggestion>(`${BASE}/room-suggestions/${id}/vote`, {
      method: 'POST',
    }),
  );
}

// ------------------------------------------------------------------ thông báo

export async function loadNotifications(page: number): Promise<ActionResult<NotificationPage>> {
  return run(() => getNotifications(Math.max(1, Math.floor(page)), 20));
}

/** Không gửi `ids` = đánh dấu mọi thông báo chưa đọc — đúng như app khi mở hộp thư. */
export async function markAllNotificationsRead(): Promise<ActionResult<{ unreadCount: number }>> {
  return run(() =>
    request<{ unreadCount: number }>(`${BASE}/notifications/read`, {
      method: 'POST',
      body: {},
    }),
  );
}

// ------------------------------------------------------------------ chat

/** Một nhịp poll: trang mới nhất kèm danh sách ghim, client tự gộp theo id. */
export async function pollChat(room: string): Promise<ActionResult<ChatPage>> {
  if (!ROOM.test(room)) return invalid();
  return run(() => getChatMessages(room, 1, 30));
}

export async function loadOlderChat(
  room: string,
  page: number,
): Promise<ActionResult<ChatPage>> {
  if (!ROOM.test(room)) return invalid();
  return run(() => getChatMessages(room, Math.max(2, Math.floor(page)), 30));
}

export async function loadChatContext(
  room: string,
  messageId: string,
): Promise<ActionResult<ChatContext>> {
  if (!ROOM.test(room) || !MONGO_ID.test(messageId)) return invalid();
  return run(() => getChatContext(room, messageId));
}

export async function sendChatMessage(input: {
  room: string;
  body: string;
  replyToId?: string;
}): Promise<ActionResult<ChatMessage>> {
  const body = input.body.trim();
  if (!ROOM.test(input.room)) return invalid();
  if (!body) return invalid('Nhắn gì đó trước khi gửi nhé.');
  if (body.length > 1000) return invalid('Tin nhắn dài quá 1000 ký tự.');
  if (input.replyToId && !MONGO_ID.test(input.replyToId)) return invalid();
  return run(() =>
    request<ChatMessage>(
      `${BASE}/chat/rooms/${encodeURIComponent(input.room)}/messages`,
      { method: 'POST', body: { body, replyToId: input.replyToId } },
    ),
  );
}

/** Bật/tắt tim — API tự đảo trạng thái và trả về con số thật. */
export async function toggleChatLike(
  messageId: string,
): Promise<ActionResult<{ isLiked: boolean; likeCount: number }>> {
  if (!MONGO_ID.test(messageId)) return invalid();
  return run(() =>
    request<{ isLiked: boolean; likeCount: number }>(
      `${BASE}/chat/messages/${messageId}/like`,
      { method: 'POST' },
    ),
  );
}
