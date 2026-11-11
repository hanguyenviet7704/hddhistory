const { AlignmentType, Paragraph, TextRun, TableOfContents } = require("docx");
const { p, h1, h2, bullet, table, blank, pageBreak, FONT } = require("../lib/helpers");

const center = (text, opts = {}) =>
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { after: opts.after ?? 120, line: 360 },
    children: [new TextRun({
      text, bold: opts.bold, italics: opts.italics,
      font: FONT, size: opts.size || 26,
    })],
  });

// Thông tin cần người viết điền — để nguyên dạng ngoặc vuông cho dễ tìm và thay.
const TRUONG = "HỌC VIỆN CÔNG NGHỆ BƯU CHÍNH VIỄN THÔNG";
const KHOA = "KHOA CÔNG NGHỆ THÔNG TIN";
const DE_TAI = "XÂY DỰNG HỆ THỐNG HỌC LỊCH SỬ THEO ĐỒ THỊ TRI THỨC VÀ LẶP LẠI NGẮT QUÃNG THÍCH NGHI";

function coverPage() {
  return [
    center(TRUONG, { bold: true, size: 28 }),
    center(KHOA, { bold: true, size: 28, after: 240 }),
    center("-----o0o-----", { after: 600 }),
    ...blank(2),
    center("ĐỒ ÁN", { bold: true, size: 40 }),
    center("TỐT NGHIỆP ĐẠI HỌC", { bold: true, size: 40, after: 480 }),
    ...blank(1),
    center(`Đề tài: ${DE_TAI}`, { bold: true, size: 30, after: 600 }),
    ...blank(2),
    table(
      ["Giảng viên hướng dẫn", ":", "[Học hàm, học vị và họ tên GVHD]"],
      [
        ["Sinh viên thực hiện", ":", "[Họ và tên] - [Mã sinh viên]"],
        ["Lớp", ":", "[Lớp]"],
        ["Khóa", ":", "[Khóa học, ví dụ 2021 – 2026]"],
        ["Hệ", ":", "Đại học chính quy"],
      ],
      [3200, 500, 5300],
    ),
    ...blank(3),
    center("Hà Nội – 2026", { bold: true }),
  ];
}

function loiCamOn() {
  return [
    pageBreak(),
    center("LỜI CẢM ƠN", { bold: true, size: 32, after: 360 }),
    p("Lời đầu tiên, em xin gửi lời cảm ơn chân thành tới các thầy cô Khoa Công nghệ thông tin cùng toàn thể thầy cô trong Học viện, những người đã tận tình giảng dạy và truyền đạt kiến thức cho em trong suốt quá trình học tập tại trường."),
    p("Đặc biệt, em xin bày tỏ lòng biết ơn sâu sắc tới thầy/cô [Họ tên GVHD] — người đã trực tiếp hướng dẫn, định hướng đề tài và góp ý cho em trong suốt quá trình thực hiện đồ án này. Những góp ý của thầy/cô không chỉ giúp em hoàn thiện sản phẩm mà còn giúp em rèn luyện tư duy nghiên cứu: làm tới đâu hiểu tới đó, kiểm chứng bằng số liệu thật thay vì chấp nhận kết quả có sẵn."),
    p("Em cũng xin cảm ơn gia đình và bạn bè đã luôn động viên, tạo điều kiện để em tập trung hoàn thành đồ án."),
    p("Do thời gian và kinh nghiệm còn hạn chế, đồ án chắc chắn còn nhiều thiếu sót. Em rất mong nhận được sự chỉ bảo và góp ý của các thầy cô để tiếp tục hoàn thiện."),
    p("Em xin chân thành cảm ơn!"),
    ...blank(1),
    center("Hà Nội, ngày ..... tháng ..... năm 2026", { italics: true }),
    center("Sinh viên thực hiện", { italics: true, after: 480 }),
    center("[Họ và tên]", { bold: true }),
  ];
}

function nhanXet(tieuDe, chuKy) {
  const dots = "…".repeat(90);
  return [
    pageBreak(),
    center(tieuDe, { bold: true, size: 30, after: 360 }),
    ...Array.from({ length: 14 }, () => p(dots, { noIndent: true })),
    ...blank(1),
    p("Điểm: ………….. (bằng chữ: ………………………………………..)", { noIndent: true }),
    ...blank(1),
    center("Hà Nội, ngày …… tháng ….. năm 2026", { italics: true }),
    center(chuKy, { bold: true }),
    center("(ký và ghi rõ họ tên)", { italics: true }),
  ];
}

