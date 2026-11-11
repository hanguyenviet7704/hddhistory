import Link from 'next/link';

import { linkButton, rowCard } from '@/components/account/link-classes';
import { dismissWeekRecap } from '@/lib/actions/personal-progress';
import type { CurrentWeekRecap } from '@/lib/progress';

import { formatWeekRange, localDateOf } from './format';

/**
 * "Hành trình tuần qua" ở trang tiến độ — gộp băng-rôn và lời mời thứ Hai của
 * app vào một thẻ (web không có popup lúc mở app).
 *
 * Quy tắc mời giống `shouldShowPopup` của app: còn mời cho tới khi XEM; "Để sau"
 * chỉ tắt lời mời trong hôm nay. Nhãn "MỚI" theo `viewedAt` thôi — bấm "Để sau"
 * không phải là đã xem.
 */
export function WeekRecapCard({
  current,
  today,
}: {
  current: CurrentWeekRecap;
  /** `YYYY-MM-DD` theo giờ Việt Nam. */
  today: string;
}) {
  const { recap, archiveCount } = current;

  if (!recap) {
    return (
      <div className="space-y-2">
        <div className="rounded-xl border border-hairline bg-surface p-4">
          <p className="font-semibold text-ink">Hành trình đang tiếp diễn</p>
          <p className="mt-1 text-sm text-ink-muted">
            Mỗi thứ Hai, hành trình của tuần sẽ được gói lại cho bạn.
          </p>
        </div>
        <NotebookRow count={archiveCount} />
      </div>
    );
  }

  const href = `/tien-do/tuan/${recap.id}`;
  const unseen = !recap.viewedAt;
  const isNew = unseen || localDateOf(recap.viewedAt ?? '') === today;
  const offer =
    unseen && (!recap.dismissedAt || localDateOf(recap.dismissedAt) !== today);
  const range = formatWeekRange(recap.weekStart, recap.weekEnd);

  return (
    <div className="space-y-2">
      {offer ? (
        <div className="rounded-xl border border-brand-200 bg-brand-100/50 p-4">
          <p className="font-semibold text-brand-900">
            Tuần {recap.weekNumber} đã sẵn sàng
          </p>
          <p className="mt-1 text-sm text-ink-muted">
            {range ? `${range}. ` : ''}Hành trình được lưu vào Sổ tay để bạn xem
            lại bất cứ lúc nào.
          </p>
          <div className="mt-3 flex flex-wrap gap-2">
            <Link href={href} className={linkButton.primary}>
              Xem hành trình
            </Link>
            <form action={dismissWeekRecap}>
              <input type="hidden" name="id" value={recap.id} />
              <button type="submit" className={linkButton.ghost}>
                Để sau
              </button>
            </form>
          </div>
        </div>
      ) : (
        <Link href={href} className={rowCard}>
          <span className="flex-1">
            <span className="flex items-center gap-2 font-semibold text-ink">
              Hành trình tuần qua
              {isNew ? (
                <span className="rounded-full bg-brand px-2 py-0.5 text-[10px] font-bold text-white">
                  MỚI
                </span>
              ) : null}
            </span>
            <span className="block text-sm text-ink-muted">
              Tuần {recap.weekNumber}
              {range ? ` · ${range}` : ''}
            </span>
          </span>
          <span aria-hidden className="text-brand-700">
            →
          </span>
        </Link>
      )}
      <NotebookRow count={archiveCount} />
    </div>
  );
}

function NotebookRow({ count }: { count: number }) {
  if (count <= 0) return null;
  return (
    <Link href="/tien-do/tuan" className={rowCard}>
      <span className="flex-1">
        <span className="block font-semibold text-ink">Sổ hành trình</span>
        <span className="block text-sm text-ink-muted">
          Những tuần bạn đã đi qua · {count} tuần
        </span>
      </span>
      <span aria-hidden className="text-brand-700">
        →
      </span>
    </Link>
  );
}
