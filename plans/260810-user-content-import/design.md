# User Content Import — sinh luồng học từ PDF / YouTube

**Ngày:** 2026-08-10
**Phạm vi:** hddhistory-api, hddhistory-flutter, hddhistory-admin
**Trạng thái:** Design đã duyệt, chưa lên implementation plan

---

## 1. Vấn đề

Người học có tài liệu riêng — giáo trình PDF, video bài giảng YouTube — nhưng không có cách đưa
chúng vào HDDhistory. Họ phải đọc/xem bên ngoài app, mất mạch học và không tính vào chuỗi ngày học.

Tính năng này cho người học nạp một tài liệu vào app, hệ thống dùng AI đọc và soạn lại thành một
bài học có cấu trúc dài 3500–5000 từ, đọc ngay trong app.

## 2. Quyết định đã chốt

| Câu hỏi | Quyết định |
|---|---|
| Ai dùng | End-user, tự import trong app Flutter |
| Nguồn đầu vào (v1) | PDF + link YouTube |
| Loại nội dung sinh ra | Chỉ lý thuyết (theory). Không bài tập, không roleplay |
| Độ dài | 3500–5000 từ, chia 5–8 phần (~500–1000 từ/phần) |
| Ngôn ngữ đầu ra | User chọn khi import; mặc định = ngôn ngữ app đang dùng |
| Nhà cung cấp AI | Gemini Flash |
| Cách đọc PDF | Gửi thẳng file cho Gemini, không tự tách text |
| Audio (TTS) | Không có ở v1 |
| Quyền truy cập | Premium-only + quota |
| Quyền xem nội dung | Riêng tư với người tạo; admin xem được |
| Đường vào trong app | Một hàng mới trong màn Hồ sơ |
| Cách đọc bài | Một trang cuộn liền, không chia màn từng phần |
| Chạy job | Mongo-persisted job + heartbeat, client polling |

## 3. Kiến trúc tổng thể

```
Flutter                         hddhistory-api                        Bên ngoài
───────                         ────────                        ─────────
chọn PDF ──upload──────────────▶ POST /cloudflares/upload ─────▶ Cloudflare R2
                                                                  (đã có sẵn)
tạo bài ───────────────────────▶ POST /learning-imports
                                   ├─ check premium
                                   ├─ check quota
                                   ├─ tạo learning_import_jobs
                                   └─ setImmediate(runJob)
                                        │
poll ──────────────────────────▶ GET /learning-imports/:id
                                        │
                                        ├─ lấy nguồn (R2 / YouTube transcript)
                                        ├─ gọi Gemini ────────────▶ Gemini Flash
                                        ├─ kiểm tra kết quả
                                        └─ ghi user_lessons
                                        │
đọc bài ───────────────────────▶ GET /user-lessons/:id

hddhistory-admin ────────────────────▶ GET /admin/learning-imports
```

Không dùng hàng đợi (dự án không có Redis/BullMQ). Job chạy in-process bằng `setImmediate`,
nhưng **tiến độ lưu trong Mongo chứ không trong RAM** — đây là bài học module voiceover đã rút ra
(xem docblock trên `voiceover-job.schema.ts`): tiến độ trong `Map` bị mất khi deploy và khi có
nhiều replica thì client poll trúng worker không giữ state.

## 4. Mô hình dữ liệu

Cả hai collection đều là **MongoDB** (Mongoose). Mongo không có cơ chế migration — thay đổi schema
chỉ được phép cộng thêm, và tạo collection mới là miễn phí.

### 4.1 `user_lessons`

Chứa trọn vẹn một bài học trong một document.

