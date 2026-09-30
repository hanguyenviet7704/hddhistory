# Stack local độc lập + nội dung lịch sử Việt Nam

Ngày: 2026-09-28

## Mục tiêu

Dựng một môi trường dev chạy được **không cần mạng nội bộ công ty và không cần
server dev**, rồi đổ vào đó một bộ nội dung lịch sử Việt Nam thật, tổ chức theo
trục biên niên.

Thành công nghĩa là: tắt VPN, chạy app trên simulator, đăng nhập được, và duyệt
được 12 thời kỳ lịch sử với nội dung đọc thật ở tầng keypoint.

## Hiện trạng (đo ngày 2026-09-28)

Bản app trên simulator được build với `.env/.env.dev.kglocal`, tức
`API_BASE_URL=http://localhost:4098`. Cổng 4098 không phải NestJS mà là
`scripts/_kg-dev-proxy.js`, chia đôi lưu lượng:

| Đường dẫn | Đích | Trạng thái |
|---|---|---|
| `/api/v1/knowledge-graph/*` | `localhost:4099` | chết, không có tiến trình nào listen |
| còn lại | `https://api-aitutor-dev.eup.ai` | đang chạy |

Nên mọi thứ nhìn thấy trong app hiện nay là dữ liệu server dev thật.

Bốn rào chặn việc chạy API local:

1. `.env` trỏ `MYSQL_HOST=192.168.10.35:33003` — **không tới được từ máy này**
   (đã kiểm tra). `MysqlModule` đặt `migrationsRun: true` nên thiếu MySQL là
   chết lúc boot, dù chỉ `PaymentModule` dùng tới nó.
2. `MONGODB_URI` trỏ host `meup_mongo` — tên service Docker, chỉ đúng khi API
   chạy trong cùng network.
3. `google-service.json` là placeholder rỗng. `FirebaseService` gọi
   `admin.credential.cert()` ngay trong constructor (`src/base/config/firebase.ts:12`)
   → ném lỗi, mọi module chạm `AuthModule` chết theo. `coach-di.check.ts` đã ghi
   nhận và stub tạm chính vấn đề này.
4. DB local rỗng — không user, không khoá học, không onboarding config.

## Quyết định đã chốt

| Vấn đề | Chốt |
|---|---|
| Mức độc lập | Hoàn toàn — không phụ thuộc server dev |
| Nơi chạy API | Trên host (`npm run start:dev`), chỉ DB trong Docker |
| Trục phân loại skillset | Biên niên, bám 12 `periods` có sẵn |
| Khối lượng | Dày — mỗi thời kỳ 2–3 khoá |
| Ngôn ngữ | Chỉ tiếng Việt |
| Ảnh | Placeholder phân biệt theo thời kỳ |

## Kiến trúc

### Hạ tầng

Docker chỉ chạy 2 DB, dùng `docker-compose.local.yml` có sẵn, **không sửa file
này**: `meup_mongo` (27017), `meup_mysql` (3306). API chạy trên host, cổng 3000.

`.env` sửa đúng 2 khối:

```
MONGODB_URI=mongodb://admin:PGmnyFWTr9XyAvDX@localhost:27017/ai-tutor?authSource=admin
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USERNAME=root
MYSQL_PASSWORD=localroot
MYSQL_DB=ai_tutor
```

Dùng `root` chứ không phải user `hddhistory` của compose, vì 12 migration TypeORM cần
quyền DDL. Chúng tự chạy lúc boot và tự dựng toàn bộ bảng payment — không có
bước thủ công nào.

`.env` là file gitignore, nên đây không phải thay đổi được commit. Giá trị cũ
(trỏ mạng nội bộ) ghi lại ở đây để khôi phục khi cần: `MYSQL_HOST=192.168.10.35`,
`MYSQL_PORT=33003`, `MYSQL_USERNAME=admin`, `MYSQL_PASSWORD=PGmnyFWTr9XyAvDX`.

Neo4j (`hddhistory-neo4j`, cổng 7687) đã chạy sẵn và `.env` đã trỏ đúng — không
cần đụng.

### Proxy 4098 bị khai tử

`KnowledgeGraphModule` đã nằm trong `app.module.ts`, và Neo4j chạy local. Khi API
local phục vụ mọi route kể cả nhánh đồ thị tri thức, lý do tồn tại của proxy biến
mất. `scripts/_kg-dev-proxy.js` và `_kg-dev-server.ts` là file chưa commit
(`??` trong git status) nên chỉ cần dừng tiến trình, không xoá file — chúng vẫn
dùng được nếu sau này muốn quay lại chế độ lai.

