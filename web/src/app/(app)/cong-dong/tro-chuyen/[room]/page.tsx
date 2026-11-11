import Link from 'next/link';
import { notFound } from 'next/navigation';

import { ChatRoom } from '@/components/community/chat-room';
import { ApiError } from '@/lib/api';
import {
  getChatGuide,
  getChatMessages,
  getChatRoom,
  getMemberStatus,
  type MemberStatus,
} from '@/lib/community';

/**
 * Phòng chat nhóm ("Hội bàn tròn"). App mở phòng bằng slug; API nhận cả slug
 * lẫn ObjectId.
 *
 * App không dùng socket cho phòng này — nó poll REST 6 giây một lần, và web
 * làm đúng như vậy trong `ChatRoom`.
 */
export default async function CommunityChatPage({
  params,
}: {
  params: Promise<{ room: string }>;
}) {
  const { room } = await params;
  if (!/^(?:[a-z0-9]+(?:-[a-z0-9]+)*|[a-f0-9]{24})$/i.test(room)) notFound();

  const [header, messages, guide, status] = await Promise.all([
    getChatRoom(room).catch((error: unknown) => {
      if (error instanceof ApiError && error.status === 404) notFound();
      throw error;
    }),
    // Hỏng trang tin đầu thì vẫn dựng phòng; client poll lại ngay.
    getChatMessages(room, 1, 30).catch(() => null),
    // Nội quy chỉ là phần phụ — null cũng là câu trả lời hợp lệ ("chưa viết").
    getChatGuide().catch(() => null),
    getMemberStatus().catch((): MemberStatus => ({ canPost: true })),
  ]);

  return (
    <div className="pt-5">
      <Link
        href="/cong-dong"
        className="text-sm font-semibold text-brand-700 hover:underline"
      >
        ← Cộng đồng
      </Link>
      <div className="mt-3 mb-3">
        <h1 className="text-2xl font-bold tracking-tight text-brand-900">
          {header.name || 'Hội bàn tròn'}
        </h1>
        <p className="text-sm text-ink-faint">
          {header.onlineCount ?? 0} đang online
        </p>
      </div>
      <ChatRoom
        room={header.slug || room}
        initial={messages}
        guide={guide}
        canSend={status.canPost}
        closedReason={
          status.canPost
            ? undefined
            : status.reason?.trim() ||
              'Quyền đăng của bạn đang tạm khoá do vi phạm nội quy cộng đồng.'
        }
      />
    </div>
  );
}
