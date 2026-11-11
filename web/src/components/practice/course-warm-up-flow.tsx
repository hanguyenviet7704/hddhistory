'use client';

/**
 * Khởi động trước khi học tiếp một khoá — ba màn `WarmUpIntroPage` →
 * `WarmUpQuestionPage` → `WarmUpCompletionPage` của app. Mọi lối ra đều quay
 * về khoá học (app: `closeFlowAndRouteToLesson` → lộ trình).
 */
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

import { buttonClass } from '@/components/ui-classes';
import type { Question } from '@/lib/practice';

import { WarmUpSession } from './warm-up-session';

export function CourseWarmUpFlow({
  courseId,
  lessonTitle,
  questions,
}: {
  courseId: string;
  lessonTitle: string;
  questions: Question[];
}) {
  const router = useRouter();
  const [phase, setPhase] = useState<'intro' | 'question' | 'completion'>('intro');
  const courseHref = `/khoa-hoc/${courseId}`;

  if (phase === 'intro') {
    return (
      <div className="rounded-xl border border-hairline bg-surface p-5 text-center">
        <p className="text-xl font-bold text-brand-900">Ôn lại bài học trước khi tiếp tục</p>
        <p className="mt-1 text-sm text-ink-muted">Khởi động 1 phút trước khi vào bài học mới</p>
        {lessonTitle ? (
          <p className="mx-auto mt-4 inline-block rounded-full bg-brand-50 px-3 py-1 text-sm font-semibold text-brand-900">
            {lessonTitle}
          </p>
        ) : null}
        <div className="mt-5 flex flex-col items-center gap-2">
          <button type="button" onClick={() => setPhase('question')} className={buttonClass.primary}>
            Bắt đầu khởi động
          </button>
          <Link href={courseHref} className={buttonClass.ghost}>
            Bỏ qua, vào bài học luôn
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
        onExit={() => router.push(courseHref)}
      />
    );
  }

  return (
    <div className="rounded-xl border border-hairline bg-surface p-5 text-center">
      <p className="text-xl font-bold text-brand-700">Đã khởi động xong! Đây là bước tiếp theo</p>
      <p className="mt-1 text-sm text-ink-muted">Bạn đã sẵn sàng tiếp tục từ nơi đã dừng lại</p>
      <Link href={courseHref} className={`${buttonClass.primary} mt-5`}>
        Bắt đầu bài học hôm nay
      </Link>
    </div>
  );
}
