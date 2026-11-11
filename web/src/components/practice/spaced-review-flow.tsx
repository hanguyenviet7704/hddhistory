'use client';

/**
 * Ôn tập ngắt quãng — `SpacedReviewCubit` + hai trang câu hỏi/hoàn thành của
 * app. Kết quả gửi theo KEYPOINT (không theo câu), chỉ những keypoint đã làm
 * hết câu; thoát giữa chừng cũng gửi phần đã làm xong như `closeFlow`.
 */
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState, useTransition } from 'react';

import { buttonClass } from '@/components/ui-classes';
import { submitSpacedReview } from '@/lib/actions/practice';
import type { Question } from '@/lib/practice';
import {
  spacedAnsweredKeypointResults,
  spacedCorrectCount,
  type WarmUpResult,
} from '@/lib/practice-scoring';

import { WarmUpSession } from './warm-up-session';

export function SpacedReviewFlow({
  questions,
  questionKeypointIds,
}: {
  questions: Question[];
  /** Keypoint của từng câu, cùng thứ tự với `questions`. */
  questionKeypointIds: string[];
}) {
  const router = useRouter();
  const [phase, setPhase] = useState<'ready' | 'question' | 'completion'>('ready');
  const [results, setResults] = useState<WarmUpResult[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();
  const keypointCount = new Set(questionKeypointIds).size;

  function submit(answered: WarmUpResult[], then?: () => void) {
    const payload = spacedAnsweredKeypointResults(answered, questionKeypointIds);
    startTransition(async () => {
      const result = payload.length ? await submitSpacedReview(payload) : null;
      if (result && !result.ok) {
        setError(result.error);
        return;
      }
      then?.();
    });
  }

  if (phase === 'ready') {
    return (
      <div className="rounded-xl border border-hairline bg-surface p-5">
        <p className="text-lg font-bold text-brand-900">Ôn tập hôm nay</p>
        <p className="mt-1 text-sm text-ink-muted">
          {keypointCount} phần kiến thức sắp quên · khoảng 3 phút
        </p>
        <button
          type="button"
          onClick={() => setPhase('question')}
          className={`${buttonClass.primary} mt-4`}
        >
          Ôn ngay
        </button>
      </div>
    );
  }

  if (phase === 'question') {
    return (
      <>
        <WarmUpSession
          questions={questions}
          onComplete={(all) => {
            setResults(all);
            setPhase('completion');
            submit(all);
          }}
          onExit={(answered) => submit(answered, () => router.push('/'))}
          exitLabel={pending ? 'Đang lưu…' : 'Thoát'}
        />
        {error ? (
          <p role="alert" className="mt-3 text-sm text-red-700">
            Không lưu được kết quả ôn tập: {error}
          </p>
        ) : null}
      </>
    );
  }

  return (
    <div className="rounded-xl border border-hairline bg-surface p-5 text-center">
      <p className="text-2xl font-bold text-brand-700">Ôn xong rồi!</p>
      <p className="mt-2 text-lg font-bold text-ink">
        Đúng {spacedCorrectCount(results)}/{results.length} câu
      </p>
      <p className="mt-2 text-sm leading-relaxed text-ink-muted">
        Phần bạn đã nhớ sẽ được hỏi lại thưa dần. Phần chưa nhớ sẽ quay lại vào ngày mai.
      </p>
      {pending ? <p className="mt-3 text-xs text-ink-faint">Đang lưu kết quả…</p> : null}
      {error ? (
        <div className="mt-3">
          <p role="alert" className="text-sm text-red-700">
            Không lưu được kết quả ôn tập: {error}
          </p>
          <button
            type="button"
            onClick={() => {
              setError(null);
              submit(results);
            }}
            className={`${buttonClass.ghost} mt-1`}
          >
            Thử lại
          </button>
        </div>
      ) : null}
      <Link href="/" className={`${buttonClass.primary} mt-5`}>
        Về trang chủ
      </Link>
    </div>
  );
}
