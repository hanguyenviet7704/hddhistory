import Link from 'next/link';

import { SavedCardList } from '@/components/learning/saved-card-list';
import { Notice } from '@/components/section';
import { getSavedCardPage } from '@/lib/learning';

export default async function SavedCardsPage() {
  const page = await getSavedCardPage(1, 100).catch(() => null);
  const cards = page?.items ?? null;

  return (
    <div className="pt-5">
      <Link
        href="/thu-vien"
        className="text-sm font-semibold text-brand-700 hover:underline"
      >
        ← Thư viện
      </Link>
      <h1 className="mt-3 text-2xl font-bold tracking-tight text-brand-900">
        Thẻ đã lưu
      </h1>
      {cards ? (
        <p className="mt-1 text-sm text-ink-faint">{cards.length} thẻ</p>
      ) : null}

      <div className="mt-5">
        {cards === null ? (
          <Notice>Không tải được thẻ đã lưu.</Notice>
        ) : cards.length === 0 ? (
          <Notice>
            Chưa có thẻ nào. Chạm “Lưu thẻ” ở cuối một phần học để giữ lại phần
            tóm tắt.
          </Notice>
        ) : (
          <SavedCardList cards={cards} />
        )}
      </div>
    </div>
  );
}
