import {
  MEMORY_RECALL_MIN_KEYWORD_CHARS,
} from '../../shared/coach.constant';

/**
 * TRA CỨU — nhận ra lúc người ta hỏi thẳng về quá khứ của chính họ.
 *
 * Thẻ nhớ trả lời được phần lớn ("bạn đang muốn gì", "dạo này thế nào"), nhưng
 * nó là bản cô đọng: câu "còn nhớ hôm trước mình kể gì không" cần ĐÚNG CHỮ họ
 * đã nói, mà chữ đó nằm ở log thô. Nhận ra bằng regex ở server chứ không hỏi
 * model, vì một call phân loại nữa là thêm một giây vào lượt mà người ta đang
 * chờ — và việc này regex làm được.
 *
 * Hai mức, và sự tách ra là toàn bộ độ chính xác của file này:
 *
 * - MẠNH: tự nó đã là câu hỏi về quá khứ ("còn nhớ", "tôi từng", "biết gì về
 *   mình"). Không cần dấu hỏi.
 * - YẾU: chỉ là một mốc thời gian ("hôm trước", "lần trước"). Người ta nhắc mốc
 *   thời gian suốt trong lúc KỂ ("hôm trước tôi đi ăn với nó") — đó là kể, không
 *   phải hỏi. Nên mức này chỉ tính khi trong câu có dấu hỏi.
 *
 * Neo bằng `[^\p{L}]` chứ không bằng `\b`: `\b` của JS dựng trên `\w` ASCII nên
 * với chữ có dấu nó đặt ranh giới ở giữa từ. Bẫy này đã cắn `routeHub` một lần
 * — regex không neo bắt oan "trường hợp", "tập trung".
 */

const STRONG_PATTERNS: RegExp[] = [
  /(?:^|[^\p{L}])(?:còn|có)\s+nhớ(?=$|[^\p{L}])/iu,
  /(?:^|[^\p{L}])nhớ\s+(?:không|ko|hông|hem)(?=$|[^\p{L}])/iu,
  /(?:^|[^\p{L}])(?:tôi|mình|em|anh|chị|tớ|t)\s+(?:đã\s+)?từng(?=$|[^\p{L}])/iu,
  /(?:^|[^\p{L}])(?:tôi|mình|em|anh|chị|tớ)\s+(?:đã\s+)?(?:nói|kể)\s+gì(?=$|[^\p{L}])/iu,
  /(?:^|[^\p{L}])biết\s+gì\s+về(?=$|[^\p{L}])/iu,
  /(?:^|[^\p{L}])(?:do\s+you\s+remember|did\s+i\s+tell|i\s+told\s+you|what\s+did\s+i\s+(?:say|tell))(?=$|[^\p{L}])/iu,
];

const WEAK_PATTERNS: RegExp[] = [
  /(?:^|[^\p{L}])(?:lần|hôm|bữa|tuần|tháng)\s+(?:trước|nọ|rồi)(?=$|[^\p{L}])/iu,
  /(?:^|[^\p{L}])(?:last\s+time|earlier|before)(?=$|[^\p{L}])/iu,
];

/**
 * Chỉ vi/en. Ba locale còn lại (zh/ja/ko) rơi về thẻ nhớ — thẻ vẫn trả lời được
 * phần lớn câu hỏi, chỉ là không có chữ nguyên văn. Viết ra ở đây thay vì để
 * người đọc sau tự phát hiện.
 */
export function looksLikeRecallQuestion(text: string | null | undefined): boolean {
  const line = (text ?? '').trim();
  if (!line) return false;

  if (STRONG_PATTERNS.some((pattern) => pattern.test(line))) return true;

  return (
    /[?？]/.test(line) && WEAK_PATTERNS.some((pattern) => pattern.test(line))
  );
}

/**
 * Những chữ mang nội dung trong câu hỏi, để dò trong log thô.
 *
 * Bỏ đại từ, hư từ và chính mấy chữ đã dùng để NHẬN RA câu hỏi ("nhớ", "từng"):
 * chúng có trong mọi câu hỏi loại này nên dò theo chúng thì trả về mọi thứ.
 */
const STOPWORDS = new Set([
  'còn','có','nhớ','không','ko','hông','hem','tôi','mình','em','anh','chị','tớ',
  'đã','từng','kể','nói','gì','về','biết','cái','chuyện','hôm','bữa','lần',
  'tuần','tháng','trước','nọ','rồi','là','mà','thì','với','cho','của','ạ','nhỉ',
  'nhé','vậy','thế','nào','đó','này','các','những','một','và','hay','bạn','ấy',
  'do','you','remember','did','i','tell','told','what','say','the','a','an','me',
  'my','about','last','time','earlier','before','was','were','is','it','that',
]);

export function recallKeywords(text: string | null | undefined, max = 4): string[] {
  const words = (text ?? '')
    .toLowerCase()
    .split(/[^\p{L}\p{N}]+/u)
    .filter(
      (word) =>
        word.length >= MEMORY_RECALL_MIN_KEYWORD_CHARS && !STOPWORDS.has(word),
    );

  // Giữ thứ tự xuất hiện: chữ đầu tiên người ta viết thường là chủ đề.
  return [...new Set(words)].slice(0, max);
}