```ts
{
  _id: ObjectId,
  userId: string,                    // index
  title: string,
  description: string,
  outputLocale: 'en' | 'vi' | 'zh' | 'ja' | 'ko',

  source: {
    type: 'pdf' | 'youtube',
    fileKey?: string,                // R2 object key (pdf)
    fileName?: string,               // tên file gốc để hiển thị
    url?: string,                    // link youtube
    videoTitle?: string,
    videoDurationSeconds?: number,
    pageCount?: number,
  },

  sections: [
    {
      title: string,
      blocks: [
        { type: 'heading' | 'paragraph', text: string }
      ],
    }
  ],

  wordCount: number,
  estimatedMinutes: number,
  stopAtSectionIndex: number,        // đọc dở tới đâu, mặc định 0
  jobId: string,                     // trỏ ngược về job đã sinh ra nó

  createdAt: Date,
  updatedAt: Date,
}
```

Index: `{ userId: 1, createdAt: -1 }`.

**Chú ý:** các trường văn bản ở đây là `string` thuần, **không phải `ITranslation`** 5-locale như
schema catalog. Bài này chỉ tồn tại ở một ngôn ngữ do user chọn, nên map 5 locale là thừa và gây
nhầm lẫn. Ngôn ngữ nằm ở `outputLocale`.

### 4.2 `learning_import_jobs`

```ts
{
  _id: ObjectId,
  userId: string,                    // index
  source: { ...giống user_lessons.source },
  outputLocale: string,

  // Không có 'cancelled': thiết kế không có chỗ nào huỷ job, và để lại một giá trị
  // không bao giờ dùng tới chỉ gây nhầm cho người đọc code sau này.
  status: 'queued' | 'processing' | 'completed' | 'failed',
  stage: 'fetching' | 'generating' | 'validating' | 'saving' | null,
  percent: number,                   // 0–100

  heartbeatAt: Date,                 // cập nhật mỗi lần đổi stage
  startedAt: Date,
  completedAt: Date,

  error: { code: string, message: string } | null,
  userLessonId: string | null,       // có khi completed

  usage: {
    inputTokens: number,
    outputTokens: number,
    estimatedCostVnd: number,
  } | null,

  countsTowardQuota: boolean,        // false khi job fail vì lỗi hệ thống
  createdAt: Date,
}
```

Index: `{ userId: 1, createdAt: -1 }`, `{ status: 1, heartbeatAt: 1 }`.

**Trạng thái `interrupted` là suy ra, không lưu:** khi đọc job, nếu `status === 'processing'` và
`heartbeatAt` cũ hơn 2 phút thì trả về cho client là `interrupted`. Lý do không lưu: không có
tiến trình nào đảm bảo còn sống để đi ghi trạng thái đó.

### 4.3 Vì sao không tái dùng Course / Lesson / Keypoint / LearningItem

Đây là quyết định có cân nhắc, không phải cho tiện.

Tái dùng schema catalog kèm một cờ `ownerUserId` nghe hấp dẫn vì màn đọc bài của app dùng lại được
ngay. Nhưng nó buộc phải rà lại **mọi truy vấn catalog hiện có** để lọc nội dung riêng ra: danh
sách khoá học, Home, Explore, tìm kiếm, recently-viewed, my-course, roadmap, badge-progress, và
các aggregation thống kê bên admin. Bỏ sót một chỗ là nội dung riêng tư của người dùng lọt ra
ngoài — kiểu lỗi âm thầm, không ai phát hiện cho tới khi có người phàn nàn.

Vì v1 chỉ sinh lý thuyết (văn xuôi thuần), tách hẳn ra bảng riêng loại bỏ toàn bộ lớp rủi ro đó.
Cái mất là một màn đọc bài mới bên Flutter — không lớn vì không phải dựng lại bài tập hay roleplay.

**Hệ quả cần chấp nhận:** bài tự tạo không tính vào `user_progress` (bảng đó khoá cứng theo
`courseId` của catalog) nên không lên huy hiệu, không hiện trong thống kê học tập. Chuỗi ngày học
thì **vẫn tính bình thường** — `user_streak` không tham chiếu course hay lesson nào cả.

