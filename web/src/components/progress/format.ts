/**
 * Định dạng ngày cho nhóm tiến độ. Mọi mốc API trả về là thời điểm UTC của nửa
 * đêm theo giờ người học, nên phải đổi về giờ Việt Nam rồi mới lấy ngày — lấy
 * thẳng `slice(0, 10)` sẽ lùi một ngày (vd. 2026-10-25T17:00Z là thứ Hai 26/10).
 */
const TIME_ZONE = 'Asia/Ho_Chi_Minh';

const dayMonth = new Intl.DateTimeFormat('vi-VN', {
  timeZone: TIME_ZONE,
  day: '2-digit',
  month: '2-digit',
});

const dayMonthYear = new Intl.DateTimeFormat('vi-VN', {
  timeZone: TIME_ZONE,
  day: '2-digit',
  month: '2-digit',
  year: 'numeric',
});

/** "26/10 – 01/11/2026". `weekEnd` của API là thứ Hai KẾ TIẾP (mốc mở), nên lùi 1ms. */
export function formatWeekRange(weekStart: string, weekEnd: string): string {
  const start = new Date(weekStart);
  const end = new Date(new Date(weekEnd).getTime() - 1);
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) return '';
  return `${dayMonth.format(start)} – ${dayMonthYear.format(end)}`;
}

export const WEEKDAY_SHORT = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
export const WEEKDAY_NAMES = [
  'Thứ Hai',
  'Thứ Ba',
  'Thứ Tư',
  'Thứ Năm',
  'Thứ Sáu',
  'Thứ Bảy',
  'Chủ Nhật',
];

/** Thứ (0 = thứ Hai) của một ngày lịch `YYYY-MM-DD` — không phụ thuộc múi giờ. */
export function mondayIndex(date: string): number {
  const [y, m, d] = date.split('-').map(Number);
  return (new Date(Date.UTC(y, m - 1, d)).getUTCDay() + 6) % 7;
}

/** "Thứ Tư, 19 tháng 8" — cùng mẫu `dayTitle` của app. */
export function formatDayTitle(date: string): string {
  const [, m, d] = date.split('-').map(Number);
  return `${WEEKDAY_NAMES[mondayIndex(date)]}, ${d} tháng ${m}`;
}

/** Ngày lịch (giờ Việt Nam) của một mốc ISO, dạng `YYYY-MM-DD`. */
export function localDateOf(iso: string): string {
  const time = new Date(iso).getTime();
  if (Number.isNaN(time)) return '';
  return new Date(time + 7 * 60 * 60_000).toISOString().slice(0, 10);
}
