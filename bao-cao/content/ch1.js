const { p, h1, h2, h3, bullet, num, table, figurePlaceholder, caption } = require("../lib/helpers");

module.exports = () => [
  h1("Chương 1: Khảo sát hiện trạng và đề xuất đề tài"),

  h2("1.1 Đặt vấn đề"),
  p("Lịch sử là môn học có khối lượng dữ kiện lớn và dày đặc mốc thời gian, tên người, tên đất. Đặc điểm này khiến người học dễ rơi vào hai trạng thái bất lợi: học thuộc lòng rời rạc mà không nắm được mối liên hệ giữa các sự kiện, hoặc đọc hiểu được tại thời điểm học nhưng quên rất nhanh sau đó. Cả hai đều xuất phát từ cùng một nguyên nhân: tri thức lịch sử vốn có cấu trúc mạng lưới — một nhân vật gắn với nhiều sự kiện, một sự kiện kéo theo nhiều hệ quả — nhưng lại thường được trình bày và ôn tập dưới dạng danh sách tuyến tính."),
  p("Bên cạnh đó, thói quen học tập hiện nay đã thay đổi đáng kể. Thời gian rảnh của người học bị phân mảnh thành nhiều khoảng ngắn xen kẽ trong ngày, thay vì những phiên học dài liên tục. Một hệ thống học tập phù hợp với bối cảnh này cần chia nhỏ tri thức thành các đơn vị học vừa đủ ngắn để hoàn thành trong vài phút, đồng thời phải chủ động nhắc lại đúng thời điểm người học sắp quên."),
  p("Đề tài này xuất phát từ nhận định trên: nếu biểu diễn tri thức lịch sử dưới dạng một đồ thị tri thức (Knowledge Graph) thay vì danh sách phẳng, hệ thống có thể khai thác chính cấu trúc liên kết đó để (i) sinh nội dung kiểm tra bám sát ngữ cảnh có thật, (ii) gợi ý những gì liên quan tới điều đang học, và (iii) về lâu dài, lập lịch ôn tập theo mức độ liên đới giữa các đơn vị tri thức chứ không chỉ theo từng thẻ học độc lập như các hệ thống lặp lại ngắt quãng truyền thống."),

  h2("1.2 Khảo sát một số hệ thống hiện có"),
  p("Để xác định khoảng trống mà đề tài có thể đóng góp, đồ án khảo sát ba nhóm sản phẩm hiện có trên thị trường và trong nghiên cứu."),

  h3("1.2.1 Nhóm ứng dụng thẻ ghi nhớ theo lặp lại ngắt quãng"),
  p("Đại diện tiêu biểu là Anki và Quizlet. Điểm mạnh của nhóm này là thuật toán lập lịch ôn tập đã được kiểm chứng qua thời gian dài sử dụng thực tế (SM-2 và các biến thể, gần đây là FSRS). Người học được nhắc lại đúng thời điểm trí nhớ bắt đầu suy giảm, nhờ đó giữ được khối lượng kiến thức lớn với chi phí thời gian thấp."),
  p("Hạn chế nằm ở mô hình dữ liệu: mỗi thẻ ghi nhớ được xem là một đơn vị độc lập. Khi người học trả lời sai một thẻ về “Trận Bạch Đằng năm 938”, hệ thống chỉ điều chỉnh lịch ôn của riêng thẻ đó, mà không suy ra rằng các tri thức liên đới — Ngô Quyền, quân Nam Hán, ý nghĩa kết thúc thời Bắc thuộc — cũng có nguy cơ chưa vững. Nội dung thẻ cũng hoàn toàn do người dùng tự soạn, không có cơ chế kiểm soát tính chính xác."),

  h3("1.2.2 Nhóm nền tảng học trực tuyến có nội dung biên soạn sẵn"),
  p("Các nền tảng như Khan Academy hay Coursera cung cấp nội dung được biên soạn và kiểm duyệt kỹ, chất lượng cao. Tuy nhiên chi phí sản xuất nội dung rất lớn, nội dung khó cập nhật nhanh, và phần kiểm tra thường được soạn thủ công theo từng bài học nên số lượng câu hỏi hữu hạn. Người học ôn lại nhiều lần sẽ gặp lại đúng các câu hỏi cũ, dẫn tới hiện tượng thuộc lòng đáp án thay vì thực sự nhớ kiến thức."),

  h3("1.2.3 Nhóm nghiên cứu ứng dụng đồ thị tri thức trong giáo dục"),
  p("Trong nghiên cứu, hướng dùng đồ thị tri thức để mô hình hoá miền kiến thức và sinh câu hỏi tự động đã được quan tâm. Cách tiếp cận phổ biến là trích xuất bộ ba (chủ thể, quan hệ, đối tượng) từ đồ thị rồi dùng mẫu câu hoặc mô hình ngôn ngữ để chuyển thành câu hỏi. Hạn chế lớn nhất khi đưa vào thực tế là rủi ro sai lệch: mô hình ngôn ngữ có thể tạo ra câu hỏi chứa dữ kiện không có trong đồ thị, điều đặc biệt nguy hiểm với môn Lịch sử, nơi một con số năm sai có thể khiến toàn bộ câu hỏi trở nên vô giá trị."),

  h2("1.3 Nhận xét và khoảng trống của đề tài"),
  p("Từ khảo sát trên, có thể rút ra ba nhận xét làm cơ sở cho đề tài:"),
  num("Các hệ thống lặp lại ngắt quãng hiện nay mạnh về lập lịch nhưng coi mỗi đơn vị tri thức là độc lập, bỏ qua quan hệ giữa chúng."),
  num("Các nền tảng nội dung biên soạn sẵn đảm bảo độ chính xác nhưng tốn kém và hạn chế số lượng câu hỏi kiểm tra."),
  num("Hướng sinh câu hỏi tự động từ đồ thị tri thức giải quyết được bài toán số lượng, nhưng chưa có cơ chế đủ chặt để bảo đảm mọi dữ kiện trong câu hỏi đều truy nguyên được về nguồn."),
  p("Khoảng trống mà đề tài hướng tới là kết hợp cả ba: dùng đồ thị tri thức làm nền biểu diễn, sinh câu hỏi có kiểm soát bằng cơ chế kiểm chứng tự động, và về lâu dài lan truyền trạng thái ghi nhớ theo cấu trúc đồ thị thay vì theo từng thẻ độc lập."),

  h2("1.4 Hướng đề xuất và phạm vi đồ án"),
  p("Hệ thống đề xuất được thiết kế theo năm tầng xử lý, kế thừa nhau theo thứ tự:"),
  table(
    ["Tầng", "Tên tầng", "Vai trò"],
    [
      ["1", "Tầng tri thức", "Chuẩn hoá tri thức lịch sử thành đồ thị tri thức, lưu trên cơ sở dữ liệu đồ thị, huấn luyện không gian nhúng KGE để tính độ tương đồng giữa các thực thể"],
      ["2", "Tầng sinh nội dung", "Trích chuỗi quan hệ từ đồ thị làm ngữ cảnh, sinh câu hỏi kiểm tra có kiểm soát và kiểm chứng tự động"],
      ["3", "Tầng lập lịch", "Lập lịch học và ôn tập thích nghi theo từng người học (Adaptive Microlearning Scheduling)"],
      ["4", "Tầng tương tác", "Người học làm bài kiểm tra, hệ thống ghi nhận phản hồi đúng/sai và thời gian trả lời"],
      ["5", "Tầng cập nhật đánh giá", "Lan truyền mức suy giảm trí nhớ sang các nút lân cận trên đồ thị (Relational Diffusion)"],
    ],
    [900, 2900, 6400],
  ),
  caption("Bảng 1.1: Năm tầng xử lý của hệ thống đề xuất"),
  p("Trong phạm vi đồ án này, hai tầng đầu — tầng tri thức và tầng sinh nội dung — được xây dựng và thử nghiệm hoàn chỉnh, có số liệu đánh giá định lượng. Ba tầng còn lại được trình bày ở mức thiết kế đề xuất và được xác định là hướng phát triển tiếp theo. Việc giới hạn phạm vi này là chủ ý: hai tầng đầu là nền tảng dữ liệu của toàn hệ thống, và chỉ khi chất lượng đồ thị cùng cơ chế sinh nội dung được kiểm chứng thì các tầng phía sau mới có cơ sở để đánh giá."),
  p("Song song với phần nghiên cứu, đồ án kế thừa một nền tảng ứng dụng đã có sẵn gồm ba thành phần — máy chủ API, trang quản trị nội dung và ứng dụng di động — để làm hạ tầng triển khai cho hệ thống. Chương 2 và Chương 3 trình bày chi tiết các thành phần này."),
  figurePlaceholder("Sơ đồ tổng quan năm tầng xử lý của hệ thống"),
  caption("Hình 1.1: Sơ đồ tổng quan năm tầng xử lý của hệ thống"),

  h2("1.5 Kết chương"),
  p("Chương 1 đã phân tích thực trạng việc học lịch sử, khảo sát ba nhóm giải pháp hiện có và chỉ ra khoảng trống mà đề tài hướng tới: biểu diễn tri thức lịch sử dưới dạng đồ thị để vừa sinh được nội dung kiểm tra có kiểm soát, vừa tạo tiền đề cho việc lập lịch ôn tập theo quan hệ giữa các đơn vị tri thức. Chương tiếp theo trình bày các công nghệ được lựa chọn để hiện thực hoá hướng đi này."),
];
