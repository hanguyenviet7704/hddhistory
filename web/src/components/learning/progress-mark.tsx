import type { ProgressState } from '@/lib/content';

/**
 * Dấu trạng thái của một bài/keypoint. Màu không đứng một mình: luôn kèm chữ
 * (ẩn với mắt nhưng đọc được bằng trình đọc màn hình) và hình khác nhau.
 */
export function ProgressMark({
  state,
  order,
}: {
  state?: ProgressState;
  order?: number;
}) {
  if (state === 'done') {
    return (
      <span className="mt-0.5 flex size-6 shrink-0 items-center justify-center rounded-full bg-emerald-600 text-xs font-bold text-white">
        <span aria-hidden>✓</span>
        <span className="sr-only">Đã xong</span>
      </span>
    );
  }
  if (state === 'in_progress') {
    return (
      <span className="mt-0.5 flex size-6 shrink-0 items-center justify-center rounded-full border-2 border-brand bg-brand-50 text-xs font-bold text-brand-700">
        {order ?? ''}
        <span className="sr-only">Đang học</span>
      </span>
    );
  }
  return (
    <span className="mt-0.5 flex size-6 shrink-0 items-center justify-center rounded-full bg-brand-100 text-xs font-bold text-brand-700">
      {order ?? ''}
      <span className="sr-only">Chưa học</span>
    </span>
  );
}

export function progressLabel(state?: ProgressState): string {
  if (state === 'done') return 'Đã xong';
  if (state === 'in_progress') return 'Đang học';
  return 'Chưa học';
}
