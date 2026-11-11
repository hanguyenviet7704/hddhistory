/**
 * Chấm điểm và dựng payload tiến độ cho câu hỏi luyện tập — bản TS thuần của
 * logic trong app, chạy được cả ở trình duyệt lẫn máy chủ.
 *
 * Mỗi hàm ở đây là bản chép từng dòng của một hàm Dart, và chú thích ghi rõ
 * hàm gốc. Đừng "sửa cho đúng" những chỗ trông lạ (ví dụ trắc nghiệm nhiều
 * đáp án chọn thừa vẫn tính là ĐÚNG, khởi động lại bắt chọn ĐỦ và KHÔNG thừa):
 * web phải chấm y như app, nếu không cùng một bài làm sẽ ra hai điểm khác nhau
 * trên hai nền tảng.
 *
 * Có HAI bộ luật, đúng như app:
 *   - bài tập trong keypoint (các cubit `presentation/cubits/{choice,...}`),
 *     có điểm số và ghi tiến độ;
 *   - khởi động / ôn tập (`evaluateDailyWarmUpQuestion`), chỉ đúng/sai.
 */
import type { MultiLang } from './content';
import type { DocumentGroup, Question, QuestionOption } from './practice';

// ---------------------------------------------------------------------------
// Chữ đa ngữ — `BaseMultiLanguageExtension.text`
// ---------------------------------------------------------------------------

/** Giống `text()` của `content.ts` nhưng dùng được ở client (file kia là server-only). */
export function mlText(value: MultiLang | string | undefined | null): string {
  if (!value) return '';
  if (typeof value === 'string') return value;
  return value.vi || value.en || value.zh || value.ja || value.ko || '';
}

// ---------------------------------------------------------------------------
// Phân loại câu — `QuestionModelExtension._toTypedPayload`
// ---------------------------------------------------------------------------

export type QuestionKind =
  | 'single'
  | 'multiple'
  | 'no_correct'
  | 'gap_filling'
  | 'cues'
  | 'stress'
  | 'arrange'
  | 'speaking'
  | 'unsupported';

export function questionKind(question: Question): QuestionKind {
  switch (question.type) {
    case 'single_choice':
      return 'single';
    case 'multiple_choice':
      return 'multiple';
    case 'single_choice_no_correct_answer':
      return 'no_correct';
    case 'record':
      return 'speaking';
    case 'drag_drop':
      switch (question.form) {
        case 'Text Gap Filling':
          return 'gap_filling';
        case 'Cues Placement':
          return 'cues';
        case 'Stress Placement':
          return 'stress';
        case 'Arrange the Sequence':
          return 'arrange';
        default:
          return 'unsupported';
      }
    default:
      return 'unsupported';
  }
}

const CHOICE_KINDS: QuestionKind[] = ['single', 'multiple', 'no_correct'];
const DRAG_KINDS: QuestionKind[] = ['gap_filling', 'cues', 'stress', 'arrange'];

// ---------------------------------------------------------------------------
// Phương án/đáp án lúc chạy — `question_payload_access.dart`
// ---------------------------------------------------------------------------

/** `OptionEntity` sau khi đi qua payload: `text` và `value` là cùng một chuỗi. */
export interface RuntimeOption {
  /** Phương án trắc nghiệm không có id ở API — luôn 0, như app. */
  id: number;
  text: MultiLang;
  value: MultiLang;
  isCorrect: boolean;
  documentGroupId: string;
}

export function optionLabel(option: { text: MultiLang; value: MultiLang }): string {
  return mlText(option.text) || mlText(option.value);
}

function choicePick(option: QuestionOption): MultiLang {
  // `toChoiceOptionEntity`: ưu tiên `value`, rỗng thì `text`.
  return mlText(option.value) ? option.value : option.text;
}

function dragPick(option: QuestionOption): MultiLang {
  // `toDragDropOptionEntity`: ưu tiên `text`, rỗng thì `value`.
  return mlText(option.text) ? option.text : option.value;
}

export function runtimeOptions(question: Question): RuntimeOption[] {
  const kind = questionKind(question);
  if (CHOICE_KINDS.includes(kind)) {
    return question.options.map((option) => {
      const picked = choicePick(option);
      return {
        id: 0,
        text: picked,
        value: picked,
        isCorrect: kind === 'no_correct' ? false : option.isCorrect,
        documentGroupId: option.documentGroupId,
      };
    });
  }
  if (DRAG_KINDS.includes(kind)) {
    return question.options.map((option) => {
      const picked = dragPick(option);
      return {
        id: option.id,
        text: picked,
        value: picked,
        isCorrect: false,
        documentGroupId: '',
      };
    });
  }
  return [];
}

export interface RuntimeAnswer {
  id: number;
  correctAnswer: MultiLang;
}

export function runtimeAnswers(question: Question): RuntimeAnswer[] {
  return DRAG_KINDS.includes(questionKind(question)) ? question.answer : [];
}

