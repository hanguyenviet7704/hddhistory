import { TemplateSheetDef } from './excel-import.util';

/**
 * Sheet `_VERSION` — trang đầu của mọi workbook xuất ra, để người sửa nội dung
 * trên Google Sheet biết mình đang sửa cái gì.
 *
 * VÌ SAO CẦN. Vòng làm việc thật là: mở sheet trên Drive, sửa, bấm sync. Nhưng
 * sync CHỈ ghi vào bản đang sửa — người học vẫn đọc tag đang phát hành cho tới
 * khi có người đánh tag mới. API vẫn trả hai header `X-Touched-Courses` và
 * `X-Auto-Tagged` để nói điều đó, nhưng người làm việc trên Drive không bao
 * giờ thấy header. Nên trước khi có sheet này, trạng thái "đã sửa nhưng chưa
 * live" là hoàn toàn vô hình đúng ở nơi người ta đang làm việc.
 *
 * CHỈ ĐỌC. Không có ô nào để điền: một cái tag gõ vào spreadsheet mà phát hành
 * được là một cú phát hành do gõ nhầm. Muốn phát hành thì sang trang Course →
 * Phiên bản, hoặc bấm sync có bật autoTag.
 *
 * Tên bắt đầu bằng `_` và không nằm trong danh sách sheet nội dung, nên import
 * bỏ qua nó — `getSheet` tra THEO TÊN và không có fallback về sheet đầu tiên
 * (đã kiểm), nên đặt sheet này lên đầu là an toàn.
 */
export const VERSION_SHEET = '_VERSION';

/** Một tag trong lịch sử khoá. */
export interface VersionHistoryEntry {
  tag: string;
  createdAt: Date | null;
  note?: string | null;
  /**
   * Tag này đã từng được phục vụ chưa. Đọc từ sổ `course_version_activations`.
   * Phân biệt "đóng băng nhưng chưa bao giờ live" với "đã live rồi thôi" —
   * hai thứ trông giống nhau trên bảng tag mà ý nghĩa hoàn toàn khác.
   *
   * `null` = KHÔNG BIẾT, dành cho tag được đánh trước khi sổ tồn tại. Phải là
   * ba trạng thái chứ không hai: gộp "không biết" vào "chưa phát hành" là in
   * một câu sai về lịch sử khoá lên đúng chỗ người ta tin nó nhất.
   */
  everPublished: boolean | null;
}

export interface VersionSheetFacts {
  courseTitle: string;
  /** Tag khoá đang phục vụ. `null` = khoá chưa có tag nào. */
  liveTag: string | null;
  /** Tag của nội dung TRONG file này. `null` = bản đang sửa. */
  contentTag: string | null;
  exportedAt: Date;
  /**
   * Tag vừa được đánh trong lần sync này. Chỉ có khi autoTag bật và import
   * sạch lỗi — nên dòng này VẮNG hẳn thay vì để trống, vì một ô trống cạnh
   * nhãn "đã phát hành" đọc ra như là đã phát hành rồi.
   */
  publishedAs?: string | null;
  /**
   * MỌI tag của khoá, mới nhất trước. Có mặt vì câu hỏi đầu tiên của người mở
   * sheet không phải "file này là bản nào" mà "khoá này có mấy bản, và bản nào
   * đang chạy" — không thấy cả danh sách thì phải mở trang admin mới trả lời
   * được, và thế là mất luôn lý do để sheet nói về phiên bản.
   */
  history?: VersionHistoryEntry[];
}

const NO_TAG = 'chưa có tag nào';
const DRAFT = 'bản đang sửa (nháp)';

const formatAt = (at: Date): string =>
  `${String(at.getDate()).padStart(2, '0')}/${String(
    at.getMonth() + 1,
  ).padStart(2, '0')}/${at.getFullYear()} ${String(at.getHours()).padStart(
    2,
    '0',
  )}:${String(at.getMinutes()).padStart(2, '0')}`;

