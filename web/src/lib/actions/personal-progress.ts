'use server';

import { refresh, revalidatePath } from 'next/cache';

import { attempt, type ActionResult } from '@/lib/action-result';
import { request } from '@/lib/api';
import type { Streak } from '@/lib/progress';

/** Id tuần do API sinh: ObjectId 24 ký tự hex. Chặn mọi thứ khác trước khi ghép URL. */
const isRecapId = (id: string) => /^[a-f0-9]{24}$/i.test(id);

/**
 * "Xem hành trình": đánh dấu đã xem tuần hiện tại — dừng hẳn lời mời mỗi sáng.
 *
 * Gọi khi trang chi tiết đã mở (từ client, sau khi gắn), không gọi lúc dựng trang
 * phía máy chủ: Next có thể dựng trước (prefetch) một trang chỉ vì liên kết tới
 * nó lướt qua màn hình, và như thế là đánh dấu "đã xem" một tuần chưa ai mở.
 */
export async function markWeekRecapViewed(id: string): Promise<ActionResult> {
  if (!isRecapId(id)) return { ok: false, error: 'Không tìm thấy tuần này.' };
  const result = await attempt(() =>
    request(`/api/v1/courses-user-progress/week-recap/${id}/viewed`, {
      method: 'POST',
    }),
  );
  if (result.ok) revalidatePath('/tien-do');
  return result.ok ? { ok: true, data: undefined } : result;
}

/**
 * "Để sau": chỉ tắt lời mời cho HẾT HÔM NAY. API dời mốc `dismissedAt` mỗi lần
 * bấm, nên sáng mai tuần chưa xem vẫn được mời lại — khác hẳn "đã xem".
 */
export async function dismissWeekRecap(formData: FormData): Promise<void> {
  const id = String(formData.get('id') ?? '');
  if (!isRecapId(id)) return;
  await attempt(() =>
    request(`/api/v1/courses-user-progress/week-recap/${id}/dismissed`, {
      method: 'POST',
    }),
  );
  revalidatePath('/tien-do');
}

/**
 * Điểm danh hôm nay cho chuỗi ngày học.
 *
 * App gọi sau khi người học ở trong app đủ `streak-config.triggerAfterSeconds`;
 * API bỏ qua lần gọi thứ hai trong cùng ngày nên gọi lại không sao.
 * `refresh()` thay vì `revalidatePath`: thành phần đếm giờ có thể nằm ở bất kỳ
 * trang nào, và trang đang mở mới là trang cần vẽ lại.
 */
export async function checkInStreak(): Promise<ActionResult<Streak>> {
  const result = await attempt(() =>
    request<Streak>('/api/v1/courses-user-progress/streak/check-in', {
      method: 'POST',
    }),
  );
  if (result.ok) refresh();
  return result;
}
