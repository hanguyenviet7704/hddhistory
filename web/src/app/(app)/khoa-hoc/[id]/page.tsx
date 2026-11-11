import Link from 'next/link';
import { notFound } from 'next/navigation';

import { Badges } from '@/components/learning/badges';
import {
  ProgressMark,
  progressLabel,
} from '@/components/learning/progress-mark';
import { RecordCourseView } from '@/components/learning/record-course-view';
import { SaveCourseButton } from '@/components/learning/save-course-button';
import { Notice, SectionHeader } from '@/components/section';
import { buttonClass } from '@/components/ui-classes';
import { getCourseWarmUp } from '@/lib/practice';
import { filterUsableWarmUpQuestions } from '@/lib/practice-scoring';
import { ApiError } from '@/lib/api';
import {
  getBadgeProgress,
  getCourse,
  getCourseLessons,
  getRoadmap,
  getSavedCourseIds,
  keypointHref,
  nextUnfinished,
  roadmapStops,
  text,
  type BadgeProgress,
  type Lesson,
  type RoadmapLesson,
  type RoadmapLevel,
} from '@/lib/content';

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

  // Lộ trình (kèm trạng thái học), huy hiệu và dấu trang là ba phần độc lập:
  // hỏng phần nào thì phần đó tự rút lui, phần đầu khoá học vẫn hiện.
  const [roadmap, badges, savedIds, warmUp] = await Promise.all([
    getRoadmap(id).catch(() => null),
    getBadgeProgress(id).catch(() => [] as BadgeProgress[]),
    getSavedCourseIds().catch(() => null),
    getCourseWarmUp(id).catch(() => null),
  ]);
  // Như app: tới hạn khởi động thì nút chính là "Khởi động ngay" — ôn lại bài
  // trước rồi mới học tiếp. Chỉ khi có câu làm được trên web.
  const warmUpDue =
    warmUp?.isDue === true &&
    filterUsableWarmUpQuestions(warmUp.previousLesson?.questions ?? []).length >
      0;

  const stops = roadmapStops(roadmap);
  const hasRoadmap = stops.length > 0;
  // Không có lộ trình (khoá cũ, hoặc API lỗi) thì quay về danh sách bài phẳng
  // như trước — vẫn học được, chỉ không có trạng thái.
  const lessons = hasRoadmap
    ? null
    : await getCourseLessons(id).then(
        (page) => page.items,
        () => null,
      );

  const doneCount = stops.filter((s) => s.keypoint.progess === 'done').length;
  const next = nextUnfinished(stops);
  const started = stops.some(
    (s) => s.keypoint.progess && s.keypoint.progess !== 'not_started',
  );
  const description =
    text(roadmap?.courseDescription) || text(course.description);

  return (
    <article className="pt-5">
      <RecordCourseView courseId={id} />

      <Link
        href="/kham-pha"
        className="text-sm font-semibold text-brand-700 hover:underline"
      >
        ← Khám phá
      </Link>

      <header className="mt-3 flex flex-wrap items-start gap-4">
        {course.image ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={course.image}
            alt=""
            className="size-20 shrink-0 rounded-xl border border-hairline object-cover"
          />
        ) : null}
        <div className="min-w-0 flex-1">
          <h1 className="text-2xl font-bold tracking-tight text-brand-900">
            {text(course.title) || 'Khoá học'}
          </h1>
          <p className="mt-1 text-sm text-ink-faint">
            {course.numberOfLesson ?? lessons?.length ?? 0} bài học
            {course.author ? ` · ${course.author}` : ''}
          </p>
        </div>
        {savedIds ? (
          <SaveCourseButton courseId={id} saved={savedIds.includes(id)} />
        ) : null}
      </header>

      {description ? (
        <p className="mt-3 leading-relaxed text-ink">{description}</p>
      ) : null}

      {hasRoadmap ? (
        <div className="mt-5 rounded-xl border border-hairline bg-surface p-4">
          <CourseProgress done={doneCount} total={stops.length} />
          {next && warmUpDue ? (
            <Link
              href={`/khoi-dong/khoa-hoc/${encodeURIComponent(id)}`}
              className={`${buttonClass.primary} mt-4 w-full`}
            >
              Khởi động ngay
              <span className="font-normal opacity-90">
                · ôn lại bài trước
              </span>
            </Link>
          ) : next ? (
            <Link
              href={keypointHref(next.keypoint._id, next.lesson._id)}
              className={`${buttonClass.primary} mt-4 w-full`}
            >
              {started ? 'Tiếp tục học' : 'Bắt đầu học'}
              <span className="font-normal opacity-90">
                · {text(next.keypoint.title) || text(next.lesson.title)}
              </span>
            </Link>
          ) : (
            <p className="mt-3 font-semibold text-emerald-700">
              Bạn đã hoàn thành khoá học này.
            </p>
          )}
        </div>
      ) : null}

      <Badges badges={badges} />

      <SectionHeader title="Lộ trình" />
      {hasRoadmap ? (
        <RoadmapView levels={roadmap?.levels ?? []} />
      ) : lessons === null ? (
        <Notice>Không tải được danh sách bài học.</Notice>
      ) : lessons.length === 0 ? (
        <Notice>Khoá học này chưa có lộ trình.</Notice>
      ) : (
        <ol className="divide-y divide-hairline rounded-xl border border-hairline bg-surface">
          {lessons.map((lesson, index) => (
            <PlainLessonRow
              key={lesson._id}
              lesson={lesson}
              order={index + 1}
            />
          ))}
        </ol>
      )}
    </article>
  );
}