export function targetAreaText(question: Question): string {
  const kind = questionKind(question);
  return kind === 'gap_filling' || kind === 'cues' || kind === 'stress'
    ? mlText(question.targetArea)
    : '';
}

/** `QuestionEntity.questionText`. */
export function questionText(question: Question): string {
  if (question.document.length === 0) return 'No question text';
  return mlText(question.document[0].data.content);
}

/** `int.tryParse` của Dart cho chuỗi số thập phân. */
function parseDartInt(value: string): number | null {
  const trimmed = value.trim();
  return /^[+-]?\d+$/.test(trimmed) ? Number.parseInt(trimmed, 10) : null;
}

/** Đáp án vị trí (1-based ở dữ liệu) → chỉ số từ 0-based. */
export function correctPositions(question: Question): Set<number> {
  const out = new Set<number>();
  for (const answer of runtimeAnswers(question)) {
    const index = parseDartInt(mlText(answer.correctAnswer)) ?? 0;
    if (index > 0) out.add(index - 1);
  }
  return out;
}

function clampScore(score: number, maxScore: number): number {
  // `score.clamp(0, maxScore).toInt()` — Dart cắt phần lẻ về phía 0.
  return Math.trunc(Math.min(Math.max(score, 0), maxScore));
}

function sameSet(a: ReadonlySet<number>, b: ReadonlySet<number>): boolean {
  if (a.size !== b.size) return false;
  for (const value of a) if (!b.has(value)) return false;
  return true;
}

// ---------------------------------------------------------------------------
// BÀI TẬP KEYPOINT — trắc nghiệm (`choice_correctness_rules.dart`,
// `choice_scoring_rules.dart`, `ChoiceStateExtension`)
// ---------------------------------------------------------------------------

export interface ChoiceSelection {
  selectedAnswerIndex: number;
  selectedAnswersIndices: readonly number[];
}

/** `ChoiceStateExtension.correctOptionsIndices`. */
export function choiceCorrectIndices(
  question: Question,
  selectedAnswerIndex: number,
): Set<number> {
  const options = runtimeOptions(question);
  if (questionKind(question) === 'no_correct') {
    if (selectedAnswerIndex < 0 || selectedAnswerIndex >= options.length) {
      return new Set();
    }
    return new Set([selectedAnswerIndex]);
  }
  const out = new Set<number>();
  options.forEach((option, index) => {
    if (option.isCorrect) out.add(index);
  });
  return out;
}

export function resolveChoiceCheckResult(input: {
  isMultipleChoice: boolean;
  isNoCorrectSingleChoice: boolean;
  selectedAnswerIndex: number;
  selectedAnswersIndices: ReadonlySet<number>;
  correctOptionsIndices: ReadonlySet<number>;
}): boolean {
  if (input.isMultipleChoice) {
    if (input.selectedAnswersIndices.size === 0) return false;
    // Chỉ cần chọn đủ các đáp án đúng; chọn thừa vẫn tính là đúng (bị trừ ở điểm).
    for (const index of input.correctOptionsIndices) {
      if (!input.selectedAnswersIndices.has(index)) return false;
    }
    return true;
  }
  if (input.isNoCorrectSingleChoice) return input.selectedAnswerIndex >= 0;
  return input.correctOptionsIndices.has(input.selectedAnswerIndex);
}

export function calculateChoiceScore(input: {
  isMultipleChoice: boolean;
  isNoCorrectSingleChoice: boolean;
  maxScore: number;
  correctOptionsIndices: ReadonlySet<number>;
  selectedAnswersIndices: ReadonlySet<number>;
  selectedAnswerIndex: number;
}): number {
  if (input.isMultipleChoice) {
    if (input.selectedAnswersIndices.size === 0) return 0;
    const correctCount = input.correctOptionsIndices.size;
    if (correctCount === 0) return 0;
    const pointPerCorrect = input.maxScore / correctCount;
    let correctSelections = 0;
    let wrongSelections = 0;
    for (const index of input.selectedAnswersIndices) {
      if (input.correctOptionsIndices.has(index)) correctSelections++;
      else wrongSelections++;
    }
    const score =
      correctSelections * pointPerCorrect -
      wrongSelections * pointPerCorrect * 0.5;
    return clampScore(score, input.maxScore);
  }
  if (input.isNoCorrectSingleChoice) {
    return input.selectedAnswerIndex >= 0 ? input.maxScore : 0;
  }
  if (input.correctOptionsIndices.size === 0) return 0;
  // App chỉ so với đáp án đúng ĐẦU TIÊN khi tính điểm, dù kiểm tra đúng/sai
  // chấp nhận mọi đáp án đúng.
  const [correctIndex] = input.correctOptionsIndices;
  return input.selectedAnswerIndex === correctIndex ? input.maxScore : 0;
}