**Đường nâng cấp về sau:** khi cần thêm bài tập, chuyển `sections` sang dùng `LearningItem` với
`type: 'theory' | 'exercise'`. Lúc đó mới phải giải bài toán phân quyền ở trên, nhưng đổi lại đã
có nhu cầu thật để biện minh.

## 5. hddhistory-api

### 5.1 Vị trí module

```
src/modules/courses/src/modules/learning-import/
  learning-import.module.ts
  learning-import.controller.ts          # transport
  user-lesson.controller.ts              # transport
  learning-import.service.ts             # orchestration
  learning-import-runner.service.ts      # chạy job
  user-lesson.service.ts
  quota.service.ts
  repository/
    learning-import-job.repository.ts
    user-lesson.repository.ts
  schema/
    learning-import-job.schema.ts
    user-lesson.schema.ts
  dto/
    create-learning-import.dto.ts
    learning-import-job.response.dto.ts
    user-lesson.response.dto.ts
    list-user-lesson.dto.ts
  source/
    pdf-source.resolver.ts               # lấy PDF từ R2
    youtube-source.resolver.ts           # lấy transcript
  ai/
    lesson-generation.module.ts
    lesson-generation.service.ts         # gọi Gemini
    lesson-generation.schema.ts          # JSON schema ràng buộc đầu ra
    lesson-generation.prompt.ts
  enum/
    import-source-type.enum.ts
    import-job-status.enum.ts
    import-error-code.enum.ts
```

Tuân thủ phân tầng bắt buộc của `hddhistory-api/AGENTS.md`: controller chỉ lo transport, service lo
nghiệp vụ, **repository là tầng duy nhất chạm database** — service không được gọi `InjectModel`.

Thư mục `ai/` là module dạng điều phối, không có controller/repository. AGENTS.md §9 cho phép
ngoại lệ này; tiền lệ đã có là `OutputPracticeAiModule`.

### 5.2 Endpoint

Tất cả dưới prefix `/api/v1`, đều `@UseGuards(AuthGuard)`.

| Method | Path | Mô tả |
|---|---|---|
| `POST` | `/learning-imports` | Tạo job. Body: `{ source, outputLocale }`. Trả `{ jobId, status }` |
| `GET` | `/learning-imports/:jobId` | Tiến độ job. Repository lọc theo owner |
| `GET` | `/learning-imports/quota` | `{ used, limit, remaining, resetsAt }` (xem §8.1) |
| `GET` | `/user-lessons` | Danh sách bài của người đang đăng nhập (phân trang) |
| `GET` | `/user-lessons/:id` | Nội dung đầy đủ một bài |
| `PATCH` | `/user-lessons/:id/progress` | Cập nhật `stopAtSectionIndex` |
| `DELETE` | `/user-lessons/:id` | Xoá bài |
| `GET` | `/admin/learning-imports` | Danh sách toàn hệ thống cho admin |
| `GET` | `/admin/learning-imports/:jobId` | Chi tiết job + nội dung bài đã sinh |

**Phân quyền:** mọi endpoint user-facing lọc theo `requestService.user.id` **ở tầng repository**,
theo đúng khuôn `CourseImportJobRepository.findOwnedJob`. Không dựa vào service nhớ truyền điều kiện.

**Về endpoint admin:** dự án hiện không có cơ chế phân quyền admin hoạt động được —
`@Roles(ADMIN)` không dùng được vì không có gì gán `user.role`, và `RoleGuard` không được dùng ở
đâu cả (xem docblock ở `analytics.controller.ts:15-39`, đã làm hỏng admin panel ba lần). Vì vậy
hai endpoint admin ở trên chỉ có `AuthGuard` như mọi endpoint khác trong dự án, giống hệt cách
các trang admin hiện có đang hoạt động. Đây là **hạn chế sẵn có của hệ thống, không phải do thiết
kế này tạo ra**, và không nên cố sửa trong phạm vi ticket này.

