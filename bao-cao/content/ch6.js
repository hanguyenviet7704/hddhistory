const { p, h1, h2, h3, bullet, num, table, caption } = require("../lib/helpers");
const { AlignmentType, Paragraph, TextRun } = require("docx");

module.exports = () => [
  h1("Chương 7: Kết luận và hướng phát triển"),

  h2("7.1 Kết quả đạt được"),
  p("Đồ án đã hoàn thành hai tầng đầu tiên trong kiến trúc năm tầng đề xuất, cùng với việc khảo sát và kế thừa một nền tảng ứng dụng sẵn có để làm hạ tầng triển khai."),
  p("Về mặt nghiên cứu, đồ án đã xây dựng hoàn chỉnh pipeline sáu bước từ trích xuất dữ liệu đến sinh câu hỏi có kiểm soát, mỗi bước đều có mã nguồn chạy được, kiểm thử tự động và số liệu thực nghiệm. Ba kết quả đáng chú ý nhất:"),
  num("**Xác định được nguyên nhân thật của chất lượng mô hình nhúng thấp.** Thay vì dừng ở nhận định chung rằng đồ thị thưa, đồ án đếm cụ thể và chỉ ra 53,3% bộ ba trong dữ liệu Wikidata có đối tượng là mốc thời gian, và 32,6% thực thể thực chất là ngày tháng chỉ xuất hiện một lần. Phát hiện này dẫn tới một nguyên tắc thiết kế dữ liệu cụ thể cho các vòng mở rộng sau."),
  num("**Chứng minh bằng thực nghiệm rằng tăng mật độ liên kết hiệu quả hơn tăng số lượng thực thể.** Bổ sung 16 thực thể mới làm MRR giảm từ 0,0696 xuống 0,0573, trong khi bổ sung 8 quan hệ đã kiểm chứng (không thêm thực thể nào) làm MRR tăng lên 0,0802 — giá trị cao nhất trong toàn bộ thử nghiệm."),
  num("**Thiết kế được cơ chế sinh nội dung có kiểm soát hai lớp** với phần kiểm chứng tự động không phụ thuộc vào thiện chí của mô hình ngôn ngữ, đã được kiểm thử bằng năm ca kiểm thử bao phủ cả trường hợp hợp lệ lẫn các dạng vi phạm."),
  p("Về mặt dữ liệu, đồ án đã biên soạn một bộ dữ liệu lịch sử Việt Nam gồm 176 thực thể và 205 quan hệ trải trên 12 thời kỳ, có gắn nguồn tham khảo, có ghi nhận các dữ kiện còn tranh luận giữa các nguồn, và được kiểm tra toàn vẹn tự động."),
  p("Về mặt công cụ, đồ án đã xây dựng bốn công cụ hỗ trợ cho phép tiếp tục mở rộng dữ liệu mà không phụ thuộc vào thao tác thủ công hoàn toàn, trong đó có một công cụ đối chiếu chéo với nguồn độc lập đã thực sự phát hiện được sai sót trong dữ liệu tự biên soạn."),

  h2("7.2 Hạn chế"),
  p("Đồ án có một số hạn chế cần nêu rõ:"),
  bullet("**Quy mô đồ thị còn nhỏ.** Với 186 thực thể và 381 bộ ba, chỉ số MRR cao nhất đạt được là 0,0802 — thấp so với các nghiên cứu công bố trên những tập dữ liệu chuẩn có hàng chục nghìn thực thể. Không gian nhúng ở mức chất lượng này chưa đủ tin cậy để làm cơ sở cho gợi ý ngữ nghĩa trong sản phẩm thật."),
  bullet("**Chỉ số đánh giá còn nhiễu.** Ở quy mô tập kiểm thử vài chục bộ ba, việc thêm hoặc bớt vài quan hệ đã đủ làm MRR dao động vài phần nghìn, khiến việc so sánh giữa các cấu hình gần nhau thiếu độ tin cậy thống kê."),
  bullet("**Bước sinh câu hỏi chưa chạy thật.** Logic sinh và kiểm chứng đã hoàn chỉnh và được kiểm thử, nhưng việc gọi mô hình ngôn ngữ thật trên dữ liệu lịch sử Việt Nam chưa thực hiện được do chưa có khoá truy cập dịch vụ."),
  bullet("**Ba tầng sau chưa triển khai.** Tầng lập lịch thích nghi, tầng tương tác và tầng cập nhật đánh giá mới ở mức thiết kế đề xuất."),
  bullet("**Dữ liệu chưa qua thẩm định chuyên môn.** Bộ dữ liệu được biên soạn dựa trên kiến thức phổ thông và sách giáo khoa, có gắn nguồn nhưng chưa được chuyên gia lịch sử rà soát độc lập."),

  h2("7.3 Hướng phát triển"),
  h3("7.3.1 Ngắn hạn"),
  bullet("Hoàn thiện bước sinh câu hỏi bằng cách chạy thật với mô hình ngôn ngữ, thu thập đủ mẫu để đo tỉ lệ câu hỏi bị cơ chế kiểm chứng từ chối — con số này chính là thước đo hiệu quả của cơ chế kiểm soát."),
  bullet("Tiếp tục làm giàu quan hệ giữa các thực thể đã có, ưu tiên những thực thể còn ít liên kết, theo đúng kết luận thực nghiệm ở mục 5.4.2."),
  bullet("Mời chuyên gia hoặc giáo viên lịch sử rà soát bộ dữ liệu, đặc biệt là phần niên đại và các dữ kiện đã được ghi nhận là còn tranh luận."),
  bullet("Thử nghiệm thêm các mô hình nhúng khác ngoài TransE (ComplEx, RotatE) để so sánh trên cùng bộ dữ liệu."),

  h3("7.3.2 Trung hạn — ba tầng còn lại"),
  p("Ba tầng còn lại của kiến trúc đề xuất cần được triển khai theo thứ tự phụ thuộc:"),
  num("**Tầng lập lịch (Adaptive Microlearning Scheduling).** Trước khi thiết kế, cần khảo sát các thuật toán lặp lại ngắt quãng hiện có (SM-2, FSRS và các biến thể) để xác định rõ điểm đề tài có thể đóng góp thêm so với chúng."),
  num("**Tầng tương tác.** Ghi nhận phản hồi của người học ở mức chi tiết đủ dùng cho tầng sau: không chỉ đúng hay sai mà còn thời gian trả lời và các thực thể mà câu hỏi kiểm tra."),
  num("**Tầng cập nhật đánh giá (Relational Diffusion).** Đây là đóng góp mang tính nghiên cứu rõ nhất của đề tài: khi người học trả lời sai một câu hỏi, thay vì chỉ điều chỉnh lịch ôn của riêng đơn vị tri thức đó, hệ thống lan truyền mức suy giảm trí nhớ sang các thực thể lân cận trên đồ thị theo trọng số phụ thuộc vào khoảng cách và độ tương đồng nhúng. Việc triển khai tầng này chỉ có ý nghĩa khi đã có dữ liệu tương tác thật để hiệu chỉnh tham số lan truyền."),

  h3("7.3.3 Dài hạn"),
  bullet("Tích hợp module tri thức vào ứng dụng thật: đưa tính năng tra cứu hồ sơ thực thể và gợi ý nội dung liên quan vào ứng dụng di động, đưa tính năng sinh nháp câu hỏi vào trang quản trị nội dung."),
  bullet("Mở rộng bộ dữ liệu lên quy mô đủ lớn để không gian nhúng đạt chất lượng dùng được trong sản phẩm, đồng thời xây dựng quy trình kiểm duyệt nội dung có sự tham gia của chuyên gia."),
  bullet("Đánh giá hiệu quả học tập thực tế bằng thực nghiệm có nhóm đối chứng, so sánh giữa nhóm dùng lịch ôn tập theo đồ thị và nhóm dùng lịch ôn tập truyền thống."),

  h2("7.4 Lời kết"),
  p("Đồ án đã hoàn thành phạm vi đề ra là hai tầng đầu tiên của hệ thống, với toàn bộ số liệu báo cáo đều xuất phát từ các lần chạy thật và kiểm chứng được. Những kết quả không đạt kỳ vọng — chất lượng mô hình nhúng còn thấp, phép kiểm tra trực giác về độ tương đồng cho kết quả ngược với giả thuyết — được giữ nguyên trong báo cáo cùng phần phân tích nguyên nhân, bởi chính những kết quả đó đã dẫn tới các quyết định thiết kế dữ liệu đúng đắn ở các vòng sau. Đây cũng là điều em học được nhiều nhất trong quá trình thực hiện đồ án: một kết quả âm được phân tích đến nơi có giá trị hơn một kết quả đẹp không rõ nguyên nhân."),

  new Paragraph({ children: [new TextRun({ text: "" })] }),

  h1("Tài liệu tham khảo"),
  p("[1] A. Bordes, N. Usunier, A. Garcia-Durán, J. Weston, O. Yakhnenko, “Translating Embeddings for Modeling Multi-relational Data”, Advances in Neural Information Processing Systems (NIPS), 2013.", { noIndent: true }),
  p("[2] M. Ali và cộng sự, “PyKEEN 1.0: A Python Library for Training and Evaluating Knowledge Graph Embeddings”, Journal of Machine Learning Research, 2021.", { noIndent: true }),
  p("[3] D. Vrandečić, M. Krötzsch, “Wikidata: A Free Collaborative Knowledgebase”, Communications of the ACM, 2014.", { noIndent: true }),
  p("[4] Q. Wang, Z. Mao, B. Wang, L. Guo, “Knowledge Graph Embedding: A Survey of Approaches and Applications”, IEEE Transactions on Knowledge and Data Engineering, 2017.", { noIndent: true }),
  p("[5] B. Yang, W. Yih, X. He, J. Gao, L. Deng, “Embedding Entities and Relations for Learning and Inference in Knowledge Bases” (DistMult), International Conference on Learning Representations (ICLR), 2015.", { noIndent: true }),
  p("[6] T. Trouillon, J. Welbl, S. Riedel, É. Gaussier, G. Bouchard, “Complex Embeddings for Simple Link Prediction” (ComplEx), International Conference on Machine Learning (ICML), 2016.", { noIndent: true }),
  p("[7] Z. Sun, Z.-H. Deng, J.-Y. Nie, J. Tang, “RotatE: Knowledge Graph Embedding by Relational Rotation in Complex Space”, International Conference on Learning Representations (ICLR), 2019.", { noIndent: true }),
  p("[8] H. Ebbinghaus, *Über das Gedächtnis* (Memory: A Contribution to Experimental Psychology), 1885.", { noIndent: true }),
  p("[9] H. L. Roediger, J. D. Karpicke, “Test-Enhanced Learning: Taking Memory Tests Improves Long-Term Retention”, Psychological Science, 2006.", { noIndent: true }),
  p("[10] P. Wozniak, E. Gorzelanczyk, “Optimization of repetition spacing in the practice of learning” (thuật toán SM-2), Acta Neurobiologiae Experimentalis, 1994.", { noIndent: true }),
  p("[11] J. Ye, D. Su, Y. Cao và cộng sự, “A Stochastic Shortest Path Approach to Memory Modeling” và mô hình FSRS (Free Spaced Repetition Scheduler), tài liệu kỹ thuật mã nguồn mở, https://github.com/open-spaced-repetition/fsrs4anki", { noIndent: true }),
  p("[12] D. Vrandečić, M. Krötzsch, “Wikidata: A Free Collaborative Knowledgebase”, Communications of the ACM, 2014.", { noIndent: true }),
  p("[13] Neo4j Inc., “The Neo4j Cypher Manual”, tài liệu kỹ thuật chính thức, https://neo4j.com/docs/cypher-manual/", { noIndent: true }),
  p("[14] Tài liệu chính thức NestJS, https://docs.nestjs.com/", { noIndent: true }),
  p("[15] Tài liệu chính thức Flutter, https://docs.flutter.dev/", { noIndent: true }),
  p("[16] Tài liệu chính thức Next.js (App Router), Vercel Inc., https://nextjs.org/docs", { noIndent: true }),
  p("[17] Tài liệu chính thức React, Meta Platforms Inc., https://react.dev/", { noIndent: true }),
  p("[18] Ngô Sĩ Liên và Quốc sử quán triều Lê, *Đại Việt sử ký toàn thư*, bản dịch, Nhà xuất bản Khoa học Xã hội.", { noIndent: true }),
  p("[19] Trần Trọng Kim, *Việt Nam sử lược*, 1920.", { noIndent: true }),
  p("[20] Viện Sử học Việt Nam, *Lịch sử Việt Nam* (bộ nhiều tập), Nhà xuất bản Khoa học Xã hội.", { noIndent: true }),
  p("[21] Nguyễn Trãi, *Bình Ngô đại cáo*, 1428.", { noIndent: true }),
];
