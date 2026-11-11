import Link from 'next/link';
import { notFound } from 'next/navigation';

import { MarkRecapViewed } from '@/components/progress/mark-recap-viewed';
import { WeekRecapPoster } from '@/components/progress/week-recap-poster';
import { Notice } from '@/components/section';
import { ApiError } from '@/lib/api';
import { getCurrentWeekRecap, getWeekRecap } from '@/lib/progress';
import { getSessionUser } from '@/lib/session';

export default async function WeekRecapPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  if (!/^[a-f0-9]{24}$/i.test(id)) notFound();

  const [recap, current, session] = await Promise.all([
    getWeekRecap(id).catch((error) => error as Error),
    getCurrentWeekRecap().catch(() => null),
    getSessionUser(),
  ]);
  if (recap instanceof ApiError && recap.status === 404) notFound();

  // Chỉ tuần HIỆN TẠI mới được đánh dấu đã xem, như app: mở lại một tuần cũ
  // trong Sổ hành trình là đọc lại lịch sử, ghi đè mốc của nó là nói dối về
  // lúc nó được xem.
  const isCurrentUnseen =
    !(recap instanceof Error) &&
    current?.recap?.id === recap.id &&
    !current.recap.viewedAt;

  return (
    <div className="pt-5">
      <Link
        href="/tien-do/tuan"
        className="text-sm font-semibold text-brand-700 hover:underline"
      >
        ← Sổ hành trình
      </Link>

      {recap instanceof Error ? (
        <div className="mt-4">
          <Notice>Không tải được hành trình của bạn.</Notice>
        </div>
      ) : (
        <>
          <h1 className="mt-2 text-2xl font-bold tracking-tight text-brand-900">
            Tuần {recap.weekNumber}
          </h1>
          <p className="mb-4 text-sm text-ink-muted">
            Tuần qua của {session?.name || 'bạn'} thế nào?
          </p>
          <WeekRecapPoster recap={recap} />
          {isCurrentUnseen ? <MarkRecapViewed id={recap.id} /> : null}
        </>
      )}
    </div>
  );
}
