/**
 * Lặp lại ngắt quãng kiểu Leitner, có chủ đích đơn giản: mỗi keypoint đứng ở
 * một "bậc", bậc quyết định bao lâu nữa mới phải ôn lại.
 *
 * - Học xong keypoint → bậc 0, ôn lần đầu sau 1 ngày.
 * - Ôn đúng → lên một bậc (1 → 3 → 7 → 14 → 30 ngày), kịch trần ở 30.
 * - Ôn sai → về bậc 0, mai ôn lại.
 */
export const REVIEW_INTERVAL_DAYS = [1, 3, 7, 14, 30];

const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * Keypoint không có câu hỏi ôn nào (admin chưa gắn `isDailyWarmUp`) bị lùi
 * hẳn ra sau thay vì nằm mãi ở đầu hàng đợi và chặn những keypoint ôn được.
 */
export const NO_QUESTION_PARK_DAYS = 30;

export const addDays = (from: Date, days: number): Date =>
  new Date(from.getTime() + days * DAY_MS);

/** Lần ôn đầu tiên của một keypoint vừa học xong. */
export const firstReviewAt = (learnedAt: Date): Date =>
  addDays(learnedAt, REVIEW_INTERVAL_DAYS[0]);

export interface IReviewStep {
  step: number;
  dueAt: Date;
}

/** Bậc và hạn ôn tiếp theo sau một lần ôn, tính từ lúc ôn (`now`). */
export const nextReview = (
  step: number,
  correct: boolean,
  now: Date,
): IReviewStep => {
  if (!correct) {
    return { step: 0, dueAt: addDays(now, REVIEW_INTERVAL_DAYS[0]) };
  }

  const current = Math.max(0, Math.floor(step || 0));
  const next = Math.min(current + 1, REVIEW_INTERVAL_DAYS.length - 1);

  return { step: next, dueAt: addDays(now, REVIEW_INTERVAL_DAYS[next]) };
};
