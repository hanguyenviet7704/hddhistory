'use server';

import { ApiError, request } from '../api';
import { describeError } from '../action-result';
import type { CoachPersona, CoachSilent, CoachTurn } from '../coach';

/**
 * Như `ActionResult` nhưng giữ cả `status`: lượt trả 410 (phiên quá 48 giờ đã
 * hết hạn) thì client phải MỞ LẠI phiên chứ không báo lỗi — người đọc không
 * làm gì sai cả.
 */
export type CoachResult<T> =
  | { ok: true; data: T }
  | { ok: false; error: string; status: number };

async function run<T>(call: () => Promise<T>): Promise<CoachResult<T>> {
  try {
    return { ok: true, data: await call() };
  } catch (error) {
    const status = error instanceof ApiError ? error.status : 0;
    // 400 = sự kiện không thuộc bước hiện tại; câu của API là tiếng Anh viết
    // cho log. Nói như app: lỗi ở phía mình, lời bạn không mất.
    const message =
      status === 400 || status >= 500
        ? 'Có lỗi ở phía mình. Những gì bạn nói không mất đi đâu cả.'
        : describeError(error);
    return { ok: false, error: message, status };
  }
}

/**
 * Mở (hoặc nối lại) một phiên ở cửa Trang chủ.
 *
 * Phiên đang dở trong 48 giờ được API nối lại kèm `replay`, nên gọi lại sau
 * khi tải lại trang không mất cuộc trò chuyện.
 */
export async function openCoachSession(
  tzOffsetMinutes: number,
): Promise<CoachResult<CoachTurn | CoachSilent>> {
  const tz = Number.isFinite(tzOffsetMinutes)
    ? Math.max(-720, Math.min(840, Math.round(tzOffsetMinutes)))
    : 420;
  return run(() =>
    request<CoachTurn | CoachSilent>('/api/v1/coach/sessions', {
      method: 'POST',
      body: { entry: 'home', locale: 'vi', tzOffsetMinutes: tz },
    }),
  );
}

/** Các trường một lượt được phép mang — trùng `CoachTurnDto` của API. */
export interface CoachTurnPayload {
  kind: string;
  label?: string;
  text?: string;
  mood?: number;
  habitId?: string;
  answer?: string;
  accept?: boolean;
  deep?: boolean;
  keep?: boolean;
  met?: boolean;
  again?: boolean;
  retry?: boolean;
  done?: boolean;
  keepGoing?: boolean;
  task?: string;
  value?: string;
  quizAnswer?: string;
  courseAction?: 'open' | 'save' | 'close' | 'harder';
  planContext?: string;
  planAction?: string;
  reminderEnabled?: boolean;
  reminderHour?: number;
  reminderMinute?: number;
  reminderDays?: 'once' | 'daily' | 'weekdays' | 'weekends' | 'custom';
  reminderCustomDays?: number[];
  reminderDate?: string;
  leftLines?: string[];
  rightLines?: string[];
}

export async function sendCoachTurn(
  sessionId: string,
  payload: CoachTurnPayload,
): Promise<CoachResult<CoachTurn>> {
  return run(() =>
    request<CoachTurn>(
      `/api/v1/coach/sessions/${encodeURIComponent(sessionId)}/turns`,
      { method: 'POST', body: payload },
    ),
  );
}

/** Đổi giọng ở bất kỳ bước nào; API nhớ cho lần sau. */
export async function setCoachPersona(
  sessionId: string,
  persona: CoachPersona,
): Promise<CoachResult<{ persona: CoachPersona }>> {
  return run(() =>
    request<{ persona: CoachPersona }>(
      `/api/v1/coach/sessions/${encodeURIComponent(sessionId)}/persona`,
      { method: 'PATCH', body: { persona } },
    ),
  );
}

export async function closeCoachSession(
  sessionId: string,
): Promise<CoachResult<unknown>> {
  return run(() =>
    request(`/api/v1/coach/sessions/${encodeURIComponent(sessionId)}/close`, {
      method: 'POST',
    }),
  );
}

/** Luồng 6 — câu níu lúc bấm Đóng đã được trả lời: ở lại, hay vẫn đóng (kèm đánh giá). */
export async function recordCoachExit(
  sessionId: string,
  stayed: boolean,
  chips?: string[],
  note?: string,
): Promise<CoachResult<unknown>> {
  return run(() =>
    request(`/api/v1/coach/sessions/${encodeURIComponent(sessionId)}/exit`, {
      method: 'POST',
      body: {
        stayed,
        ...(chips && chips.length > 0 ? { chips } : {}),
        ...(note?.trim() ? { note: note.trim().slice(0, 300) } : {}),
      },
    }),
  );
}

/** "Giải thích đơn giản hơn" — đếm vào NỘI DUNG, không ghi gì về người đọc. */
export async function explainKeypointAgain(
  keypointId: string,
): Promise<CoachResult<unknown>> {
  return run(() =>
    request('/api/v1/coach/explain-again', {
      method: 'POST',
      body: { keypointId },
    }),
  );
}