/** Gói hai hàm trên theo đúng cách `ChoiceCubit.checkAnswer` gọi chúng. */
export function gradeChoice(
  question: Question,
  selection: ChoiceSelection,
): { isCorrect: boolean; score: number } {
  const kind = questionKind(question);
  const correct = choiceCorrectIndices(question, selection.selectedAnswerIndex);
  const selected = new Set(selection.selectedAnswersIndices);
  const common = {
    isMultipleChoice: kind === 'multiple',
    isNoCorrectSingleChoice: kind === 'no_correct',
    selectedAnswerIndex: selection.selectedAnswerIndex,
    selectedAnswersIndices: selected,
    correctOptionsIndices: correct,
  };
  return {
    isCorrect: resolveChoiceCheckResult(common),
    score: calculateChoiceScore({ ...common, maxScore: question.maxScore }),
  };
}

export type ChoiceAnswerState =
  | 'normal'
  | 'selected'
  | 'correct'
  | 'incorrect'
  | 'disabled'
  | 'correctNotSelected';

/** `ChoiceStateExtension.getAnswerState`. */
export function choiceAnswerState(
  question: Question,
  selection: ChoiceSelection,
  hasChecked: boolean,
  index: number,
): ChoiceAnswerState {
  const kind = questionKind(question);
  const isMultiple = kind === 'multiple';
  const wasSelected = isMultiple
    ? selection.selectedAnswersIndices.includes(index)
    : selection.selectedAnswerIndex === index;
  if (!hasChecked) return wasSelected ? 'selected' : 'normal';
  if (kind === 'no_correct') return wasSelected ? 'correct' : 'disabled';
  const isCorrectOption = choiceCorrectIndices(
    question,
    selection.selectedAnswerIndex,
  ).has(index);
  if (isCorrectOption) {
    return isMultiple && !wasSelected ? 'correctNotSelected' : 'correct';
  }
  return wasSelected ? 'incorrect' : 'disabled';
}

/** `resolveNoCorrectAnswerDocumentGroup` — tài liệu đi kèm phương án đã chọn. */
export function noCorrectDocumentGroup(
  question: Question,
  selectedAnswerIndex: number,
): DocumentGroup | null {
  if (questionKind(question) !== 'no_correct') return null;
  const option = question.options[selectedAnswerIndex];
  if (!option) return null;
  const groupId = option.documentGroupId.trim();
  if (!groupId) return null;
  return question.documentGroups.find((group) => group.id === groupId) ?? null;
}

// ---------------------------------------------------------------------------
// BÀI TẬP KEYPOINT — điền chỗ trống (`DragAndDropCubit`, `DragAndDropState`)
// Trạng thái là "ô → chữ" đúng như app: so đáp án bằng CHUỖI, không bằng id.
// ---------------------------------------------------------------------------

export type PlacedWords = Readonly<Record<number, string>>;

export function gapDropZoneCount(question: Question): number {
  const answerCount = runtimeAnswers(question).length;
  if (answerCount === 0) return 0;
  const blankCount = targetAreaText(question).split('___').length - 1;
  if (blankCount <= 0) return answerCount;
  return Math.min(answerCount, blankCount);
}

export function gapIsAllFilled(question: Question, placed: PlacedWords): boolean {
  const required = gapDropZoneCount(question);
  if (required === 0) return false;
  for (let i = 0; i < required; i++) {
    if (!placed[i]) return false;
  }
  return true;
}

/** Ô trống ngoài cùng bên trái — chỗ một chữ được CHẠM sẽ rơi vào. */
export function gapFirstEmptySlot(
  question: Question,
  placed: PlacedWords,
): number | null {
  const count = gapDropZoneCount(question);
  for (let i = 0; i < count; i++) {
    if (placed[i] === undefined) return i;
  }
  return null;
}

export function checkGapFilling(question: Question, placed: PlacedWords): boolean {
  const answers = runtimeAnswers(question);
  for (let i = 0; i < answers.length; i++) {
    const placedAnswer = placed[i];
    if (placedAnswer === undefined || placedAnswer !== mlText(answers[i].correctAnswer)) {
      return false;
    }
  }
  return true;
}

/** Đúng 1 vị trí = điểm tối đa / số vị trí; sai không bị trừ. */
export function scoreGapFilling(question: Question, placed: PlacedWords): number {
  const answers = runtimeAnswers(question);
  if (Object.keys(placed).length === 0) return 0;
  const total = answers.length;
  if (total === 0) return 0;
  const perPosition = question.maxScore / total;
  let correct = 0;
  for (let i = 0; i < total; i++) {
    if (placed[i] === mlText(answers[i].correctAnswer)) correct++;
  }
  return clampScore(correct * perPosition, question.maxScore);
}

export type SlotState = 'normal' | 'correct' | 'incorrect';

export function gapSlotState(
  question: Question,
  placed: PlacedWords,
  hasChecked: boolean,
  index: number,
): SlotState {
  if (!hasChecked) return 'normal';
  const word = placed[index];
  const answer = runtimeAnswers(question)[index];
  if (!word || !answer) return 'normal';
  return word === mlText(answer.correctAnswer) ? 'correct' : 'incorrect';
}