PDF **không đi qua body JSON** — body JSON bị chặn ở 25MB trong `main.ts`. File đi qua endpoint
upload R2 sẵn có (`POST /cloudflares/upload`, giới hạn 500MB, đã cho phép `application/pdf`), rồi
client gửi `fileKey` trả về cho `POST /learning-imports`.

### 5.3 Vòng đời job

```
queued
  └─▶ processing / fetching     lấy nguồn: tải PDF từ R2, hoặc lấy transcript YouTube
      └─▶ processing / generating   gọi Gemini
          └─▶ processing / validating  kiểm tra kết quả
              └─▶ processing / saving   ghi user_lessons
                  └─▶ completed
```

Mỗi lần chuyển stage: cập nhật `stage`, `percent`, `heartbeatAt` vào Mongo.

Bất kỳ bước nào ném lỗi → `failed` kèm `error.code` phân loại được (danh sách ở §8).

**Nguồn sự thật của kết quả là `user_lessons`, không phải job doc.** Job doc chỉ là bản ghi tiến
độ; xoá job không làm mất bài. Đây cũng là khuôn voiceover đang dùng.

### 5.4 Lớp gọi AI

Interface hẹp, để đổi nhà cung cấp sau này chỉ là thay phần thân:

```ts
interface ILessonGenerator {
  generate(input: {
    source: ResolvedSource;      // { kind: 'pdfBytes', bytes } | { kind: 'text', text }
    outputLocale: string;
    targetWordCount: { min: number; max: number };
    targetSectionCount: { min: number; max: number };
  }): Promise<{
    lesson: GeneratedLesson;
    usage: { inputTokens: number; outputTokens: number };
  }>;
}
```

Cấu hình qua env: `GEMINI_API_KEY`, `GEMINI_MODEL`, `GEMINI_TIMEOUT_MS`. Khai báo trong
`.env.example`; khoá thật không bao giờ commit. Model ID để trong env chứ không viết cứng, để đổi
model không cần deploy code.

Đầu ra được ràng buộc bằng **JSON schema** gửi kèm request (Gemini hỗ trợ structured output), nên
không phải dò chuỗi hay bóc markdown khỏi câu trả lời.

PDF gửi thẳng dạng file cho Gemini — không tự tách text. Lợi: đọc được cả PDF scan, giữ được bảng
biểu và bố cục, và bỏ hẳn một phụ thuộc thư viện. YouTube vẫn đi đường transcript vì đó là dữ liệu
sẵn có dạng text.

**Không dùng streaming** (sửa khi triển khai). Thiết kế ban đầu định dùng streaming để tránh đứt
kết nối giữa chừng, nhưng đây là gọi server-sang-server: `fetch` của Node không tự hết giờ, nên
một `AbortController` với hạn 10 phút (chỉnh được qua env) đã đủ, và đổi lại không phải viết bộ
phân tích SSE — thứ chỉ hỏng khi chạy thật chứ không hỏng lúc biên dịch. Nếu sau này cần hiện
tiến độ theo từng đoạn chữ thì mới đổi sang streaming.

### 5.5 Kiểm tra kết quả trước khi lưu

Sinh ra rồi không có nghĩa là dùng được. Trước khi ghi vào `user_lessons`, kiểm:

- Số phần nằm trong 5–8
- Tổng số từ ≥ 3000 (dưới ngưỡng này coi như AI không đủ dữ liệu, trả lỗi `CONTENT_TOO_SHORT`)
- Mỗi phần có tiêu đề và ít nhất một đoạn văn
- Không có phần rỗng hoặc trùng tiêu đề

Không đạt → `failed`, **không trừ quota**, và thông báo cho user là tài liệu không đủ nội dung
chứ không phải "lỗi hệ thống".

## 6. hddhistory-flutter

### 6.1 Vị trí

Feature mới `lib/src/learning_import/`, Clean Architecture như các feature khác:

