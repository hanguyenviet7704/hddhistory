import Link from 'next/link';

import type { StudyJournal } from '@/lib/progress';

import { WEEKDAY_SHORT, mondayIndex } from './format';

/** Bốn sắc độ "Ít → Nhiều" của API (level 1..4); 0 là ngày không học. */
const LEVEL_CLASS = [
  'bg-surface-alt text-ink-muted',
  'bg-brand-100 text-brand-900',
  'bg-brand-200 text-brand-900',
  'bg-brand-300 text-brand-900',
  'bg-brand text-white',
];

export function shiftMonth(month: string, delta: number): string {
  const [y, m] = month.split('-').map(Number);
  const d = new Date(Date.UTC(y, m - 1 + delta, 1));
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}`;
}

/**
 * Lịch một tháng. Mỗi ô là một liên kết (`?thang=…&ngay=…`) chứ không phải nút
 * JavaScript: chọn ngày là đổi URL, nên quay lại/chia sẻ đúng ngày đang xem và
 * trang không cần thành client component.
 */
export function StudyJournalCalendar({
  journal,
  month,
  today,
  selected,
}: {
  journal: StudyJournal;
  month: string;
  /** `YYYY-MM-DD` theo giờ Việt Nam; ngày sau đó là "chưa tới". */
  today: string;
  selected?: string;
}) {
  const [y, m] = month.split('-').map(Number);
  const daysInMonth = new Date(Date.UTC(y, m, 0)).getUTCDate();
  const lead = mondayIndex(`${month}-01`);
  const byDate = new Map(journal.days.map((day) => [day.date, day]));

  const currentMonth = today.slice(0, 7);
  // Không cho lùi quá tháng đầu tiên có học (chưa học bao giờ thì không lùi),
  // và không tiến quá tháng này — hai phía đó chỉ toàn ô trống.
  const firstMonth = journal.firstActiveDate?.slice(0, 7) ?? currentMonth;
  const prev = month > firstMonth ? shiftMonth(month, -1) : null;
  const next = month < currentMonth ? shiftMonth(month, 1) : null;

  return (
    <div className="rounded-xl border border-hairline bg-surface p-4">
      <div className="flex items-center justify-between gap-2">
        <MonthLink month={prev} label="Tháng trước" arrow="←" />
        <h3 className="font-semibold text-ink">
          Tháng {m}/{y}
        </h3>
        <MonthLink month={next} label="Tháng sau" arrow="→" />
      </div>

      <p className="mt-1 text-center text-sm text-ink-muted">
        <strong className="text-ink">{journal.summary.activeDays}</strong> ngày có
        học · <strong className="text-ink">{journal.summary.keypoints}</strong>{' '}
        keypoint
      </p>

      <div className="mt-3 grid grid-cols-7 gap-1 text-center text-xs text-ink-faint" aria-hidden>
        {WEEKDAY_SHORT.map((day) => (
          <span key={day}>{day}</span>
        ))}
      </div>
      <ol className="mt-1 grid grid-cols-7 gap-1">
        {Array.from({ length: lead }, (_, index) => (
          <li key={`lead-${index}`} aria-hidden />
        ))}
        {Array.from({ length: daysInMonth }, (_, index) => {
          const dayNumber = index + 1;
          const date = `${month}-${String(dayNumber).padStart(2, '0')}`;
          const entry = byDate.get(date);
          const level = Math.min(4, Math.max(0, entry?.level ?? 0));
          const base =
            'flex aspect-square items-center justify-center rounded-lg text-sm font-semibold';

          if (date > today) {
            return (
              <li key={date}>
                <span
                  className={`${base} text-ink-faint/50`}
                  aria-label={`Ngày ${dayNumber}, chưa tới`}
                >
                  {dayNumber}
                </span>
              </li>
            );
          }
          const isSelected = date === selected;
          return (
            <li key={date}>
              <Link
                href={`/tien-do?thang=${month}&ngay=${date}#nhat-ky`}
                scroll={false}
                aria-current={isSelected ? 'date' : undefined}
                aria-label={`Ngày ${dayNumber}: ${
                  entry ? `đã học ${entry.keypoints} keypoint` : 'không học'
                }`}
                className={`${base} ${LEVEL_CLASS[level]} transition hover:ring-2 hover:ring-brand-300 focus-visible:ring-2 focus-visible:ring-brand ${
                  isSelected ? 'ring-2 ring-brand-700' : ''
                } ${date === today ? 'underline underline-offset-2' : ''}`}
              >
                {dayNumber}
              </Link>
            </li>
          );
        })}
      </ol>

      <div className="mt-3 flex items-center justify-between gap-3 text-xs text-ink-faint">
        <span>Chạm vào ô ngày để xem lịch sử học</span>
        <span className="flex items-center gap-1" aria-hidden>
          Ít
          {LEVEL_CLASS.slice(1).map((cls) => (
            <span key={cls} className={`size-3 rounded-sm ${cls}`} />
          ))}
          Nhiều
        </span>
      </div>
    </div>
  );
}

function MonthLink({
  month,
  label,
  arrow,
}: {
  month: string | null;
  label: string;
  arrow: string;
}) {
  const className =
    'flex size-9 items-center justify-center rounded-full text-brand-700';
  if (!month) {
    return (
      <span className={`${className} opacity-30`} aria-hidden>
        {arrow}
      </span>
    );
  }
  return (
    <Link
      href={`/tien-do?thang=${month}#nhat-ky`}
      scroll={false}
      aria-label={label}
      className={`${className} transition hover:bg-brand-100`}
    >
      {arrow}
    </Link>
  );
}