// ---------------------------------------------------------------------------
// BÀI TẬP KEYPOINT — đặt dấu ngắt (`CuesPlacementCubit`) và đánh dấu từ
// (`MarkStressWordCubit`). Cả hai so TẬP vị trí, thứ tự không quan trọng.
// ---------------------------------------------------------------------------

/** `CuesPlacementStateX.words` / `MarkStressWordStateX.words` — tách theo MỘT dấu cách. */
export function lessonWords(question: Question): string[] {
  return targetAreaText(question).split(' ');
}

export function checkPositions(
  question: Question,
  selected: ReadonlySet<number>,
): boolean {
  return sameSet(selected, correctPositions(question));
}

/** Đúng 1 vị trí = điểm tối đa / số vị trí đúng; đặt sai không bị trừ. */
export function scorePositions(
  question: Question,
  selected: ReadonlySet<number>,
): number {
  const correct = correctPositions(question);
  if (selected.size === 0) return 0;
  if (correct.size === 0) return 0;
  const perPosition = question.maxScore / correct.size;
  let hits = 0;
  for (const position of selected) if (correct.has(position)) hits++;
  return clampScore(hits * perPosition, question.maxScore);
}

/** `CuesPlacementStateX.getPauseMarkState` (null = không vẽ dấu). */
export function cueMarkState(
  question: Question,
  placedPositions: ReadonlySet<number>,
  hasChecked: boolean,
  index: number,
): ChoiceAnswerState | null {
  const hasMark = placedPositions.has(index);
  if (!hasChecked) return hasMark ? 'selected' : null;
  const shouldHaveMark = correctPositions(question).has(index);
  if (hasMark && shouldHaveMark) return 'correct';
  if (hasMark) return 'incorrect';
  if (shouldHaveMark) return 'correctNotSelected';
  return null;
}

/** `MarkStressWordStateX.getWordState`. */
export function stressWordState(
  question: Question,
  selected: ReadonlySet<number>,
  hasChecked: boolean,
  index: number,
): ChoiceAnswerState {
  const isSelected = selected.has(index);
  if (!hasChecked) return isSelected ? 'selected' : 'normal';
  const isCorrect = correctPositions(question).has(index);
  if (isSelected && isCorrect) return 'correct';
  if (isSelected) return 'incorrect';
  if (isCorrect) return 'correctNotSelected';
  return 'disabled';
}

// ---------------------------------------------------------------------------
// BÀI TẬP KEYPOINT — sắp xếp thứ tự (`ArrangeTheSequenceCubit`)
// ---------------------------------------------------------------------------

/** `_answerLabel`: chữ của đáp án, rỗng thì lấy chữ phương án cùng id. */
export function arrangeCorrectOrder(question: Question): string[] {
  const options = runtimeOptions(question);
  return runtimeAnswers(question).map((answer) => {
    const own = mlText(answer.correctAnswer);
    if (own) return own;
    const match = options.find((option) => option.id === answer.id);
    return match ? optionLabel(match) : '';
  });
}

export function checkArrange(question: Question, currentLabels: readonly string[]): boolean {
  const correct = arrangeCorrectOrder(question);
  if (currentLabels.length !== correct.length) return false;
  return correct.every((label, index) => currentLabels[index] === label);
}

export function scoreArrange(question: Question, currentLabels: readonly string[]): number {
  const correct = arrangeCorrectOrder(question);
  if (currentLabels.length === 0) return 0;
  const total = correct.length;
  if (total === 0) return 0;
  const perPosition = question.maxScore / total;
  let hits = 0;
  for (let i = 0; i < total; i++) {
    if (i < currentLabels.length && currentLabels[i] === correct[i]) hits++;
  }
  return clampScore(hits * perPosition, question.maxScore);
}

export function arrangeItemState(
  question: Question,
  currentLabels: readonly string[],
  hasChecked: boolean,
  index: number,
): SlotState {
  if (!hasChecked) return 'normal';
  const correct = arrangeCorrectOrder(question);
  if (index >= currentLabels.length || index >= correct.length) return 'incorrect';
  return currentLabels[index] === correct[index] ? 'correct' : 'incorrect';
}

/** Vị trí (1-based) mà mục đang ở `index` lẽ ra phải đứng. */
export function arrangeCorrectPositionFor(
  question: Question,
  currentLabels: readonly string[],
  index: number,
): number | null {
  if (index < 0 || index >= currentLabels.length) return null;
  const position = arrangeCorrectOrder(question).indexOf(currentLabels[index]);
  return position < 0 ? null : position + 1;
}

// ---------------------------------------------------------------------------
// Câu phụ hỏi lại khi trả lời sai — `ExerciseCubit.addSubQuestionToLessonCubit`
// ---------------------------------------------------------------------------

export function findSubQuestion(
  subQuestions: readonly Question[],
  mainQuestionId: number,
): Question | null {
  const match = subQuestions.find((sub) => sub.mainQuestion === mainQuestionId);
  return match && match.id !== 0 ? match : null;
}