```
lib/src/learning_import/
  data/{datasources/remote, models, repositories}
  domain/{entities, repositories, usecases}
  presentation/{cubits, pages, widgets, sheets}
```

### 6.2 Route

Ba route mới, đăng ký dưới nhánh Setting shell (nhánh chứa `/profile`):

| Path | Màn hình |
|---|---|
| `/profile/my-lessons` | Danh sách bài đã tạo |
| `/profile/my-lessons/import` | Bottom sheet luồng tạo bài |
| `/profile/my-lessons/:id` | Màn đọc bài |

Thêm hằng vào `RoutePath` / `RouteNamed` trong `lib/config/routes/base/app_routes.dart`, khai báo
route data class trong `lib/config/routes/data/routes_shell_setting_data.dart`, gắn vào cây trong
`routes_shell.dart` dưới `TypedGoRoute<ProfileRoute>`. Chạy lại build_runner sau đó — **không sửa
tay `routes.g.dart`**.

### 6.3 Màn Hồ sơ

Thêm một hàng "Bài học của tôi" vào `profile_page.dart`, đặt cạnh `_LibrarySection`, dùng đúng
khuôn hàng của màn đó (thẻ bo góc `studyThemeCardColor`, icon trái, `Icon(Icons.chevron_right_rounded)`
bên phải, bọc trong `Semantics(button: true)`, `AppHaptic.select()` khi bấm). Sao chép cấu trúc
`_LibrarySection` chứ không tự dựng style mới.

### 6.4 Luồng tạo bài

Bottom sheet ba bước:

1. **Chọn nguồn** — "Tải lên tệp PDF" (dùng `FileService.pickFile()`, đã có `file_picker` trong
   pubspec) hoặc "Dán link YouTube". Link được validate ngay tại client trước khi gửi.
2. **Chọn ngôn ngữ bài học** — 5 locale, mặc định = locale app đang dùng.
3. **Xác nhận** — hiện quota còn lại trước khi bấm tạo.

**Chặn premium:** trước khi mở sheet, kiểm `context.read<ProfileCubit>().state.user.isPremium`.
Chưa premium → theo đúng khuôn hiện có:

```dart
AppDI.injector.get<IapCubit>().setPaywallEntryPoint(PaywallEntryPoint.learningImport);
const PaywallRoute().push(context);
```

Cần thêm một giá trị `learningImport` vào enum `PaywallEntryPoint` để tracking phân biệt được
người mua gói vì tính năng này.

**Upload PDF:** dùng `UploadCubit.uploadFile(UploadFileParams(...))` sẵn có, với
`folder: 'user_import'`, `prefix: 'pdf_'`. Không viết luồng upload mới.

### 6.5 Màn hình chờ

Hiện **tên bước đang chạy** (đọc từ `stage` của job) thay vì thanh chạy vô nghĩa, kèm ước lượng
thời gian còn lại.

Poll `GET /learning-imports/:jobId` mỗi 3 giây. User **rời màn hình được** — job chạy tiếp trên
server; quay lại danh sách sẽ thấy bài ở trạng thái "đang tạo" và bấm vào xem tiếp tiến độ.

### 6.6 Màn đọc bài

**Một trang cuộn liền** từ đầu đến cuối, không chia màn từng phần:

- Tiêu đề phần dính trên đầu (sticky header) khi cuộn qua
- Thanh tiến độ đọc mảnh ở đỉnh màn hình
- Nhớ vị trí cuộn: lưu `stopAtSectionIndex` khi rời màn, mở lại nhảy tới đúng chỗ
- Thời gian đọc tính vào chuỗi ngày học như mọi hoạt động khác (gọi cùng helper `markPresence`
  mà app đang dùng)

Widget hiển thị: `heading` và `paragraph` render bằng theme token của app (`AppText`,
`studyThemeOnBg`), **không hard-code màu hoặc cỡ chữ**.

Ngoài ra: xoá bài (có hộp thoại xác nhận), và hiện nguồn gốc (tên file / tiêu đề video) trên màn
danh sách.

