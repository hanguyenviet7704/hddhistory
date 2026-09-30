# Tầng tri thức & tầng sinh nội dung — thiết kế pipeline nghiên cứu

Ngày: 2026-09-21
Trạng thái: Đã duyệt (chờ triển khai)

## 1. Bối cảnh

Đồ án "hệ thống học Lịch sử theo đồ thị tri thức và lặp lại ngắt quãng thích
nghi" gồm 5 tầng do giáo viên hướng dẫn giao:

1. Tầng tri thức — chuẩn hoá/biểu diễn tri thức trên mô hình đồ thị tri thức
   (KG), lưu trên cơ sở dữ liệu đồ thị, huấn luyện Knowledge Graph Embeddings
   (KGE) để tính độ tương đồng giữa các thực thể.
2. Tầng sinh nội dung — trích chuỗi quan hệ từ KG làm ngữ cảnh để sinh câu hỏi
   có kiểm soát.
3. Tầng lập lịch — Adaptive Microlearning Scheduling.
4. Tầng tương tác — người dùng làm bài kiểm tra, hệ thống ghi nhận phản hồi.
5. Tầng cập nhật đánh giá — lan truyền suy giảm trí nhớ (Relational Diffusion)
   sang các nút lân cận trên KG.

Giáo viên yêu cầu làm **tầng 1 và 2 trước**, trong 1–2 tuần, bằng dữ liệu công
khai (Wikidata / DBpedia / YAGO / ConceptNet) — chưa dùng dữ liệu lịch sử Việt
Nam tự soạn (chưa có sẵn). Sản phẩm là một báo cáo chi tiết giải thích pipeline,
công thức, ví dụ minh hoạ từng bước, kèm demo chạy được. Yêu cầu rõ: hiểu từng
phần trước khi đưa vào báo cáo, không dùng AI sinh ra mà không hiểu.

Tầng 3–5 và việc khảo sát các thuật toán lặp lại ngắt quãng hiện có nằm ngoài
phạm vi tài liệu này — làm sau khi tầng 1–2 xong.

## 2. Mục tiêu và phạm vi

**Trong phạm vi:**
- Trích một subgraph lịch sử Việt Nam từ Wikidata qua SPARQL.
- Lưu subgraph vào Neo4j (cơ sở dữ liệu đồ thị).
- Huấn luyện mô hình KGE (PyKEEN, TransE) trên subgraph, đánh giá bằng MRR/Hits@k.
- Tính độ tương đồng giữa thực thể từ embedding, minh hoạ bằng ví dụ thật.
- Trích chuỗi quan hệ multi-hop quanh một thực thể làm ngữ cảnh có cấu trúc.
- Sinh câu hỏi có kiểm soát từ ngữ cảnh đó, kèm script validate tự động (mọi
  năm/tên riêng trong câu hỏi phải khớp ngữ cảnh đầu vào).
- Một notebook báo cáo giải thích từng bước bằng markdown + công thức + ví dụ.

**Ngoài phạm vi (giai đoạn này):**
- Dữ liệu lịch sử Việt Nam tự soạn (giai đoạn 1858–1945 trong tài liệu đặc tả
  gốc) — sẽ dùng ở giai đoạn sau khi pipeline đã chứng minh được trên dữ liệu
  công khai.
- Tích hợp vào API/app chính (Express/NestJS, Next.js, Flutter) — đây là module
  nghiên cứu độc lập.
- Tầng lập lịch, tầng tương tác, tầng cập nhật đánh giá (Relational Diffusion).

## 3. Kiến trúc

| Thành phần | Công nghệ | Vai trò |
|---|---|---|
| Nguồn dữ liệu | Wikidata SPARQL endpoint (`query.wikidata.org/sparql`) | Trích thực thể/quan hệ lịch sử Việt Nam công khai |
| Lưu trữ đồ thị | Neo4j (Docker, `neo4j:5-community`) | Lưu KG, truy vấn Cypher (multi-hop) |
| Huấn luyện embedding | PyKEEN (Python) | Huấn luyện TransE, đánh giá MRR/Hits@k |
| Ngôn ngữ xử lý | Python 3.9 (venv riêng) | Toàn bộ script + notebook |
| Báo cáo/demo | Jupyter notebook | Markdown + công thức LaTeX + code + hình minh hoạ trong một tài liệu |

