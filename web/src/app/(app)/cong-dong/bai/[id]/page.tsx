import Link from 'next/link';
import { notFound } from 'next/navigation';

import { CommentThread } from '@/components/community/comment-thread';
import { PostCard } from '@/components/community/post-card';
import { ApiError } from '@/lib/api';
import {
  getComments,
  getMemberStatus,
  getPost,
  type MemberStatus,
} from '@/lib/community';

export default async function CommunityPostPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  // Id không phải ObjectId thì API ném 500 (CastError) thay vì 404 — chặn ở đây.
  if (!/^[a-f0-9]{24}$/i.test(id)) notFound();

  const [post, comments, status] = await Promise.all([
    getPost(id).catch((error: unknown) => {
      // Bài bị xoá/ẩn/không có: API trả 404 cho cả ba, nên chỉ một trang lỗi.
      if (error instanceof ApiError && error.status === 404) notFound();
      throw error;
    }),
    getComments(id, 1, 10).catch(() => null),
    getMemberStatus().catch((): MemberStatus => ({ canPost: true })),
  ]);

  const closedReason = post.commentsLocked
    ? 'Bài này đã đóng bình luận.'
    : !status.canPost
      ? status.reason?.trim() ||
        'Quyền đăng của bạn đang tạm khoá do vi phạm nội quy cộng đồng.'
      : undefined;

  return (
    <div className="pt-5">
      <Link
        href="/cong-dong"
        className="text-sm font-semibold text-brand-700 hover:underline"
      >
        ← Cộng đồng
      </Link>

      <div className="mt-3">
        <PostCard post={post} variant="detail" />
      </div>

      <CommentThread
        postId={post.id}
        initial={comments}
        canWrite={!closedReason}
        closedReason={closedReason}
        placeholder={
          post.type === 'WEEKLY_QUESTION'
            ? 'Trả lời câu hỏi tuần này…'
            : 'Viết bình luận…'
        }
      />
    </div>
  );
}
