import * as ExcelJS from 'exceljs';

import { getRows, getSheet } from './excel-import.util';
import {
  VERSION_SHEET,
  buildVersionSheet,
  versionSheetRows,
} from './version-sheet';

const at = new Date('2026-09-09T03:09:00Z');

/** Ba bản: v1.0.2 đang live, v1.0.1 từng live, v1.0.0 đóng băng chưa từng live. */
const HISTORY = [
  {
    tag: 'v1.0.2',
    createdAt: new Date('2026-09-05T07:20:00Z'),
    note: 'gộp bài 2',
    everPublished: true,
  },
  {
    tag: 'v1.0.1',
    createdAt: new Date('2026-09-03T02:10:00Z'),
    note: 'thêm micro-action',
    everPublished: true,
  },
  {
    tag: 'v1.0.0',
    createdAt: new Date('2026-09-01T01:00:00Z'),
    note: 'bản phát hành đầu tiên',
    everPublished: false,
  },
];

/** Đọc giá trị của một dòng theo nhãn, để test không phụ thuộc thứ tự dòng. */
const value = (rows: string[][], label: string) =>
  rows.find(row => row[0] === label)?.[1] ?? null;

describe('buildVersionSheet', () => {
  it('có bốn cột — khối lịch sử cần đủ bốn', () => {
    const def = buildVersionSheet({
      courseTitle: 'Ghi chú đúng cách',
      liveTag: 'v1.0.2',
      contentTag: 'v1.0.2',
      exportedAt: at,
      history: HISTORY,
    });

    expect(def.sheetName).toBe(VERSION_SHEET);
    expect(def.headers).toHaveLength(4);
    // Khối thông tin ở trên chỉ dùng hai cột đầu.
    expect(def.sampleRows?.[0]).toHaveLength(2);
    // Khối lịch sử dùng cả bốn.
    expect(def.sampleRows?.find(row => row[0] === 'v1.0.2')).toHaveLength(4);
  });

  it('tên sheet bắt đầu bằng _ nên import bỏ qua', () => {
    // Import tra sheet THEO TÊN ('courses', 'lessons', ...), nên mọi sheet
    // ngoài danh sách đó đều bị bỏ qua. Dấu _ chỉ để người đọc thấy ngay đây
    // không phải sheet nội dung.
    expect(VERSION_SHEET.startsWith('_')).toBe(true);
    expect(
      ['courses', 'lessons', 'keypoints', 'theories', 'exercises', 'roadmap'],
    ).not.toContain(VERSION_SHEET);
  });
});

