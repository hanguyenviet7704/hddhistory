/**
 * Dựng câu mẫu cho phần "Câu trả lời đúng" — bản chép `_dragSentenceSpans` và
 * `_positionSentenceSpans` của `daily_warm_up_result_explanation_content.dart`
 * (tấm kết quả bài tập keypoint dựng câu theo cùng cách).
 */
export interface Span {
  text: string;
  strong: boolean;
}

/** Điền đáp án vào các chỗ `___`. */
export function gapSpans(targetArea: string, answers: string[]): Span[] {
  const spans: Span[] = [];
  const parts = targetArea.split('___');
  parts.forEach((part, index) => {
    if (part) spans.push({ text: part, strong: false });
    if (index < answers.length) spans.push({ text: answers[index], strong: true });
  });
  return spans;
}

/** Tô đậm các từ ở vị trí đúng; dấu ngắt thêm hậu tố, trọng âm viết HOA. */
export function positionSpans(
  words: string[],
  correctIndices: Iterable<number>,
  options: { suffix?: string; uppercase?: boolean } = {},
): Span[] {
  const correct = new Set(correctIndices);
  const spans: Span[] = [];
  words.forEach((word, index) => {
    const marked = correct.has(index);
    const shown = marked && options.uppercase ? word.toUpperCase() : word;
    spans.push({ text: `${shown}${marked ? (options.suffix ?? '') : ''}`, strong: marked });
    if (index < words.length - 1) spans.push({ text: ' ', strong: false });
  });
  return spans;
}
