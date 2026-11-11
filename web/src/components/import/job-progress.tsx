'use client';

import Link from 'next/link';
import { useEffect, useRef, useState, useTransition } from 'react';

import { buttonClass } from '@/components/ui';
import { pollImportJob } from '@/lib/actions/learning-import';
import type { ImportJob } from '@/lib/learning-import';

import { importErrorText, STAGE_LABEL } from './import-copy';

/** Nhịp của app: đủ dày để tên bước không trễ hẳn so với thực tế. */
const BASE_INTERVAL_MS = 3_000;
/** Trần giãn nhịp — job chạy vài phút, chờ quá 15 giây thì màn hình như treo. */
const MAX_INTERVAL_MS = 15_000;

function running(job: ImportJob): boolean {
  return job.status === 'queued' || job.status === 'processing';
}

/**
 * Màn chờ: poll `GET /learning-imports/{jobId}` qua server action.
 *
 * Giãn nhịp (×1.5, tối đa 15 giây) khi một nhịp hỏng hoặc khi tiến độ đứng yên
 * — bước sinh bài có thể đứng một con số cả phút, hỏi dồn chỉ tốn request. Có
 * tiến triển là về lại 3 giây. Dừng hẳn khi job xong hoặc hỏng. Một nhịp hỏng
 * không bao giờ hiện thành lỗi: nhịp sau hỏi lại (giống app).
 */
export function JobProgress({ initial }: { initial: ImportJob }) {
  const [job, setJob] = useState(initial);
  const [, startTransition] = useTransition();
  const delay = useRef(BASE_INTERVAL_MS);

  useEffect(() => {
    if (!running(job)) return;
    const timer = setTimeout(() => {
      startTransition(async () => {
        const result = await pollImportJob(job.id);
        if (!result.ok) {
          delay.current = Math.min(delay.current * 1.5, MAX_INTERVAL_MS);
          // Đặt lại cùng giá trị nhưng là object mới để effect chạy nhịp sau.
          setJob((current) => ({ ...current }));
          return;
        }
        const next = result.data;
        const moved =
          next.status !== job.status ||
          next.stage !== job.stage ||
          (next.percent ?? 0) !== (job.percent ?? 0);
        delay.current = moved
          ? BASE_INTERVAL_MS
          : Math.min(delay.current * 1.5, MAX_INTERVAL_MS);
        setJob(next);
      });
    }, delay.current);
    return () => clearTimeout(timer);
  }, [job]);

  const percent = job.status === 'completed' ? 100 : Math.round(job.percent ?? 0);

  if (job.status === 'completed') {
    return (
      <div role="status" className="mt-6 rounded-xl border border-hairline bg-surface p-5">
        <p className="text-lg font-bold text-brand-900">Bài học đã sẵn sàng</p>
        <p className="mt-1 text-ink-muted">
          {job.sourceLabel ? `${job.sourceLabel} đã sẵn sàng để đọc.` : 'Bài của bạn đã sẵn sàng để đọc.'}
        </p>
        <div className="mt-4 flex flex-wrap gap-2">
          {job.userLessonId ? (
            <Link
              href={`/bai-cua-toi/${encodeURIComponent(job.userLessonId)}`}
              className={buttonClass.primary}
            >
              Đọc ngay
            </Link>
          ) : null}
          <Link href="/bai-cua-toi" className={buttonClass.secondary}>
            Bài tôi tạo
          </Link>
        </div>
      </div>
    );
  }

  if (job.status === 'failed' || job.status === 'interrupted') {
    return (
      <div className="mt-6 rounded-xl border border-hairline bg-surface p-5">
        <p className="text-lg font-bold text-brand-900">Chưa tạo xong được</p>
        <p role="alert" className="mt-1 text-sm font-medium text-red-700">
          {job.status === 'interrupted'
            ? importErrorText('INTERRUPTED')
            : importErrorText(job.errorCode)}
        </p>
        <Link href="/nhap-bai" className={`${buttonClass.primary} mt-4`}>
          Thử lại
        </Link>
      </div>
    );
  }

  return (
    <div className="mt-6 rounded-xl border border-hairline bg-surface p-5">
      <p className="font-semibold text-brand-900" aria-live="polite">
        {(job.stage && STAGE_LABEL[job.stage]) || 'Đang tạo bài học'}
      </p>
      <div
        role="progressbar"
        aria-label="Tiến độ tạo bài"
        aria-valuemin={0}
        aria-valuemax={100}
        aria-valuenow={percent}
        className="mt-3 h-2 overflow-hidden rounded-full bg-brand-100"
      >
        <div
          className="h-full rounded-full bg-brand transition-[width] duration-700"
          style={{ width: `${Math.max(4, percent)}%` }}
        />
      </div>
      <p className="mt-2 text-sm text-ink-muted">{percent}%</p>
      <p className="mt-4 text-sm text-ink-faint">
        Bạn rời màn hình này được — quá trình vẫn chạy tiếp. Bài sẽ hiện trong{' '}
        <Link href="/bai-cua-toi" className="font-semibold text-brand-700 hover:underline">
          Bài tôi tạo
        </Link>
        .
      </p>
    </div>
  );
}
