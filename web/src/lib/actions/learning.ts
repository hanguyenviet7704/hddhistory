'use server';

/**
 * Các thao tác ghi của vòng học: hoàn thành keypoint, lưu khoá/thẻ, hạn mức
 * đọc, lịch sử tìm kiếm, xem gần đây, và sự kiện banner/popup trang chủ.
 *
 * Mỗi hàm ở đây là một endpoint công khai (server action), nên KHÔNG tin dữ
 * liệu client gửi lên hơn mức cần: khoá học của một bài lấy lại từ API chứ
 * không lấy từ form, và người dùng luôn là người trong cookie phiên.
 */
import { refresh, revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';

import { attempt, type ActionResult } from '../action-result';
import { request } from '../api';
import { getLesson, type MultiLang } from '../content';
import { getSessionUser } from '../session';

/** Id Mongo — chặn sớm thứ rác trước khi nó thành một lời gọi API. */
function isId(value: unknown): value is string {
  return typeof value === 'string' && /^[a-f0-9]{24}$/i.test(value);
}

// ---------------------------------------------------------------------------
// Hoàn thành keypoint
// ---------------------------------------------------------------------------

/**
 * "Hoàn thành" một keypoint — làm đúng những gì app làm khi người đọc tới thẻ
 * cuối (`LessonCubit._updateUserProgressKeypoint` →
 * `ProgressCubit.updateUserProgressKeypoint`), rồi điểm danh chuỗi ngày:
 *
 * 1. `PUT /courses-user-progress/keypoints` với điểm 0, `passed: true` — app
 *    đọc lý thuyết không chấm điểm, nên cũng gửi 0.
 * 2. Nếu mọi keypoint KHÁC của bài đã xong thì bài cũng xong:
 *    `PUT /courses-user-progress/lesson/{id}`. Thiếu bước này lộ trình vẫn ghi
 *    bài là "đang học" dù đã đọc hết, và số bài đã xong của khoá không tăng.
 * 3. `POST .../streak/check-in`. Trên app việc này chạy theo thời gian mở app;
 *    web không có đồng hồ đó, nên điểm danh ở hành động học rõ ràng nhất. Gọi
 *    lặp trong ngày không đổi gì (API idempotent).
 *
 * Xong thì sang màn hoàn thành; lỗi thì trả về câu tiếng Việt cho nút hiện.
 */
export async function completeKeypoint(
  _previous: ActionResult | null,
  formData: FormData,
): Promise<ActionResult> {
  const keypointId = formData.get('keypointId');
  const lessonId = formData.get('lessonId');
  if (!isId(keypointId) || !isId(lessonId)) {
    return { ok: false, error: 'Thiếu thông tin bài học để lưu tiến độ.' };
  }

  const user = await getSessionUser();
  if (!user)
    return { ok: false, error: 'Phiên đăng nhập đã hết. Đăng nhập lại.' };

  const result = await attempt(async () => {
    const lesson = await getLesson(lessonId);
    const courseId = lesson.courseId;
    if (!courseId) throw new Error('Bài học này không thuộc khoá học nào.');

    // `?bai=` đến từ URL, gõ tay được. Keypoint không nằm trong bài thì không
    // ghi: tiến độ sẽ gắn nhầm bài, và "mọi keypoint khác đã xong" bên dưới
    // sẽ xét nhầm cả bài — đủ để đánh dấu xong một bài chưa hề học.
    const keypoints = lesson.keypoints ?? [];
    if (!keypoints.some((k) => k._id === keypointId)) {
      throw new Error('Phần học này không thuộc bài học đang mở.');
    }

    // Đọc trạng thái TRƯỚC khi ghi — y như `isAllOtherKeypointsCompleted`
    // của app, vốn xét các keypoint khác keypoint đang mở.
    const others = keypoints.filter((k) => k._id !== keypointId);
    const lessonWillComplete = others.every((k) => k.progess === 'done');

    await request('/api/v1/courses-user-progress/keypoints', {
      method: 'PUT',
      body: {
        userId: user.id,
        courseId,
        lessonId,
        keypoints: [{ keypointId, averageScore: 0, passed: true, reviews: '' }],
      },
    });

    if (lessonWillComplete) {
      await request(
        `/api/v1/courses-user-progress/lesson/${encodeURIComponent(lessonId)}`,
        {
          method: 'PUT',
          body: {
            userId: user.id,
            courseId,
            averageScore: 0,
            passed: true,
            reviews: '',
          },
        },
      );
    }

    // Chuỗi ngày là phần thưởng đi kèm, không phải điều kiện: hỏng thì tiến
    // độ đã ghi vẫn là thật, đừng báo lỗi cả thao tác vì nó.
    await request('/api/v1/courses-user-progress/streak/check-in', {
      method: 'POST',
    }).catch(() => null);
  });

  if (!result.ok) return result;

  // Tiến độ hiện ở khắp nơi (trang chủ, thư viện, lộ trình) — làm mới cả cây
  // thay vì đoán sót một trang.
  revalidatePath('/', 'layout');
  redirect(
    `/phan/${encodeURIComponent(keypointId)}/hoan-thanh?bai=${encodeURIComponent(lessonId)}`,
  );
}

// ---------------------------------------------------------------------------
// Hạn mức đọc keypoint
// ---------------------------------------------------------------------------

export interface ClaimResult {
  granted: boolean;
  reason?: string;
}

/**
 * Hỏi server xem có được đọc tiếp qua bức tường không. Không tiêu lượt nào —
 * lượt chỉ bị trừ khi HOÀN THÀNH keypoint — nên bấm thử bao nhiêu lần cũng an
 * toàn. Được thì làm mới trang để bức tường biến mất.
 */
export async function claimKeypointAccess(
  keypointId: string,
): Promise<ActionResult<ClaimResult>> {
  if (!isId(keypointId)) return { ok: false, error: 'Phần học không hợp lệ.' };
  const result = await attempt(() =>
    request<ClaimResult>(
      `/api/v1/keypoint-access/${encodeURIComponent(keypointId)}/claim`,
      { method: 'POST' },
    ),
  );
  if (result.ok && result.data.granted) refresh();
  return result;
}

// ---------------------------------------------------------------------------
// Lưu khoá học / thẻ
// ---------------------------------------------------------------------------

export async function setCourseSaved(
  courseId: string,
  saved: boolean,
): Promise<ActionResult> {
  if (!isId(courseId)) return { ok: false, error: 'Khoá học không hợp lệ.' };
  const result = await attempt(async () => {
    if (saved) {
      await request('/api/v1/saved-courses', {
        method: 'POST',
        body: { courseId },
      });
    } else {
      await request(`/api/v1/saved-courses/${encodeURIComponent(courseId)}`, {
        method: 'DELETE',
      });
    }
  });
  if (result.ok) refresh();
  return result.ok ? { ok: true, data: undefined } : result;
}

export interface SaveCardInput {
  keypointId: string;
  lessonId?: string;
  courseId?: string;
  recap?: MultiLang;
  recapText?: string;
}

/**
 * Lưu/bỏ lưu thẻ tóm tắt của keypoint. Mặt sau thẻ là một BẢN CHỤP phần tóm
 * tắt (server không tự dựng lại), nên gửi kèm đủ mọi ngôn ngữ đang có — giống
 * app, để thẻ vẫn đúng ngôn ngữ nếu người dùng đổi ngôn ngữ sau này.
 */
export async function setCardSaved(
  input: SaveCardInput,
  saved: boolean,
): Promise<ActionResult> {
  if (!isId(input.keypointId)) return { ok: false, error: 'Thẻ không hợp lệ.' };
  const result = await attempt(async () => {
    if (saved) {
      await request('/api/v1/saved-cards', {
        method: 'POST',
        body: {
          keypointId: input.keypointId,
          ...(isId(input.lessonId) ? { lessonId: input.lessonId } : {}),
          ...(isId(input.courseId) ? { courseId: input.courseId } : {}),
          ...(input.recap ? { recap: input.recap } : {}),
          ...(input.recapText
            ? { recapText: input.recapText.slice(0, 8000) }
            : {}),
        },
      });
    } else {
      await request(
        `/api/v1/saved-cards/${encodeURIComponent(input.keypointId)}`,
        { method: 'DELETE' },
      );
    }
  });
  if (result.ok) refresh();
  return result.ok ? { ok: true, data: undefined } : result;
}

// ---------------------------------------------------------------------------
// Xem gần đây, lịch sử tìm kiếm
// ---------------------------------------------------------------------------

/**
 * Ghi "vừa mở khoá này" — app ghi mỗi lần nạp lộ trình. Gọi từ client sau
 * khi trang đã hiện (không ghi lúc render: prefetch của Link cũng render trang,
 * và một lần lướt qua liên kết không phải là đã xem). Không làm mới trang.
 */
export async function recordCourseView(courseId: string): Promise<void> {
  if (!isId(courseId)) return;
  await request('/api/v1/courses-recently-viewed', {
    method: 'POST',
    body: { courseId },
  }).catch(() => null);
}

export async function clearRecentlyViewed(): Promise<ActionResult> {
  const result = await attempt(() =>
    request('/api/v1/courses-recently-viewed', { method: 'DELETE' }),
  );
  if (result.ok) refresh();
  return result.ok ? { ok: true, data: undefined } : result;
}

/** Ghi một lần tìm. Chỉ gọi khi người dùng chủ động gửi, không theo từng phím gõ. */
export async function recordSearch(query: string): Promise<void> {
  const trimmed = typeof query === 'string' ? query.trim().slice(0, 200) : '';
  if (!trimmed) return;
  await request('/api/v1/courses-search-history', {
    method: 'POST',
    body: { query: trimmed },
  }).catch(() => null);
}

export async function clearSearchHistory(): Promise<ActionResult> {
  const result = await attempt(() =>
    request('/api/v1/courses-search-history', { method: 'DELETE' }),
  );
  if (result.ok) refresh();
  return result.ok ? { ok: true, data: undefined } : result;
}

// ---------------------------------------------------------------------------
// Banner và popup trang chủ — sự kiện bắn-và-quên
// ---------------------------------------------------------------------------

/** API chỉ nhận khoá chiến dịch dạng 16 ký tự hex thường. */
function isCampaignKey(value: unknown): value is string {
  return typeof value === 'string' && /^[a-f0-9]{16}$/.test(value);
}

type CampaignEvent =
  'banner-impression' | 'banner-click' | 'popup-impression' | 'popup-click';

const CAMPAIGN_PATHS: Record<CampaignEvent, string> = {
  'banner-impression': '/api/v1/home-banner/impression',
  'banner-click': '/api/v1/home-banner/click',
  'popup-impression': '/api/v1/home-popup/impression',
  // Bấm popup cũng "về hưu" chiến dịch đó với người này — server sẽ thôi trả về.
  'popup-click': '/api/v1/home-popup/click',
};

/**
 * Một lần hiện / một lần bấm. Không bao giờ ném, không làm mới trang: sự kiện
 * thống kê hỏng thì người dùng cũng không nên thấy gì khác.
 */
export async function trackCampaign(
  event: CampaignEvent,
  campaignKey: string,
): Promise<void> {
  if (!isCampaignKey(campaignKey) || !(event in CAMPAIGN_PATHS)) return;
  await request(CAMPAIGN_PATHS[event], {
    method: 'POST',
    body: { campaignKey },
  }).catch(() => null);
}
