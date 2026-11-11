import Link from 'next/link';

import { AutoRefresh } from '@/components/import/auto-refresh';
import { importErrorText, STAGE_LABEL } from '@/components/import/import-copy';
import { UserLessonCard } from '@/components/import/user-lesson-card';
import { Notice } from '@/components/section';
import { buttonClass } from '@/components/ui-classes';
import { getImportJobs, isJobRunning } from '@/lib/learning-import';
import { getUserLessons, readPercent } from '@/lib/user-lessons';

export default async function MyLessonsPage() {
  const [lessons, jobs] = await Promise.all([
    getUserLessons(1, 50).then(
      (page) => page.items,
      (error: Error) => error,
    ),
    getImportJobs(1, 5).then(
      (page) => page.items,
      () => [],
    ),
  ]);

  // Lượt đang chạy CHƯA có dòng bài trên kệ (API giấu bài nháp tới khi job
  // xong), nên vẽ nó thành một thẻ "đang tạo" riêng — như app.
  const running = jobs.filter(isJobRunning);
  // Lượt mới nhất hỏng thì nói ra một lần ở đầu kệ; lượt hỏng cũ hơn một bài
  // đã tạo thành công sau đó thì thôi, chuyện đã qua.
  const latest = jobs[0];
  const latestFailed =
    latest && (latest.status === 'failed' || latest.status === 'interrupted')
      ? latest
      : null;
  const anyPartial =
    Array.isArray(lessons) && lessons.some((l) => l.contentStatus === 'partial');

  return (
    <div className="pt-5">
      {running.length > 0 || anyPartial ? <AutoRefresh everyMs={8000} /> : null}

      <div className="flex items-start justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-brand-900">
            Bài tôi tạo
          </h1>
          <p className="mt-1 text-sm text-ink-muted">
            Bài bạn tạo từ tài liệu của mình
          </p>
        </div>
        <Link href="/nhap-bai" className={`${buttonClass.primary} shrink-0`}>
          Tạo bài học
        </Link>
      </div>

      {latestFailed ? (
        <div className="mt-5 rounded-xl border border-hairline bg-surface p-4">
          <p className="font-semibold text-brand-900">Chưa tạo xong được</p>
          {latestFailed.sourceLabel ? (
            <p className="mt-0.5 truncate text-xs text-ink-faint">
              {latestFailed.sourceLabel}
            </p>
          ) : null}
          <p role="alert" className="mt-1 text-sm text-red-700">
            {latestFailed.status === 'interrupted'
              ? importErrorText('INTERRUPTED')
              : importErrorText(latestFailed.errorCode)}
          </p>
          <Link
            href="/nhap-bai"
            className="mt-2 inline-block text-sm font-semibold text-brand-700 hover:underline"
          >
            Thử lại
          </Link>
        </div>
      ) : null}

      <ul className="mt-5 space-y-2">
        {running.map((job) => (
          <li key={job.id}>
            <Link
              href={`/nhap-bai/${encodeURIComponent(job.id)}`}
              className="block rounded-xl border border-brand-200 bg-brand-50 p-3 transition hover:bg-brand-100"
            >
              <span className="block truncate font-semibold text-brand-900">
                {job.sourceLabel || 'Đang tạo bài học'}
              </span>
              <span className="mt-0.5 block text-xs text-ink-muted">
                {(job.stage && STAGE_LABEL[job.stage]) || 'Đang tạo bài học'} ·{' '}
                {Math.round(job.percent ?? 0)}%
              </span>
            </Link>
          </li>
        ))}
        {Array.isArray(lessons)
          ? lessons.map((lesson) => (
              <li key={lesson.id}>
                <UserLessonCard lesson={lesson} percent={readPercent(lesson)} />
              </li>
            ))
          : null}
      </ul>

      {lessons instanceof Error ? (
        <Notice>Không tải được danh sách bài. {lessons.message}</Notice>
      ) : lessons.length === 0 && running.length === 0 ? (
        <div className="rounded-xl border border-hairline bg-surface p-5 text-center">
          <p className="font-semibold text-brand-900">Chưa có bài nào</p>
          <p className="mt-1 text-sm text-ink-muted">
            Biến một tệp PDF hoặc video YouTube thành bài học đọc ngay trong app.
          </p>
          <Link href="/nhap-bai" className={`${buttonClass.secondary} mt-3`}>
            Tạo bài học
          </Link>
        </div>
      ) : null}
    </div>
  );
}
