import { DailyWarmUpFlow, type SuggestedCourse } from '@/components/practice/daily-warm-up-flow';
import { Notice } from '@/components/section';
import { getCourse, text } from '@/lib/content';
import { getDailyWarmUp, type DailyWarmUp } from '@/lib/practice';
import { filterUsableWarmUpQuestions } from '@/lib/practice-scoring';

export default async function DailyWarmUpPage() {
  let warmUp: DailyWarmUp | null = null;
  try {
    warmUp = await getDailyWarmUp();
  } catch {
    warmUp = null;
  }

  // App chỉ mời khởi động khi có khoá gợi ý VÀ ít nhất một câu vẽ được
  // (`loadForHomeEntry`); câu ghi âm hay thiếu dữ liệu bị lọc bỏ.
  const questions = warmUp ? filterUsableWarmUpQuestions(warmUp.questions) : [];
  const suggestedId = warmUp?.suggestedCourseId.trim() ?? '';

  let course: SuggestedCourse | null = null;
  if (suggestedId && questions.length) {
    const found = await getCourse(suggestedId).catch(() => null);
    if (found?._id) {
      course = { id: found._id, title: text(found.title), image: found.image };
    }
  }

  return (
    <div className="pt-5">
      <h1 className="text-2xl font-bold tracking-tight text-brand-900">Khởi động</h1>
      <div className="mt-4">
        {warmUp === null ? (
          <Notice>Không tải được bài khởi động hôm nay.</Notice>
        ) : questions.length === 0 || !suggestedId ? (
          <Notice>
            Hôm nay chưa có câu khởi động nào. Học thêm bài để có câu ôn lại vào ngày mai.
          </Notice>
        ) : (
          <DailyWarmUpFlow
            questions={questions}
            course={course}
            isCourseCompleted={warmUp.isCourseCompleted}
          />
        )}
      </div>
    </div>
  );
}