function mucLuc() {
  return [
    pageBreak(),
    center("MỤC LỤC", { bold: true, size: 32, after: 240 }),
    p("Để cập nhật mục lục: mở file trong Microsoft Word, nhấp chuột phải vào bảng mục lục bên dưới rồi chọn “Update Field” → “Update entire table”.", { italics: true, noIndent: true }),
    new TableOfContents("Mục lục", { hyperlink: true, headingStyleRange: "1-3" }),
  ];
}

function danhMucVietTat() {
  return [
    pageBreak(),
    center("DANH MỤC CÁC TỪ VIẾT TẮT", { bold: true, size: 32, after: 240 }),
    table(
      ["Từ viết tắt", "Tiếng Anh", "Nghĩa tiếng Việt"],
      [
        ["KG", "Knowledge Graph", "Đồ thị tri thức"],
        ["KGE", "Knowledge Graph Embedding", "Nhúng đồ thị tri thức"],
        ["SRS", "Spaced Repetition System", "Hệ thống lặp lại ngắt quãng"],
        ["LLM", "Large Language Model", "Mô hình ngôn ngữ lớn"],
        ["MRR", "Mean Reciprocal Rank", "Trung bình nghịch đảo thứ hạng"],
        ["API", "Application Programming Interface", "Giao diện lập trình ứng dụng"],
        ["REST", "Representational State Transfer", "Kiến trúc dịch vụ web REST"],
        ["SPARQL", "SPARQL Protocol and RDF Query Language", "Ngôn ngữ truy vấn dữ liệu RDF"],
        ["RDF", "Resource Description Framework", "Khung mô tả tài nguyên"],
        ["QID / PID", "Wikidata Item / Property Identifier", "Mã định danh thực thể / thuộc tính trên Wikidata"],
        ["CSDL", "Database", "Cơ sở dữ liệu"],
        ["IAP", "In-App Purchase", "Thanh toán trong ứng dụng"],
        ["JWT", "JSON Web Token", "Chuẩn token xác thực JSON"],
        ["DTO", "Data Transfer Object", "Đối tượng truyền dữ liệu"],
        ["CRA", "Create React App", "Bộ khởi tạo ứng dụng React"],
        ["PCA", "Principal Component Analysis", "Phân tích thành phần chính (giảm chiều)"],
        ["RSC", "React Server Components", "Thành phần React kết xuất phía máy chủ"],
        ["SSR", "Server-Side Rendering", "Kết xuất phía máy chủ"],
        ["TransE", "Translating Embeddings", "Mô hình nhúng đồ thị theo phép tịnh tiến"],
        ["PyKEEN", "Python KnowlEdge EmbeddiNgs", "Thư viện huấn luyện nhúng đồ thị tri thức"],
        ["SM-2", "SuperMemo 2", "Thuật toán lập lịch lặp lại ngắt quãng"],
        ["FSRS", "Free Spaced Repetition Scheduler", "Bộ lập lịch lặp lại ngắt quãng mã nguồn mở"],
      ],
      [1800, 4200, 3000],
    ),
  ];
}

function danhMucHinhBang() {
  return [
    pageBreak(),
    center("DANH MỤC HÌNH VẼ", { bold: true, size: 32, after: 240 }),
    p("Danh mục hình được tạo tự động từ các chú thích hình trong tài liệu. Sau khi chèn đầy đủ hình minh hoạ vào các vị trí đã đánh dấu, hãy dùng chức năng Insert → Table of Figures của Microsoft Word để sinh danh mục này.", { italics: true, noIndent: true }),
    ...blank(1),
    p("Các hình cần chèn được đánh dấu sẵn trong nội dung bằng khung nét đứt có ghi rõ nội dung hình.", { noIndent: true }),
  ];
}

module.exports = {
  frontmatter: () => [
    ...coverPage(),
    ...loiCamOn(),
    ...nhanXet("NHẬN XÉT CỦA GIẢNG VIÊN HƯỚNG DẪN", "CÁN BỘ - GIẢNG VIÊN HƯỚNG DẪN"),
    ...nhanXet("NHẬN XÉT CỦA GIẢNG VIÊN PHẢN BIỆN", "CÁN BỘ - GIẢNG VIÊN PHẢN BIỆN"),
    ...mucLuc(),
    ...danhMucVietTat(),
    ...danhMucHinhBang(),
  ],
  DE_TAI,
};
