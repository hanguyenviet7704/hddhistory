/**
 * Sinh file báo cáo đồ án tốt nghiệp dạng .docx.
 *
 * Cách chạy:  node build.js
 * Kết quả:    bao-cao-do-an.docx
 */
const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, Header, Footer, PageNumber,
  AlignmentType, HeadingLevel, LevelFormat, convertMillimetersToTwip,
} = require("docx");

const { numberingConfig, FONT } = require("./lib/helpers");
const { frontmatter } = require("./content/frontmatter");

const chapters = [
  require("./content/ch1"),
  require("./content/ch2"),
  require("./content/ch3"),
  require("./content/ch4"),
  require("./content/ch5"),
  require("./content/ch6"),
];

// Làm phẳng sâu: một số hàm dựng (code, blank) trả về mảng nhiều đoạn, nếu để
// lồng nguyên mảng thì docx-js sinh ra thẻ XML rác dạng <0/> và file hỏng.
const body = [...frontmatter(), ...chapters.flatMap((ch) => ch())].flat(Infinity);

const doc = new Document({
  creator: "Đồ án tốt nghiệp",
  title: "Xây dựng hệ thống học Lịch sử theo đồ thị tri thức và lặp lại ngắt quãng thích nghi",
  numbering: numberingConfig,
  styles: {
    default: {
      document: { run: { font: FONT, size: 26 } },
      // Các style heading dựng sẵn phải khai báo để mục lục tự động nhận diện.
      heading1: {
        run: { font: FONT, size: 32, bold: true, color: "000000" },
        paragraph: { spacing: { before: 240, after: 240 }, alignment: AlignmentType.CENTER },
      },
      heading2: {
        run: { font: FONT, size: 28, bold: true, color: "000000" },
        paragraph: { spacing: { before: 240, after: 120 } },
      },
      heading3: {
        run: { font: FONT, size: 26, bold: true, italics: true, color: "000000" },
        paragraph: { spacing: { before: 180, after: 120 } },
      },
    },
  },
  sections: [{
    properties: {
      page: {
        margin: {
          top: convertMillimetersToTwip(25),
          bottom: convertMillimetersToTwip(25),
          left: convertMillimetersToTwip(30),
          right: convertMillimetersToTwip(20),
        },
      },
    },
    headers: {
      default: new Header({
        children: [new Paragraph({
          alignment: AlignmentType.RIGHT,
          children: [new TextRun({
            text: "Đồ án tốt nghiệp đại học",
            italics: true, font: FONT, size: 20, color: "666666",
          })],
        })],
      }),
    },
    footers: {
      default: new Footer({
        children: [new Paragraph({
          alignment: AlignmentType.CENTER,
          children: [new TextRun({ children: [PageNumber.CURRENT], font: FONT, size: 22 })],
        })],
      }),
    },
    children: body,
  }],
});

const out = path.join(__dirname, "bao-cao-do-an.docx");
Packer.toBuffer(doc).then((buffer) => {
  fs.writeFileSync(out, buffer);
  const kb = (buffer.length / 1024).toFixed(1);
  console.log(`Đã tạo ${out} (${kb} KB, ${body.length} khối nội dung)`);
});
