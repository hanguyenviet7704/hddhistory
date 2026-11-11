import { SpacedReviewFlow } from '@/components/practice/spaced-review-flow';
import { Notice } from '@/components/section';
import { getSpacedReviewToday, type Question, type SpacedReviewToday } from '@/lib/practice';
import { filterUsableWarmUpQuestions } from '@/lib/practice-scoring';

/** "thứ Năm, 6/11" — ngày ôn kế tiếp theo giờ Việt Nam. */
function formatDue(iso: string): string {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '';
  return new Intl.DateTimeFormat('vi-VN', {
    weekday: 'long',
    day: 'numeric',
    month: 'numeric',
    timeZone: 'Asia/Ho_Chi_Minh',
  }).format(date);
}

export default async function SpacedReviewPage() {
  let today: SpacedReviewToday | null = null;
  try {
    today = await getSpacedReviewToday();
  } catch {
    today = null;
  }

  // Như `SpacedReviewCubit.refresh`: trải phẳng câu của mọi keypoint, nhớ
  // keypoint của từng câu để gửi kết quả theo keypoint.
  const questions: Question[] = [];
  const keypointIds: string[] = [];
  for (const keypoint of today?.keypoints ?? []) {
    for (const question of filterUsableWarmUpQuestions(keypoint.questions)) {
      questions.push(question);
      keypointIds.push(keypoint.keypointId);
    }
  }

  const nextDue = today?.nextDueAt ? formatDue(today.nextDueAt) : '';

  return (
    <div className="pt-5">
      <h1 className="text-2xl font-bold tracking-tight text-brand-900">Ôn tập</h1>
      <p className="mt-1 text-sm text-ink-muted">
        Củng cố bài học trước khi quên — mỗi phần được hỏi lại thưa dần khi bạn đã nhớ.
      </p>
      <div className="mt-4">
        {today === null ? (
          <Notice>Không tải được phần ôn tập hôm nay.</Notice>
        ) : questions.length === 0 ? (
          <Notice>
            Hôm nay không có gì cần ôn.
            {nextDue ? ` Lần ôn tiếp theo: ${nextDue}.` : ' Học thêm bài để có phần ôn tập.'}
          </Notice>
        ) : (
          <SpacedReviewFlow questions={questions} questionKeypointIds={keypointIds} />
        )}
      </div>
    </div>
  );
}
