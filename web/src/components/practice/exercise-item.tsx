/**
 * HỢP ĐỒNG giữa trình đọc keypoint (`/phan/[id]`) và bộ làm bài tập.
 *
 * Trình đọc gọi `<ExerciseItem>` cho mỗi learning item có câu hỏi; ở đây
 * chuẩn hoá `questions`/`subQuestions` thô của API (phía máy chủ) rồi giao
 * cho `ExerciseRunner` (client) vẽ, chấm điểm giống app và ghi tiến độ.
 * Giữ nguyên chữ ký props này.
 *
 * `lessonId` cần có để ghi tiến độ (API bắt buộc); `courseId` thiếu thì
 * action tự lấy lại từ bài học.
 */
import type { LearningItem } from '@/lib/learning';
import { toQuestions } from '@/lib/practice';

import { ExerciseRunner } from './exercise-runner';

export interface ExerciseContext {
  courseId?: string;
  lessonId?: string;
  keypointId: string;
}

export function ExerciseItem({
  item,
  context,
}: {
  item: LearningItem;
  context: ExerciseContext;
}) {
  const questions = toQuestions(item.questions);
  // `LearningItem` của trình đọc không khai báo `subQuestions`, nhưng API trả
  // về trong cùng object (`LearningItemModel.subQuestions` của app).
  const subQuestions = toQuestions(
    (item as LearningItem & { subQuestions?: unknown }).subQuestions,
  );

  if (questions.length === 0) {
    return <p className="mt-2 text-sm text-ink-faint">Phần này chưa có câu hỏi.</p>;
  }

  return (
    <ExerciseRunner
      questions={questions}
      subQuestions={subQuestions}
      context={{
        courseId: context.courseId,
        lessonId: context.lessonId,
        keypointId: item.keypointId || context.keypointId,
      }}
    />
  );
}
