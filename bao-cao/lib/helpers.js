const {
  AlignmentType, BorderStyle, HeadingLevel, Paragraph, ShadingType, Table,
  TableCell, TableRow, TextRun, WidthType, PageBreak, LevelFormat,
} = require("docx");

const FONT = "Times New Roman";
const SIZE = 26; // 13pt (half-points) — cỡ chữ thân bài theo quy định đồ án PTIT
const LINE = 360; // giãn dòng 1.5

/** Đoạn văn thân bài, thụt đầu dòng 1cm như quy cách đồ án. */
function p(text, opts = {}) {
  return new Paragraph({
    alignment: opts.align || AlignmentType.JUSTIFIED,
    spacing: { line: LINE, after: opts.after ?? 120 },
    indent: opts.noIndent ? undefined : { firstLine: 567 },
    children: runs(text, opts),
  });
}

/** Tách chuỗi có đánh dấu **đậm** và *nghiêng* thành các TextRun. */
function runs(text, opts = {}) {
  const parts = String(text).split(/(\*\*[^*]+\*\*|\*[^*]+\*)/g).filter(Boolean);
  return parts.map((part) => {
    if (part.startsWith("**") && part.endsWith("**")) {
      return new TextRun({ text: part.slice(2, -2), bold: true, font: FONT, size: opts.size || SIZE });
    }
    if (part.startsWith("*") && part.endsWith("*")) {
      return new TextRun({ text: part.slice(1, -1), italics: true, font: FONT, size: opts.size || SIZE });
    }
    return new TextRun({
      text: part, font: FONT, size: opts.size || SIZE,
      bold: opts.bold, italics: opts.italics,
    });
  });
}

function h1(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    pageBreakBefore: true,
    spacing: { before: 240, after: 240, line: LINE },
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: text.toUpperCase(), bold: true, font: FONT, size: 32 })],
  });
}

function h2(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 240, after: 120, line: LINE },
    children: [new TextRun({ text, bold: true, font: FONT, size: 28 })],
  });
}

function h3(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_3,
    spacing: { before: 180, after: 120, line: LINE },
    children: [new TextRun({ text, bold: true, italics: true, font: FONT, size: SIZE })],
  });
}

/** Gạch đầu dòng. */
function bullet(text, level = 0) {
  return new Paragraph({
    numbering: { reference: "bullet-list", level },
    spacing: { line: LINE, after: 60 },
    alignment: AlignmentType.JUSTIFIED,
    children: runs(text),
  });
}

/** Danh sách đánh số. */
function num(text, level = 0) {
  return new Paragraph({
    numbering: { reference: "number-list", level },
    spacing: { line: LINE, after: 60 },
    alignment: AlignmentType.JUSTIFIED,
    children: runs(text),
  });
}

/** Chú thích hình/bảng, căn giữa, in nghiêng. */
function caption(text) {
  return new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 60, after: 180, line: LINE },
    children: [new TextRun({ text, italics: true, font: FONT, size: 24 })],
  });
}

/** Chỗ dành cho ảnh chụp màn hình/biểu đồ người viết tự chèn sau. */
function figurePlaceholder(label) {
  return new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 120, after: 60, line: LINE },
    border: {
      top: { style: BorderStyle.DASHED, size: 6, color: "999999" },
      bottom: { style: BorderStyle.DASHED, size: 6, color: "999999" },
      left: { style: BorderStyle.DASHED, size: 6, color: "999999" },
      right: { style: BorderStyle.DASHED, size: 6, color: "999999" },
    },
    children: [new TextRun({ text: `[ Chèn hình: ${label} ]`, italics: true, color: "777777", font: FONT, size: 24 })],
  });
}

/** Khối mã nguồn / truy vấn, nền xám, font đơn cách. */
function code(lines) {
  return lines.map((line, i) => new Paragraph({
    spacing: { line: 240, after: i === lines.length - 1 ? 180 : 0 },
    shading: { type: ShadingType.CLEAR, fill: "F2F2F2" },
    children: [new TextRun({ text: line || " ", font: "Consolas", size: 20 })],
  }));
}

/** Công thức toán, căn giữa, in nghiêng. */
function formula(text) {
  return new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 120, after: 120, line: LINE },
    children: [new TextRun({ text, italics: true, font: "Cambria Math", size: 28 })],
  });
}

/**
 * Bảng: header = mảng tiêu đề, rows = mảng các mảng ô, widths = mảng độ rộng DXA.
 * Đặt width cho cả bảng lẫn từng ô (yêu cầu của docx-js để Google Docs hiển thị đúng).
 */
function table(header, rows, widths) {
  const total = widths.reduce((a, b) => a + b, 0);
  const cell = (text, opts = {}) => new TableCell({
    width: { size: opts.width, type: WidthType.DXA },
    shading: opts.headerRow ? { type: ShadingType.CLEAR, fill: "D9D9D9" } : undefined,
    children: [new Paragraph({
      alignment: opts.headerRow ? AlignmentType.CENTER : AlignmentType.LEFT,
      spacing: { line: 240, before: 40, after: 40 },
      children: runs(text, { bold: opts.headerRow, size: 24 }),
    })],
  });

  return new Table({
    width: { size: total, type: WidthType.DXA },
    columnWidths: widths,
    rows: [
      new TableRow({
        tableHeader: true,
        children: header.map((t, i) => cell(t, { width: widths[i], headerRow: true })),
      }),
      ...rows.map((r) => new TableRow({
        children: r.map((t, i) => cell(t, { width: widths[i] })),
      })),
    ],
  });
}

function pageBreak() {
  return new Paragraph({ children: [new PageBreak()] });
}

function blank(count = 1) {
  return Array.from({ length: count }, () => new Paragraph({ children: [new TextRun({ text: "", font: FONT, size: SIZE })] }));
}

const numberingConfig = {
  config: [
    {
      reference: "bullet-list",
      levels: [
        { level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 260 } } } },
        { level: 1, format: LevelFormat.BULLET, text: "–", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 1280, hanging: 260 } } } },
      ],
    },
    {
      reference: "number-list",
      levels: [
        { level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } } },
        { level: 1, format: LevelFormat.LOWER_LETTER, text: "%2)", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 1280, hanging: 360 } } } },
      ],
    },
  ],
};

module.exports = {
  FONT, SIZE, LINE, p, h1, h2, h3, bullet, num, caption, figurePlaceholder,
  code, formula, table, pageBreak, blank, runs, numberingConfig,
};
