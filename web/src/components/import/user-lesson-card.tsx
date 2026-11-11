import Link from 'next/link';

import type { UserLessonSummary } from '@/lib/user-lessons';

/**
 * Một bài tự tạo trên kệ: bìa, tên, nguồn, và người đọc đang ở đâu.
 *
 * Không `server-only` và không gọi API — trang Thư viện dùng lại được.
 * `percent` tính sẵn ở trang (xem `readPercent`) vì danh sách không có thân bài.
 */
export function UserLessonCard({
  lesson,
  percent,
}: {
  lesson: UserLessonSummary;
  percent: number;
}) {
  const partial = lesson.contentStatus === 'partial';
  const status = partial
    ? 'Đang tạo…'
    : lesson.completedAt
      ? 'Đã hoàn thành'
      : percent > 0
        ? `Hoàn thành ${percent}%`
        : 'Chưa bắt đầu';

  return (
    <Link
      href={`/bai-cua-toi/${encodeURIComponent(lesson.id)}`}
      className="flex gap-3 rounded-xl border border-hairline bg-surface p-3 transition hover:bg-brand-50"
    >
      {lesson.coverUrl ? (
        // Ảnh từ CDN của API, tên miền không cố định — <img> thường.
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={lesson.coverUrl}
          alt=""
          className="size-16 shrink-0 rounded-lg border border-hairline object-cover"
        />
      ) : (
        <span
          aria-hidden
          className="flex size-16 shrink-0 items-center justify-center rounded-lg bg-brand-100 text-xs font-bold text-brand-700 uppercase"
        >
          {lesson.sourceType === 'youtube' ? 'Video' : 'PDF'}
        </span>
      )}
      <span className="min-w-0 flex-1">
        <span className="line-clamp-2 block font-semibold text-ink">
          {lesson.title || 'Bài học'}
        </span>
        {lesson.sourceLabel ? (
          <span className="mt-0.5 block truncate text-xs text-ink-faint">
            {lesson.sourceType === 'youtube' ? 'YouTube' : 'PDF'} · {lesson.sourceLabel}
          </span>
        ) : null}
        <span className="mt-1 flex flex-wrap gap-x-3 text-xs text-ink-muted">
          <span className={lesson.completedAt ? 'font-semibold text-emerald-700' : ''}>
            {status}
          </span>
          {lesson.estimatedMinutes ? <span>{lesson.estimatedMinutes} phút</span> : null}
        </span>
      </span>
    </Link>
  );
}
