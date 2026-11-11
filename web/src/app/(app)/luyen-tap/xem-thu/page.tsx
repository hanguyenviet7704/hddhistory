import { notFound } from 'next/navigation';

import { ExerciseRunner } from '@/components/practice/exercise-runner';
import { FIXTURE_QUESTIONS, FIXTURE_SUB_QUESTIONS } from '@/components/practice/fixtures';
import { PreviewWarmUp } from '@/components/practice/preview-warm-up';
import { SectionHeader } from '@/components/section';
import { toQuestions } from '@/lib/practice';
import { filterUsableWarmUpQuestions, questionKind } from '@/lib/practice-scoring';

/**
 * Trang xem thử bộ làm bài — CHỈ ở môi trường phát triển.
 *
 * Database local chưa có câu hỏi nào, nên đây là chỗ duy nhất nhìn được mọi
 * dạng câu. Chấm điểm như thật nhưng không ghi gì lên server.
 */
const KIND_LABELS: Record<string, string> = {
  single: 'Trắc nghiệm một đáp án',
  multiple: 'Trắc nghiệm nhiều đáp án',
  no_correct: 'Không có đáp án đúng (kèm nhóm tài liệu)',
  gap_filling: 'Điền chỗ trống (Text Gap Filling)',
  cues: 'Đặt dấu ngắt (Cues Placement)',
  stress: 'Đánh dấu từ (Stress Placement)',
  arrange: 'Sắp xếp thứ tự (Arrange the Sequence)',
  speaking: 'Câu nói (record)',
  unsupported: 'Dạng chưa hỗ trợ',
};

export default function PracticePreviewPage() {
  if (process.env.NODE_ENV === 'production') notFound();

  const questions = toQuestions(FIXTURE_QUESTIONS);
  const subQuestions = toQuestions(FIXTURE_SUB_QUESTIONS);
  const context = { keypointId: '000000000000000000000000' };

  return (
    <div className="pt-5">
      <h1 className="text-2xl font-bold tracking-tight text-brand-900">Xem thử bài tập</h1>
      <p className="mt-1 text-sm text-ink-muted">
        Trang dành cho phát triển: mỗi dạng câu một thẻ, chấm như app, không lưu kết quả.
        Trả lời sai câu 1 hoặc câu 4 để thấy câu phụ hỏi lại.
      </p>

      <SectionHeader title="Bài tập trong keypoint" />
      <div className="space-y-4">
        {questions.map((question) => (
          <section
            key={question.id}
            className="rounded-xl border border-hairline bg-surface p-4"
          >
            <p className="text-xs font-bold tracking-wide text-brand-700 uppercase">
              {KIND_LABELS[questionKind(question)]}
            </p>
            <ExerciseRunner
              questions={[question]}
              subQuestions={subQuestions}
              context={context}
              preview
            />
          </section>
        ))}
      </div>

      <SectionHeader title="Cả bộ trong một learning item" />
      <section className="rounded-xl border border-hairline bg-surface p-4">
        <ExerciseRunner
          questions={questions}
          subQuestions={subQuestions}
          context={context}
          preview
        />
      </section>

      <SectionHeader title="Khởi động / ôn tập" />
      <p className="mb-2 text-sm text-ink-muted">
        Cùng bộ câu qua luật khởi động: câu ghi âm bị lọc bỏ, chấm đúng/sai không điểm.
      </p>
      <PreviewWarmUp questions={filterUsableWarmUpQuestions(questions)} />
    </div>
  );
}