### 6.7 Chuỗi dịch

Namespace mới `learning_import` — tạo `assets/i18n/<locale>/learning_import.yaml` cho **đủ cả 5
locale** (en, vi, zh, ja, ko), rồi chạy `dart run slang`. Thiếu một locale nghĩa là màn hình hiện
chuỗi tiếng Anh giữa giao diện tiếng Việt.

Riêng chuỗi cho hàng mới trong màn Hồ sơ đặt vào namespace `setting` (nơi các chuỗi profile đang ở).

## 7. hddhistory-admin

Một trang chỉ đọc **"Import của người dùng"**.

| Vai trò | File |
|---|---|
| Trang danh sách | `src/pages/learning-imports/LearningImportList.tsx` |
| Trang chi tiết | `src/pages/learning-imports/LearningImportDetail.tsx` |
| Service | `src/services/learningImportService.ts` |
| Types | `src/types/interface/learningImport.interface.ts` |
| Đăng ký route | `src/routes/index.tsx` |
| Menu | `src/components/layout/Sidebar.tsx` — nhóm "Operations" |

**Khuôn để sao chép:** trang `habit-checkins` (trang danh sách chỉ-đọc gần đây nhất).

**Quy ước bảng:** admin **không dùng MUI DataGrid** ở bất kỳ đâu — bảng là markup Tailwind tự dựng,
icon dùng `@heroicons/react/24/outline`, MUI chỉ dùng cho `Pagination`. Service là object thuần với
các method `async` gọi `axiosClient` và bóc envelope bằng `res.data?.data ?? res.data`.

**Cột danh sách:** người dùng, nguồn (tên file / link video), ngôn ngữ, thời điểm, trạng thái,
số từ, chi phí ước tính. Có ô tìm kiếm (debounce) và lọc theo trạng thái.

**Trang chi tiết:** thông tin job + **toàn văn bài AI đã sinh**, để đánh giá chất lượng và hiểu
người dùng import cái gì. Không có nút tải file gốc về.

Trang phải xử lý cả trạng thái `forbidden` (403) như các trang admin khác.

## 8. Hạn mức và mã lỗi

### 8.1 Bốn tầng giới hạn

| Tầng | Giá trị đề xuất | Chặn điều gì |
|---|---|---|
| Quyền | Chỉ tài khoản premium | Người dùng miễn phí đốt tiền API |
| Số lượt | 10 bài / tháng dương lịch | Một người chạy hàng trăm lần |
| Đồng thời | 1 job đang chạy / người | Bấm liên tục tạo hàng loạt job |
| Kích thước | PDF ≤ 300 trang **và** ≤ 20MB; video ≤ 3 giờ | File 2000 trang làm chi phí một lần bằng cả tháng |

> **20MB chứ không phải 50MB** (sửa khi triển khai): endpoint upload R2 cho tới 500MB,
> nhưng file PDF đi kèm ngay trong request gửi sang Gemini, và request dạng đó có
> trần riêng nhỏ hơn nhiều. Từ chối ở 20MB kèm thông báo rõ ràng tốt hơn để người
> dùng chờ hai phút rồi nhận lỗi từ nhà cung cấp.

Kiểm premium ở server bằng `SubscriptionService.findActivePremiumForUser(userId)` — bọc trong một
helper boolean, theo đúng khuôn `UserHabitService.hasUnlimitedSlots`. Không tin cờ `isPremium` do
client gửi lên.

Chặn đồng thời: theo khuôn `DriveImportJobRepository.findActiveByUser`.

