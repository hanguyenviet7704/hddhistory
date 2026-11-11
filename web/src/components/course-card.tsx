import Link from 'next/link';

import { text, type Course } from '@/lib/content';

/** Thanh tiến độ, chỉ hiện khi khoá đã bắt đầu. */
function Progress({ done, total }: { done: number; total: number }) {
  if (!total || !done) return null;
  const percent = Math.min(100, Math.round((done / total) * 100));
  return (
    <div className="mt-2">
      <div
        className="h-1.5 overflow-hidden rounded-full bg-brand-100"
        role="progressbar"
        aria-valuenow={percent}
        aria-valuemin={0}
        aria-valuemax={100}
        aria-label="Tiến độ khoá học"
      >
        <div
          className="h-full rounded-full bg-brand"
          style={{ width: `${percent}%` }}
        />
      </div>
      <p className="mt-1 text-xs text-ink-faint">
        {done}/{total} bài học
      </p>
    </div>
  );
}

export function CourseCard({ course }: { course: Course }) {
  const title = text(course.title);
  const total = course.numberOfLesson ?? 0;
  const done = course.numberOfLessonPassed ?? 0;

  return (
    <Link
      href={`/khoa-hoc/${encodeURIComponent(course._id)}`}
      className="flex gap-3 rounded-xl border border-hairline bg-surface p-4 transition hover:border-brand-200 hover:shadow-sm focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand"
    >
      {course.image ? (
        // Ảnh từ CDN của API (và Wikimedia), tên miền không cố định.
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={course.image}
          alt=""
          loading="lazy"
          className="size-16 shrink-0 rounded-lg bg-surface-alt object-cover"
        />
      ) : null}
      <div className="min-w-0 flex-1">
        <h3 className="font-semibold text-ink">{title || 'Khoá học'}</h3>
        {text(course.description) ? (
          <p className="mt-1 line-clamp-2 text-sm text-ink-muted">
            {text(course.description)}
          </p>
        ) : null}
        <p className="mt-2 text-xs text-ink-faint">
          {total > 0 ? `${total} bài học` : 'Chưa có bài học'}
          {course.author ? ` · ${course.author}` : ''}
        </p>
        <Progress done={done} total={total} />
      </div>
    </Link>
  );
}

export function CourseGrid({ courses }: { courses: Course[] }) {
  return (
    <div className="grid gap-3 sm:grid-cols-2">
      {courses.map((course) => (
        <CourseCard key={course._id} course={course} />
      ))}
    </div>
  );
}
