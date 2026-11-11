import Link from 'next/link';
import { notFound } from 'next/navigation';

import { CardDeck } from '@/components/import/card-deck';
import { LessonSectionView, RichText } from '@/components/import/lesson-section';
import { Notice } from '@/components/section';
import { buttonClass } from '@/components/ui-classes';
import { ApiError } from '@/lib/api';
import { getUserLesson, type UserLessonDetail } from '@/lib/user-lessons';

export default async function UserLessonReaderPage({
  params,
}: {
  params: Promise<{ id: string; k: string }>;
}) {
  const { id, k } = await params;
  if (!/^[0-9a-f]{24}$/i.test(id) || !/^\d+$/.test(k)) notFound();
  const keypointIndex = Number(k);

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

  const keypoints = lesson.keypoints ?? [];
  const keypoint = keypoints[keypointIndex];
  if (!keypoint) notFound();

  const roadmapHref = `/bai-cua-toi/${encodeURIComponent(id)}`;
  const sections = keypoint.sections ?? [];
  const takeaway = keypoint.takeaway?.trim() ?? '';

  const cards = sections.map((section, index) => (
    <LessonSectionView key={index} section={section} />
  ));
  // Thẻ tổng kết cuối keypoint — app lật thẻ này sang `takeaway`. Bài cũ không
  // có trường này thì thôi, không bày một thẻ trống.
  if (takeaway) {
    cards.push(
      <div key="takeaway">
        <p className="text-xs font-bold tracking-wide text-brand-700 uppercase">
          Tóm tắt
        </p>
        <p className="mt-2 text-lg leading-relaxed text-ink">
          <RichText source={takeaway} />
        </p>
      </div>,
    );
  }

  const next = keypointIndex + 1;
  const plannedTotal = Math.max(
    keypoints.length,
    lesson.plannedKeypointTitles?.length ?? 0,
  );
  const nextWritten = next < keypoints.length;
  const nextPending = !nextWritten && next < plannedTotal;

  const doneCard = (
    <div className="flex min-h-[14rem] flex-col items-center justify-center text-center">
      <p className="text-lg font-bold text-brand-900">
        Hoàn thành nội dung trọng tâm
      </p>
      <p className="mt-1 text-ink-muted">
        Tuyệt vời — bạn đã học hết nội dung này.
      </p>
      {nextPending ? (
        <p className="mt-3 max-w-sm text-sm text-ink-muted">
          <span className="block font-semibold text-brand-900">
            Phần tiếp theo đang được tạo
          </span>
          Keypoint sau cùng lời đọc đang được hoàn thiện — thường chỉ một lát
          thôi.
        </p>
      ) : null}
      <div className="mt-4 flex flex-wrap justify-center gap-2">
        {nextWritten ? (
          <Link
            href={`${roadmapHref}/phan/${next}`}
            className={buttonClass.primary}
          >
            Sang phần tiếp theo
          </Link>
        ) : null}
        <Link
          href={roadmapHref}
          className={nextWritten ? buttonClass.secondary : buttonClass.primary}
        >
          Về lộ trình
        </Link>
      </div>
    </div>
  );

  const resumeHere = (lesson.stopAtKeypointIndex ?? 0) === keypointIndex;
  const audio = lesson.audio?.keypoints?.find(
    (entry) => entry.keypointIndex === keypointIndex,
  );

  return (
    <article className="pt-5">
      <Link
        href={roadmapHref}
        className="text-sm font-semibold text-brand-700 hover:underline"
      >
        ← {lesson.title || 'Lộ trình'}
      </Link>
      <p className="mt-3 text-xs font-bold tracking-wide text-brand-700 uppercase">
        Keypoint {keypointIndex + 1}/{plannedTotal}
      </p>
      <h1 className="mt-1 text-2xl font-bold tracking-tight text-brand-900">
        {keypoint.title || `Phần ${keypointIndex + 1}`}
      </h1>

      {audio?.url ? (
        <div className="mt-3">
          <p className="mb-1 text-sm text-ink-muted">Nghe</p>
          {/* Một tệp lời đọc cho cả keypoint; web không đồng bộ theo thẻ như app. */}
          <audio controls preload="none" src={audio.url} className="w-full" />
        </div>
      ) : lesson.audioPending ? (
        <p className="mt-3 text-sm text-ink-faint">Đang tạo giọng đọc…</p>
      ) : null}

      {cards.length === 0 ? (
        <div className="mt-4">
          <Notice>Phần này chưa có nội dung.</Notice>
        </div>
      ) : (
        <CardDeck
          key={keypointIndex}
          lessonId={id}
          keypointIndex={keypointIndex}
          sectionCount={sections.length}
          initialIndex={resumeHere ? (lesson.stopAtSectionIndex ?? 0) : 0}
          savedPosition={{
            keypoint: lesson.stopAtKeypointIndex ?? 0,
            section: lesson.stopAtSectionIndex ?? 0,
          }}
          cards={cards}
          doneCard={doneCard}
        />
      )}
    </article>
  );
}