describe('versionSheetRows', () => {
  it('nói rõ khi file đúng bằng nội dung người học đang đọc', () => {
    const rows = versionSheetRows({
      courseTitle: 'Ghi chú đúng cách',
      liveTag: 'v1.0.3',
      contentTag: 'v1.0.3',
      exportedAt: at,
    });

    expect(value(rows, 'Khoá')).toBe('Ghi chú đúng cách');
    expect(value(rows, 'Đang phát hành')).toBe('v1.0.3');
    expect(value(rows, 'Nội dung trong file này')).toBe('v1.0.3');
    expect(value(rows, 'Tình trạng')).toMatch(/ĐÚNG bằng nội dung người học/);
  });

  it('cảnh báo khi file là một tag KHÁC bản đang phát hành', () => {
    const rows = versionSheetRows({
      courseTitle: 'Ghi chú đúng cách',
      liveTag: 'v1.0.3',
      contentTag: 'v1.0.1',
      exportedAt: at,
    });

    const status = value(rows, 'Tình trạng') ?? '';
    expect(status).toMatch(/v1\.0\.1/);
    expect(status).toMatch(/v1\.0\.3/);
    expect(status).toMatch(/KHÁC/);
  });

  it('nói rõ nháp chưa tới người học khi file là bản đang sửa', () => {
    const rows = versionSheetRows({
      courseTitle: 'Ghi chú đúng cách',
      liveTag: 'v1.0.3',
      contentTag: null,
      exportedAt: at,
    });

    expect(value(rows, 'Nội dung trong file này')).toMatch(/nháp/i);
    const status = value(rows, 'Tình trạng') ?? '';
    expect(status).toMatch(/v1\.0\.3/);
    expect(status).toMatch(/nháp/i);
  });

  it('khoá chưa có tag nào thì nói người học đang đọc trực tiếp bản sửa', () => {
    const rows = versionSheetRows({
      courseTitle: 'Khoá mới',
      liveTag: null,
      contentTag: null,
      exportedAt: at,
    });

    expect(value(rows, 'Đang phát hành')).toMatch(/chưa có tag/i);
    expect(value(rows, 'Tình trạng')).toMatch(/trực tiếp bản đang sửa/i);
  });

  it('sau khi sync có đánh tag thì báo đã phát hành thành tag nào', () => {
    const rows = versionSheetRows({
      courseTitle: 'Ghi chú đúng cách',
      liveTag: 'v1.0.4',
      contentTag: null,
      exportedAt: at,
      publishedAs: 'v1.0.4',
    });

    expect(value(rows, 'Lần sync vừa rồi')).toMatch(/v1\.0\.4/);
  });

  it('không sync thì KHÔNG có dòng đó, thay vì để trống gây tưởng đã phát hành', () => {
    const rows = versionSheetRows({
      courseTitle: 'Ghi chú đúng cách',
      liveTag: 'v1.0.3',
      contentTag: null,
      exportedAt: at,
    });

    expect(rows.some(row => row[0] === 'Lần sync vừa rồi')).toBe(false);
  });

  it('luôn có dòng nhắc rằng sửa file chỉ ghi vào nháp', () => {
    const rows = versionSheetRows({
      courseTitle: 'Ghi chú đúng cách',
      liveTag: 'v1.0.3',
      contentTag: 'v1.0.3',
      exportedAt: at,
    });

    expect(value(rows, 'Lưu ý')).toMatch(/chỉ ghi vào bản nháp/i);
    expect(value(rows, 'Lưu ý')).toMatch(/đánh tag/i);
  });

  it('mọi ô đều là chữ — sheet này chỉ để đọc, không có ô nào để điền', () => {
    const rows = versionSheetRows({
      courseTitle: 'Ghi chú đúng cách',
      liveTag: 'v1.0.2',
      contentTag: 'v1.0.1',
      exportedAt: at,
      publishedAs: 'v1.0.2',
      history: HISTORY,
    });

    for (const row of rows) {
      for (const cell of row) expect(typeof cell).toBe('string');
      // Không dòng nào kết thúc bằng một ô rỗng dùng làm chỗ điền.
      expect(row[row.length - 1]).not.toBe('');
    }
  });

  it('liệt kê ĐỦ mọi phiên bản của khoá, mới nhất trước', () => {
    const rows = versionSheetRows({
      courseTitle: 'Ghi chú đúng cách',
      liveTag: 'v1.0.2',
      contentTag: 'v1.0.1',
      exportedAt: at,
      history: HISTORY,
    });

    const tags = rows.filter(row => /^v\d/.test(row[0])).map(row => row[0]);
    expect(tags).toEqual(['v1.0.2', 'v1.0.1', 'v1.0.0']);
  });

  it('mỗi dòng lịch sử mang ngày đánh tag và ghi chú', () => {
    const rows = versionSheetRows({
      courseTitle: 'Ghi chú đúng cách',
      liveTag: 'v1.0.2',
      contentTag: null,
      exportedAt: at,
      history: HISTORY,
    });

    const row = rows.find(r => r[0] === 'v1.0.1')!;
    expect(row[1]).toBe('03/09/2026 09:10');
    expect(row[2]).toBe('thêm micro-action');
  });

  it('đánh dấu bản đang phát hành, bản đã từng, và bản chưa phát hành', () => {
    const rows = versionSheetRows({
      courseTitle: 'Ghi chú đúng cách',
      liveTag: 'v1.0.2',
      contentTag: null,
      exportedAt: at,
      history: HISTORY,
    });

    const statusOf = (tag: string) =>
      rows.find(r => r[0] === tag)?.[3] ?? '';

    expect(statusOf('v1.0.2')).toMatch(/ĐANG PHÁT HÀNH/);
    expect(statusOf('v1.0.1')).toMatch(/đã từng phát hành/);
    expect(statusOf('v1.0.0')).toMatch(/chưa phát hành/);
  });

  it('chỉ ra dòng nào là nội dung trong file này', () => {
    const rows = versionSheetRows({
      courseTitle: 'Ghi chú đúng cách',
      liveTag: 'v1.0.2',
      contentTag: 'v1.0.1',
      exportedAt: at,
      history: HISTORY,
    });

    expect(rows.find(r => r[0] === 'v1.0.1')?.[3]).toMatch(/file này/);
    expect(rows.find(r => r[0] === 'v1.0.2')?.[3]).not.toMatch(/file này/);
  });

  it('file là bản NHÁP thì không dòng lịch sử nào bị nhận là file này', () => {
    const rows = versionSheetRows({
      courseTitle: 'Ghi chú đúng cách',
      liveTag: 'v1.0.2',
      contentTag: null,
      exportedAt: at,
      history: HISTORY,
    });

    expect(rows.filter(r => (r[3] ?? '').includes('file này'))).toHaveLength(0);
  });

  it('everPublished = null hiện "chưa rõ", KHÔNG hiện "chưa phát hành"', () => {
    // Sổ cửa sổ chỉ có từ khi tính năng lên, nên tag cũ hơn mốc đó là KHÔNG
    // BIẾT. In "chưa phát hành" vào đó là nói sai về lịch sử khoá — đúng loại
    // lỗi mà cả sheet này sinh ra để tránh.
    const rows = versionSheetRows({
      courseTitle: 'Ghi chú đúng cách',
      liveTag: 'v1.0.2',
      contentTag: null,
      exportedAt: at,
      history: [
        { tag: 'v1.0.2', createdAt: null, note: null, everPublished: true },
        { tag: 'v0.9.0', createdAt: null, note: null, everPublished: null },
      ],
    });

    const status = rows.find(r => r[0] === 'v0.9.0')?.[3] ?? '';
    expect(status).toMatch(/chưa rõ/i);
    expect(status).not.toMatch(/chưa phát hành/i);
  });

  it('khoá chưa có tag nào thì không dựng khối lịch sử rỗng', () => {
    const rows = versionSheetRows({
      courseTitle: 'Khoá mới',
      liveTag: null,
      contentTag: null,
      exportedAt: at,
      history: [],
    });

    expect(rows.some(row => row[0] === 'Lịch sử phiên bản')).toBe(false);
  });
});

