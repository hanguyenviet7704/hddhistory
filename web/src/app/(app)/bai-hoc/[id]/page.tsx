import Link from 'next/link';
import { notFound } from 'next/navigation';

import {
  ProgressMark,
  progressLabel,
} from '@/components/learning/progress-mark';
import { Notice, SectionHeader } from '@/components/section';
import { buttonClass } from '@/components/ui-classes';
import { ApiError } from '@/lib/api';
import {
  getLesson,
  keypointHref,
  text,
  type LessonDetail,
} from '@/lib/content';

export default async function LessonPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  // Bài học tự mang danh sách keypoint kèm trạng thái học của người đang xem,
  // nên một lời gọi là đủ cho cả nội dung lẫn dấu đã xong/chưa xong.
  let lesson: LessonDetail;
  try {
    lesson = await getLesson(id);
  } catch (error) {
    if (error instanceof ApiError && error.status === 404) notFound();
    throw error;
  }

  const keypoints = lesson.keypoints ?? [];
  const done = keypoints.filter((k) => k.progess === 'done').length;
  const next = keypoints.find((k) => k.progess !== 'done');

  return (
    <article className="pt-5">
      {lesson.courseId ? (
        <Link
          href={`/khoa-hoc/${encodeURIComponent(lesson.courseId)}`}
          className="text-sm font-semibold text-brand-700 hover:underline"
        >
          ← Lộ trình khoá học
        </Link>
      ) : null}

      <h1 className="mt-3 text-2xl font-bold tracking-tight text-brand-900">
        {text(lesson.title) || 'Bài học'}
      </h1>
      {keypoints.length > 0 ? (
        <p className="mt-1 text-sm text-ink-faint">
          Đã xong {done}/{keypoints.length} phần
        </p>
      ) : null}
      {text(lesson.description) ? (
        <p className="mt-2 leading-relaxed text-ink">
          {text(lesson.description)}
        </p>
      ) : null}

      {next ? (
        <Link
          href={keypointHref(next._id, id)}
          className={`${buttonClass.primary} mt-4 w-full`}
        >
          {done > 0 ? 'Tiếp tục học' : 'Bắt đầu bài học'}
        </Link>
      ) : keypoints.length > 0 ? (
        <p className="mt-4 font-semibold text-emerald-700">
          Bạn đã học xong bài này.
        </p>
      ) : null}

      <SectionHeader title="Nội dung" />
      {keypoints.length === 0 ? (
        <Notice>Bài học này chưa có nội dung.</Notice>
      ) : (
        <ol className="divide-y divide-hairline rounded-xl border border-hairline bg-surface">
          {keypoints.map((keypoint, index) => (
            <li key={keypoint._id}>
              <Link
                href={keypointHref(keypoint._id, id)}
                className="flex gap-3 px-4 py-3 transition hover:bg-brand-50 focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-brand"
              >
                <ProgressMark state={keypoint.progess} order={index + 1} />
                <span className="min-w-0 flex-1">
                  <span className="block font-semibold text-ink">
                    {text(keypoint.title) || `Phần ${index + 1}`}
                  </span>
                  {text(keypoint.description) ? (
                    <span className="mt-0.5 block text-sm text-ink-muted">
                      {text(keypoint.description)}
                    </span>
                  ) : null}
                  <span className="mt-1 block text-xs text-ink-faint">
                    {progressLabel(keypoint.progess)}
                    {keypoint.estimateCompleTimeNumber
                      ? ` · ~${keypoint.estimateCompleTimeNumber} phút`
                      : ''}
                  </span>
                </span>
              </Link>
            </li>
          ))}
        </ol>
      )}
    </article>
  );
}