Thư mục `knowledge-graph/` là một repo Git độc lập, tách khỏi 3 codebase
Node/Flutter đã đổi tên trước đó (`hddhistory-api`, `hddhistory-admin`,
`hddhistory-flutter`) vì đây là môi trường Python riêng, không tích hợp vào
app chính ở giai đoạn này.

### Cấu trúc thư mục

```
knowledge-graph/
  notebooks/
    01_pipeline_report.ipynb      # notebook báo cáo chính, chạy tuần tự 6 bước
  src/
    extract_wikidata.py           # bước 1: SPARQL -> triples CSV
    load_neo4j.py                 # bước 2: triples CSV -> Neo4j
    train_kge.py                  # bước 3: triples -> PyKEEN -> embedding
    similarity.py                 # bước 4: embedding -> cosine similarity
    relation_chain.py             # bước 5: Cypher multi-hop -> ngữ cảnh có cấu trúc
    generate_question.py          # bước 6: ngữ cảnh -> prompt LLM -> câu hỏi + validate
  data/
    raw/                          # triples thô từ Wikidata
    processed/                    # triples đã chuẩn hoá, embedding đã huấn luyện
  reports/                        # ảnh/xuất PCA-tSNE, log MRR/Hits@k để đưa vào báo cáo
  requirements.txt
  docker-compose.yml              # dịch vụ neo4j
```

## 4. Pipeline chi tiết

### Bước 1 — Trích subgraph từ Wikidata

- Dùng `SPARQLWrapper` gọi `query.wikidata.org/sparql`.
- Lọc thực thể: `wdt:P17 wd:Q881` (quốc gia = Việt Nam) giao với các lớp thực
  thể lịch sử (`wdt:P31` là sự kiện/nhân vật/tổ chức lịch sử — cụ thể hoá khi
  viết query thật, vì độ phủ Wikidata cho từng lớp khác nhau).
- Quan hệ lấy kèm: `P710` (participant), `P585`/`P580`/`P582` (point in
  time/start/end), `P276` (location), `P17` (country), `P39` (position held),
  quan hệ nhân quả nếu có (`P828` has cause).
- Xuất `data/raw/triples.csv` dạng `(head_qid, relation_pid, tail_qid,
  head_label, relation_label, tail_label)` — giữ cả label tiếng Việt/Anh để
  đọc được trong báo cáo.
- Ràng buộc thực tế: nếu số triples quá ít (< 100) để KGE học có ý nghĩa, mở
  rộng phạm vi lọc (bỏ ràng buộc quốc gia nghiêm ngặt, thêm thực thể liên quan
  trực tiếp một hop) — quyết định cụ thể ghi lại trong notebook kèm số liệu đếm
  được, không quyết định trước khi chưa thấy số thật.

### Bước 2 — Nạp vào Neo4j

- Neo4j chạy qua `docker-compose.yml` (image `neo4j:5-community`, cổng 7474/7687).
- `src/load_neo4j.py` đọc `triples.csv`, với mỗi dòng: `MERGE (h:Entity
  {qid: $head_qid}) SET h.label = $head_label`, tương tự cho tail, rồi `MERGE
  (h)-[r:RELATION {pid: $relation_pid, label: $relation_label}]->(t)`.
- Dùng một loại relationship chung `RELATION` với thuộc tính `pid`/`label` thay
  vì một loại Cypher relationship riêng cho mỗi quan hệ, để bước 5 (truy vấn
  multi-hop) không phải liệt kê tên loại quan hệ cố định.

### Bước 3 — Huấn luyện KGE (PyKEEN)

- Đưa `triples.csv` vào `pykeen.triples.TriplesFactory`, chia train/test (ví dụ
  80/20).
- Huấn luyện `TransE` làm baseline. Công thức điểm số:
  `score(h, r, t) = -‖ h + r - t ‖` (càng gần 0 độ lớn âm càng lớn, càng đúng).
  Hàm loss: margin ranking loss giữa triple đúng và triple âm (negative
  sampling).
- Đánh giá: MRR (Mean Reciprocal Rank), Hits@1/3/10 trên test set — log ra
  `reports/kge_eval.json` để trích vào báo cáo.
- Nếu kịp thời gian: huấn luyện thêm `ComplEx` để so sánh, không bắt buộc.

### Bước 4 — Độ tương đồng giữa thực thể

- `src/similarity.py`: lấy vector embedding của các thực thể đã huấn luyện,
  tính cosine similarity: `sim(u, v) = (u·v) / (‖u‖‖v‖)`.