**Chu kỳ quota là tháng dương lịch**, reset lúc 00:00 ngày 1 hàng tháng theo giờ server — không
theo chu kỳ subscription của từng người. Lý do: dễ giải thích cho người dùng ("còn 7 lượt, làm mới
ngày 1/9") và không phải đọc ngày gia hạn của từng subscription. Số lượt đã dùng được **tính bằng
cách đếm** `learning_import_jobs` có `countsTowardQuota: true` và `createdAt` trong tháng hiện tại
— không có bộ đếm riêng để không phải lo đồng bộ hai nguồn sự thật.

**Về giới hạn số trang PDF:** §5.4 nói không tự tách text, nhưng vẫn cần biết số trang để chặn.
Hai thứ này không mâu thuẫn — đọc **metadata** của PDF (bảng đối tượng ở cuối file) lấy được số
trang mà không phải render hay trích text trang nào, chi phí gần như bằng không. Nếu metadata hỏng
hoặc không đọc được thì rơi về chặn theo dung lượng file (≤ 50MB) và cho chạy tiếp, chứ không từ
chối — người dùng không nên bị chặn vì một file PDF ghi sai header.

**Job thất bại vì lỗi hệ thống không trừ lượt** (`countsTowardQuota: false`). Lỗi do tài liệu của
user (PDF không đọc được, video không có phụ đề) thì cũng không trừ — user chưa nhận được gì.

Tất cả các con số trên nằm trong **cấu hình, không viết cứng**, để chỉnh sau khi có số liệu thật
mà không cần deploy.

### 8.2 Mã lỗi

Mỗi mã có một câu thông báo riêng ở client. Không dùng "Đã có lỗi xảy ra".

| Mã | Nghĩa | Trừ quota |
|---|---|---|
| `PDF_UNREADABLE` | Không trích được nội dung từ PDF | Không |
| `PDF_TOO_LARGE` | Vượt giới hạn số trang | Không |
| `YOUTUBE_NO_TRANSCRIPT` | Video không có phụ đề | Không |
| `YOUTUBE_UNAVAILABLE` | Video riêng tư / không tồn tại / bị chặn vùng | Không |
| `YOUTUBE_TOO_LONG` | Video vượt giới hạn thời lượng | Không |
| `CONTENT_TOO_SHORT` | Tài liệu quá ngắn, không đủ soạn thành bài | Không |
| `AI_TIMEOUT` | Gemini không phản hồi kịp | Không |
| `AI_FAILED` | Gemini lỗi hoặc trả kết quả không hợp lệ | Không |
| `SOURCE_FETCH_FAILED` | Không tải được file từ R2 | Không |
| `INTERNAL` | Lỗi ngoài dự kiến | Không |
| `AI_NOT_CONFIGURED` | Server chưa có khoá Gemini | — |
| `QUOTA_EXCEEDED` | Hết lượt trong tháng | — |
| `JOB_ALREADY_RUNNING` | Đang có job khác chạy | — |
| `NOT_PREMIUM` | Chưa mua gói | — |

Bốn mã cuối được từ chối **trước khi** job tồn tại nên không có gì để tính; ba mã đầu ghi vào job
đã tạo. Chính sách "không trừ lượt" nằm ở một chỗ duy nhất trong code
(`LEARNING_IMPORT_QUOTA_CHARGING_ERRORS`) — hiện là tập rỗng, và đó là quyết định chứ không phải
thiếu sót: mọi kiểu hỏng đều để người dùng tay trắng.

Trạng thái `interrupted` (job đứt do deploy) hiển thị riêng, cho bấm thử lại, không trừ quota.

## 9. Chi phí

Ước tính cho một lần import tài liệu ~20.000 từ, sinh bài 5.000 từ, trên Gemini Flash:
khoảng **300–600đ/lần**. Với trần 10 lượt/tháng, chi phí tối đa khoảng **6.000đ/người/tháng** —
nhỏ so với giá gói subscription.

Mỗi job ghi lại `usage.inputTokens`, `usage.outputTokens`, `usage.estimatedCostVnd`. Sau một tháng
vận hành sẽ có số thật để quyết định điều chỉnh quota hay đổi model, thay vì đoán.

## 10. Thứ tự triển khai

1. **hddhistory-api** — schema, repository, service, endpoint, lớp gọi Gemini, job runner
2. **hddhistory-admin** — trang danh sách + chi tiết (dùng được ngay để soi kết quả khi test API)
3. **hddhistory-flutter** — route, màn hình, luồng import, màn đọc bài, i18n

App phụ thuộc endpoint nên không làm ngược được. Admin làm trước app vì nó là công cụ để đánh giá
chất lượng bài AI sinh ra trong lúc còn đang chỉnh prompt.

Deploy: API và admin lên dev trước; app build dev sau khi API dev đã chạy.

## 11. Ngoài phạm vi bản đầu

Ghi rõ để không trôi phạm vi giữa chừng:

- Bài tập trắc nghiệm và roleplay sinh từ tài liệu
- Audio đọc bài (TTS)
- Nguồn khác: link web, dán text thủ công, ảnh chụp tài liệu
- Chia sẻ bài cho người dùng khác
- Admin biến bài user thành nội dung catalog chính thức
- Tính vào `user_progress` / huy hiệu / thống kê học tập
- Tải file gốc về từ admin

Mỗi mục đều mở rộng được sau mà không phải đập đi làm lại. Riêng phần bài tập, khi cần sẽ chuyển
`sections` sang dùng chung cấu trúc `LearningItem` của app — lúc đó mới phải xử lý bài toán lọc
nội dung riêng khỏi các truy vấn catalog (xem §4.3).

## 11b. Đã triển khai những gì

**hddhistory-api** — `src/modules/courses/src/modules/learning-import/` (mới), cùng ba chỗ sửa nhỏ:
`base/config/configuration.ts` (thêm ba biến `GEMINI_*`), `courses.module.ts` (đăng ký module),
`.env.example`.

Đã xác thực: `npx tsc --noEmit` sạch phần `src/`; `nest build` báo 0 lỗi; đồ thị DI của module mới
resolve được khi boot riêng (đã loại trừ bẫy `AuthGuard` thiếu `AuthModule` — thứ mà `tsc` không
thấy được); 25/25 test trong `learning-import.util.spec.ts` đạt.

**hddhistory-admin** — `pages/learning-imports/`, `services/learningImportService.ts`,
`types/interface/learningImport.interface.ts`, cùng hai chỗ sửa: `routes/index.tsx`,
`components/layout/Sidebar.tsx`. `npx tsc --noEmit` sạch.

**Chưa chạy được đầu-cuối trên máy này**: cần `GEMINI_API_KEY` thật, và máy dev hiện không kết nối
được MySQL/Mongo (`google-service.json` cũng đang là bản mẫu). Kiểm thử thật phải làm trên api-dev.

## 12. Rủi ro đã biết

| Rủi ro | Ảnh hưởng | Cách giảm |
|---|---|---|
| Chất lượng bài AI không đạt | Người dùng thất vọng, không dùng lại | Trang admin để đọc bài thật và chỉnh prompt trước khi mở cho user; ngưỡng validate ở §5.5 |
| Job chết khi deploy | User treo ở màn chờ | Heartbeat + trạng thái `interrupted` + nút thử lại |
| Chi phí vượt dự tính | Đốt tiền | 4 tầng giới hạn ở §8.1 + ghi usage từng job |
| Lấy transcript YouTube không ổn định | Một phần nguồn không dùng được | Mã lỗi riêng, thông báo rõ; PDF vẫn hoạt động độc lập |
| Bài dài 5.000 từ sinh một lần có thể lệch chất lượng giữa các phần | Phần đầu kỹ, phần cuối sơ sài | Nếu quan sát thấy, nâng cấp sang sinh hai pha (dàn ý trước, viết từng phần sau) — không phải đổi API, database, app hay admin |
| Không có cơ chế phân quyền admin | Endpoint admin về lý thuyết ai đăng nhập cũng gọi được | Hạn chế sẵn có của toàn dự án (xem §5.2), không xử lý trong ticket này |
