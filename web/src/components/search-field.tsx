'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useEffect, useRef, useState, useTransition } from 'react';

/** Khoảng chờ trước khi một lần gõ biến thành một lần điều hướng. */
const DEBOUNCE_MS = 350;

/**
 * Ô tìm kiếm dùng chung cho tra cứu đồ thị và danh sách khoá học.
 *
 * Ghi từ khoá vào query string rồi để server component nạp lại, nên kết quả
 * chia sẻ được bằng URL và bấm back vẫn đúng — thứ mà giữ trạng thái trong bộ
 * nhớ component sẽ mất.
 *
 * Hoãn 350ms giống app: đủ để gõ trọn một chữ tiếng Việt có dấu (bộ gõ telex
 * bắn nhiều sự kiện cho một chữ) mà chưa thành độ trễ cảm nhận được.
 */
export function SearchField({
  initialQuery,
  basePath,
  placeholder,
  label,
}: {
  initialQuery: string;
  basePath: string;
  placeholder: string;
  label: string;
}) {
  const router = useRouter();
  const params = useSearchParams();
  const [value, setValue] = useState(initialQuery);
  const [isPending, startTransition] = useTransition();
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(
    () => () => {
      if (timer.current) clearTimeout(timer.current);
    },
    [],
  );

  function push(next: string) {
    const search = new URLSearchParams(params.toString());
    if (next.trim()) search.set('q', next.trim());
    else search.delete('q');
    startTransition(() => {
      router.replace(
        search.size ? `${basePath}?${search.toString()}` : basePath,
        { scroll: false },
      );
    });
  }

  function onChange(next: string) {
    setValue(next);
    if (timer.current) clearTimeout(timer.current);
    timer.current = setTimeout(() => push(next), DEBOUNCE_MS);
  }

  const id = `search-${basePath.replace(/\W+/g, '-')}`;

  return (
    <form
      role="search"
      className="relative"
      onSubmit={(event) => {
        event.preventDefault();
        if (timer.current) clearTimeout(timer.current);
        push(value);
      }}
    >
      <label htmlFor={id} className="sr-only">
        {label}
      </label>
      <input
        id={id}
        type="search"
        value={value}
        onChange={(event) => onChange(event.target.value)}
        placeholder={placeholder}
        className="w-full rounded-xl border border-hairline bg-surface px-4 py-3 text-ink shadow-sm outline-none placeholder:text-ink-faint focus:border-brand focus:ring-2 focus:ring-brand/30"
      />
      {isPending ? (
        <span className="absolute top-1/2 right-4 -translate-y-1/2 text-xs text-ink-faint">
          Đang tìm…
        </span>
      ) : null}
    </form>
  );
}
