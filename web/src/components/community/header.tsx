import Link from 'next/link';

import { buttonClass } from '@/components/ui-classes';
import type { WeeklyQuestion } from '@/lib/community';

import { daysLeft } from './format';

/** Nút "Viết bài", hoặc nút khoá khi bị cấm đăng — lý do nằm ở banner. */
export function ComposeLink({
  canPost,
  topicId,
}: {
  canPost: boolean;
  topicId?: string;
}) {
  if (!canPost) {
    return (
      <span
        aria-disabled
        title="Hiện bạn chưa thể đăng bài"
        className={`${buttonClass.primary} cursor-not-allowed px-3 py-2 text-sm opacity-60`}
      >
        Viết bài
      </span>
    );
  }
  const href = topicId
    ? `/cong-dong/viet?phong=${encodeURIComponent(topicId)}`
    : '/cong-dong/viet';
  return (
    <Link href={href} className={`${buttonClass.primary} px-3 py-2 text-sm`}>
      Viết bài
    </Link>
  );
}

/** Chuông thông báo kèm số chưa đọc — chấm đỏ ở đầu tab của app. */
export function NotificationBell({ unread }: { unread: number }) {
  return (
    <Link
      href="/cong-dong/thong-bao"
      aria-label={
        unread > 0 ? `Thông báo, ${unread} chưa đọc` : 'Thông báo'
      }
      className="relative flex size-10 items-center justify-center rounded-full text-brand-900 hover:bg-brand-100"
    >
      <svg viewBox="0 0 24 24" className="size-5" aria-hidden fill="none" stroke="currentColor" strokeWidth="2">
        <path d="M6 16V11a6 6 0 1 1 12 0v5l1.5 2h-15L6 16Z" strokeLinejoin="round" />
        <path d="M10 20a2 2 0 0 0 4 0" />
      </svg>
      {unread > 0 ? (
        <span
          aria-hidden
          className="absolute top-0.5 right-0.5 flex min-w-4 items-center justify-center rounded-full bg-red-700 px-1 text-[10px] leading-4 font-bold text-white"
        >
          {unread > 99 ? '99+' : unread}
        </span>
      ) : null}
    </Link>
  );
}

/** Thẻ "Câu hỏi của tuần" trên đầu bảng tin. */
export function WeeklyCard({ weekly }: { weekly: WeeklyQuestion }) {
  const left = daysLeft(weekly.endsAt);
  return (
    <Link
      href="/cong-dong/tuan"
      className="block rounded-xl border border-brand-200 bg-brand-100/50 p-4 transition hover:bg-brand-100"
    >
      <p className="text-xs font-bold tracking-wide text-brand-700 uppercase">
        Câu hỏi của tuần
        {weekly.weekNumber ? ` · Tuần ${weekly.weekNumber}` : ''}
      </p>
      <p className="mt-1 font-semibold text-brand-900">{weekly.title}</p>
      {weekly.note ? (
        <p className="mt-1 text-sm text-ink-muted">{weekly.note}</p>
      ) : null}
      <p className="mt-2 flex flex-wrap items-center gap-x-2 text-xs text-ink-faint">
        <span>{weekly.answerCount ?? 0} người đã trả lời</span>
        {left ? <span suppressHydrationWarning>· còn {left} ngày</span> : null}
        <span className="ml-auto font-semibold text-brand-700">Vào bàn luận →</span>
      </p>
    </Link>
  );
}
