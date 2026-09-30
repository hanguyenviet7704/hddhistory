const { p, h1, h2, h3, bullet, num, table, code, formula, figurePlaceholder, caption } = require("../lib/helpers");

module.exports = () => [
  h1("Chương 5: Cài đặt và thử nghiệm"),

  h2("5.1 Môi trường cài đặt"),
  p("Toàn bộ thử nghiệm được thực hiện trên môi trường sau:"),
  table(
    ["Thành phần", "Cấu hình"],
    [
      ["Máy thử nghiệm", "MacBook, bộ nhớ 16 GB, chạy trên CPU (không dùng GPU)"],
      ["Python", "Phiên bản 3.9.6, môi trường ảo riêng cho module tri thức"],
      ["Neo4j", "Phiên bản 5 bản Community, chạy trong Docker, cổng 7474 và 7687"],
      ["PyKEEN", "Phiên bản 1.11.0 trên nền PyTorch 2.8.0"],
      ["Thư viện phụ trợ", "SPARQLWrapper, pandas, NumPy, scikit-learn, matplotlib, jupytext"],
      ["Ràng buộc phiên bản", "class-resolver ghim ở 0.5.1 để tránh lỗi tương thích khi nạp PyKEEN"],
    ],
    [2600, 7600],
  ),
  caption("Bảng 5.1: Môi trường cài đặt và thử nghiệm"),

  h2("5.2 Kết quả xây dựng bộ dữ liệu"),
  p("Bộ dữ liệu lịch sử Việt Nam sau năm vòng biên soạn có quy mô như sau:"),
  table(
    ["Chỉ số", "Giá trị"],
    [
      ["Tổng số thực thể", "176"],
      ["Trong đó: nhân vật / sự kiện / tổ chức / địa danh", "76 / 43 / 31 / 10"],
      ["Tổng số quan hệ", "205"],
      ["Số loại quan hệ khác nhau", "34"],
      ["Số thời kỳ lịch sử", "12 (từ Hồng Bàng đến hiện đại)"],
      ["Số nguồn tham khảo", "11"],
      ["Số dữ kiện còn tranh luận được ghi nhận (claims)", "5"],
    ],
    [5600, 4600],
  ),
  caption("Bảng 5.2: Quy mô bộ dữ liệu lịch sử Việt Nam"),
  p("Kiểm tra tính toàn vẹn của bộ dữ liệu được thực hiện tự động sau mỗi vòng biên soạn, gồm bốn phép kiểm tra: không có mã định danh trùng lặp, không có quan hệ nào trỏ tới thực thể không tồn tại, không có tham chiếu nguồn nào trỏ tới nguồn không tồn tại, và không có thực thể nào thuộc thời kỳ không tồn tại. Cả bốn phép kiểm tra đều đạt ở phiên bản cuối cùng."),

  h3("5.2.1 Phân tích mật độ liên kết"),
  p("Một chỉ số quan trọng với chất lượng huấn luyện mô hình nhúng là mật độ liên kết của đồ thị. Phân tích bộ dữ liệu cho thấy bậc trung bình của một thực thể chỉ đạt 2,15 quan hệ, và có tới 73 trên 160 thực thể (45,6%) chỉ có đúng một quan hệ duy nhất tại thời điểm khảo sát."),
  p("Đây là vấn đề nghiêm trọng với mô hình nhúng: một thực thể chỉ bị ràng buộc bởi một bộ ba thì vị trí của nó trong không gian vector gần như không được xác định, vì có vô số vị trí cùng thoả mãn ràng buộc đó. Giải pháp được áp dụng là hiện thực hoá quan hệ “thuộc thời kỳ” — vốn đã tồn tại ngầm trong trường dữ liệu của mỗi thực thể — thành cạnh thật của đồ thị. Cách làm này không thêm thông tin mới mà chỉ làm rõ thông tin đã có, nhưng nâng bậc trung bình lên 3,91 và loại bỏ hoàn toàn các thực thể chỉ có một quan hệ."),
  table(
    ["Chỉ số", "Trước khi bổ sung", "Sau khi bổ sung"],
    [
      ["Số bộ ba", "205", "381"],
      ["Bậc trung bình", "2,15", "3,91"],
      ["Số thực thể chỉ có 1 quan hệ", "73 / 160 (45,6%)", "0"],
    ],
    [4000, 3100, 3100],
  ),
  caption("Bảng 5.3: Tác động của việc hiện thực hoá quan hệ thuộc thời kỳ"),

  h2("5.3 Thử nghiệm huấn luyện mô hình nhúng"),
  p("Mô hình TransE được huấn luyện trên năm cấu hình dữ liệu khác nhau để đánh giá ảnh hưởng của chất lượng và mật độ dữ liệu tới kết quả. Mọi lần chạy đều dùng chung tham số: chia 80/20, 100 vòng lặp, hạt giống ngẫu nhiên cố định 42."),
  table(
    ["Cấu hình dữ liệu", "Thực thể", "Bộ ba", "MRR", "Hits@1", "Hits@10"],
    [
      ["Wikidata (dữ liệu công khai)", "1009", "1000", "0,0218", "0,0000", "0,0475"],
      ["Tự biên soạn, 160 thực thể", "170", "332", "0,0696", "0,0224", "0,1119"],
      ["Tự biên soạn, thêm 16 thực thể", "186", "372", "0,0573", "0,0000", "0,1867"],
      ["Tự biên soạn, thêm 8 quan hệ đã kiểm chứng", "186", "379", "0,0802", "0,0197", "0,1776"],
      ["Tự biên soạn, thêm 2 quan hệ (bản cuối)", "186", "381", "0,0694", "0,0130", "0,1688"],
    ],
    [3400, 1300, 1200, 1400, 1400, 1500],
  ),
  caption("Bảng 5.4: Kết quả huấn luyện TransE trên các cấu hình dữ liệu"),
  figurePlaceholder("Biểu đồ so sánh MRR và Hits@10 giữa các cấu hình dữ liệu"),
  caption("Hình 5.1: So sánh kết quả huấn luyện giữa các cấu hình dữ liệu"),

  h2("5.4 Phân tích kết quả"),
  h3("5.4.1 Vì sao dữ liệu tự biên soạn cho kết quả tốt hơn Wikidata"),
  p("Chỉ số MRR trên dữ liệu tự biên soạn cao gấp khoảng ba lần so với dữ liệu Wikidata (0,0696 so với 0,0218 ở cấu hình tương đương). Nguyên nhân được xác định bằng cách phân tích trực tiếp thành phần dữ liệu, chứ không dừng ở nhận định chung chung rằng “dữ liệu sạch hơn”."),
  p("Đếm trên tệp dữ liệu Wikidata cho thấy 533 trên 1000 bộ ba (53,3%) có giá trị ở vị trí đối tượng là một mốc thời gian dạng chuỗi ngày tháng, và 329 trên 1009 thực thể (32,6%) thực chất là các mốc thời gian chứ không phải thực thể lịch sử. Đáng chú ý hơn, 281 trong số 329 mốc thời gian đó (85,4%) chỉ xuất hiện đúng một lần trong toàn bộ dữ liệu."),
  p("Hệ quả là hơn một nửa số “quan hệ” mà mô hình học được thực chất là thuộc tính ngày tháng, và một phần ba số “thực thể” trong từ vựng là các mốc thời gian chỉ xuất hiện một lần nên không bao giờ có thể được xếp hạng đúng. Điều này giải thích trực tiếp vì sao Hits@1 bằng 0 trên dữ liệu Wikidata. Bộ dữ liệu tự biên soạn không gặp vấn đề này vì ngày tháng được lưu như thuộc tính của thực thể sự kiện thay vì trở thành nút riêng trong đồ thị."),
  p("Bài học rút ra cho thiết kế dữ liệu: khi mở rộng bộ dữ liệu về sau, ngày tháng nên tiếp tục được mô hình hoá như thuộc tính của nút, không nên chuyển thành thực thể độc lập nối bằng quan hệ."),

  h3("5.4.2 Thêm thực thể không đồng nghĩa với cải thiện chất lượng"),
  p("Một kết quả ngược với kỳ vọng ban đầu: khi bổ sung 16 thực thể mới qua công cụ nhập tự động, MRR giảm từ 0,0696 xuống 0,0573 và Hits@1 giảm về 0. Phân tích cho thấy 8 trên 16 thực thể mới (50%) vẫn chỉ có đúng một quan hệ ngay cả sau khi đã bổ sung quan hệ thủ công, vì với nhiều nhân vật chỉ tồn tại một mối liên hệ chắc chắn trong phạm vi đồ thị hiện có."),
  p("Ngược lại, khi bổ sung 8 quan hệ đã được đối chiếu chéo với Wikidata mà không thêm thực thể nào, MRR tăng lên 0,0802 — giá trị cao nhất trong toàn bộ thử nghiệm. Kết luận: với đồ thị ở quy mô nhỏ, tăng mật độ liên kết giữa các thực thể đã có mang lại cải thiện rõ hơn so với mở rộng số lượng thực thể."),

  h3("5.4.3 Về độ nhiễu của chỉ số ở quy mô nhỏ"),
  p("Lần chạy cuối cùng bổ sung thêm 2 quan hệ đúng nhưng MRR lại giảm từ 0,0802 xuống 0,0694. Cần nêu rõ rằng đây là dao động thống kê chứ không phải dấu hiệu dữ liệu sai: với tập kiểm thử chỉ khoảng 76 bộ ba, việc thêm hai bộ ba làm thay đổi thành phần ngẫu nhiên của tập kiểm thử, đủ để dịch chuyển chỉ số vài phần nghìn. Đây là giới hạn cố hữu khi đánh giá trên tập dữ liệu nhỏ, và là lý do các kết luận trong đồ án được rút ra từ xu hướng qua nhiều lần chạy thay vì từ một con số đơn lẻ."),

  h3("5.4.4 Đánh giá chất lượng ngữ nghĩa của không gian nhúng"),
  p("Ngoài các chỉ số định lượng, đồ án kiểm tra chất lượng ngữ nghĩa bằng cách xem danh sách thực thể gần nhất của một số nhân vật tiêu biểu. Kết quả cho thấy không gian nhúng ở mức chất lượng này chưa phản ánh đáng tin cậy quan hệ ngữ nghĩa: bên cạnh một số kết quả hợp lý (ví dụ Hồ Chí Minh gần với Đảng Cộng sản Việt Nam ở mức 0,35), vẫn xuất hiện những kết quả không có liên hệ rõ ràng ở thứ hạng cao hơn."),
  p("Kết luận trung thực: pipeline tính toán hoạt động đúng về mặt kỹ thuật, nhưng chất lượng đầu vào — một đồ thị 186 thực thể với 381 bộ ba — chưa đủ để không gian nhúng mang ý nghĩa ngữ nghĩa đáng tin cậy. Đây là lý do tính năng tra cứu hồ sơ thực thể được thiết kế để phần thông tin chính lấy trực tiếp từ đồ thị đã kiểm duyệt, còn gợi ý theo nhúng chỉ đóng vai trò bổ sung và được ghi chú rõ về độ tin cậy."),

  h2("5.5 Thử nghiệm cơ chế sinh câu hỏi có kiểm soát"),
  p("Cơ chế kiểm chứng ở bước 6 được thử nghiệm bằng năm ca kiểm thử tự động, mô phỏng các tình huống mà một mô hình ngôn ngữ có thể tạo ra đầu ra không hợp lệ."),
  table(
    ["Ca kiểm thử", "Tình huống", "Kết quả mong đợi", "Kết quả thực tế"],
    [
      ["TC-01", "Câu hỏi chỉ dùng năm và thực thể có trong ngữ cảnh", "Chấp nhận", "Đạt"],
      ["TC-02", "Câu hỏi chứa năm không có trong ngữ cảnh", "Từ chối, nêu rõ năm sai", "Đạt"],
      ["TC-03", "Câu hỏi khai báo thực thể không có trong ngữ cảnh", "Từ chối, nêu rõ thực thể sai", "Đạt"],
      ["TC-04", "Câu hỏi không khai báo thực thể nào", "Từ chối", "Đạt"],
      ["TC-05", "Hàm gọi mô hình trả về đúng nội dung phản hồi", "Trích xuất đúng phần văn bản", "Đạt"],
    ],
    [1400, 3900, 2600, 2300],
  ),
  caption("Bảng 5.5: Kết quả kiểm thử cơ chế sinh câu hỏi có kiểm soát"),
  p("Cần nêu rõ giới hạn của thử nghiệm này: các ca kiểm thử xác minh logic kiểm chứng hoạt động đúng với đầu vào giả lập, nhưng việc chạy thật với mô hình ngôn ngữ trên dữ liệu lịch sử Việt Nam chưa được thực hiện do chưa có khoá truy cập dịch vụ mô hình tại thời điểm viết báo cáo. Phần này được ghi nhận là công việc còn lại, không được trình bày như đã hoàn thành."),

  h2("5.6 Kiểm thử phần mềm"),
  p("Toàn bộ module tri thức được kiểm thử bằng bộ kiểm thử tự động viết bằng pytest. Nguyên tắc thiết kế kiểm thử: các phép kiểm thử logic thuần tuý không phụ thuộc mạng, cơ sở dữ liệu hay mô hình đã huấn luyện, nhờ đó chạy nhanh và ổn định; các phép kiểm thử cần cơ sở dữ liệu được tách riêng và ghi chú rõ điều kiện tiên quyết."),
  table(
    ["Nhóm kiểm thử", "Số ca", "Phụ thuộc bên ngoài"],
    [
      ["Trích xuất và chuyển đổi dữ liệu Wikidata", "2", "Không (dùng dữ liệu giả lập)"],
      ["Nạp dữ liệu và tính bất biến trên Neo4j", "1", "Cần Neo4j đang chạy"],
      ["Huấn luyện mô hình nhúng", "1", "Không (mô hình nhỏ, 5 vòng lặp)"],
      ["Tính độ tương đồng cosine", "3", "Không"],
      ["Trích chuỗi quan hệ", "2", "Cần Neo4j đang chạy"],
      ["Sinh câu hỏi và kiểm chứng", "5", "Không (dùng đối tượng giả lập)"],
      ["Hồ sơ thực thể", "13", "Không"],
    ],
    [4200, 1400, 4600],
  ),
  caption("Bảng 5.6: Thống kê bộ kiểm thử tự động của module tri thức"),
  p("Tổng cộng 27 ca kiểm thử. Trong quá trình phát triển, bộ kiểm thử đã phát hiện được các lỗi thực tế, trong đó đáng kể nhất là việc kiểm thử tính bất biến giúp bảo vệ ràng buộc rằng nạp lại cùng một tập dữ liệu không được nhân đôi dữ liệu."),

  h3("5.6.1 Một số vấn đề phát hiện trong quá trình thử nghiệm"),
  p("Quá trình thử nghiệm phát hiện và xử lý một số vấn đề đáng ghi nhận:"),
  bullet("**Xung đột thư viện**: phiên bản class-resolver mới khiến việc nạp PyKEEN thất bại trên Python 3.9. Đã xử lý bằng cách ghim phiên bản và ghi chú lý do trực tiếp trong tệp khai báo phụ thuộc, tránh việc nâng cấp vô ý về sau làm hỏng môi trường."),
  bullet("**Cảnh báo sai của thư viện tính toán**: phép nhân ma trận phát cảnh báo chia cho không. Kiểm chứng bằng ma trận số ngẫu nhiên hoàn toàn hợp lệ cho thấy cảnh báo vẫn xuất hiện, xác định đây là dương tính giả của thư viện đại số tuyến tính trên nền tảng macOS chứ không phải lỗi dữ liệu. Đã tắt cảnh báo cho riêng phép tính đó kèm giải thích, đồng thời giữ bộ lọc giá trị không hữu hạn để phòng trường hợp lỗi thật."),
  bullet("**Giới hạn tần suất truy cập dịch vụ ngoài**: công cụ nhập dữ liệu từ Wikidata bị từ chối khi gửi nhiều yêu cầu liên tiếp. Đã bổ sung cơ chế chờ tăng dần khi gặp lỗi và giãn cách giữa các lần gọi."),
  bullet("**Sai sót dữ liệu phát hiện qua đối chiếu chéo**: công cụ gợi ý quan hệ phát hiện một mô tả sai trong bộ dữ liệu tự biên soạn (một nhân vật bị mô tả nhầm quan hệ họ hàng) và một quan hệ đã kiểm chứng bị bỏ sót khi cập nhật dữ liệu. Cả hai đều đã được sửa. Đây là minh chứng cho giá trị của việc đối chiếu chéo với nguồn độc lập thay vì chỉ dựa vào một lượt biên soạn."),

  h2("5.7 Kết chương"),
  p("Chương 5 đã trình bày môi trường cài đặt, kết quả xây dựng bộ dữ liệu, các thử nghiệm huấn luyện mô hình nhúng với số liệu cụ thể và phân tích nguyên nhân đằng sau các số liệu đó. Kết quả quan trọng nhất là xác định được nguyên nhân thật của chất lượng mô hình thấp — cấu trúc dữ liệu chứ không phải thuật toán — và chứng minh được rằng tăng mật độ liên kết hiệu quả hơn tăng số lượng thực thể. Chương cuối tổng kết những gì đã đạt được và đề xuất hướng phát triển."),
];
