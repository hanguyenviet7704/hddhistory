'use client';

import Link from 'next/link';
import { useEffect, useState, useTransition } from 'react';

import { buttonClass, FormMessage } from '@/components/ui';
import {
  loadNotifications,
  markAllNotificationsRead,
} from '@/lib/actions/community';
import type { CommunityNotification, NotificationPage } from '@/lib/community';

import { Avatar } from './author';
import { notificationHref, notificationText, relativeTime } from './format';

/**
 * Hộp thư cộng đồng.
 *
 * Mở là đánh dấu đã đọc hết, như `markAllRead` của app — nhưng chỉ SAU khi đã
 * vẽ: lần ghé này người đọc vẫn thấy dòng nào mới (nền đậm), lần sau mới về
 * trạng thái đã đọc. Server không `revalidate` sau thao tác này vì đúng là
 * không muốn trang dựng lại ngay trước mắt người đọc.
 */
export function NotificationList({ initial }: { initial: NotificationPage }) {
  const [items, setItems] = useState<CommunityNotification[]>(initial.items ?? []);
  const [page, setPage] = useState(initial.currentPage || 1);
  const [pages, setPages] = useState(initial.totalPages || 1);
  const [error, setError] = useState<string>();
  const [pending, startTransition] = useTransition();
  const [, startMarking] = useTransition();

  useEffect(() => {
    if (!initial.unreadCount) return;
    startMarking(async () => {
      await markAllNotificationsRead();
    });
  }, [initial.unreadCount]);

  function loadMore() {
    setError(undefined);
    startTransition(async () => {
      const result = await loadNotifications(page + 1);
      if (!result.ok) {
        setError(result.error);
        return;
      }
      setItems((current) => {
        const seen = new Set(current.map((item) => item.id));
        return [...current, ...result.data.items.filter((item) => !seen.has(item.id))];
      });
      setPage(result.data.currentPage || page + 1);
      setPages(result.data.totalPages || pages);
    });
  }

  if (items.length === 0) {
    return (
      <div className="rounded-xl border border-hairline bg-surface p-6 text-center">
        <p className="font-semibold text-brand-900">Chưa có gì mới</p>
        <p className="mt-1 text-sm text-ink-muted">
          Trả lời cho bài của bạn sẽ hiện ở đây.
        </p>
      </div>
    );
  }

  return (
    <>
      <ul className="overflow-hidden rounded-xl border border-hairline bg-surface">
        {items.map((item) => {
          const { actor, text } = notificationText(item);
          const href = notificationHref(item);
          const content = (
            <>
              <Avatar
                author={actor ? item.actor : { authorType: 'OFFICIAL' }}
              />
              <span className="min-w-0 flex-1">
                <span className="block text-sm text-ink">
                  {actor ? <strong className="font-semibold text-brand-900">{actor} </strong> : null}
                  {text}
                </span>
                <time
                  dateTime={item.createdAt}
                  suppressHydrationWarning
                  className="mt-0.5 block text-xs text-ink-faint"
                >
                  {relativeTime(item.createdAt)}
                </time>
              </span>
              {!item.isRead ? (
                <span className="mt-1.5 size-2 shrink-0 rounded-full bg-red-700">
                  <span className="sr-only">Chưa đọc</span>
                </span>
              ) : null}
            </>
          );
          const rowClass = `flex items-start gap-3 border-b border-hairline px-4 py-3 last:border-b-0 ${
            item.isRead ? '' : 'bg-brand-50'
          }`;
          return (
            <li key={item.id}>
              {href ? (
                <Link href={href} className={`${rowClass} hover:bg-brand-100/60`}>
                  {content}
                </Link>
              ) : (
                <div className={rowClass}>{content}</div>
              )}
            </li>
          );
        })}
      </ul>
      {page < pages ? (
        <div className="mt-3 text-center">
          <button
            type="button"
            onClick={loadMore}
            disabled={pending}
            className={buttonClass.secondary}
          >
            {pending ? 'Đang tải…' : 'Xem thêm'}
          </button>
        </div>
      ) : null}
      <div className="mt-2">
        <FormMessage error={error} />
      </div>
    </>
  );
}
