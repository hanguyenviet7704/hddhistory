const { p, h1, h2, h3, bullet, table, code, formula, figurePlaceholder, caption } = require("../lib/helpers");

module.exports = () => [
  h1("Chương 2: Các công nghệ sử dụng"),

  h2("2.1 Tổng quan lựa chọn công nghệ"),
  p("Hệ thống gồm hai nhóm thành phần có yêu cầu kỹ thuật khác nhau, do đó sử dụng hai nhóm công nghệ tương ứng. Nhóm thứ nhất là nền tảng ứng dụng phục vụ người dùng cuối, gồm máy chủ API, trang quản trị nội dung và ứng dụng di động. Nhóm thứ hai là module nghiên cứu xây dựng tầng tri thức và tầng sinh nội dung, hoạt động độc lập theo dạng pipeline xử lý dữ liệu."),
  table(
    ["Thành phần", "Công nghệ chính", "Vai trò"],
    [
      ["Máy chủ API", "NestJS 9 (Node.js, TypeScript)", "Cung cấp REST API và WebSocket cho ứng dụng di động và trang quản trị"],
      ["Trang quản trị", "React 19 (Create React App)", "Biên soạn và kiểm duyệt nội dung học tập"],
      ["Ứng dụng di động", "Flutter (Dart SDK 3.12)", "Giao diện học tập cho người dùng cuối trên iOS và Android"],
      ["Cơ sở dữ liệu nghiệp vụ", "MongoDB 6 và MySQL 8", "Lưu nội dung học tập (MongoDB) và dữ liệu thanh toán (MySQL)"],
      ["Cơ sở dữ liệu đồ thị", "Neo4j 5 Community", "Lưu đồ thị tri thức, truy vấn quan hệ đa bước bằng Cypher"],
      ["Học biểu diễn đồ thị", "PyKEEN 1.11 (PyTorch)", "Huấn luyện mô hình nhúng đồ thị tri thức TransE"],
      ["Nguồn dữ liệu mở", "Wikidata (SPARQL)", "Trích xuất dữ liệu thực thể lịch sử công khai"],
      ["Mô hình ngôn ngữ", "API mô hình ngôn ngữ lớn", "Sinh câu hỏi kiểm tra từ ngữ cảnh đã kiểm chứng"],
    ],
    [2400, 3000, 4800],
  ),
  caption("Bảng 2.1: Tổng hợp công nghệ sử dụng trong hệ thống"),

  h2("2.2 NestJS"),
  p("NestJS là framework xây dựng ứng dụng phía máy chủ trên nền Node.js, sử dụng TypeScript và mô hình kiến trúc mô-đun hoá theo kiểu Angular. Máy chủ API của hệ thống sử dụng NestJS phiên bản 9.4.3 cùng TypeScript 4.9.5."),
  p("Lý do lựa chọn NestJS cho đề tài này gồm ba điểm. Thứ nhất, NestJS áp đặt sẵn một cấu trúc phân lớp rõ ràng gồm controller, service và repository; với một hệ thống có quy mô lớn (93 controller, 132 service, 133 repository trong mã nguồn hiện tại) thì ràng buộc kiến trúc này giúp mã nguồn không bị rối. Thứ hai, cơ chế tiêm phụ thuộc (dependency injection) sẵn có cho phép thay thế tầng truy cập dữ liệu mà không sửa tầng nghiệp vụ. Thứ ba, NestJS hỗ trợ đồng thời REST và WebSocket trong cùng một ứng dụng, phù hợp với nhu cầu vừa trả dữ liệu theo yêu cầu vừa đẩy sự kiện thời gian thực."),
  p("Hệ thống cấu hình tiền tố toàn cục là /api kết hợp cơ chế đánh phiên bản theo URI với phiên bản mặc định là 1, do đó mọi endpoint đều có dạng /api/v1/…"),
  code([
    "// src/main.ts",
    "app.setGlobalPrefix('api');",
    "app.enableVersioning({",
    "  type: VersioningType.URI,",
    "  defaultVersion: '1',",
    "});",
  ]),

  h2("2.3 React và hệ sinh thái giao diện quản trị"),
  p("Trang quản trị nội dung được xây dựng bằng React phiên bản 19.1.1 khởi tạo qua Create React App 5.0.1, sử dụng TypeScript 4.9.5. Các thư viện chính gồm React Router DOM 7.9.3 cho điều hướng, Redux Toolkit 2.9.0 cho quản lý trạng thái toàn cục, Material UI 7.3.2 kết hợp Tailwind CSS 3.4.17 cho giao diện, và Axios 1.12.2 cho giao tiếp HTTP."),
  p("Một đặc điểm đáng chú ý trong thiết kế trạng thái của trang quản trị: Redux chỉ được dùng cho hai lát cắt trạng thái mang tính toàn cục thật sự là ngôn ngữ hiển thị và thông báo hệ thống. Dữ liệu lấy từ máy chủ không được lưu vào Redux mà do từng trang tự gọi service tương ứng và giữ trong trạng thái cục bộ của component. Cách làm này đánh đổi khả năng chia sẻ dữ liệu giữa các trang để lấy sự đơn giản và tránh việc đồng bộ hoá bộ nhớ đệm phức tạp."),
  p("Ngoài ra, trang quản trị sử dụng một số thư viện chuyên biệt phục vụ công việc biên soạn nội dung: TipTap 2.27.1 làm trình soạn thảo văn bản định dạng, dnd-kit cho thao tác kéo thả sắp xếp thứ tự bài học, Recharts 3.10.1 cho biểu đồ thống kê và thư viện xlsx cho nhập/xuất dữ liệu dạng bảng tính."),

  h2("2.4 Flutter"),
  p("Ứng dụng di động sử dụng Flutter với yêu cầu Dart SDK từ phiên bản 3.12.0. Flutter cho phép dùng chung một mã nguồn cho cả iOS và Android, đồng thời kiểm soát được chi tiết giao diện — yếu tố quan trọng với một ứng dụng học tập cần điều chỉnh cỡ chữ, độ tương phản và nhịp hoạt ảnh theo từng nhóm người dùng."),
  p("Các thư viện chính được sử dụng gồm: flutter_bloc 9.1.1 cho quản lý trạng thái theo mô hình BLoC/Cubit, get_it 9.2.1 kết hợp injectable 3.0.0 cho tiêm phụ thuộc, go_router 17.3.0 cho điều hướng khai báo, Dio 5.9.2 kết hợp Retrofit 4.9.2 cho giao tiếp REST, freezed 3.2.5 cho sinh mã lớp dữ liệu bất biến, hydrated_bloc 11.0.0 cho lưu trạng thái xuống bộ nhớ thiết bị, và just_audio 0.10.5 cho phát nội dung thu âm."),
  p("Ứng dụng được tổ chức theo Clean Architecture: mỗi tính năng được chia thành ba lớp data, domain và presentation. Lớp domain định nghĩa thực thể nghiệp vụ, giao diện repository và các use case; lớp data hiện thực repository thông qua các nguồn dữ liệu cục bộ và từ xa; lớp presentation chứa Cubit quản lý trạng thái cùng các trang và widget."),

  h2("2.5 MongoDB và MySQL"),
  p("Hệ thống sử dụng đồng thời hai cơ sở dữ liệu quan hệ và phi quan hệ cho hai loại dữ liệu có đặc tính khác nhau."),
  p("MongoDB (truy cập qua Mongoose 6.13.8) lưu phần lớn dữ liệu nghiệp vụ: nội dung học tập, tiến độ người dùng, cấu hình hiển thị. Lựa chọn này phù hợp vì nội dung học tập có cấu trúc không đồng đều — cùng là một đơn vị học nhưng bài lý thuyết, bài tập và bài hội thoại có các trường dữ liệu rất khác nhau — và việc lồng tài liệu giúp giảm số truy vấn khi dựng một màn hình."),
  p("MySQL (truy cập qua TypeORM 0.3.27 và driver mysql2 3.15.3) lưu riêng dữ liệu thanh toán và đăng ký gói dịch vụ. Đây là nhóm dữ liệu đòi hỏi tính toàn vẹn giao dịch chặt chẽ, quan hệ rõ ràng giữa sản phẩm, giá, đơn hàng và trạng thái thuê bao, nên mô hình quan hệ là lựa chọn phù hợp hơn. Cấu hình TypeORM tắt chế độ tự đồng bộ lược đồ và chạy migration tự động khi khởi động ứng dụng, bảo đảm thay đổi cấu trúc bảng luôn được ghi nhận thành phiên bản."),

  h2("2.6 Neo4j và ngôn ngữ truy vấn Cypher"),
  p("Neo4j là cơ sở dữ liệu đồ thị gốc: dữ liệu được lưu trực tiếp dưới dạng nút và cạnh có thuộc tính thay vì mô phỏng đồ thị bằng các bảng quan hệ. Hệ thống sử dụng Neo4j 5 bản Community chạy trong Docker."),
  p("Lý do dùng Neo4j thay vì tiếp tục lưu đồ thị trong MongoDB nằm ở loại truy vấn cần thực hiện. Tầng sinh nội dung cần lấy toàn bộ quan hệ trong bán kính hai đến ba bước từ một thực thể — đây là truy vấn duyệt đồ thị, mà với cơ sở dữ liệu quan hệ hoặc tài liệu sẽ phải thực hiện nhiều phép nối lồng nhau với chi phí tăng theo cấp số nhân theo số bước. Ngôn ngữ Cypher của Neo4j diễn đạt trực tiếp loại truy vấn này:"),
  code([
    "MATCH path = (e:Entity {qid: $qid})-[:RELATION*1..2]-(other)",
    "UNWIND relationships(path) AS rel",
    "WITH DISTINCT startNode(rel) AS s, rel, endNode(rel) AS o",
    "RETURN s.label AS subject, rel.label AS relation,",
    "       o.label AS object, rel.pid AS source_pid",
    "LIMIT $limit",
  ]),
  p("Mô hình dữ liệu trên Neo4j được thiết kế tối giản: mọi thực thể là nút mang nhãn Entity với hai thuộc tính qid và label; mọi quan hệ dùng chung một loại cạnh RELATION mang thuộc tính pid và label. Việc dùng một loại cạnh chung thay vì tạo loại cạnh riêng cho từng quan hệ giúp truy vấn đa bước không phải liệt kê trước danh sách loại quan hệ, nhờ đó thêm loại quan hệ mới không cần sửa truy vấn."),

  h2("2.7 Đồ thị tri thức và mô hình nhúng TransE"),
  h3("2.7.1 Khái niệm đồ thị tri thức"),
  p("Đồ thị tri thức biểu diễn tri thức dưới dạng tập hợp các bộ ba (h, r, t), trong đó h là thực thể chủ thể, r là loại quan hệ và t là thực thể đối tượng. Ví dụ, phát biểu “Ngô Quyền lãnh đạo Trận Bạch Đằng năm 938” được biểu diễn thành bộ ba (Ngô Quyền, lãnh đạo, Trận Bạch Đằng năm 938). Cách biểu diễn này cho phép máy tính duyệt, suy luận và tính toán trên tri thức thay vì chỉ lưu trữ văn bản."),

  h3("2.7.2 Bài toán nhúng đồ thị tri thức"),
  p("Nhúng đồ thị tri thức (Knowledge Graph Embedding) là kỹ thuật ánh xạ mỗi thực thể và mỗi loại quan hệ thành một vector số trong không gian nhiều chiều, sao cho cấu trúc quan hệ của đồ thị được bảo toàn trong không gian đó. Khi đã có biểu diễn vector, các phép toán vốn khó thực hiện trên đồ thị rời rạc — như đo độ tương đồng giữa hai thực thể hay dự đoán quan hệ còn thiếu — trở thành các phép toán đại số tuyến tính thông thường."),

  h3("2.7.3 Mô hình TransE"),
  p("TransE là mô hình nhúng đồ thị tri thức cổ điển và dễ diễn giải nhất, được chọn làm mô hình cơ sở trong đồ án. Ý tưởng của TransE là coi mỗi quan hệ như một phép tịnh tiến trong không gian vector: nếu bộ ba (h, r, t) là đúng thì vector của h cộng với vector của r phải xấp xỉ vector của t."),
  formula("score(h, r, t) = − ‖ h + r − t ‖"),
  p("Trong đó ‖·‖ là chuẩn L1 hoặc L2. Dấu âm được đặt trước để giá trị điểm số càng cao tương ứng với bộ ba càng có khả năng đúng. Mô hình được huấn luyện bằng hàm mất mát margin ranking loss: với mỗi bộ ba đúng, hệ thống sinh ra một bộ ba sai bằng cách thay thế ngẫu nhiên thực thể đầu hoặc cuối (kỹ thuật negative sampling), rồi tối ưu sao cho điểm số của bộ ba đúng lớn hơn điểm số của bộ ba sai ít nhất một khoảng margin."),
  formula("L = Σ max(0, γ + score(h′, r, t′) − score(h, r, t))"),
  p("Sau khi huấn luyện, độ tương đồng giữa hai thực thể được đo bằng cosine similarity giữa hai vector biểu diễn của chúng:"),
  formula("sim(u, v) = (u · v) / (‖u‖ · ‖v‖)"),
  p("Giá trị nằm trong đoạn [−1, 1]; càng gần 1 thì hai thực thể càng được mô hình đánh giá là xuất hiện trong ngữ cảnh quan hệ tương tự nhau."),

  h3("2.7.4 Độ đo đánh giá"),
  p("Chất lượng mô hình nhúng được đánh giá bằng bài toán dự đoán liên kết: với mỗi bộ ba trong tập kiểm thử, mô hình xếp hạng toàn bộ thực thể có thể đứng ở vị trí cần dự đoán, sau đó xem thực thể đúng nằm ở thứ hạng nào. Hai độ đo được sử dụng:"),
  bullet("**MRR (Mean Reciprocal Rank)** — trung bình của nghịch đảo thứ hạng trên toàn bộ tập kiểm thử. Giá trị càng gần 1 càng tốt."),
  bullet("**Hits@k** — tỉ lệ các bộ ba mà thực thể đúng nằm trong nhóm k thực thể được xếp hạng cao nhất. Đồ án báo cáo Hits@1, Hits@3 và Hits@10."),

  h2("2.8 PyKEEN"),
  p("PyKEEN là thư viện Python chuyên cho nghiên cứu nhúng đồ thị tri thức, xây dựng trên PyTorch. Đồ án sử dụng PyKEEN phiên bản 1.11.0. Thư viện cung cấp sẵn nhiều mô hình nhúng (TransE, DistMult, ComplEx, RotatE…), cơ chế chia tập huấn luyện/kiểm thử và bộ độ đo đánh giá chuẩn, nhờ đó kết quả có thể so sánh được với các công bố khác."),
  p("Trong quá trình cài đặt, đồ án gặp một lỗi tương thích thư viện đáng ghi nhận: phiên bản class-resolver từ 0.5.5 trở lên khiến việc nạp mô-đun pykeen.triples thất bại do xung đột kiểm tra kiểu theo chuẩn PEP 612 trên môi trường Python 3.9. Lỗi được xử lý bằng cách ghim class-resolver ở phiên bản 0.5.1 — đúng mức tối thiểu mà PyKEEN khai báo — và ghi chú trực tiếp trong tệp requirements để tránh vô tình nâng cấp về sau."),

  h2("2.9 Wikidata và ngôn ngữ truy vấn SPARQL"),
  p("Wikidata là cơ sở tri thức mở do cộng đồng xây dựng, lưu dữ liệu dưới dạng RDF. Mỗi thực thể có một mã định danh dạng QID (ví dụ Q8740 là Chiến tranh Việt Nam) và mỗi loại thuộc tính có mã PID (ví dụ P710 là “người tham gia”). Wikidata cung cấp một điểm truy vấn SPARQL công khai, cho phép trích xuất dữ liệu có cấu trúc mà không cần tải toàn bộ kho dữ liệu."),
  p("SPARQL là ngôn ngữ truy vấn chuẩn cho dữ liệu RDF, hoạt động theo nguyên tắc khớp mẫu bộ ba. Truy vấn dưới đây lấy các thực thể có thuộc tính quốc gia là Việt Nam cùng một số loại quan hệ quan tâm:"),
  code([
    "SELECT ?head ?headLabel ?relation ?relationLabel ?tail ?tailLabel WHERE {",
    "  ?head wdt:P17 wd:Q881 .",
    "  { ?head wdt:P710 ?tail . BIND(wd:P710 AS ?relation) }",
    "  UNION { ?head wdt:P585 ?tail . BIND(wd:P585 AS ?relation) }",
    "  UNION { ?head wdt:P276 ?tail . BIND(wd:P276 AS ?relation) }",
    "  SERVICE wikibase:label { bd:serviceParam wikibase:language \"vi,en\". }",
    "}",
    "LIMIT 1000",
  ]),
  p("Wikidata được dùng trong đồ án với hai vai trò: làm dữ liệu công khai để kiểm chứng pipeline xử lý trước khi áp dụng lên dữ liệu tự biên soạn, và làm nguồn đối chiếu chéo để phát hiện sai sót trong bộ dữ liệu tự biên soạn."),

  h2("2.10 Mô hình ngôn ngữ lớn và sinh nội dung có kiểm soát"),
  p("Mô hình ngôn ngữ lớn được sử dụng ở tầng sinh nội dung để chuyển một tập dữ kiện có cấu trúc thành câu hỏi kiểm tra bằng ngôn ngữ tự nhiên. Tuy nhiên, với môn Lịch sử, việc để mô hình tự do sinh nội dung là rủi ro: mô hình có thể đưa vào câu hỏi những mốc thời gian hoặc tên riêng không tồn tại trong dữ liệu đầu vào."),
  p("Đồ án do đó áp dụng nguyên tắc sinh có kiểm soát gồm hai lớp. Lớp thứ nhất là ràng buộc trong lời nhắc: chỉ cung cấp cho mô hình đúng tập dữ kiện đã trích từ đồ thị, yêu cầu mô hình không dùng bất kỳ tên riêng hay năm nào ngoài tập đó, và bắt buộc trả kết quả theo định dạng JSON có khai báo danh sách thực thể đã sử dụng. Lớp thứ hai — quan trọng hơn — là kiểm chứng tự động sau khi sinh: một đoạn mã đối chiếu mọi số năm bốn chữ số và mọi thực thể được khai báo trong câu hỏi với tập dữ kiện đầu vào, và từ chối câu hỏi nếu phát hiện phần tử không khớp. Chi tiết cơ chế này được trình bày ở mục 4.8."),

  h2("2.11 Kết chương"),
  p("Chương 2 đã trình bày các công nghệ được lựa chọn cùng lý do lựa chọn tương ứng với từng bài toán cụ thể của hệ thống: NestJS, React và Flutter cho nền tảng ứng dụng; MongoDB và MySQL cho dữ liệu nghiệp vụ; Neo4j cho lưu trữ và truy vấn đồ thị; PyKEEN với mô hình TransE cho học biểu diễn; Wikidata và SPARQL cho nguồn dữ liệu mở; và mô hình ngôn ngữ lớn kèm cơ chế kiểm soát cho sinh nội dung. Chương tiếp theo trình bày phân tích và thiết kế hệ thống trên nền các công nghệ này."),
];
