import Link from 'next/link';

import { Avatar } from '@/components/community/author';
import { CommentThread } from '@/components/community/comment-thread';
import { daysLeft, formatDate } from '@/components/community/format';
import { Notice } from '@/components/section';
import { describeError } from '@/lib/action-result';
import {
  getComments,
  getMemberStatus,
  getWeekly,
  type MemberStatus,
} from '@/lib/community';

/**
 * Câu hỏi của tuần. Câu trả lời chỉ là bình luận trên bài WEEKLY_QUESTION, nên
 * phần dưới dùng lại nguyên luồng bình luận của trang bài viết — như app.
 */
export default async function CommunityWeeklyPage() {
  const [weekly, status] = await Promise.all([
    getWeekly().catch((error: unknown) =>
      error instanceof Error ? error : new Error(String(error)),
    ),
    getMemberStatus().catch((): MemberStatus => ({ canPost: true })),
  ]);

  const comments =
    weekly && !(weekly instanceof Error)
      ? await getComments(weekly.id, 1, 10).catch(() => null)
      : null;

  return (
    <div className="pt-5">
      <Link
        href="/cong-dong"
        className="text-sm font-semibold text-brand-700 hover:underline"
      >
        ← Cộng đồng
      </Link>
      <h1 className="mt-3 text-2xl font-bold tracking-tight text-brand-900">
        Câu hỏi của tuần
      </h1>

      {weekly instanceof Error ? (
        <div className="mt-4">
          <Notice>Chưa tải được nội dung. {describeError(weekly)}</Notice>
        </div>
      ) : !weekly ? (
        <div className="mt-4 rounded-xl border border-hairline bg-surface p-6 text-center">
          <p className="font-semibold text-brand-900">Tuần này chưa có câu hỏi</p>
          <p className="mt-1 text-sm text-ink-muted">
            Mỗi tuần đội ngũ HDDhistory đặt một câu hỏi mới. Ghé lại sau vài ngày nhé.
          </p>
        </div>
      ) : (
        <>
          <article className="mt-4 rounded-xl border border-brand-200 bg-brand-100/50 p-4">
            <p className="text-xs font-bold tracking-wide text-brand-700 uppercase">
              {weekly.weekNumber ? `Tuần ${weekly.weekNumber}` : 'Tuần này'}
              {weekly.startsAt && weekly.endsAt
                ? ` · ${formatDate(weekly.startsAt)} – ${formatDate(weekly.endsAt)}`
                : ''}
            </p>
            <p className="mt-2 text-lg font-semibold text-brand-900">{weekly.title}</p>
            <p className="mt-1 text-sm text-ink-muted">
              {weekly.note ||
                'Hãy trả lời bằng trải nghiệm của chính bạn và giữ cho nơi này an toàn.'}
            </p>
            <div className="mt-3 flex items-center gap-2 text-xs text-ink-faint">
              <Avatar author={{ authorType: 'OFFICIAL' }} size="sm" />
              <span>Đội ngũ HDDhistory</span>
              <span className="ml-auto">
                {weekly.answerCount ?? 0} người đã trả lời
                {daysLeft(weekly.endsAt) ? (
                  <span suppressHydrationWarning> · còn {daysLeft(weekly.endsAt)} ngày</span>
                ) : null}
              </span>
            </div>
          </article>

          <CommentThread
            postId={weekly.id}
            initial={comments}
            canWrite={status.canPost}
            closedReason={
              status.canPost
                ? undefined
                : status.reason?.trim() ||
                  'Quyền đăng của bạn đang tạm khoá do vi phạm nội quy cộng đồng.'
            }
            placeholder="Trả lời câu hỏi tuần này…"
            emptyTitle="Chưa có câu trả lời"
            emptyBody="Bạn trả lời đầu tiên nhé."
          />
        </>
      )}
    </div>
  );
}