// ---------------------------------------------------------------------------
// Payload `PUT /courses-user-progress/exercises` — `progress_payload_mapper.dart`
// và `_updateUserProgressExercise` của từng cubit. Bỏ trường null y như
// `@JsonSerializable(includeIfNull: false)`.
// ---------------------------------------------------------------------------

export interface ProgressValue {
  en?: string;
  vi?: string;
}

export interface ProgressOption {
  value?: ProgressValue;
  isCorrect?: boolean;
}

export interface ProgressDragDropOption {
  id?: number;
  text?: ProgressValue;
}

export interface ExerciseProgressData {
  exerciseId: string;
  type: 'single_choice' | 'multiple_choice' | 'single_choice_no_correct_answer' | 'drag_drop';
  form?: string;
  passed: boolean;
  score: number;
  multipleAnswer?: ProgressOption[];
  singleAnswer?: ProgressOption;
  dragDropAnswer?: ProgressDragDropOption[];
}

/** Hình dạng `OptionEntity` mà mapper của app nhận. */
interface EntityOption {
  id: number;
  text: MultiLang;
  value: MultiLang;
  isCorrect: boolean;
}

const EMPTY_OPTION: EntityOption = { id: 0, text: {}, value: {}, isCorrect: false };

function progressValue(value: MultiLang): ProgressValue | null {
  const en = (value.en ?? '').trim();
  const vi = (value.vi ?? '').trim();
  if (!en && !vi) return null;
  const out: ProgressValue = {};
  if (en) out.en = en;
  if (vi) out.vi = vi;
  return out;
}

function hasEnViZh(value: MultiLang): boolean {
  return [value.en, value.vi, value.zh].some((part) => (part ?? '').trim() !== '');
}

function progressOption(option: EntityOption, forceIncorrect = false): ProgressOption | null {
  const value = progressValue(hasEnViZh(option.value) ? option.value : option.text);
  if (!value) return null;
  return { value, isCorrect: forceIncorrect ? false : option.isCorrect };
}

function progressDragDropList(
  options: readonly EntityOption[],
): ProgressDragDropOption[] | undefined {
  const mapped: ProgressDragDropOption[] = [];
  for (const option of options) {
    const text = progressValue(hasEnViZh(option.text) ? option.text : option.value);
    const hasId = option.id > 0;
    if (!hasId && !text) continue;
    const out: ProgressDragDropOption = {};
    if (hasId) out.id = option.id;
    if (text) out.text = text;
    mapped.push(out);
  }
  return mapped.length ? mapped : undefined;
}

/** `OptionEntity.withFallbackLabel`. */
function withFallbackLabel(option: EntityOption, fallback: string): EntityOption {
  const base: MultiLang = { en: fallback, vi: fallback, zh: fallback };
  return {
    id: option.id,
    text: mlText(option.text) ? option.text : base,
    value: mlText(option.value) ? option.value : base,
    isCorrect: option.isCorrect,
  };
}

function textOption(id: number, label: string): EntityOption {
  const value: MultiLang = { en: label, vi: label, zh: label };
  return { id, text: value, value, isCorrect: false };
}

export function buildChoiceProgress(
  question: Question,
  selection: ChoiceSelection,
  graded: { isCorrect: boolean; score: number },
): ExerciseProgressData {
  const kind = questionKind(question);
  const options = runtimeOptions(question);
  const data: ExerciseProgressData = {
    exerciseId: question.exerciseId,
    type:
      kind === 'no_correct'
        ? 'single_choice_no_correct_answer'
        : kind === 'multiple'
          ? 'multiple_choice'
          : 'single_choice',
    passed: graded.isCorrect,
    score: graded.score,
  };
  if (kind === 'multiple') {
    const picked = [...selection.selectedAnswersIndices]
      .sort((a, b) => a - b)
      .filter((index) => index >= 0 && index < options.length)
      .map((index) => progressOption(options[index]))
      .filter((option): option is ProgressOption => option !== null);
    if (picked.length) data.multipleAnswer = picked;
  } else {
    const option = options[selection.selectedAnswerIndex] ?? EMPTY_OPTION;
    const single = progressOption(option, kind === 'no_correct');
    if (single) data.singleAnswer = single;
  }
  return data;
}

function dragDropData(
  question: Question,
  graded: { isCorrect: boolean; score: number },
  answer: EntityOption[],
): ExerciseProgressData {
  const data: ExerciseProgressData = {
    exerciseId: question.exerciseId,
    type: 'drag_drop',
    form: question.form,
    passed: graded.isCorrect,
    score: graded.score,
  };
  const list = progressDragDropList(answer);
  if (list) data.dragDropAnswer = list;
  return data;
}

