'use client';

import { useOptimistic, useState, useTransition } from 'react';

import { buttonClass } from '@/components/ui';
import { setCardSaved, type SaveCardInput } from '@/lib/actions/learning';

import { BookmarkIcon } from './save-course-button';

/** Lưu thẻ tóm tắt của keypoint vào Thư viện → Thẻ đã lưu. */
export function SaveCardButton({
  card,
  saved,
  compact = false,
}: {
  card: SaveCardInput;
  saved: boolean;
  /** Bản nhỏ cho danh sách thẻ đã lưu: chỉ còn nút bỏ lưu. */
  compact?: boolean;
}) {
  const [optimistic, setOptimistic] = useOptimistic(saved);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  function toggle() {
    const next = !optimistic;
    setError(null);
    startTransition(async () => {
      setOptimistic(next);
      const result = await setCardSaved(card, next);
      if (!result.ok) setError(result.error);
    });
  }

  const label = optimistic ? 'Bỏ khỏi mục đã lưu' : 'Lưu thẻ';

  return (
    <span className="inline-flex flex-col items-end gap-1">
      <button
        type="button"
        onClick={toggle}
        disabled={pending}
        aria-pressed={optimistic}
        aria-label={compact ? label : undefined}
        className={compact ? buttonClass.ghost : buttonClass.secondary}
      >
        <BookmarkIcon filled={optimistic} />
        {compact ? null : optimistic ? 'Đã lưu thẻ' : 'Lưu thẻ'}
      </button>
      {error ? (
        <span role="alert" className="text-xs text-red-700">
          {error}
        </span>
      ) : null}
    </span>
  );
}
