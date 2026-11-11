'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';

import { request } from '../api';
import { attempt, type ActionResult } from '../action-result';

/**
 * Nhớ chỗ người đọc dừng: keypoint nào, thẻ thứ mấy TRONG keypoint đó.
 *
 * Gọi mỗi khi đổi thẻ, như `LessonPage._saveImportedProgress` của app. Cố ý
 * KHÔNG revalidate: đây là lời ghi chạy ngầm giữa lúc đọc, dựng lại cả trang
 * sau mỗi lần lật thẻ là tốn cho không. Danh sách và lộ trình đọc API với
 * `revalidate: 0` nên lần vào sau tự thấy số mới. Server tự kẹp chỉ số lạc và
 * tự đóng dấu "đã xong" ở thẻ cuối của keypoint cuối.
 */
export async function saveLessonProgress(
  lessonId: string,
  keypointIndex: number,
  sectionIndex: number,
): Promise<ActionResult<{ stopAtKeypointIndex: number; stopAtSectionIndex: number }>> {
  return attempt(() =>
    request<{ stopAtKeypointIndex: number; stopAtSectionIndex: number }>(
      `/api/v1/user-lessons/${encodeURIComponent(lessonId)}/progress`,
      {
        method: 'PATCH',
        body: {
          stopAtKeypointIndex: Math.max(0, Math.floor(keypointIndex)),
          stopAtSectionIndex: Math.max(0, Math.floor(sectionIndex)),
        },
      },
    ),
  );
}

/**
 * "Có, thêm nữa!" — chỉ ghi lại mong muốn, không sinh gì và không tốn lượt.
 * Gọi hai lần vẫn trả lời như nhau (API giữ ngày đầu tiên).
 */
export async function requestMoreContent(
  lessonId: string,
): Promise<ActionResult<{ requested: boolean }>> {
  const result = await attempt(() =>
    request<{ requested: boolean }>(
      `/api/v1/user-lessons/${encodeURIComponent(lessonId)}/additional-content-request`,
      { method: 'POST' },
    ),
  );
  if (result.ok) revalidatePath(`/bai-cua-toi/${lessonId}`);
  return result;
}

export async function deleteUserLesson(
  _prev: { error?: string } | null,
  formData: FormData,
): Promise<{ error?: string }> {
  const lessonId = String(formData.get('lessonId') ?? '');
  if (!lessonId) return { error: 'Không tìm thấy bài này.' };

  const result = await attempt(() =>
    request(`/api/v1/user-lessons/${encodeURIComponent(lessonId)}`, {
      method: 'DELETE',
    }),
  );
  if (!result.ok) return { error: result.error };

  revalidatePath('/bai-cua-toi');
  redirect('/bai-cua-toi');
}
