'use server';

/**
 * Các thao tác ghi của bộ làm bài: kết quả từng câu bài tập keypoint và kết
 * quả phiên ôn tập ngắt quãng.
 *
 * Đây là endpoint công khai: dữ liệu client gửi lên được dựng lại thành
 * object mới với đúng các trường API nhận, người dùng luôn lấy từ cookie phiên.
 */
import { revalidatePath } from 'next/cache';

import { attempt, type ActionResult } from '../action-result';
import { request } from '../api';
import { getLesson } from '../content';
import type {
  ExerciseProgressData,
  ProgressDragDropOption,
  ProgressOption,
  ProgressValue,
} from '../practice-scoring';
import { getSessionUser } from '../session';

function isId(value: unknown): value is string {
  return typeof value === 'string' && /^[a-f0-9]{24}$/i.test(value);
}

const TYPES = new Set([
  'single_choice',
  'multiple_choice',
  'single_choice_no_correct_answer',
  'drag_drop',
]);
const FORMS = new Set([
  'Text Gap Filling',
  'Cues Placement',
  'Stress Placement',
  'Arrange the Sequence',
]);

function cleanValue(value: unknown): ProgressValue | undefined {
  if (!value || typeof value !== 'object') return undefined;
  const source = value as Record<string, unknown>;
  const out: ProgressValue = {};
  if (typeof source.en === 'string' && source.en) out.en = source.en;
  if (typeof source.vi === 'string' && source.vi) out.vi = source.vi;
  return out.en || out.vi ? out : undefined;
}

function cleanOption(value: unknown): ProgressOption | undefined {
  if (!value || typeof value !== 'object') return undefined;
  const source = value as Record<string, unknown>;
  const inner = cleanValue(source.value);
  if (!inner) return undefined;
  return { value: inner, isCorrect: source.isCorrect === true };
}

function cleanDragDrop(value: unknown): ProgressDragDropOption | undefined {
  if (!value || typeof value !== 'object') return undefined;
  const source = value as Record<string, unknown>;
  const out: ProgressDragDropOption = {};
  if (typeof source.id === 'number' && Number.isInteger(source.id) && source.id > 0) {
    out.id = source.id;
  }
  const text = cleanValue(source.text);
  if (text) out.text = text;
  return out.id !== undefined || out.text ? out : undefined;
}

function cleanExercise(input: ExerciseProgressData): ExerciseProgressData | null {
  if (!input || typeof input !== 'object') return null;
  if (typeof input.exerciseId !== 'string' || !input.exerciseId.trim()) return null;
  if (!TYPES.has(input.type)) return null;
  const out: ExerciseProgressData = {
    exerciseId: input.exerciseId.slice(0, 64),
    type: input.type,
    passed: input.passed === true,
    score: typeof input.score === 'number' && Number.isFinite(input.score) ? input.score : 0,
  };
  if (typeof input.form === 'string' && FORMS.has(input.form)) out.form = input.form;
  if (Array.isArray(input.multipleAnswer)) {
    const list = input.multipleAnswer
      .map(cleanOption)
      .filter((item): item is ProgressOption => !!item);
    if (list.length) out.multipleAnswer = list;
  }
  const single = cleanOption(input.singleAnswer);
  if (single) out.singleAnswer = single;
  if (Array.isArray(input.dragDropAnswer)) {
    const list = input.dragDropAnswer
      .map(cleanDragDrop)
      .filter((item): item is ProgressDragDropOption => !!item);
    if (list.length) out.dragDropAnswer = list;
  }
  return out;
}

/**
 * Ghi kết quả MỘT câu bài tập — `_updateUserProgressExercise` của từng cubit
 * (`PUT /courses-user-progress/exercises`, mỗi lần một câu như app).
 *
 * API bắt buộc `courseId` và `lessonId`; thiếu khoá học thì lấy lại từ bài
 * học, giống fallback `lesson.courseId` của app.
 */
export async function saveExerciseProgress(input: {
  courseId?: string;
  lessonId?: string;
  keypointId: string;
  exercise: ExerciseProgressData;
}): Promise<ActionResult> {
  const exercise = cleanExercise(input?.exercise);
  if (!exercise) return { ok: false, error: 'Câu hỏi này thiếu mã bài tập.' };
  if (!isId(input.keypointId) || !isId(input.lessonId)) {
    return { ok: false, error: 'Thiếu thông tin bài học để lưu kết quả.' };
  }
  const lessonId = input.lessonId;

  const user = await getSessionUser();
  if (!user) return { ok: false, error: 'Phiên đăng nhập đã hết. Đăng nhập lại.' };

  const result = await attempt(async () => {
    const courseId = isId(input.courseId)
      ? input.courseId
      : (await getLesson(lessonId)).courseId;
    if (!courseId) throw new Error('Bài học này không thuộc khoá học nào.');
    await request('/api/v1/courses-user-progress/exercises', {
      method: 'PUT',
      body: {
        userId: user.id,
        courseId,
        lessonId,
        keypointId: input.keypointId,
        exercises: [exercise],
      },
    });
  });
  if (!result.ok) return result;

  // Trang tiến độ phải thấy điểm mới. Next có thể dựng lại luôn trang đang
  // làm bài trong cùng phản hồi — vô hại: bộ làm bài giữ câu đang làm trong
  // state client, không đọc lại từ props.
  revalidatePath('/tien-do');
  return { ok: true, data: undefined };
}

/**
 * Gửi kết quả phiên ôn ngắt quãng — `SpacedReviewRepository.submitAnswers`:
 * `{ results: [{ keypointId, correct }] }`.
 */
export async function submitSpacedReview(
  results: { keypointId: string; correct: boolean }[],
): Promise<ActionResult> {
  if (!Array.isArray(results)) return { ok: false, error: 'Dữ liệu không hợp lệ.' };
  const clean = results
    .filter(
      (item) =>
        item &&
        typeof item.keypointId === 'string' &&
        item.keypointId.trim() !== '' &&
        item.keypointId.length <= 64,
    )
    .map((item) => ({ keypointId: item.keypointId, correct: item.correct === true }))
    // Giới hạn của DTO (`ArrayMaxSize(50)`).
    .slice(0, 50);
  if (clean.length === 0) return { ok: true, data: undefined };

  const result = await attempt(() =>
    request('/api/v1/spaced-review/answers', {
      method: 'POST',
      body: { results: clean },
    }),
  );
  if (!result.ok) return result;
  // Thẻ "Ôn tập hôm nay" ở trang chủ phải biến mất/đổi số sau khi ôn.
  revalidatePath('/');
  return { ok: true, data: undefined };
}
