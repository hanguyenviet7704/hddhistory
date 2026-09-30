import Link from 'next/link';
import { notFound } from 'next/navigation';

import { Notice, SectionHeader } from '@/components/section';
import { ApiError, request } from '@/lib/api';
import { getKeypoints } from '@/lib/learning';
import { text, type Lesson } from '@/lib/content';

export default async function LessonPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  let lesson: Lesson;
  try {
    lesson = await request<Lesson>(
      `/api/v1/courses-lessons/${encodeURIComponent(id)}`,
    );
  } catch (error) {
    if (error instanceof ApiError && error.status === 404) notFound();
    throw error;
  }

  const keypoints = await getKeypoints(id).then(
    (page) => page.items,
    () => null,
  );

  return (
    <article className="pt-5">
      {lesson.courseId ? (
        <Link
          href={`/khoa-hoc/${encodeURIComponent(lesson.courseId)}`}
          className="text-sm font-semibold text-brand-700 hover:underline"
        >
          ← Khoá học
        </Link>
      ) : null}

      <h1 className="mt-3 text-2xl font-bold tracking-tight text-brand-900">
        {text(lesson.title) || 'Bài học'}
      </h1>
      {text(lesson.description) ? (
        <p className="mt-2 leading-relaxed text-ink">
          {text(lesson.description)}
        </p>
      ) : null}

      <SectionHeader title="Nội dung" />
      {keypoints === null ? (
        <Notice>Không tải được nội dung bài học.</Notice>
      ) : keypoints.length === 0 ? (
        <Notice>Bài học này chưa có nội dung.</Notice>
      ) : (
        <ol className="divide-y divide-hairline rounded-xl border border-hairline bg-surface">
          {keypoints.map((keypoint, index) => (
            <li key={keypoint._id}>
              <Link
                href={`/phan/${encodeURIComponent(keypoint._id)}`}
                className="flex gap-3 px-4 py-3 transition hover:bg-brand-50"
              >
              <span className="mt-0.5 flex size-6 shrink-0 items-center justify-center rounded-full bg-brand-100 text-xs font-bold text-brand-700">
                {index + 1}
              </span>
              <span className="min-w-0 flex-1">
                <span className="block font-semibold text-ink">
                  {text(keypoint.title) || `Phần ${index + 1}`}
                </span>
                {text(keypoint.description) ? (
                  <span className="mt-0.5 block text-sm text-ink-muted">
                    {text(keypoint.description)}
                  </span>
                ) : null}
                {keypoint.estimateCompleTimeNumber ? (
                  <span className="mt-1 block text-xs text-ink-faint">
                    ~{keypoint.estimateCompleTimeNumber} phút
                  </span>
                ) : null}
              </span>
              </Link>
            </li>
          ))}
        </ol>
      )}

      {/* Nói thẳng giới hạn thay vì để người dùng bấm vào một bài tập không
          chạy: phần luyện tập của app cần ghi âm và trình phát riêng. */}
      <p className="mt-4 text-sm text-ink-faint">
        Phần luyện tập (bài tập, nói, đóng vai) hiện chỉ có trên ứng dụng di động.
      </p>
    </article>
  );
}