- Ví dụ minh hoạ cụ thể trong notebook: chọn 2 thực thể cùng nhóm (ví dụ hai
  nhân vật cùng một phong trào/tổ chức) và 2 thực thể không liên quan, so sánh
  điểm similarity giữa hai cặp để minh chứng embedding phản ánh đúng cấu trúc
  đồ thị.
- Giảm chiều bằng PCA hoặc t-SNE, vẽ scatter plot các thực thể, lưu vào
  `reports/embedding_plot.png`.

### Bước 5 — Trích chuỗi quan hệ làm ngữ cảnh

- `src/relation_chain.py`: Cypher truy vấn multi-hop quanh 1 thực thể mục tiêu
  (`MATCH path = (e:Entity {qid: $qid})-[:RELATION*1..3]-(other) RETURN path`),
  giới hạn số lượng path trả về để ngữ cảnh không quá dài.
- Chuyển path thành danh sách fact có cấu trúc, dạng
  `{"subject": ..., "relation": ..., "object": ..., "source_pid": ...}` — đây
  là "ngữ cảnh có kiểm soát" cho bước 6, tương tự nguyên tắc ở mục 8.2 tài liệu
  đặc tả gốc (chỉ truyền dữ liệu đã có nguồn, không để mô hình tự nhớ).

### Bước 6 — Sinh câu hỏi có kiểm soát

- `src/generate_question.py`: đưa danh sách fact ở bước 5 vào prompt yêu cầu
  mô hình trả về JSON `{"question": ..., "answer": ..., "explanation": ...,
  "anchors": [qid...]}`.
- Validate tự động sau khi sinh: trích mọi số 4 chữ số và tên riêng xuất hiện
  trong `question`/`answer`/`explanation`, đối chiếu với `subject`/`object`/
  ngày tháng có trong fact đầu vào — nếu có phần tử không khớp, đánh dấu
  `rejected` kèm lý do cụ thể.
- Notebook trình diễn cả 2 trường hợp: (a) input đủ → câu hỏi được chấp nhận,
  (b) cố tình rút bớt fact đầu vào → câu hỏi tham chiếu dữ kiện ngoài ngữ cảnh
  bị chặn — chứng minh cơ chế kiểm soát có tác dụng thật, không chỉ mô tả trên
  giấy.

## 5. Ghi chú kỹ thuật khác

- Không tái sử dụng code Meup/HDDhistory app chính (NestJS/React/Flutter) —
  module này độc lập, chỉ tham khảo nguyên tắc ở mục 8.2 tài liệu đặc tả gốc
  cho bước 6.
- Docker daemon trên máy này hiện chưa chạy — cần khởi động trước khi chạy
  bước 2 (`open -a Docker` rồi đợi daemon sẵn sàng).
- Python hệ thống là 3.9.6, không có Homebrew để cài bản mới hơn — dùng venv
  dựng trên Python 3.9, kiểm tra tương thích PyKEEN ngay khi cài (bước đầu
  triển khai).

## 6. Timeline

| Tuần | Nội dung | Kết quả |
|---|---|---|
| 1 | Bước 1–4: trích dữ liệu, dựng đồ thị, huấn luyện KGE, tính similarity | Notebook chạy được tới bước 4, có số liệu MRR/Hits@k và ví dụ similarity thật, phần đầu báo cáo viết xong |
| 2 | Bước 5–6: trích chuỗi quan hệ, sinh câu hỏi có kiểm soát | Notebook hoàn chỉnh 6 bước, có ví dụ câu hỏi được chấp nhận và bị chặn, báo cáo hoàn thiện |

## 7. Tiêu chí nghiệm thu

- Subgraph Wikidata trích được có số triples đủ lớn để huấn luyện KGE có ý
  nghĩa (ghi rõ số liệu thật, không giả định).
- Mô hình KGE huấn luyện xong có MRR/Hits@k ghi lại được, không phải số bỏ trống.
- Có ít nhất một ví dụ similarity đúng trực giác (hai thực thể liên quan gần
  nhau hơn hai thực thể không liên quan) và được giải thích trong notebook.
- Có ít nhất một câu hỏi sinh ra được validate "chấp nhận" và một trường hợp bị
  "từ chối" do thiếu ngữ cảnh, cả hai đều có trong notebook.
- Mỗi bước trong notebook có phần markdown giải thích công thức/ý nghĩa trước
  đoạn code, không phải chỉ có code và output.
