'use client';

import { startTransition, useEffect, useRef } from 'react';

import { markWeekRecapViewed } from '@/lib/actions/personal-progress';

/**
 * Đánh dấu "đã xem" sau khi trang tuần thật sự hiện ra trên màn hình.
 *
 * Không vẽ gì. `useRef` chặn lần gọi thứ hai khi React (chế độ dev) gắn
 * component hai lần — API ghi `viewedAt` một lần duy nhất nên gọi thừa không
 * hỏng gì, chỉ là tốn một request.
 */
export function MarkRecapViewed({ id }: { id: string }) {
  const sent = useRef(false);
  useEffect(() => {
    if (sent.current) return;
    sent.current = true;
    startTransition(async () => {
      await markWeekRecapViewed(id);
    });
  }, [id]);
  return null;
}
