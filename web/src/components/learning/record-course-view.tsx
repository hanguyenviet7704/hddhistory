'use client';

import { useEffect, useTransition } from 'react';

import { recordCourseView } from '@/lib/actions/learning';

/**
 * Ghi "đã xem khoá này" sau khi trang thật sự hiện ra trong trình duyệt —
 * không ghi lúc render, vì prefetch của liên kết cũng render trang. Không vẽ gì.
 */
export function RecordCourseView({ courseId }: { courseId: string }) {
  const [, startTransition] = useTransition();
  useEffect(() => {
    startTransition(async () => {
      await recordCourseView(courseId);
    });
  }, [courseId]);
  return null;
}
