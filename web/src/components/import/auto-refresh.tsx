'use client';

import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

/**
 * Dựng lại trang máy chủ theo nhịp, chừng nào còn thứ đang hình thành.
 *
 * Dùng cho danh sách (có lượt tạo đang chạy) và lộ trình bài (keypoint sau
 * còn đang được viết / lồng tiếng), giống `_syncRefreshTimer` của app: 8 giây
 * khi còn viết chữ, 30 giây khi chỉ còn chờ lời đọc. Trang mẹ tự bỏ component
 * này khi không còn gì để chờ, và timer chết theo.
 */
export function AutoRefresh({ everyMs }: { everyMs: number }) {
  const router = useRouter();
  useEffect(() => {
    const timer = setInterval(() => {
      // Tab ẩn thì không ai nhìn — đừng tốn request.
      if (document.visibilityState === 'visible') router.refresh();
    }, everyMs);
    return () => clearInterval(timer);
  }, [router, everyMs]);
  return null;
}