/**
 * Dòng "Tình trạng" là dòng duy nhất người ta thật sự đọc, nên nó phải trả lời
 * đúng một câu: nội dung trong file này có phải thứ người học đang đọc không.
 */
const statusOf = (facts: VersionSheetFacts): string => {
  const { liveTag, contentTag } = facts;

  if (!liveTag) {
    return 'Khoá chưa có tag nào — người học đang đọc trực tiếp bản đang sửa, nên mỗi lần sync là đổi luôn nội dung họ thấy.';
  }
  if (!contentTag) {
    return `File này là bản đang sửa (nháp). Người học vẫn đọc ${liveTag} cho tới khi có người đánh tag mới.`;
  }
  if (contentTag === liveTag) {
    return `File này ĐÚNG bằng nội dung người học đang đọc (${liveTag}).`;
  }

  return `File này là bản đã đóng băng ${contentTag}, KHÁC bản người học đang đọc (${liveTag}).`;
};

const HISTORY_HEADING = 'Lịch sử phiên bản';

/**
 * Trạng thái của một tag trong bảng lịch sử. Ba trạng thái, không phải hai:
 * một tag đóng băng mà chưa bao giờ được phục vụ là thứ KHÁC với một tag đã
 * live rồi bị thay — nhìn vào chỉ thấy "không phải bản đang chạy" thì không
 * biết nó đã từng tới tay người học hay chưa.
 */
const historyStatus = (
  entry: VersionHistoryEntry,
  facts: VersionSheetFacts,
): string => {
  const parts: string[] = [];

  if (entry.tag === facts.liveTag) parts.push('ĐANG PHÁT HÀNH');
  else if (entry.everPublished === true) parts.push('đã từng phát hành');
  else if (entry.everPublished === false) parts.push('chưa phát hành');
  else parts.push('chưa rõ (đánh trước khi có sổ ghi phát hành)');

  // Chỉ đánh dấu khi file này ĐÚNG là một tag; file nháp thì không dòng nào
  // được nhận là nó, vì nháp không phải bản nào trong danh sách.
  if (facts.contentTag && entry.tag === facts.contentTag) {
    parts.push('nội dung trong file này');
  }

  return parts.join(' · ');
};

export const versionSheetRows = (facts: VersionSheetFacts): string[][] => {
  const rows: string[][] = [
    ['Khoá', facts.courseTitle || '(không tên)'],
    ['Đang phát hành', facts.liveTag ?? NO_TAG],
    ['Nội dung trong file này', facts.contentTag ?? DRAFT],
    ['Xuất lúc', formatAt(facts.exportedAt)],
    ['Tình trạng', statusOf(facts)],
  ];

  if (facts.publishedAs) {
    rows.push([
      'Lần sync vừa rồi',
      `đã phát hành thành ${facts.publishedAs} — người học đang đọc bản này.`,
    ]);
  }

  rows.push([
    'Lưu ý',
    'Sửa file này chỉ ghi vào bản nháp. Muốn người học thấy thì phải đánh tag ở trang Course → Phiên bản, hoặc bấm sync có bật autoTag.',
  ]);

  const history = facts.history ?? [];
  if (history.length) {
    rows.push([HISTORY_HEADING, `${history.length} bản`]);
    rows.push(['Tag', 'Đánh lúc', 'Ghi chú', 'Trạng thái']);
    for (const entry of history) {
      rows.push([
        entry.tag,
        entry.createdAt ? formatAt(entry.createdAt) : '—',
        entry.note || '—',
        historyStatus(entry, facts),
      ]);
    }
  }

  return rows;
};

export const buildVersionSheet = (
  facts: VersionSheetFacts,
): TemplateSheetDef => ({
  sheetName: VERSION_SHEET,
  // Bốn cột vì khối lịch sử cần bốn; khối thông tin ở trên chỉ dùng hai cột
  // đầu và để trống hai cột sau — ExcelJS cho phép dòng ngắn hơn header.
  headers: ['Thông tin', 'Giá trị', '', ''],
  sampleRows: versionSheetRows(facts),
});
