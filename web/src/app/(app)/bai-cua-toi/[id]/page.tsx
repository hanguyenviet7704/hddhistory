import Link from 'next/link';
import { notFound } from 'next/navigation';

import { AutoRefresh } from '@/components/import/auto-refresh';
import {
  AdditionalContentPanel,
  DeleteLessonButton,
} from '@/components/import/lesson-actions';
import { Notice, SectionHeader } from '@/components/section';
import { buttonClass } from '@/components/ui-classes';
import { ApiError } from '@/lib/api';
import {
  getUserLesson,
  readPercent,
  type UserLessonDetail,
} from '@/lib/user-lessons';

export default async function UserLessonRoadmapPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  // Id sai định dạng làm API trả 500 (CastError) thay vì 404.
  if (!/^[0-9a-f]{24}$/i.test(id)) notFound();

  let lesson: UserLessonDetail;
  try {
    lesson = await getUserLesson(id);
  } catch (error) {
    if (error instanceof ApiError && error.status === 404) notFound();
    return (
      <div className="pt-5">
        <Notice>
          Không tải được bài học. {error instanceof Error ? error.message : ''}
        </Notice>
      </div>
    );
  }

  const written = lesson.keypoints ?? [];
  // Dàn ý đã chốt từ lúc tạo: vẽ được cả các keypoint chưa viết thành node
  // "Đang tạo…" thay vì để lộ trình dài dần ra dưới tay người đọc.
  const planned = lesson.plannedKeypointTitles ?? [];
  const total = Math.max(written.length, planned.length);
  const partial = lesson.contentStatus === 'partial';
  const stop = Math.min(lesson.stopAtKeypointIndex ?? 0, Math.max(0, written.length - 1));
  const percent = readPercent(lesson, total);
  const started = percent > 0 || (lesson.stopAtSectionIndex ?? 0) > 0;
  const audioReady = new Set(
    (lesson.audio?.keypoints ?? []).map((audio) => audio.keypointIndex),
  );

  // Như app: 8 giây khi chữ còn đang được viết, 30 giây khi chỉ còn chờ lời
  // đọc; không còn gì để chờ thì thôi.
  const refreshEvery = partial ? 8000 : lesson.audioPending ? 30000 : null;

  return (
    <article className="pt-5">
      {refreshEvery ? <AutoRefresh everyMs={refreshEvery} /> : null}

      <Link
        href="/bai-cua-toi"
        className="text-sm font-semibold text-brand-700 hover:underline"
      >
        ← Bài tôi tạo
      </Link>

      {lesson.coverUrl ? (
        // Ảnh từ CDN của API, tên miền không cố định — <img> thường.
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={lesson.coverUrl}
          alt=""
          className="mt-3 aspect-[2/1] w-full rounded-xl border border-hairline object-cover"
        />
      ) : null}

      <p className="mt-4 text-xs font-bold tracking-wide text-brand-700 uppercase">
        Từ nội dung của bạn
      </p>
      <h1 className="mt-1 text-2xl font-bold tracking-tight text-brand-900">
        {lesson.title || 'Bài học'}
      </h1>
      {lesson.description ? (
        <p className="mt-2 leading-relaxed text-ink">{lesson.description}</p>
      ) : null}
      <p className="mt-2 text-sm text-ink-muted">
        {[
          lesson.sourceLabel
            ? `${lesson.sourceType === 'youtube' ? 'YouTube' : 'PDF'} · ${lesson.sourceLabel}`
            : null,
          lesson.estimatedMinutes ? `${lesson.estimatedMinutes} phút` : null,
        ]
          .filter(Boolean)
          .join(' · ')}
      </p>

      <div className="mt-4 flex flex-wrap items-center gap-3">
        {written.length > 0 ? (
          <Link
            href={`/bai-cua-toi/${encodeURIComponent(id)}/phan/${stop}`}
            className={buttonClass.primary}
          >
            {started ? 'Học tiếp' : 'Bắt đầu học'}
          </Link>
        ) : (
          <span className="text-sm text-ink-muted">Đang tạo…</span>
        )}
        <span className="text-sm text-ink-muted">
          {lesson.completedAt
            ? 'Đã hoàn thành'
            : `${Math.min(stop, total)}/${total} keypoint`}
        </span>
      </div>

      <SectionHeader
        title={`${total} keypoint rút ra từ nội dung bạn vừa đưa vào`}
      />
      <ol className="divide-y divide-hairline rounded-xl border border-hairline bg-surface">
        {Array.from({ length: total }, (_, index) => {
          const keypoint = written[index];
          const title = keypoint?.title || planned[index] || `Phần ${index + 1}`;
          const done = Boolean(lesson.completedAt) || index < stop;
          const current = !lesson.completedAt && index === stop && started;
          const marker = (
            <span
              className={`mt-0.5 flex size-6 shrink-0 items-center justify-center rounded-full text-xs font-bold ${
                done ? 'bg-emerald-100 text-emerald-800' : 'bg-brand-100 text-brand-700'
              }`}
            >
              {index + 1}
            </span>
          );

          if (!keypoint) {
            return (
              <li key={index} className="flex gap-3 px-4 py-3 opacity-70">
                {marker}
                <span className="min-w-0 flex-1">
                  <span className="block font-semibold text-ink">{title}</span>
                  <span className="mt-0.5 block text-xs text-ink-faint">
                    Đang tạo…
                  </span>
                </span>
              </li>
            );
          }

          return (
            <li key={index}>
              <Link
                href={`/bai-cua-toi/${encodeURIComponent(id)}/phan/${index}`}
                aria-current={current ? 'step' : undefined}
                className={`flex gap-3 px-4 py-3 transition hover:bg-brand-50 ${
                  current ? 'bg-brand-50' : ''
                }`}
              >
                {marker}
                <span className="min-w-0 flex-1">
                  <span className="block font-semibold text-ink">{title}</span>
                  <span className="mt-0.5 block text-xs text-ink-faint">
                    {(keypoint.sections ?? []).length} thẻ
                    {done ? ' · Đã đọc' : current ? ' · Đang đọc' : ' · Chưa bắt đầu'}
                    {audioReady.has(index)
                      ? ' · Có giọng đọc'
                      : lesson.audioPending
                        ? ' · Đang tạo giọng đọc…'
                        : ''}
                  </span>
                </span>
              </Link>
            </li>
          );
        })}
      </ol>

      {lesson.completedAt ? (
        <AdditionalContentPanel
          lessonId={id}
          answered={Boolean(lesson.additionalContentRequestedAt)}
        />
      ) : null}

      <div className="mt-8">
        <DeleteLessonButton lessonId={id} />
      </div>
    </article>
  );
}