/** `DragAndDropCubit.toExerciseResult`: mỗi ô → phương án gốc khớp chữ (chưa dùng). */
export function buildGapFillingProgress(
  question: Question,
  placed: PlacedWords,
  graded: { isCorrect: boolean; score: number },
): ExerciseProgressData {
  const options = runtimeOptions(question);
  let totalSlots = runtimeAnswers(question).length;
  const placedKeys = Object.keys(placed).map(Number);
  if (totalSlots === 0 && placedKeys.length) totalSlots = Math.max(...placedKeys) + 1;
  const used = new Set<number>();
  const answer: EntityOption[] = [];
  for (let i = 0; i < totalSlots; i++) {
    const word = placed[i];
    if (!word) {
      answer.push(EMPTY_OPTION);
      continue;
    }
    const index = options.findIndex(
      (option, optionIndex) => !used.has(optionIndex) && optionLabel(option) === word,
    );
    if (index >= 0) used.add(index);
    answer.push(withFallbackLabel(index >= 0 ? options[index] : EMPTY_OPTION, word));
  }
  return dragDropData(question, graded, answer);
}

/** `CuesPlacementCubit.toExerciseResult`: id = id dấu, chữ = chỉ số từ (0-based). */
export function buildCuesProgress(
  question: Question,
  placedMarks: Readonly<Record<number, number>>,
  graded: { isCorrect: boolean; score: number },
): ExerciseProgressData {
  const answer = Object.entries(placedMarks)
    .map(([word, markId]) => [Number(word), markId] as const)
    .sort((a, b) => a[0] - b[0])
    .map(([word, markId]) => textOption(markId, String(word)));
  return dragDropData(question, graded, answer);
}

/** `MarkStressWordCubit.toExerciseResult`: id = chỉ số từ, chữ = chính từ đó. */
export function buildStressProgress(
  question: Question,
  selected: ReadonlySet<number>,
  graded: { isCorrect: boolean; score: number },
): ExerciseProgressData {
  const words = lessonWords(question);
  const answer = [...selected]
    .sort((a, b) => a - b)
    .filter((index) => index >= 0 && index < words.length)
    .map((index) => textOption(index, words[index]));
  return dragDropData(question, graded, answer);
}

/** `ArrangeTheSequenceCubit.toExerciseResult`: thứ tự hiện tại của các phương án. */
export function buildArrangeProgress(
  question: Question,
  currentItems: readonly RuntimeOption[],
  graded: { isCorrect: boolean; score: number },
): ExerciseProgressData {
  const answer = currentItems.map((item) => withFallbackLabel(item, optionLabel(item)));
  return dragDropData(question, graded, answer);
}

// ---------------------------------------------------------------------------
// KHỞI ĐỘNG / ÔN TẬP — `daily_warm_up_question_filter.dart` và
// `daily_warm_up_question_evaluator.dart` (dùng chung cho khởi động hằng ngày,
// khởi động khoá học và ôn tập ngắt quãng, đúng như app).
// ---------------------------------------------------------------------------

/** `_targetWords`: tách theo mọi khoảng trắng, bỏ từ rỗng. */
export function warmUpWords(question: Question): string[] {
  return mlText(question.targetArea)
    .split(/\s+/)
    .filter((word) => word.trim() !== '');
}

/** `_dailyWarmUpOptions`: chỉ phương án có id và có chữ. */
export function warmUpOptions(question: Question): RuntimeOption[] {
  return runtimeOptions(question).filter(
    (option) => option.id !== 0 && optionLabel(option).trim() !== '',
  );
}

function hasDragOptions(question: Question): boolean {
  return question.options.some(
    (option) => option.id !== 0 && mlText(dragPick(option)).trim() !== '',
  );
}

function hasUsableOrderedAnswers(question: Question): boolean {
  const answers = question.answer;
  if (answers.length === 0) return false;
  const optionIds = new Set(
    question.options.map((option) => option.id).filter((id) => id !== 0),
  );
  const labelCounts = new Map<string, number>();
  for (const option of question.options) {
    const label = mlText(dragPick(option)).trim();
    if (!label) continue;
    labelCounts.set(label, (labelCounts.get(label) ?? 0) + 1);
  }
  return answers.every((answer) => {
    if (answer.id !== 0 && optionIds.has(answer.id)) return true;
    const label = mlText(answer.correctAnswer).trim();
    return label !== '' && labelCounts.get(label) === 1;
  });
}

function hasPositionPayload(question: Question): boolean {
  const words = warmUpWords(question);
  if (words.length === 0 || question.answer.length === 0 || !hasDragOptions(question)) {
    return false;
  }
  return question.answer.every((answer) => {
    const position = parseDartInt(mlText(answer.correctAnswer).trim());
    return position !== null && position > 0 && position <= words.length;
  });
}

