'use client';

/**
 * Chạy các câu của MỘT learning item trong keypoint, theo luồng của app:
 *
 * 1. Lần lượt từng câu (`ExerciseCubit.nextQuestion`). Kiểm tra xong là ghi
 *    kết quả câu đó lên server ngay (`_updateUserProgressExercise`).
 * 2. Trả lời SAI một câu có câu phụ (`subQuestions[].mainQuestion == id`) thì
 *    câu phụ đó được xếp vào hàng ôn (`addSubQuestionToLessonCubit`). Câu
 *    "không có đáp án đúng" không bao giờ gọi câu phụ.
 * 3. Hết câu chính mà hàng ôn còn câu: màn "Đến giờ ôn lại rồi!" rồi làm các
 *    câu phụ (`ReviewTimeRoute` → `reviewDone`). App gom hàng ôn ở cấp cả
 *    keypoint; ở web mỗi learning item tự chạy nên gom theo item.
 */
import { useState, useTransition } from 'react';

import { buttonClass } from '@/components/ui-classes';
import { saveExerciseProgress } from '@/lib/actions/practice';
import type { Question } from '@/lib/practice';
import { findSubQuestion } from '@/lib/practice-scoring';

import { LessonQuestion, type LessonCheck } from './lesson-question';

export interface RunnerContext {
  courseId?: string;
  lessonId?: string;
  keypointId: string;
}

type Phase = 'main' | 'review-intro' | 'review' | 'done';

export function ExerciseRunner({
  questions,
  subQuestions,
  context,
  preview = false,
}: {
  questions: Question[];
  subQuestions: Question[];
  context: RunnerContext;
  /** Trang xem thử: chấm như thật nhưng không ghi gì lên server. */
  preview?: boolean;
}) {
  // Chụp bộ câu lúc mở: trang có thể được dựng lại sau mỗi lần ghi tiến độ,
  // và bài đang làm không được nhảy theo props mới.
  const [main] = useState(questions);
  const [subs] = useState(subQuestions);
  const [phase, setPhase] = useState<Phase>('main');
  const [index, setIndex] = useState(0);
  const [pending, setPending] = useState<Question[]>([]);
  const [stats, setStats] = useState({ graded: 0, correct: 0 });
  const [round, setRound] = useState(0);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [, startTransition] = useTransition();

  const canSave = !preview && !!context.lessonId;
  const list = phase === 'review' ? pending : main;
  const current = list[index];

  function handleChecked(question: Question, check: LessonCheck) {
    if (!check.neutral) {
      setStats((value) => ({
        graded: value.graded + 1,
        correct: value.correct + (check.isCorrect ? 1 : 0),
      }));
    }
    if (phase === 'main' && !check.isCorrect && !check.neutral) {
      const sub = findSubQuestion(subs, question.id);
      if (sub) setPending((queue) => (queue.includes(sub) ? queue : [...queue, sub]));
    }
    // Như app: câu không có mã bài tập thì không ghi.
    if (!canSave || !check.progress.exerciseId) return;
    startTransition(async () => {
      const result = await saveExerciseProgress({
        courseId: context.courseId,
        lessonId: context.lessonId,
        keypointId: question.keypointId || context.keypointId,
        exercise: check.progress,
      });
      setSaveError(result.ok ? null : result.error);
    });
  }

  function next() {
    if (index < list.length - 1) {
      setIndex(index + 1);
      return;
    }
    setIndex(0);
    if (phase === 'main' && pending.length > 0) setPhase('review-intro');
    else setPhase('done');
  }

  function restart() {
    setPhase('main');
    setIndex(0);
    setPending([]);
    setStats({ graded: 0, correct: 0 });
    setRound((value) => value + 1);
  }

  if (main.length === 0) return null;

  return (
    <div className="mt-3">
      {!preview && !context.lessonId ? (
        <p className="mb-3 text-xs text-ink-faint">
          Kết quả phần này chưa được lưu vì thiếu thông tin bài học.
        </p>
      ) : null}

      {phase === 'review-intro' ? (
        <div className="rounded-xl border border-brand-200 bg-brand-50 p-5 text-center">
          <p className="text-lg font-bold text-brand-900">Đến giờ ôn lại rồi!</p>
          <p className="mt-1 text-sm text-ink-muted">Làm lại những câu chưa đúng nhé.</p>
          <button
            type="button"
            onClick={() => setPhase('review')}
            className={`${buttonClass.primary} mt-4`}
          >
            Tiếp tục
          </button>
        </div>
      ) : phase === 'done' ? (
        <div className="rounded-xl border border-hairline bg-surface-alt p-5 text-center">
          <p className="text-lg font-bold text-brand-900">Hoàn thành!</p>
          {stats.graded > 0 ? (
            <p className="mt-1 text-sm text-ink-muted">
              Đúng {stats.correct}/{stats.graded} câu
            </p>
          ) : null}
          <button type="button" onClick={restart} className={`${buttonClass.secondary} mt-4`}>
            Làm lại
          </button>
        </div>
      ) : current ? (
        <div>
          <p className="mb-2 text-xs font-semibold text-ink-faint">
            {phase === 'review' ? 'Ôn lại · ' : ''}Câu {index + 1}/{list.length}
          </p>
          <LessonQuestion
            key={`${round}-${phase}-${index}`}
            question={current}
            onChecked={(check) => handleChecked(current, check)}
            onNext={next}
            nextLabel="Tiếp tục"
          />
        </div>
      ) : null}

      {saveError ? (
        <p role="alert" className="mt-3 text-sm text-red-700">
          Không lưu được kết quả: {saveError}
        </p>
      ) : null}
    </div>
  );
}
