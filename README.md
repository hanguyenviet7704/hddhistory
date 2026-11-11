# HDDhistory — Học lịch sử Việt Nam bằng đồ thị tri thức

Đồ án tốt nghiệp — Học viện Công nghệ Bưu chính Viễn thông (PTIT).

Hệ thống học lịch sử Việt Nam dựa trên **đồ thị tri thức** (knowledge graph)
kết hợp **nhúng đồ thị** (KGE) để đo độ tương đồng giữa các thực thể và gợi ý
nội dung liên quan.

## Nội dung repo

| Thư mục | Nội dung |
|---|---|
| `knowledge-graph/` | Tầng tri thức: pipeline trích xuất từ Wikidata, huấn luyện KGE (TransE), đo độ tương đồng, và **bộ dữ liệu lịch sử Việt Nam tự soạn** |
| `web/` | Giao diện web (Next.js): tra cứu đồ thị, đọc nội dung khoá học |
| `bao-cao/` | Mã nguồn sinh quyển báo cáo (`.docx`) |
| `hddhistory-api/` | Backend NestJS 9 (REST + WebSocket), dùng MongoDB + MySQL |
| `hddhistory-admin/` | Trang quản trị nội dung (React 19, CRA) |
| `hddhistory-flutter/` | Ứng dụng di động (Flutter, Clean Architecture) |

## Bộ dữ liệu

`knowledge-graph/data/vn_history/vn_history_seed.json` — soạn thủ công và đối
chiếu với Wikidata:

- **176 thực thể**: 76 nhân vật, 43 sự kiện, 31 triều đại/tổ chức, 10 địa danh
- **205 quan hệ** thuộc 35 loại (`led`, `founded`, `succeeded`, `child_of`…)
- **12 thời kỳ** lịch sử, **11 nguồn** sử liệu được trích dẫn

Phủ từ thời Hồng Bàng tới hiện đại.

## Tầng tri thức

Pipeline sáu bước trong `knowledge-graph/src/`, viết ở dạng jupytext (giải
thích bằng văn xuôi trước mỗi khối mã):

1. Trích xuất thực thể từ Wikidata qua SPARQL
2. Làm sạch và chuẩn hoá thành bộ ba `(head, relation, tail)`
3. Huấn luyện nhúng TransE bằng PyKEEN
4. Đo độ tương đồng bằng cosine trên không gian nhúng
5. Gợi ý thực thể liên quan
6. Sinh câu hỏi từ đồ thị

Kết quả đo và phân tích nằm trong `knowledge-graph/notebooks/`.

## Chạy thử

### Đồ thị tri thức (Neo4j)

```bash
docker run -d --name hddhistory-neo4j -p 7474:7474 -p 7687:7687 \
  -e NEO4J_AUTH=neo4j/<mật khẩu> neo4j:5-community
```

### Web

```bash
cd web
cp .env.example .env.local     # trỏ API_BASE_URL vào API
npm install
npm run dev                    # http://localhost:3000
```

### Báo cáo

```bash
cd bao-cao
npm install
node build.js                  # sinh bao-cao-do-an.docx
```

### API (`hddhistory-api/`)

Cần Node 18+, MongoDB và MySQL.

```bash
cd hddhistory-api
cp .env.example .env                                # điền chuỗi kết nối DB, khoá Firebase, R2, Gemini…
cp google-service.example.json google-service.json  # nếu dùng import từ Google Drive/Sheets
npm install
npm run start:dev                                   # http://localhost:4000/api/v1/...
```

Migration MySQL tự chạy khi khởi động, không cần lệnh riêng.

### Admin (`hddhistory-admin/`)

```bash
cd hddhistory-admin
cp .env.example .env          # REACT_APP_BACKEND_URL trỏ vào API
npm install
npm start                     # http://localhost:3000
```

### App di động (`hddhistory-flutter/`)

Cần Flutter SDK (xem `hddhistory-flutter/pubspec.yaml` để biết phiên bản Dart).
Tạo file `hddhistory-flutter/.env/.env.dev` với các khoá:

```
API_BASE_URL=
SOCKET_BASE_URL=
AI_SERVICE_BASE_URL=
API_KEY=
CONNECT_TIMEOUT=
RECEIVE_TIMEOUT=
APP_ENVIRONMENT=
```

```bash
cd hddhistory-flutter
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart run slang
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=.env/.env.dev
```

Hoặc dùng các script trong `tools/macos/build/` (`run_app.sh`, `build_apk.sh`…).

> Các file `.env` thật **không** nằm trong repo — xin chủ repo gửi riêng.

## Nguồn gốc mã nguồn ứng dụng

`hddhistory-api/`, `hddhistory-admin/` và `hddhistory-flutter/` được tách
(fork) từ nền tảng Meup rồi đổi tên thành HDDhistory; lịch sử commit của từng
phần được giữ nguyên trong repo này. Một số tên gắn với hạ tầng của Meup (domain
`meup.training`, Firebase project `meup-bf64f`, mã sản phẩm IAP `meup_*`) vẫn
được giữ nguyên.
