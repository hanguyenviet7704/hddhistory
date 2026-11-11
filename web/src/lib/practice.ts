/**
 * Câu hỏi luyện tập: kiểu dữ liệu, chuẩn hoá từ JSON thô, và các lời gọi đọc.
 *
 * Hình dạng lấy từ `QuestionModel` của app
 * (`hddhistory-flutter/lib/src/lesson/data/models/question_model.dart`) và từ
 * interface bài tập của API
 * (`hddhistory-api/.../learning-item/interface/excercises/*.ts`). Mọi trường
 * đều có giá trị mặc định giống `@Default(...)` của app: API lỏng tay, câu
 * thiếu trường vẫn phải vẽ được thay vì làm vỡ cả trang.
 *
 * File này chỉ chạy phía máy chủ (gọi API). Client component chỉ được
 * `import type` từ đây — mọi hàm thuần dùng ở trình duyệt nằm ở
 * `practice-scoring.ts`.
 */
import 'server-only';

import { request } from './api';
import type { MultiLang } from './content';

export type QuestionType =
  | 'single_choice'
  | 'multiple_choice'
  | 'single_choice_no_correct_answer'
  | 'drag_drop'
  | 'record'
  | 'unknown';

export type DragDropForm =
  | 'Text Gap Filling'
  | 'Cues Placement'
  | 'Stress Placement'
  | 'Arrange the Sequence'
  | 'unknown';

export type QuestionDocumentType =
  | 'title'
  | 'text'
  | 'caption'
  | 'video'
  | 'image'
  | 'audio'
  | 'explanation'
  | 'unknown';

export interface QuestionDocument {
  id: number;
  type: QuestionDocumentType;
  data: { content: MultiLang; url: MultiLang; thumbnail: string };
}

export interface QuestionOption {
  id: number;
  text: MultiLang;
  value: MultiLang;
  isCorrect: boolean;
  documentGroupId: string;
}

export interface QuestionAnswer {
  id: number;
  correctAnswer: MultiLang;
}

export interface DocumentGroup {
  id: string;
  documents: QuestionDocument[];
}

export interface Question {
  id: number;
  exerciseId: string;
  type: QuestionType;
  form: DragDropForm;
  speechBubble: MultiLang;
  document: QuestionDocument[];
  explanation: MultiLang;
  targetArea: MultiLang;
  answer: QuestionAnswer[];
  options: QuestionOption[];
  documentGroups: DocumentGroup[];
  record: string;
  maxDuration: number;
  maxScore: number;
  mainQuestion: number;
  /** `keypoint.id` của câu — rỗng thì dùng keypoint đang mở (như app). */
  keypointId: string;
}

// ---------------------------------------------------------------------------
// Chuẩn hoá JSON thô → Question
// ---------------------------------------------------------------------------

type Raw = Record<string, unknown>;

const QUESTION_TYPES: QuestionType[] = [
  'single_choice',
  'multiple_choice',
  'single_choice_no_correct_answer',
  'drag_drop',
  'record',
];

const FORMS: DragDropForm[] = [
  'Text Gap Filling',
  'Cues Placement',
  'Stress Placement',
  'Arrange the Sequence',
];

const DOCUMENT_TYPES: QuestionDocumentType[] = [
  'title',
  'text',
  'caption',
  'video',
  'image',
  'audio',
  'explanation',
];

function obj(value: unknown): Raw {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? (value as Raw)
    : {};
}

function arr(value: unknown): unknown[] {
  return Array.isArray(value) ? value : [];
}

function str(value: unknown): string {
  return typeof value === 'string' ? value : '';
}

function num(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : 0;
}

function ml(value: unknown): MultiLang {
  // Một vài bản ghi cũ lưu chuỗi trần thay vì object đa ngữ.
  if (typeof value === 'string') return { vi: value };
  const source = obj(value);
  const out: MultiLang = {};
  for (const key of ['vi', 'en', 'zh', 'ja', 'ko'] as const) {
    if (typeof source[key] === 'string') out[key] = source[key] as string;
  }
  return out;
}

/**
 * Enum theo kiểu json_serializable của app: THIẾU trường thì lấy mặc định,
 * CÓ mà lạ thì thành `unknown` (`unknownEnumValue`).
 */
function enumOf<T extends string>(
  value: unknown,
  known: readonly T[],
  fallback: T,
  unknown: T,
): T {
  if (value === undefined || value === null) return fallback;
  return known.includes(value as T) ? (value as T) : unknown;
}

function toDocument(raw: unknown): QuestionDocument {
  const source = obj(raw);
  const data = obj(source.data);
  return {
    // App đọc `_id`, API ghi `id` — nhận cả hai.
    id: num(source._id ?? source.id),
    type: enumOf(source.type, DOCUMENT_TYPES, 'text', 'unknown'),
    data: {
      content: ml(data.content),
      url: ml(data.url),
      thumbnail: str(data.thumbnail),
    },
  };
}

