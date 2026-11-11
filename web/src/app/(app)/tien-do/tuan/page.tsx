import Link from 'next/link';

import { rowCard } from '@/components/account/link-classes';
import { formatWeekRange } from '@/components/progress/format';
import { Notice } from '@/components/section';
import { getWeekRecapArchive } from '@/lib/progress';

/** "Sổ hành trình": mọi tuần đã gói lại, mới nhất trước. Tuần không học không có ở đây. */
export default async function WeekRecapArchivePage({
  searchParams,
}: {
  searchParams: Promise<{ trang?: string | string[] }>;
}) {
  const { trang } = await searchParams;
  const page = Math.max(1, Number(typeof trang === 'string' ? trang : 1) || 1);
  const archive = await getWeekRecapArchive(page).catch(() => null);

  return (
    <div className="pt-5">
      <Link
        href="/tien-do"
        className="text-sm font-semibold text-brand-700 hover:underline"
      >
        ← Tiến độ
      </Link>
      <h1 className="mt-2 text-2xl font-bold tracking-tight text-brand-900">
        Sổ hành trình
      </h1>
      <p className="mt-1 text-sm text-ink-muted">Những tuần bạn đã đi qua</p>

      <div className="mt-4">
        {archive === null ? (
          <Notice>Không tải được hành trình của bạn.</Notice>
        ) : archive.items.length === 0 ? (
          <Notice>Chưa có tuần nào trong sổ tay của bạn.</Notice>
        ) : (
          <ul className="space-y-2">
            {archive.items.map((week) => (
              <li key={week.id}>
                <Link href={`/tien-do/tuan/${week.id}`} className={rowCard}>
                  <span className="flex-1">
                    <span className="block font-semibold text-ink">
                      Tuần {week.weekNumber}
                    </span>
                    <span className="block text-sm text-ink-muted">
                      {formatWeekRange(week.weekStart, week.weekEnd)}
                    </span>
                  </span>
                  <span aria-hidden className="text-brand-700">
                    →
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </div>

      {archive && archive.totalPages > 1 ? (
        <nav
          aria-label="Phân trang"
          className="mt-4 flex items-center justify-between text-sm"
        >
          {page > 1 ? (
            <Link
              href={`/tien-do/tuan?trang=${page - 1}`}
              className="font-semibold text-brand-700 hover:underline"
            >
              ← Mới hơn
            </Link>
          ) : (
            <span />
          )}
          <span className="text-ink-faint">
            Trang {page}/{archive.totalPages}
          </span>
          {page < archive.totalPages ? (
            <Link
              href={`/tien-do/tuan?trang=${page + 1}`}
              className="font-semibold text-brand-700 hover:underline"
            >
              Cũ hơn →
            </Link>
          ) : (
            <span />
          )}
        </nav>
      ) : null}
    </div>
  );
}