/**
 * Sheet lạ nằm ở vị trí ĐẦU TIÊN là chỗ dễ gãy nhất: nếu ở đâu đó có
 * `worksheets[0]` hoặc một fallback "không thấy tên thì lấy sheet đầu" thì
 * `_VERSION` sẽ bị đọc như sheet nội dung và cả import sẽ sai một cách im
 * lặng. Test này đi qua đúng `getSheet`/`getRows` mà import dùng.
 *
 * Workbook dựng bằng ExcelJS trực tiếp chứ không qua
 * `createMultiSheetTemplateWorkbook`: hàm đó dùng `import ExcelJS from` (default
 * import), mà `tsconfig.json` — cái ts-jest đọc — chỉ bật
 * `allowSyntheticDefaultImports` chứ KHÔNG bật `esModuleInterop` (chỉ
 * `tsconfig.build.json` bật). Nên dưới jest nó biên dịch thành
 * `require('exceljs').default` = undefined. Chạy thật thì đúng; gọi từ spec thì
 * nổ. Không sửa tsconfig ở đây vì đổi cách biên dịch của cả repo.
 */
describe('_VERSION trong workbook thật', () => {
  const workbookWithVersionFirst = () => {
    const workbook = new ExcelJS.Workbook();

    const def = buildVersionSheet({
      courseTitle: 'Ghi chú đúng cách',
      liveTag: 'v1.0.3',
      contentTag: null,
      exportedAt: at,
    });
    const versionSheet = workbook.addWorksheet(def.sheetName);
    versionSheet.addRow(def.headers);
    for (const row of def.sampleRows ?? []) versionSheet.addRow(row);

    const courses = workbook.addWorksheet('courses');
    courses.addRow(['id', 'course_key', 'title_vi']);
    courses.addRow(['68c1', 'k1', 'Ghi chú đúng cách']);

    return workbook;
  };

  it('đứng đầu workbook', () => {
    expect(workbookWithVersionFirst().worksheets[0].name).toBe(VERSION_SHEET);
  });

  it('không làm lệch việc đọc sheet nội dung', () => {
    const rows = getRows(getSheet(workbookWithVersionFirst(), ['courses']));

    expect(rows).toHaveLength(1);
    expect(rows[0].values.id).toBe('68c1');
    expect(rows[0].values.title_vi).toBe('Ghi chú đúng cách');
  });

  it('tra tên sheet không tồn tại vẫn trả undefined, KHÔNG rơi về sheet đầu', () => {
    const workbook = workbookWithVersionFirst();

    expect(getSheet(workbook, ['keypoints'])).toBeUndefined();
    expect(getRows(getSheet(workbook, ['keypoints']))).toEqual([]);
  });
});
