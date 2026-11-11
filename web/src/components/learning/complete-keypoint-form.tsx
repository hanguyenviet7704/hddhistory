'use client';

import { useActionState } from 'react';

import { FormMessage, SubmitButton } from '@/components/ui';
import { completeKeypoint } from '@/lib/actions/learning';

/**
 * Nút "Hoàn thành" cuối trình đọc. Thành công thì server action tự chuyển sang
 * màn hoàn thành, nên ở đây chỉ còn phải lo trạng thái chờ và câu báo lỗi.
 */
export function CompleteKeypointForm({
  keypointId,
  lessonId,
  done,
}: {
  keypointId: string;
  lessonId: string;
  /** Đã xong từ trước: vẫn cho bấm (ôn lại), chỉ đổi chữ. */
  done: boolean;
}) {
  const [state, action] = useActionState(completeKeypoint, null);

  return (
    <form action={action} className="flex flex-col items-stretch gap-2">
      <input type="hidden" name="keypointId" value={keypointId} />
      <input type="hidden" name="lessonId" value={lessonId} />
      <SubmitButton pendingLabel="Đang lưu tiến độ…">
        {done ? 'Hoàn thành lại' : 'Hoàn thành'}
      </SubmitButton>
      <FormMessage error={state && !state.ok ? state.error : undefined} />
    </form>
  );
}