/** `isUsableDailyWarmUpQuestion` — câu nào trình khởi động vẽ được. */
export function isUsableWarmUpQuestion(question: Question): boolean {
  const text = questionText(question);
  const renderable =
    (text.trim() !== '' && text !== 'No question text') ||
    mlText(question.speechBubble).trim() !== '';
  if (!renderable) return false;

  switch (questionKind(question)) {
    case 'single':
    case 'multiple': {
      const visible = question.options.filter(
        (option) => mlText(choicePick(option)).trim() !== '',
      );
      return visible.length > 0 && visible.some((option) => option.isCorrect);
    }
    case 'no_correct':
      return question.options.some(
        (option) => mlText(choicePick(option)).trim() !== '',
      );
    case 'gap_filling':
      return (
        mlText(question.targetArea).trim() !== '' &&
        hasDragOptions(question) &&
        hasUsableOrderedAnswers(question)
      );
    case 'arrange':
      return hasDragOptions(question) && hasUsableOrderedAnswers(question);
    case 'cues':
    case 'stress':
      return hasPositionPayload(question);
    default:
      return false;
  }
}

export function filterUsableWarmUpQuestions(questions: readonly Question[]): Question[] {
  return questions.filter(isUsableWarmUpQuestion);
}

export type WarmUpResultType = 'correct' | 'incorrect' | 'neutral' | 'unsupported';

export interface WarmUpResult {
  questionId: number;
  questionIndex: number;
  type: WarmUpResultType;
  isCorrect: boolean;
  selectedIndices: number[];
  correctIndices: number[];
  selectedOptionIds: number[];
  correctOptionIds: number[];
}

/** Bài làm đang dở của một câu khởi động — các trường của `DailyWarmUpState`. */
export interface WarmUpDraft {
  selectedAnswerIndex: number;
  selectedAnswersIndices: number[];
  orderedOptionIds: number[];
  /** ô/từ → id phương án. */
  placedOptionIds: Record<number, number>;
  selectedWordIndices: number[];
}

export const EMPTY_WARM_UP_DRAFT: WarmUpDraft = {
  selectedAnswerIndex: -1,
  selectedAnswersIndices: [],
  orderedOptionIds: [],
  placedOptionIds: {},
  selectedWordIndices: [],
};

const sortNumbers = (values: Iterable<number>) => [...values].sort((a, b) => a - b);

function warmUpResult(
  question: Question,
  questionIndex: number,
  type: WarmUpResultType,
  isCorrect: boolean,
  extra: Partial<Pick<WarmUpResult, 'selectedIndices' | 'correctIndices' | 'selectedOptionIds' | 'correctOptionIds'>> = {},
): WarmUpResult {
  return {
    questionId: question.id,
    questionIndex,
    type,
    isCorrect,
    selectedIndices: extra.selectedIndices ?? [],
    correctIndices: extra.correctIndices ?? [],
    selectedOptionIds: extra.selectedOptionIds ?? [],
    correctOptionIds: extra.correctOptionIds ?? [],
  };
}

/** `_correctOrderedOptionIds`: id phương án theo đúng thứ tự đáp án, [] nếu mơ hồ. */
export function warmUpCorrectOptionIds(question: Question): number[] {
  const optionIds = new Set(
    question.options.map((option) => option.id).filter((id) => id !== 0),
  );
  const ids: number[] = [];
  for (const answer of question.answer) {
    if (answer.id !== 0 && optionIds.has(answer.id)) {
      ids.push(answer.id);
      continue;
    }
    const label = mlText(answer.correctAnswer).trim();
    if (!label) return [];
    const matches = question.options.filter(
      (option) => mlText(dragPick(option)).trim() === label && option.id !== 0,
    );
    if (matches.length !== 1) return [];
    ids.push(matches[0].id);
  }
  return ids;
}

function sameOrdered(a: readonly number[], b: readonly number[]): boolean {
  return a.length === b.length && a.every((value, index) => value === b[index]);
}

export function evaluateWarmUpQuestion(
  question: Question,
  draft: WarmUpDraft,
  questionIndex = 0,
): WarmUpResult {
  const kind = questionKind(question);
  switch (kind) {
    case 'single':
    case 'multiple': {
      const options = question.options;
      const correct = new Set<number>();
      options.forEach((option, index) => {
        if (option.isCorrect) correct.add(index);
      });
      const selected =
        kind === 'multiple'
          ? new Set(
              draft.selectedAnswersIndices.filter(
                (index) => index >= 0 && index < options.length,
              ),
            )
          : draft.selectedAnswerIndex >= 0 && draft.selectedAnswerIndex < options.length
            ? new Set([draft.selectedAnswerIndex])
            : new Set<number>();
      // Khác bài tập keypoint: ở đây phải chọn ĐÚNG và ĐỦ, thừa là sai.
      const isCorrect = sameSet(selected, correct);
      return warmUpResult(question, questionIndex, isCorrect ? 'correct' : 'incorrect', isCorrect, {
        selectedIndices: sortNumbers(selected),
        correctIndices: sortNumbers(correct),
      });
    }
    case 'no_correct': {
      const inRange =
        draft.selectedAnswerIndex >= 0 &&
        draft.selectedAnswerIndex < question.options.length;
      const selected = inRange ? [draft.selectedAnswerIndex] : [];
      return warmUpResult(
        question,
        questionIndex,
        selected.length ? 'neutral' : 'unsupported',
        selected.length > 0,
        { selectedIndices: selected, correctIndices: selected },
      );
    }
    case 'gap_filling':
    case 'arrange': {
      const ordered =
        kind === 'gap_filling'
          ? Object.entries(draft.placedOptionIds)
              .map(([slot, id]) => [Number(slot), id] as const)
              .sort((a, b) => a[0] - b[0])
              .map(([, id]) => id)
          : draft.orderedOptionIds;
      const correctIds = warmUpCorrectOptionIds(question);
      const isCorrect = correctIds.length > 0 && sameOrdered(ordered, correctIds);
      return warmUpResult(question, questionIndex, isCorrect ? 'correct' : 'incorrect', isCorrect, {
        selectedOptionIds: [...ordered],
        correctOptionIds: correctIds,
      });
    }
    case 'cues':
    case 'stress': {
      const selected = new Set(
        kind === 'cues'
          ? Object.keys(draft.placedOptionIds).map(Number)
          : draft.selectedWordIndices,
      );
      const correct = correctPositions(question);
      const isCorrect = correct.size > 0 && sameSet(selected, correct);
      return warmUpResult(question, questionIndex, isCorrect ? 'correct' : 'incorrect', isCorrect, {
        selectedIndices: sortNumbers(selected),
        correctIndices: sortNumbers(correct),
      });
    }
    default:
      return warmUpResult(question, questionIndex, 'unsupported', false);
  }
}

