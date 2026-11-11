import type { Streak } from '@/lib/progress';

/** Nhãn ngày lấy từ app (`learning_streak.week*`), thứ Hai → Chủ nhật. */
const WEEK_LABELS = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

/**
 * Dải chuỗi ngày: bảy chấm của tuần này và số ngày liên tiếp.
 *
 * Hôm nay được tô viền để người học biết chấm nào là "còn kịp", tính theo giờ
 * Việt Nam. LƯU Ý: API chia ngày theo header `x-timezone-offset` (app luôn
 * gửi), thiếu thì tính theo UTC — nên từ 0h tới 7h sáng giờ VN, chấm của API
 * và ô "hôm nay" ở đây có thể lệch nhau một ngày cho tới khi `request()` gửi
 * header đó.
 */
export function StreakStrip({
  streak,
  title = 'Tuần này',
}: {
  streak: Streak;
  title?: string;
}) {
  const today = todayIndexVn();
  const current = streak.currentStreak ?? 0;

  return (
    <section
      aria-label="Chuỗi ngày học"
      className="rounded-xl border border-hairline bg-surface p-4"
    >
      <div className="flex items-baseline justify-between gap-3">
        <p className="font-semibold text-ink">
          {current > 0 ? `Chuỗi ${current} ngày` : title}
        </p>
        {streak.bestStreak ? (
          <p className="text-xs text-ink-faint">
            Chuỗi dài nhất: {streak.bestStreak} ngày
          </p>
        ) : null}
      </div>
      <ol className="mt-3 grid grid-cols-7 gap-1 text-center">
        {WEEK_LABELS.map((label, index) => {
          const studied = Boolean(streak.weekStudy?.[index]);
          return (
            <li key={label} className="flex flex-col items-center gap-1">
              <span
                className={`flex size-8 items-center justify-center rounded-full text-xs font-bold ${
                  studied
                    ? 'bg-brand text-white'
                    : 'bg-surface-alt text-ink-faint'
                } ${index === today ? 'ring-2 ring-brand-300 ring-offset-1' : ''}`}
              >
                {studied ? '✓' : ''}
                <span className="sr-only">
                  {studied ? 'đã học' : 'chưa học'}
                </span>
              </span>
              <span
                className={`text-xs ${index === today ? 'font-bold text-brand-900' : 'text-ink-faint'}`}
              >
                {label}
              </span>
            </li>
          );
        })}
      </ol>
      {current === 0 ? (
        <p className="mt-3 text-sm text-ink-muted">
          Hoàn thành một bài học để bắt đầu chuỗi
        </p>
      ) : null}
    </section>
  );
}

/** 0 = thứ Hai … 6 = Chủ nhật, theo giờ Hà Nội. */
function todayIndexVn(): number {
  const weekday = new Intl.DateTimeFormat('en-US', {
    weekday: 'short',
    timeZone: 'Asia/Ho_Chi_Minh',
  }).format(new Date());
  return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].indexOf(weekday);
}
