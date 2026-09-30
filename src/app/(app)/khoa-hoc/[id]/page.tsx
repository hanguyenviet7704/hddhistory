import Link from 'next/link';
import { notFound } from 'next/navigation';

import { Notice, SectionHeader } from '@/components/section';
import { ApiError } from '@/lib/api';
import { getCourse, getCourseLessons, text, type Lesson } from '@/lib/content';

export default async function CoursePage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  let course;
  try {
    course = await getCourse(id);
  } catch (error) {
    if (error instanceof ApiError && error.status === 404) notFound();
    throw error;
  }

  // Danh sách bài học là phần phụ: hỏng thì vẫn cho xem phần đầu khoá học.
  const lessons = await getCourseLessons(id).then(
    (page) => page.items,
    () => null,
  );

  const total = course.numberOfLesson ?? lessons?.length ?? 0;
  const done = course.numberOfLessonPassed ?? 0;

  return (
    <article className="pt-5">
      <Link
        href="/kham-pha"
        className="text-sm font-semibold text-brand-700 hover:underline"
      >
        ← Khám phá
      </Link>

      <h1 className="mt-3 text-2xl font-bold tracking-tight text-brand-900">
        {text(course.title) || 'Khoá học'}
      </h1>
      <p className="mt-1 text-sm text-ink-faint">
        {total} bài học
        {done ? ` · đã xong ${done}` : ''}
        {course.author ? ` · ${course.author}` : ''}
      </p>
      {text(course.description) ? (
        <p className="mt-3 leading-relaxed text-ink">
          {text(course.description)}
        </p>
      ) : null}

      <SectionHeader title="Lộ trình" />
      {lessons === null ? (
        <Notice>Không tải được danh sách bài học.</Notice>
      ) : lessons.length === 0 ? (
        <Notice>Khoá học này chưa có bài học nào.</Notice>
      ) : (
        <ol className="divide-y divide-hairline rounded-xl border border-hairline bg-surface">
          {lessons.map((lesson, index) => (
            <LessonRow key={lesson._id} lesson={lesson} order={index + 1} />
          ))}
        </ol>
      )}
    </article>
  );
}

function LessonRow({ lesson, order }: { lesson: Lesson; order: number }) {
  return (
    <li>
      <Link
        href={`/bai-hoc/${encodeURIComponent(lesson._id)}`}
        className="flex gap-3 px-4 py-3 transition hover:bg-brand-50"
      >
        <span className="mt-0.5 flex size-6 shrink-0 items-center justify-center rounded-full bg-brand-100 text-xs font-bold text-brand-700">
          {order}
        </span>
        <span className="min-w-0 flex-1">
          <span className="block font-semibold text-ink">
            {text(lesson.title) || `Bài ${order}`}
          </span>
          {text(lesson.description) ? (
            <span className="mt-0.5 block line-clamp-2 text-sm text-ink-muted">
              {text(lesson.description)}
            </span>
          ) : null}
        </span>
      </Link>
    </li>
  );
}
