'use client';

import { useOptimistic, useState, useTransition } from 'react';

import { buttonClass } from '@/components/ui';
import { setCourseSaved } from '@/lib/actions/learning';

/**
 * Dấu trang của khoá học. Đổi trạng thái ngay khi bấm (lạc quan) rồi mới chờ
 * server — giống app, nơi dấu trang lật tức thì; hỏng thì tự lật lại và báo.
 */
export function SaveCourseButton({
  courseId,
  saved,
}: {
  courseId: string;
  saved: boolean;
}) {
  const [optimistic, setOptimistic] = useOptimistic(saved);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  function toggle() {
    const next = !optimistic;
    setError(null);
    startTransition(async () => {
      setOptimistic(next);
      const result = await setCourseSaved(courseId, next);
      if (!result.ok) setError(result.error);
    });
  }

  return (
    <div className="flex flex-col items-end gap-1">
      <button
        type="button"
        onClick={toggle}
        disabled={pending}
        aria-pressed={optimistic}
        className={optimistic ? buttonClass.secondary : buttonClass.ghost}
      >
        <BookmarkIcon filled={optimistic} />
        {optimistic ? 'Đã lưu' : 'Lưu khoá học'}
      </button>
      {error ? (
        <p role="alert" className="text-xs text-red-700">
          {error}
        </p>
      ) : null}
    </div>
  );
}

export function BookmarkIcon({ filled }: { filled: boolean }) {
  return (
    <svg
      aria-hidden
      viewBox="0 0 24 24"
      className="size-4"
      fill={filled ? 'currentColor' : 'none'}
      stroke="currentColor"
      strokeWidth={2}
      strokeLinejoin="round"
    >
      <path d="M6 3h12v18l-6-4-6 4z" />
    </svg>
  );
}
