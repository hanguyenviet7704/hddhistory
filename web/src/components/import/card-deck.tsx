'use client';

import { useCallback, useEffect, useRef, useState } from 'react';

import { buttonClass } from '@/components/ui';
import { saveLessonProgress } from '@/lib/actions/user-lessons';

/**
 * Trình đọc thẻ của một keypoint trong bài tự tạo: mỗi lần một thẻ.
 *
 * Các thẻ được dựng SẴN ở máy chủ (bằng `DocumentBody`) và truyền vào dưới
 * dạng node — `DocumentBody` dùng `text()` của `lib/content` vốn `server-only`,
 * nên không chạy được trong client component.
 *
 * Mỗi lần đổi thẻ là một lần lưu chỗ dừng, như app lưu theo `viewedCardIndex`.
 * Thẻ "điều đọng lại" và thẻ hoàn thành không phải section của API, nên chúng
 * được ghi là section cuối — chạm tới đó tức là đã đọc hết keypoint.
 */
export function CardDeck({
  lessonId,
  keypointIndex,
  sectionCount,
  initialIndex,
  savedPosition,
  cards,
  doneCard,
}: {
  lessonId: string;
  keypointIndex: number;
  /** Số section thật của API — các thẻ sau đó là thẻ phụ của web. */
  sectionCount: number;
  initialIndex: number;
  /** Chỗ dừng server đang giữ, để khỏi ghi lại đúng giá trị đó. */
  savedPosition: { keypoint: number; section: number };
  cards: React.ReactNode[];
  doneCard: React.ReactNode;
}) {
  const total = cards.length + 1;
  const [index, setIndex] = useState(() =>
    Math.min(Math.max(0, initialIndex), total - 1),
  );
  const lastSaved = useRef(`${savedPosition.keypoint}:${savedPosition.section}`);
  const heading = useRef<HTMLDivElement>(null);
  const [saveFailed, setSaveFailed] = useState(false);

  useEffect(() => {
    const section = Math.min(index, Math.max(0, sectionCount - 1));
    const key = `${keypointIndex}:${section}`;
    if (key === lastSaved.current) return;
    lastSaved.current = key;
    // Không await trong UI: mất một lần ghi chỉ mất chỗ đánh dấu, không mất bài.
    // Server action chạy tuần tự nên lật nhanh cũng không ghi lộn thứ tự.
    void saveLessonProgress(lessonId, keypointIndex, section).then((result) =>
      setSaveFailed(!result.ok),
    );
  }, [index, keypointIndex, lessonId, sectionCount]);

  const go = useCallback(
    (next: number) => {
      const clamped = Math.min(Math.max(0, next), total - 1);
      setIndex(clamped);
      // Đưa tiêu điểm về đầu thẻ mới để trình đọc màn hình đọc từ đầu.
      heading.current?.focus();
    },
    [total],
  );

  useEffect(() => {
    function onKey(event: KeyboardEvent) {
      const target = event.target as HTMLElement | null;
      if (target && ['INPUT', 'TEXTAREA', 'AUDIO'].includes(target.tagName)) return;
      if (event.key === 'ArrowRight') go(index + 1);
      if (event.key === 'ArrowLeft') go(index - 1);
    }
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [go, index]);

  const isDone = index === total - 1;

  return (
    <div className="mt-4">
      <div className="mb-2 flex items-center justify-between text-xs text-ink-faint">
        <span aria-live="polite">
          {isDone ? 'Hoàn thành' : `Thẻ ${index + 1}/${cards.length}`}
        </span>
        <span className="flex gap-1" aria-hidden>
          {Array.from({ length: total }, (_, i) => (
            <span
              key={i}
              className={`h-1.5 w-4 rounded-full ${i <= index ? 'bg-brand' : 'bg-brand-100'}`}
            />
          ))}
        </span>
      </div>

      <div
        ref={heading}
        tabIndex={-1}
        className="min-h-[16rem] rounded-xl border border-hairline bg-surface p-5 outline-none focus-visible:ring-2 focus-visible:ring-brand/30"
      >
        {isDone ? doneCard : cards[index]}
      </div>

      <div className="mt-4 flex items-center justify-between gap-2">
        <button
          type="button"
          onClick={() => go(index - 1)}
          disabled={index === 0}
          className={buttonClass.secondary}
        >
          ← Trước
        </button>
        {!isDone ? (
          <button
            type="button"
            onClick={() => go(index + 1)}
            className={buttonClass.primary}
          >
            {index === cards.length - 1 ? 'Hoàn thành' : 'Tiếp →'}
          </button>
        ) : null}
      </div>
      {saveFailed ? (
        <p role="status" className="mt-2 text-xs text-ink-faint">
          Chưa lưu được chỗ bạn đang đọc — sẽ thử lại ở thẻ sau.
        </p>
      ) : null}
    </div>
  );
}