/** `canCheckCurrentQuestion` của ba cubit khởi động/ôn tập. */
export function canCheckWarmUp(question: Question, draft: WarmUpDraft): boolean {
  switch (questionKind(question)) {
    case 'single':
    case 'no_correct':
      return draft.selectedAnswerIndex >= 0;
    case 'multiple':
      return draft.selectedAnswersIndices.length > 0;
    case 'gap_filling':
      return (
        question.answer.length > 0 &&
        Object.keys(draft.placedOptionIds).length === question.answer.length
      );
    case 'arrange':
      // App chỉ ghi thứ tự khi người dùng kéo ít nhất một lần — chưa kéo thì
      // chưa kiểm tra được, kể cả khi thứ tự ban đầu tình cờ đã đúng.
      return (
        question.answer.length > 0 &&
        draft.orderedOptionIds.length === question.answer.length
      );
    case 'cues':
      return Object.keys(draft.placedOptionIds).length > 0;
    case 'stress':
      return draft.selectedWordIndices.length > 0;
    default:
      return false;
  }
}

/** `dailyWarmUpChoiceAnswerState`. */
export function warmUpChoiceState(
  question: Question,
  draft: WarmUpDraft,
  index: number,
  result: WarmUpResult | null,
): ChoiceAnswerState {
  const kind = questionKind(question);
  const isMultiple = kind === 'multiple';
  const wasSelected = isMultiple
    ? draft.selectedAnswersIndices.includes(index)
    : draft.selectedAnswerIndex === index;
  if (!result) return wasSelected ? 'selected' : 'normal';
  if (kind === 'no_correct') return wasSelected ? 'correct' : 'disabled';
  const isCorrectOption = result.correctIndices.includes(index);
  if (isCorrectOption && isMultiple && !wasSelected) return 'correctNotSelected';
  if (isCorrectOption) return 'correct';
  return wasSelected ? 'incorrect' : 'disabled';
}

// ---------------------------------------------------------------------------
// ÔN TẬP NGẮT QUÃNG — `SpacedReviewStateX`
// ---------------------------------------------------------------------------

/** Câu "trung lập" (không có đáp án đúng) được tính là nhớ. */
export function spacedCorrectCount(results: readonly WarmUpResult[]): number {
  return results.filter((result) => result.type !== 'incorrect').length;
}

/**
 * Kết quả theo keypoint để gửi `POST /spaced-review/answers`: chỉ keypoint đã
 * trả lời HẾT các câu của nó trong phiên; một câu sai là cả keypoint chưa nhớ.
 */
export function spacedAnsweredKeypointResults(
  results: readonly WarmUpResult[],
  questionKeypointIds: readonly string[],
): { keypointId: string; correct: boolean }[] {
  const answered = new Map<string, number>();
  const wrong = new Set<string>();
  for (let i = 0; i < results.length && i < questionKeypointIds.length; i++) {
    const keypointId = questionKeypointIds[i];
    answered.set(keypointId, (answered.get(keypointId) ?? 0) + 1);
    if (results[i].type === 'incorrect') wrong.add(keypointId);
  }
  const total = new Map<string, number>();
  for (const keypointId of questionKeypointIds) {
    total.set(keypointId, (total.get(keypointId) ?? 0) + 1);
  }
  const out: { keypointId: string; correct: boolean }[] = [];
  for (const [keypointId, count] of answered) {
    if (count >= (total.get(keypointId) ?? 0)) {
      out.push({ keypointId, correct: !wrong.has(keypointId) });
    }
  }
  return out;
}