export function toQuestion(raw: unknown): Question {
  const source = obj(raw);
  return {
    id: num(source.id),
    exerciseId: str(source.exerciseId),
    type: enumOf(source.type, QUESTION_TYPES, 'single_choice', 'unknown'),
    form: enumOf(source.form, FORMS, 'Text Gap Filling', 'unknown'),
    speechBubble: ml(source.speechBubble),
    document: arr(source.document).map(toDocument),
    explanation: ml(source.explanation),
    targetArea: ml(source.targetArea),
    answer: arr(source.answer).map((item) => {
      const answer = obj(item);
      return { id: num(answer.id), correctAnswer: ml(answer.correctAnswer) };
    }),
    options: arr(source.options).map((item) => {
      const option = obj(item);
      return {
        id: num(option.id),
        text: ml(option.text),
        value: ml(option.value),
        isCorrect: option.isCorrect === true,
        documentGroupId: str(option.documentGroupId),
      };
    }),
    documentGroups: arr(source.documentGroups).map((item) => {
      const group = obj(item);
      return {
        id: str(group.id),
        documents: arr(group.documents).map(toDocument),
      };
    }),
    record: str(source.record),
    maxDuration: num(source.maxDuration),
    maxScore: num(source.maxScore),
    mainQuestion: num(source.mainQuestion),
    keypointId: str(obj(source.keypoint)._id ?? obj(source.keypoint).id),
  };
}

export function toQuestions(raw: unknown): Question[] {
  return arr(raw).map(toQuestion);
}

// ---------------------------------------------------------------------------
// Đọc dữ liệu
// ---------------------------------------------------------------------------

/** `GET /courses-user-progress/daily-warm-up` — thử thách khởi động hằng ngày. */
export interface DailyWarmUp {
  courseId: string;
  suggestedCourseId: string;
  lessonId: string;
  keypointId: string;
  isCourseCompleted: boolean;
  questions: Question[];
}

export async function getDailyWarmUp(): Promise<DailyWarmUp> {
  // Server chọn câu ngẫu nhiên theo tiến độ — cache là trả lại đúng bộ cũ.
  const raw = obj(
    await request<unknown>('/api/v1/courses-user-progress/daily-warm-up', {
      revalidate: 0,
    }),
  );
  return {
    courseId: str(raw.courseId),
    suggestedCourseId: str(raw.suggestedCourseId),
    lessonId: str(raw.lessonId),
    keypointId: str(raw.keypointId),
    isCourseCompleted: raw.isCourseCompleted === true,
    questions: toQuestions(raw.questions),
  };
}

/** `GET /warm-up/for-course/{id}` — ôn bài trước khi học tiếp một khoá. */
export interface CourseWarmUp {
  isDue: boolean;
  previousLesson: { id: string; title: MultiLang; questions: Question[] } | null;
}

export async function getCourseWarmUp(courseId: string): Promise<CourseWarmUp> {
  const raw = obj(
    await request<unknown>(
      `/api/v1/warm-up/for-course/${encodeURIComponent(courseId)}`,
      { revalidate: 0 },
    ),
  );
  const lesson = raw.previousLesson ? obj(raw.previousLesson) : null;
  return {
    isDue: raw.isDue === true,
    previousLesson: lesson
      ? {
          id: str(lesson.id),
          title: ml(lesson.title),
          questions: toQuestions(lesson.questions),
        }
      : null,
  };
}

/** `GET /spaced-review/today` — phiên ôn ngắt quãng hôm nay. */
export interface SpacedReviewKeypoint {
  keypointId: string;
  lessonId: string;
  courseId: string;
  title: MultiLang;
  questions: Question[];
}

export interface SpacedReviewToday {
  /** Tổng số keypoint đến hạn — có thể nhiều hơn số trong phiên. */
  dueCount: number;
  keypoints: SpacedReviewKeypoint[];
  /** Hạn ôn gần nhất khi hôm nay không còn gì (ISO), hoặc null. */
  nextDueAt: string | null;
}

export async function getSpacedReviewToday(): Promise<SpacedReviewToday> {
  const raw = obj(
    await request<unknown>('/api/v1/spaced-review/today', { revalidate: 0 }),
  );
  return {
    dueCount: num(raw.dueCount),
    keypoints: arr(raw.keypoints).map((item) => {
      const keypoint = obj(item);
      return {
        keypointId: str(keypoint.keypointId),
        lessonId: str(keypoint.lessonId),
        courseId: str(keypoint.courseId),
        title: ml(keypoint.title),
        questions: toQuestions(keypoint.questions),
      };
    }),
    nextDueAt: str(raw.nextDueAt) || null,
  };
}
