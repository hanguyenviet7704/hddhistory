import Link from 'next/link';

import { keypointHref, text } from '@/lib/content';
import type { SavedCardItem } from '@/lib/learning';

import { SaveCardButton } from './save-card-button';

/**
 * Thẻ đã lưu: tiêu đề phần học, khoá học, và mặt sau (phần tóm tắt). Mặt sau
 * ưu tiên `recap` đa ngữ, rồi `recapText` của thẻ lưu từ bản app cũ, rồi mô tả
 * keypoint — đúng thứ tự app đọc, để thẻ không bao giờ trống.
 */
export function SavedCardList({ cards }: { cards: SavedCardItem[] }) {
  return (
    <ul className="grid gap-3 sm:grid-cols-2">
      {cards.map((card) => {
        const recap =
          text(card.recap) || card.recapText || text(card.description);
        return (
          <li
            key={card._id ?? card.keypointId}
            className="flex flex-col rounded-xl border border-hairline bg-surface p-4"
          >
            <div className="flex items-start gap-2">
              <Link
                href={keypointHref(card.keypointId, card.lessonId || undefined)}
                className="min-w-0 flex-1 font-semibold text-ink hover:text-brand-700 hover:underline"
              >
                {text(card.title) || 'Thẻ'}
              </Link>
              <SaveCardButton
                card={{ keypointId: card.keypointId }}
                saved
                compact
              />
            </div>
            {text(card.courseTitle) ? (
              <p className="text-xs text-ink-faint">{text(card.courseTitle)}</p>
            ) : null}
            {recap ? (
              <p className="mt-2 line-clamp-6 text-sm whitespace-pre-line text-ink-muted">
                {recap}
              </p>
            ) : null}
          </li>
        );
      })}
    </ul>
  );
}
