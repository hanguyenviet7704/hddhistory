import Link from 'next/link';
import { notFound } from 'next/navigation';

import { Badges } from '@/components/learning/badges';
import { StreakStrip } from '@/components/learning/streak-strip';
import { Notice, SectionHeader } from '@/components/section';
import { buttonClass } from '@/components/ui-classes';
import { ApiError } from '@/lib/api';
import {
  getBadgeProgress,
  getLesson,
  getRoadmap,
  keypointHref,
  roadmapStops,
  stopNeighbours,
  text,
  type BadgeProgress,
  type RoadmapStop,
} from '@/lib/content';
import { getKeypoint } from '@/lib/learning';
import { getStreak } from '@/lib/progress';

/**
 * Màn hoàn thành một keypoint — tương ứng `KeypointCompleteRoute` của app:
 * chuỗi ngày vừa được tính, huy hiệu khoá đã tiến tới đâu, và lối đi tiếp
 * (phần kế trong bài → bài kế trong lộ trình → về lộ trình khi đã hết).
 */
export default async function KeypointCompletePage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ bai?: string }>;
}) {
  const { id } = await params;
  const { bai: lessonId } = await searchParams;

  let keypoint;
  try {
    keypoint = await getKeypoint(id);
  } catch (error) {
    if (error instanceof ApiError && error.status === 404) notFound();
    throw error;
  }

  const [lesson, streak] = await Promise.all([
    lessonId ? getLesson(lessonId).catch(() => null) : Promise.resolve(null),
    getStreak().catch(() => null),
  ]);
  const courseId = lesson?.courseId;

  const [roadmap, badges] = courseId
    ? await Promise.all([
        getRoadmap(courseId).catch(() => null),
        getBadgeProgress(courseId).catch(() => [] as BadgeProgress[]),
      ])
    : [null, [] as BadgeProgress[]];

  const stops = roadmapStops(roadmap);
  const { index, next } = stopNeighbours(stops, id);
  // Ưu tiên phần CHƯA xong kế tiếp — người học quay lại ôn một phần cũ thì
  // "tiếp theo" phải là chỗ họ đang dở, không phải phần đã học rồi.
  const upcoming: RoadmapStop | null =
    (index >= 0
      ? stops.slice(index + 1).find((s) => s.keypoint.progess !== 'done')
      : null) ??
    stops.find((s) => s.keypoint.progess !== 'done') ??
    null;
  const courseDone = stops.length > 0 && !upcoming;
  const lessonDone =
    (lesson?.keypoints?.length ?? 0) > 0 &&
    lesson!.keypoints!.every((k) => k.progess === 'done');
  const target = upcoming ?? (courseDone ? null : next);

  return (
    <article className="pt-5">
      <div className="rounded-xl border border-hairline bg-surface p-6 text-center">
        <span
          aria-hidden
          className="mx-auto flex size-14 items-center justify-center rounded-full bg-emerald-600 text-2xl font-bold text-white"
        >
          ✓
        </span>
        <h1 className="mt-3 text-2xl font-bold tracking-tight text-brand-900">
          {courseDone
            ? 'Hoàn thành khoá học!'
            : lessonDone
              ? 'Hoàn thành bài học!'
              : 'Hoàn thành phần học!'}
        </h1>
        <p className="mt-1 text-ink-muted">{text(keypoint.title)}</p>

        <div className="mt-5 flex flex-col gap-2 sm:flex-row sm:justify-center">
          {target ? (
            <Link
              href={keypointHref(target.keypoint._id, target.lesson._id)}
              className={buttonClass.primary}
            >
              {target.lesson._id === lessonId
                ? 'Sang phần tiếp theo'
                : 'Sang bài tiếp theo'}
            </Link>
          ) : null}
          {courseId ? (
            <Link
              href={`/khoa-hoc/${encodeURIComponent(courseId)}`}
              className={target ? buttonClass.secondary : buttonClass.primary}
            >
              Quay lại lộ trình
            </Link>
          ) : (
            <Link href="/" className={buttonClass.secondary}>
              Về trang chủ
            </Link>
          )}
          {courseDone ? (
            <Link href="/kham-pha" className={buttonClass.secondary}>
              Khám phá khoá học khác
            </Link>
          ) : null}
        </div>
        {target ? (
          <p className="mt-3 text-sm text-ink-faint">
            Tiếp theo:{' '}
            {text(target.keypoint.title) || text(target.lesson.title)}
          </p>
        ) : null}
      </div>

      <SectionHeader title="Chuỗi ngày" />
      {streak ? (
        <>
          <StreakStrip streak={streak} />
          {streak.currentStreak > 0 ? (
            <p
              role="status"
              className="mt-2 text-sm font-semibold text-emerald-700"
            >
              Hôm nay bạn đã có mặt!
            </p>
          ) : null}
        </>
      ) : (
        <Notice>Không tải được chuỗi ngày học.</Notice>
      )}

      <Badges badges={badges} title="Huy hiệu khoá học" />
    </article>
  );
}