### Thay đổi code production: đúng một chỗ

`src/base/config/firebase.ts`. Thêm nhánh: khi service account thiếu
`project_id` **và** `NODE_ENV !== 'production'`, dựng một app no-op thay vì
`credential.cert()`, kèm `logger.warn` nói rõ push/Remote Config đang tắt.

Hai điều kiện chứ không phải một: thiếu `project_id` là dấu hiệu placeholder, còn
chặn `production` đảm bảo môi trường thật không bao giờ im lặng chạy với Firebase
giả — ở đó thiếu credential vẫn phải là lỗi ồn ào.

Không đụng vào logic nghiệp vụ nào khác.

## Seed

Ba script mới, theo đúng khuôn `scripts/seed-habits.ts`: `ts-node`, đọc
`MONGODB_URI` từ `.env`, **idempotent** (khớp trước khi ghi, chạy lại nhiều lần
không nhân bản).

| Script | Việc |
|---|---|
| `scripts/seed-dev-user.ts` | 1 user test cho `POST /auth/dev-login` |
| `scripts/seed-vn-history.ts` | dựng cây Skillset → Course → Lesson → Keypoint |
| `scripts/generate-placeholder-images.ts` | sinh ảnh placeholder theo thời kỳ |

Thêm 3 lệnh vào `package.json`: `seed:dev-user`, `seed:vn-history`,
`gen:placeholder-images`.

Khoá idempotent: Skillset theo `title.vi`, Course theo `(title.vi, skillsetId)`,
Lesson theo `(title.vi, courseId)`, Keypoint theo `(title.vi, index)` trong bài.

Nội dung tách khỏi code, đặt ở `scripts/data/vn-history-curriculum.json`. Đây là
nguyên liệu seed, không phải dữ liệu runtime, nên không nằm trong `src/`.

### Ảnh placeholder

Sinh cục bộ thành SVG trong `public/`, phục vụ ở tiền tố `/static/` (đã cấu hình
sẵn trong `src/main.ts`). Mỗi thời kỳ một nền màu riêng kèm chữ tên thời kỳ và
khoảng năm.

Đây là điều chỉnh so với lựa chọn "dịch vụ placeholder ngoài": nó cho đúng thứ
bạn cần — phân biệt được khoá khi duyệt, không giả vờ là ảnh tư liệu thật — mà
không kéo theo phụ thuộc mạng, vốn mâu thuẫn với mục tiêu độc lập hoàn toàn. Nếu
bạn muốn đúng dịch vụ ngoài thì nói, đổi lại rất nhanh.

## Nội dung

12 skillset bám thẳng 12 `periods` trong
`src/modules/knowledge-graph/data/vn_history_seed.json`, giữ nguyên tên và mốc
thời gian để hai bộ dữ liệu không trôi khỏi nhau. `index` của skillset chạy theo
thứ tự thời gian.

Phân bổ khoá (32 khoá, ~160 bài, ~560 keypoint):

| # | Thời kỳ | Khoá |
|---|---|---|
| 1 | Hồng Bàng | Truyền thuyết dựng nước · Âu Lạc và An Dương Vương |
| 2 | Bắc thuộc | Ách đô hộ phương Bắc · Hai Bà Trưng và Bà Triệu · Từ Lý Bí đến Ngô Quyền |
| 3 | Ngô–Đinh–Tiền Lê | Buổi đầu tự chủ · Đinh Bộ Lĩnh thống nhất · Lê Hoàn chống Tống |
| 4 | Nhà Lý | Dời đô về Thăng Long · Lý Thường Kiệt chống Tống · Văn hoá và Phật giáo thời Lý |
| 5 | Nhà Trần | Nhà Trần thay nhà Lý · Ba lần chống Mông–Nguyên · Trúc Lâm và chữ Nôm |
| 6 | Hồ–thuộc Minh–Lam Sơn | Hồ Quý Ly và cải cách · Hai mươi năm thuộc Minh · Khởi nghĩa Lam Sơn |
| 7 | Lê sơ | Lê Thái Tổ dựng triều · Lê Thánh Tông và luật Hồng Đức |
| 8 | Trịnh–Nguyễn | Mạc Đăng Dung và Nam–Bắc triều · Đàng Trong – Đàng Ngoài · Nam tiến mở cõi |
| 9 | Tây Sơn | Ba anh em Tây Sơn · Quang Trung đại phá quân Thanh |
| 10 | Nhà Nguyễn | Gia Long thống nhất · Minh Mạng và bộ máy nhà nước |
| 11 | Pháp thuộc | Pháp xâm lược · Cần Vương và các phong trào yêu nước · Tới Cách mạng tháng Tám |
| 12 | Hiện đại | Kháng chiến chống Pháp 1945–1954 · Giai đoạn 1954–1975 · Thống nhất và Đổi mới |