function CourseProgress({ done, total }: { done: number; total: number }) {
  const percent = total ? Math.round((done / total) * 100) : 0;
  return (
    <div>
      <div className="flex items-baseline justify-between text-sm">
        <span className="font-semibold text-ink">Tiến độ</span>
        <span className="text-ink-muted">
          {done}/{total} phần · {percent}%
        </span>
      </div>
      <div
        className="mt-2 h-2 overflow-hidden rounded-full bg-brand-100"
        role="progressbar"
        aria-label="Tiến độ khoá học"
        aria-valuenow={percent}
        aria-valuemin={0}
        aria-valuemax={100}
      >
        <div
          className="h-full rounded-full bg-brand"
          style={{ width: `${percent}%` }}
        />
      </div>
    </div>
  );
}

function RoadmapView({ levels }: { levels: RoadmapLevel[] }) {
  // Đánh số bài liên tục qua các cấp độ — tính trước rồi mới vẽ, vì đếm dồn
  // trong lúc render là thứ React Compiler cấm.
  const numbered = levels.map((level) =>
    (level.nodes ?? []).flatMap((node, nodeIndex) =>
      (node.lessons ?? []).map((lesson) => ({
        key: `${node.id ?? nodeIndex}-${lesson._id}`,
        lesson,
      })),
    ),
  );
  const offsets = numbered.map((_, index) =>
    numbered.slice(0, index).reduce((sum, rows) => sum + rows.length, 0),
  );

  return (
    <div className="space-y-5">
      {levels.map((level, levelIndex) => (
        <section key={level.id ?? levelIndex}>
          {levels.length > 1 ? (
            <h3 className="mb-2 font-semibold text-brand-900">
              Cấp độ {levelIndex + 1}
              {text(level.titleBadge) ? ` · ${text(level.titleBadge)}` : ''}
            </h3>
          ) : null}
          <ol className="divide-y divide-hairline rounded-xl border border-hairline bg-surface">
            {numbered[levelIndex].map((row, rowIndex) => (
              <RoadmapLessonRow
                key={row.key}
                lesson={row.lesson}
                order={offsets[levelIndex] + rowIndex + 1}
              />
            ))}
          </ol>
        </section>
      ))}
    </div>
  );
}

/**
 * Một bài trong lộ trình. Bài chỉ có một keypoint thì mở thẳng trình đọc —
 * giống nút Bắt đầu trên lộ trình của app — thay vì bắt đi qua một trang bài
 * học chỉ có đúng một dòng.
 */
function RoadmapLessonRow({
  lesson,
  order,
}: {
  lesson: RoadmapLesson;
  order: number;
}) {
  const keypoints = lesson.keypoints ?? [];
  const readable = !lesson.type || lesson.type === 'lesson';
  const title = text(lesson.title) || `Bài ${order}`;

  const body = (
    <>
      <ProgressMark state={lesson.progess} order={order} />
      <span className="min-w-0 flex-1">
        <span className="block font-semibold text-ink">{title}</span>
        {text(lesson.description) ? (
          <span className="mt-0.5 block line-clamp-2 text-sm text-ink-muted">
            {text(lesson.description)}
          </span>
        ) : null}
        <span className="mt-1 block text-xs text-ink-faint">
          {readable
            ? `${progressLabel(lesson.progess)}${
                keypoints.length > 1 ? ` · ${keypoints.length} phần` : ''
              }`
            : 'Chỉ có trên ứng dụng di động'}
        </span>
      </span>
    </>
  );

  if (!readable) {
    return <li className="flex gap-3 px-4 py-3 opacity-70">{body}</li>;
  }

  const href =
    keypoints.length === 1
      ? keypointHref(keypoints[0]._id, lesson._id)
      : `/bai-hoc/${encodeURIComponent(lesson._id)}`;

  return (
    <li>
      <Link
        href={href}
        className="flex gap-3 px-4 py-3 transition hover:bg-brand-50 focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-brand"
      >
        {body}
      </Link>
    </li>
  );
}

function PlainLessonRow({ lesson, order }: { lesson: Lesson; order: number }) {
  return (
    <li>
      <Link
        href={`/bai-hoc/${encodeURIComponent(lesson._id)}`}
        className="flex gap-3 px-4 py-3 transition hover:bg-brand-50"
      >
        <ProgressMark order={order} />
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
