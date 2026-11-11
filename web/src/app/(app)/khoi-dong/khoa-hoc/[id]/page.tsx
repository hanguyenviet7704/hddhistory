import Link from 'next/link';

import { CourseWarmUpFlow } from '@/components/practice/course-warm-up-flow';
import { Notice } from '@/components/section';
import { buttonClass } from '@/components/ui-classes';
import { getCourse, text } from '@/lib/content';
import { getCourseWarmUp, type CourseWarmUp } from '@/lib/practice';
import { filterUsableWarmUpQuestions } from '@/lib/practice-scoring';

export default async function CourseWarmUpPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  const [warmUp, course] = await Promise.all([
    getCourseWarmUp(id).catch((): CourseWarmUp | null => null),
    getCourse(id).catch(() => null),
  ]);

  // `WarmUpForCourseEntity.hasWarmUpAvailable`: đến hạn VÀ có câu vẽ được.
  const questions =
    warmUp?.isDue && warmUp.previousLesson
      ? filterUsableWarmUpQuestions(warmUp.previousLesson.questions)
      : [];

  return (
    <div className="pt-5">
      <p className="text-sm text-ink-faint">
        <Link href={`/khoa-hoc/${id}`} className="hover:underline">
          {text(course?.title) || 'Khoá học'}
        </Link>
      </p>
      <h1 className="text-2xl font-bold tracking-tight text-brand-900">Khởi động</h1>
      <div className="mt-4">
        {warmUp === null ? (
          <Notice>Không tải được bài khởi động của khoá học này.</Notice>
        ) : questions.length === 0 ? (
          <div className="space-y-3">
            <Notice>Chưa cần khởi động — bạn có thể vào bài học luôn.</Notice>
            <Link href={`/khoa-hoc/${id}`} className={buttonClass.primary}>
              Bắt đầu bài học hôm nay
            </Link>
          </div>
        ) : (
          <CourseWarmUpFlow
            courseId={id}
            lessonTitle={text(warmUp.previousLesson?.title)}
            questions={questions}
          />
        )}
      </div>
    </div>
  );
}
