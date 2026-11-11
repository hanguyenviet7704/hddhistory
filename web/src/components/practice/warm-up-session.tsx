'use client';

/**
 * Chuỗi câu khởi động/ôn tập: chấm từng câu, "Tiếp tục" sang câu sau, câu
 * cuối thì báo hoàn thành kèm toàn bộ kết quả (`continueFromResult`).
 */
import { useState } from 'react';

import { buttonClass } from '@/components/ui-classes';
import type { Question } from '@/lib/practice';
import type { WarmUpResult } from '@/lib/practice-scoring';

import { WarmUpQuestion } from './warm-up-question';

export function ProgressDots({ total, current }: { total: number; current: number }) {
  return (
    <div className="flex items-center gap-3">
      <div
        className="flex flex-1 gap-1.5"
        role="progressbar"
        aria-valuemin={1}
        aria-valuemax={total}
        aria-valuenow={current + 1}
        aria-label={`Câu ${current + 1} trên ${total}`}
      >
        {Array.from({ length: total }, (_, index) => (
          <span
            key={index}
            className={`h-1.5 flex-1 rounded-full ${index <= current ? 'bg-brand' : 'bg-brand-100'}`}
          />
        ))}
      </div>
      <span className="text-xs font-semibold text-ink-faint">
        {current + 1}/{total}
      </span>
    </div>
  );
}

export function WarmUpSession({
  questions,
  onComplete,
  onExit,
  exitLabel = 'Thoát',
}: {
  questions: Question[];
  onComplete: (results: WarmUpResult[]) => void;
  /** Thoát giữa chừng — nhận các câu đã làm. */
  onExit?: (results: WarmUpResult[]) => void;
  exitLabel?: string;
}) {
  const [index, setIndex] = useState(0);
  const [results, setResults] = useState<WarmUpResult[]>([]);
  const question = questions[index];
  if (!question) return null;

  return (
    <div className="rounded-xl border border-hairline bg-surface p-4">
      <div className="mb-4 flex items-center gap-3">
        <div className="flex-1">
          <ProgressDots total={questions.length} current={index} />
        </div>
        {onExit ? (
          <button
            type="button"
            onClick={() => onExit(results)}
            className={`${buttonClass.ghost} shrink-0`}
          >
            {exitLabel}
          </button>
        ) : null}
      </div>
      <WarmUpQuestion
        key={index}
        question={question}
        questionIndex={index}
        onChecked={(result) => setResults((current) => [...current, result])}
        onContinue={() => {
          if (index >= questions.length - 1) onComplete(results);
          else setIndex(index + 1);
        }}
      />
    </div>
  );
}
