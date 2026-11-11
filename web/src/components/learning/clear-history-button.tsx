'use client';

import { useState, useTransition } from 'react';

import { buttonClass } from '@/components/ui';
import {
  clearRecentlyViewed,
  clearSearchHistory,
} from '@/lib/actions/learning';

/** Nút "Xoá" cho lịch sử tìm kiếm hoặc danh sách xem gần đây. */
export function ClearHistoryButton({
  kind,
  label = 'Xoá',
}: {
  kind: 'search' | 'recent';
  label?: string;
}) {
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  return (
    <span className="inline-flex flex-col items-end">
      <button
        type="button"
        disabled={pending}
        onClick={() => {
          setError(null);
          startTransition(async () => {
            const result =
              kind === 'search'
                ? await clearSearchHistory()
                : await clearRecentlyViewed();
            if (!result.ok) setError(result.error);
          });
        }}
        aria-label={
          kind === 'search'
            ? 'Xoá lịch sử tìm kiếm'
            : 'Xoá danh sách xem gần đây'
        }
        className={buttonClass.ghost}
      >
        {pending ? 'Đang xoá…' : label}
      </button>
      {error ? (
        <span role="alert" className="text-xs text-red-700">
          {error}
        </span>
      ) : null}
    </span>
  );
}
