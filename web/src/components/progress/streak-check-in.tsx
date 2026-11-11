'use client';

import { useEffect, useRef, useState, useTransition } from 'react';

import { checkInStreak } from '@/lib/actions/personal-progress';

/**
 * Đếm thời gian người học thật sự ở trên trang rồi điểm danh hôm nay — bản web
 * của việc app gọi `streak/check-in` sau `triggerAfterSeconds` giây mở app.
 *
 * Chỉ đếm khi tab đang hiện: một tab bỏ quên sau cửa sổ khác không phải là
 * "có mặt". Không vẽ gì cho tới khi điểm danh xong; lúc đó hiện một dòng báo
 * ngắn (nếu admin bật `popupEnabled`) rồi tự ẩn sau `autoHideSeconds`.
 */
export function StreakCheckIn({
  checkedIn,
  triggerAfterSeconds,
  popupEnabled = true,
  autoHideSeconds = 3,
}: {
  checkedIn: boolean;
  triggerAfterSeconds: number;
  popupEnabled?: boolean;
  autoHideSeconds?: number;
}) {
  const [toast, setToast] = useState(false);
  const [, startTransition] = useTransition();
  const fired = useRef(false);

  useEffect(() => {
    if (checkedIn || fired.current) return;
    let seconds = 0;
    const timer = window.setInterval(() => {
      if (document.visibilityState !== 'visible') return;
      seconds += 1;
      if (seconds < triggerAfterSeconds || fired.current) return;
      fired.current = true;
      window.clearInterval(timer);
      startTransition(async () => {
        const result = await checkInStreak();
        // Hụt (mạng chập chờn) thì cho đếm lại ở lần mở trang sau; không làm
        // phiền người học bằng thông báo lỗi cho việc họ không hề yêu cầu.
        if (!result.ok) {
          fired.current = false;
          return;
        }
        if (popupEnabled) setToast(true);
      });
    }, 1000);
    return () => window.clearInterval(timer);
  }, [checkedIn, triggerAfterSeconds, popupEnabled]);

  useEffect(() => {
    if (!toast) return;
    const hide = window.setTimeout(() => setToast(false), autoHideSeconds * 1000);
    return () => window.clearTimeout(hide);
  }, [toast, autoHideSeconds]);

  return (
    <div role="status" aria-live="polite">
      {toast ? (
        <p className="fixed inset-x-4 bottom-6 z-20 mx-auto max-w-sm rounded-xl bg-brand-900 px-4 py-3 text-center text-sm font-semibold text-brand-50 shadow-lg">
          Hôm nay bạn đã có mặt!
        </p>
      ) : null}
    </div>
  );
}
