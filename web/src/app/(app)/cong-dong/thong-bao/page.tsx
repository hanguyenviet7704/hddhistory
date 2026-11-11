import Link from 'next/link';

import { NotificationList } from '@/components/community/notification-list';
import { Notice } from '@/components/section';
import { describeError } from '@/lib/action-result';
import { getNotifications } from '@/lib/community';

export default async function CommunityNotificationsPage() {
  const page = await getNotifications(1, 20).catch((error: unknown) =>
    error instanceof Error ? error : new Error(String(error)),
  );

  return (
    <div className="pt-5">
      <Link
        href="/cong-dong"
        className="text-sm font-semibold text-brand-700 hover:underline"
      >
        ← Cộng đồng
      </Link>
      <h1 className="mt-3 mb-4 text-2xl font-bold tracking-tight text-brand-900">
        Thông báo
      </h1>
      {page instanceof Error ? (
        <Notice>Không tải được thông báo. {describeError(page)}</Notice>
      ) : (
        <NotificationList initial={page} />
      )}
    </div>
  );
}
