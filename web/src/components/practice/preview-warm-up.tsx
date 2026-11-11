'use client';

/** Vòng khởi động chạy trên câu mẫu — chỉ cho trang xem thử, không gọi API. */
import { useState } from 'react';

import { buttonClass } from '@/components/ui-classes';
import type { Question } from '@/lib/practice';
import { spacedCorrectCount, type WarmUpResult } from '@/lib/practice-scoring';

import { WarmUpSession } from './warm-up-session';

export function PreviewWarmUp({ questions }: { questions: Question[] }) {
  const [round, setRound] = useState(0);
  const [results, setResults] = useState<WarmUpResult[] | null>(null);

  if (results) {
    return (
      <div className="rounded-xl border border-hairline bg-surface p-5 text-center">
        <p className="text-lg font-bold text-brand-700">Hoàn thành thử thách!</p>
        <p className="mt-1 text-sm text-ink-muted">
          Đúng {spacedCorrectCount(results)}/{results.length} câu (câu trung lập tính là đúng,
          như màn ôn tập)
        </p>
        <button
          type="button"
          onClick={() => {
            setResults(null);
            setRound(round + 1);
          }}
          className={`${buttonClass.secondary} mt-4`}
        >
          Làm lại
        </button>
      </div>
    );
  }

  return <WarmUpSession key={round} questions={questions} onComplete={setResults} />;
}
