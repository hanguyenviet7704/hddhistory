'use client';

/**
 * Thử thách khởi động hằng ngày — `DailyWarmUpPage` của app: màn mời →
 * các câu → màn hoàn thành gợi ý khoá học. Không ghi tiến độ (app cũng không).
 */
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

import { buttonClass } from '@/components/ui-classes';
import type { Question } from '@/lib/practice';

import { WarmUpSession } from './warm-up-session';

export interface SuggestedCourse {
  id: string;
  title: string;
  image?: string;
}

export function DailyWarmUpFlow({
  questions,
  course,
  isCourseCompleted,
}: {
  questions: Question[];
  course: SuggestedCourse | null;
  isCourseCompleted: boolean;
}) {
  const router = useRouter();
  const [phase, setPhase] = useState<'entry' | 'question' | 'completion'>('entry');

  if (phase === 'entry') {
    return (
      <div className="rounded-xl border border-hairline bg-surface p-5 text-center">
        <p className="text-xs font-bold tracking-wide text-brand-700 uppercase">
          Thử thách hằng ngày
        </p>
        <p className="mt-2 text-lg font-bold text-brand-900">
          Củng cố bài học trước khi quên 70%
        </p>
        <p className="mt-1 text-sm text-ink-muted">{questions.length} câu hỏi</p>
        <div className="mt-5 flex flex-col items-center gap-2">
          <button type="button" onClick={() => setPhase('question')} className={buttonClass.primary}>
            Bắt đầu khởi động
          </button>
          <Link href="/" className={buttonClass.ghost}>
            Để sau
          </Link>
        </div>
      </div>
    );
  }

  if (phase === 'question') {
    return (
      <WarmUpSession
        questions={questions}
        onComplete={() => setPhase('completion')}
        onExit={() => router.push('/')}
      />
    );
  }

  return (
    <div className="rounded-xl border border-hairline bg-surface p-5 text-center">
      <p className="text-2xl font-bold text-brand-700">Hoàn thành thử thách!</p>
      <p className="mt-1 text-sm text-ink-muted">
        {isCourseCompleted ? 'Tiếp tục học với khóa học mới' : 'Sẵn sàng tiếp tục tiến bộ?'}
      </p>
      {course ? (
        <Link
          href={`/khoa-hoc/${course.id}`}
          className="mt-5 flex items-center gap-3 rounded-xl border border-hairline bg-surface-alt p-3 text-left hover:border-brand-300"
        >
          {course.image ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={course.image} alt="" className="size-14 shrink-0 rounded-lg object-cover" />
          ) : null}
          <span>
            <span className="block text-xs text-ink-faint">Khóa học</span>
            <span className="block font-semibold text-ink">{course.title}</span>
          </span>
        </Link>
      ) : null}
      <div className="mt-5 flex flex-col items-center gap-2">
        {course ? (
          <Link href={`/khoa-hoc/${course.id}`} className={buttonClass.primary}>
            Bắt đầu bài học hôm nay
          </Link>
        ) : null}
        <Link href="/kham-pha" className={buttonClass.ghost}>
          Khám phá thêm
        </Link>
      </div>
    </div>
  );
}
