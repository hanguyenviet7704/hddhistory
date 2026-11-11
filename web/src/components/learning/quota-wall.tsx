'use client';

import { useState, useTransition } from 'react';

import { buttonClass } from '@/components/ui';
import { claimKeypointAccess } from '@/lib/actions/learning';

/**
 * Bức tường "hết lượt học miễn phí hôm nay", đứng đúng chỗ thẻ bị chặn — chữ
 * lấy từ app (`lesson.lockedCardTitle/Body`). Web không bán Premium, nên thay
 * nút nâng cấp bằng nút hỏi lại server: lượt có thể đã mở lại (sang ngày mới,
 * hoặc đã học xong phần này trên thiết bị khác).
 */
export function QuotaWall({ keypointId }: { keypointId: string }) {
  const [message, setMessage] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  function retry() {
    setMessage(null);
    startTransition(async () => {
      const result = await claimKeypointAccess(keypointId);
      if (!result.ok) setMessage(result.error);
      else if (!result.data.granted) {
        setMessage('Vẫn chưa có lượt mới. Quay lại vào ngày mai nhé.');
      }
    });
  }

  return (
    <section className="rounded-xl border border-brand-200 bg-brand-100/50 p-5 text-center">
      <h2 className="text-lg font-bold text-brand-900">
        Hết lượt học miễn phí hôm nay
      </h2>
      <p className="mt-1 text-sm text-ink-muted">
        Quay lại vào ngày mai, hoặc nâng cấp Premium trên ứng dụng để học tiếp
        ngay.
      </p>
      <button
        type="button"
        onClick={retry}
        disabled={pending}
        className={`${buttonClass.secondary} mt-4`}
      >
        {pending ? 'Đang kiểm tra…' : 'Kiểm tra lại lượt học'}
      </button>
      {message ? (
        <p role="alert" className="mt-2 text-sm text-ink-muted">
          {message}
        </p>
      ) : null}
    </section>
  );
}