Mỗi khoá 5 bài, mỗi bài 3–4 keypoint. Keypoint là nơi nội dung đọc thật nằm —
mỗi cái một ý trọn vẹn, 80–150 chữ.

### Nguyên tắc biên tập

Lấy thẳng từ `note_on_accuracy` của bộ seed, và đây là ràng buộc chứ không phải
khuyến nghị:

- **Hồng Bàng và đầu Bắc thuộc là huyền sử/bán huyền sử.** Không có xác nhận
  khảo cổ hay văn bản đồng đại. Viết rõ "theo truyền thuyết", "theo *Đại Việt sử
  ký toàn thư*" — không nêu như sự thật xác quyết. Từ Ngô–Đinh trở đi niên đại
  mới có đồng thuận sử học.
- **Thời kỳ hiện đại (1945–nay) viết ở mức sự kiện và mốc thời gian**: ai, ở đâu,
  khi nào, hệ quả trực tiếp. Không đưa đánh giá chính trị vào nội dung học.
- Niên đại, tên riêng và quan hệ nhân vật **đối chiếu với `entities`/`relations`
  của `vn_history_seed.json`**, không bịa thêm thực thể mới. Bộ seed đó đã qua rà
  soát thủ công, kể cả sửa một lỗi quan hệ (Dương Tam Kha là em vợ Ngô Quyền,
  không phải cha vợ).
- Chỉ điền `title.vi` / `description.vi`. Các locale khác bỏ trống.

## Nối app vào

File env mới cho Flutter: `.env/.env.dev.local`, chép từ `.env.dev.kglocal` và
đổi `API_BASE_URL=http://localhost:3000`. `SOCKET_BASE_URL` cũng trỏ về
`ws://localhost:3000`, nếu không socket vẫn lén ra server dev.

iOS Simulator dùng chung network với host nên `localhost` chạy thẳng. Android
emulator sẽ cần `10.0.2.2` — ghi chú lại, chưa làm đợt này.

Build lại bằng `--dart-define-from-file=.env/.env.dev.local` (không bao giờ dùng
`--dart-define` rời).

## Kiểm chứng

Không chạy full test suite (máy này hết RAM — CLAUDE.md). Các mốc kiểm:

1. `docker compose -f docker-compose.local.yml up -d` → 2 container Up.
2. `npm run build` — cổng CI thật, strict mode. `tsc --noEmit` dùng config lỏng
   nên không đủ.
3. API boot sạch, không lỗi Firebase, migration chạy hết → `typeorm_migrations`
   có 12 dòng.
4. `POST /api/v1/auth/dev-login` trả token.
5. `GET /api/v1/skillsets` trả 12 skillset đúng thứ tự thời gian.
6. Đếm trong Mongo: 12 skillset, 32 course, ~160 lesson, ~560 keypoint.
7. Chạy lại seeder lần hai → số lượng không đổi (chứng minh idempotent).
8. App trên simulator: đăng nhập, mở danh sách, đọc được keypoint thật.

## Ngoài phạm vi

- Android emulator.
- Dịch en/zh/ja/ko.
- Ảnh tư liệu thật (bản quyền).
- Audio/voiceover cho keypoint.
- Đổ nội dung này lên server dev hay production.
- Chuyển chính `_kg-dev-proxy.js` thành thứ dùng lâu dài.

## Rủi ro

- **Cây thư mục đang bẩn** — 19 file thay đổi từ các session khác (`community/bot`,
  `knowledge-graph`, schema user...). Chỉ stage đúng file mình chạm, theo path.
  Không `git add <thư mục>`, không `git stash`, không `git restore`.
- **Seed thiếu onboarding config** có thể làm app chặn ở màn onboarding trước khi
  tới được nội dung. Chưa đo được cho tới khi API local chạy thật; nếu vướng thì
  bổ sung seed onboarding, ghi nhận vào plan.
- **Khối lượng biên soạn lớn** (~560 keypoint). Làm theo lô 12 thời kỳ, mỗi lô
  seed và kiểm được ngay, để hỏng thì hỏng một lô chứ không hỏng cả mẻ.
