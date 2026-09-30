/**
 * "Đã đổi cái gì" — tính bằng cách so với chính lần lưu TRƯỚC của khu vực đó.
 *
 * Một dòng nhật ký lưu nguyên nội dung đã gửi lên, và đó là thứ biên tập viên
 * KHÔNG đọc được: mở ra là một trang JSON. Câu họ thật sự hỏi luôn là "ai vừa
 * đổi cái gì", mà cái đó cần trạng thái TRƯỚC.
 *
 * Interceptor không biết trạng thái trước — nó chỉ thấy request. Nhưng nhật ký
 * thì có: lần lưu trước của cùng một đường dẫn CHÍNH LÀ trạng thái trước, đã
 * nằm sẵn trong bảng. Nên không phải sửa module nào, không phải chụp thêm gì,
 * và nó đúng với mọi khu vực kể cả khu vực viết sau này.
 *
 * Giới hạn phải nói thẳng: lần lưu ĐẦU TIÊN của một khu vực không có gì để so,
 * và nếu ai đó sửa thẳng vào database thì nhật ký không thấy. Giao diện nói rõ
 * cả hai chứ không giả vờ là đã so được.
 */

/** Số thay đổi nhiều nhất đem ra hiển thị — quá ngần này thì không ai đọc nữa. */
const MAX_CHANGES = 200;

export interface AuditChange {
  /** Đường dẫn tới trường, ví dụ `hotlines[0].number`. */
  field: string;
  before: unknown;
  after: unknown;
}

/**
 * Trải một object thành bản đồ `đường.dẫn -> giá trị lá`.
 *
 * Mảng đánh chỉ số, vì "phần tử thứ hai của hotlines đổi số điện thoại" là
 * điều đọc được, còn "mảng hotlines đổi" thì không.
 */
function flatten(
  value: unknown,
  prefix = '',
  out: Record<string, unknown> = {},
): Record<string, unknown> {
  if (value === null || typeof value !== 'object') {
    out[prefix] = value;

    return out;
  }

  if (Array.isArray(value)) {
    // Mảng rỗng là một giá trị có nghĩa ("đã xoá hết"), không phải không có gì.
    if (value.length === 0) out[prefix] = [];
    value.forEach((item, index) => flatten(item, `${prefix}[${index}]`, out));

    return out;
  }

  const entries = Object.entries(value as Record<string, unknown>);
  if (entries.length === 0) out[prefix] = {};
  for (const [key, child] of entries) {
    flatten(child, prefix ? `${prefix}.${key}` : key, out);
  }

  return out;
}

function parse(raw: string): unknown {
  try {
    return JSON.parse(raw);
  } catch {
    return undefined;
  }
}

const same = (a: unknown, b: unknown) =>
  JSON.stringify(a ?? null) === JSON.stringify(b ?? null);

/**
 * Những trường khác nhau giữa hai lần lưu.
 *
 * Trả về mảng RỖNG khi hai lần giống hệt — và đó là một câu trả lời thật, có
 * nghĩa là "có người bấm lưu mà không đổi gì", chứ không phải là không so được.
 * Trả về `null` khi không so được (không có bản trước, hoặc nội dung đã bị cắt
 * nên so sẽ ra kết quả bịa).
 */
export function diffBodies(
  beforeRaw: string | null | undefined,
  afterRaw: string | null | undefined,
  options: { beforeTruncated?: boolean; afterTruncated?: boolean } = {},
): AuditChange[] | null {
  if (!beforeRaw || !afterRaw) return null;
  // Nội dung bị cắt thì phần đuôi thiếu sẽ hiện ra như "đã xoá" — thà không so
  // còn hơn so ra một danh sách thay đổi không có thật.
  if (options.beforeTruncated || options.afterTruncated) return null;

  const before = parse(beforeRaw);
  const after = parse(afterRaw);
  if (before === undefined || after === undefined) return null;

  const flatBefore = flatten(before);
  const flatAfter = flatten(after);
  const fields = new Set([...Object.keys(flatBefore), ...Object.keys(flatAfter)]);

  const changes: AuditChange[] = [];
  for (const field of [...fields].sort()) {
    if (same(flatBefore[field], flatAfter[field])) continue;
    changes.push({
      field,
      before: flatBefore[field],
      after: flatAfter[field],
    });
    if (changes.length >= MAX_CHANGES) break;
  }

  return changes;
}
