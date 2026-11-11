# Onboarding v3 — taxonomy trong DB, 3 câu hỏi phụ thuộc, gợi ý khoá server, nhắc học theo giờ

- Ngày: 2026-09-18
- Trạng thái: THIẾT KẾ ĐÃ CHỐT với BA (user) — cấu trúc dữ liệu do dev tự quyết; đang thi công
- Nguồn:
  - Bản thiết kế tương tác Claude Design `HDDhistory Onboarding v2 (1).html` (12 màn S0–S11; logic thật
    trong `class Component extends DCLogic` cuối template).
  - Google Sheet `1bRW615OJAjOM18TblvgOlI_RuNU7_mFsRb1-Pa3kkoE`, tab `Nhãn` (gói nhãn) và
    `Mapping Khoá học`. **Sheet là nguồn sự thật**; demo HTML đã lệch ở danh sách mong muốn.
  - Ảnh chụp luật hiển thị câu 2 / câu 3 do BA gửi (chép lại ở §3).
- File đi kèm: `onboarding-taxonomy-template.xlsx` — file import mẫu, ĐÃ đổ sẵn dữ liệu từ sheet.

## 1. Vì sao không phải là "đổi nhãn trên luồng cũ"

Luồng đang chạy (`lib/src/onboard_v2/`, 9 màn) dựng trên 6 path / 18 symptom là **enum cứng ở cả
Dart lẫn TS**; config admin chỉ đổi được nhãn, không thêm được key (bất biến
`key == trackingId`, xem `plans/260721-onboard-v2-config-driven/contract.md`). Câu trả lời
**không bao giờ lên server** (chỉ `name`, `age`, `isOnboarded`), gợi ý khoá là
`onboardingSymptoms $in` rồi random ở client, course không có field tag nào khác, và chưa có
nhắc học theo giờ.

Bản mới: 5 nhánh → 26 gói → 115 nhãn chi tiết, câu 3 phụ thuộc câu 2, nhắc học có giờ, kết quả
xếp hạng. Quyết định của BA: **mọi quan hệ nằm trong DB, không enum**; import Excel theo mẫu
giống sheet; sau kết quả vẫn đến màn chọn theme rồi về Home; nhắc học là một loại noti tự động
trong trang "Thông báo định kỳ", bắn theo giờ user chọn.

## 2. Mô hình dữ liệu (MongoDB)

### 2.1 Module mới `src/modules/onboarding-taxonomy/`

| Collection | Field | Ghi chú |
|---|---|---|
| `onboarding_branches` | `code` (unique, IN HOA: `CX`), `label: ITranslation`, `subtitle: ITranslation`, `iconUrl`, `imageUrl`, `order`, `isSelectable` (hiện ở câu 1), `categoryId: string\|null`, `isActive` | `KP` (Khám phá não bộ) có `isSelectable=false`: chỉ để gắn khoá. `categoryId` để Home xếp chủ đề theo nhánh đã chọn. |
| `onboarding_packages` | `code` (unique: `CX-1`), `branchCode`, `problemLabel: ITranslation` (đáp án câu 2), `desireLabel: ITranslation` (đáp án câu 3), `order`, `isActive` | **1 gói = 1 vấn đề = 1 mong muốn.** Mã mong muốn == mã gói. |
| `onboarding_labels` | `code` (unique: `CX01`), `packageCode`, `label: ITranslation`, `order` | Nhãn chi tiết, KHÔNG hiện cho user; chỉ là khớp nối gói ↔ khoá. Có 3 nhãn trùng chữ khác mã (CX12/QH07, CV04/QH03, CV21/QH04) — luôn khoá theo MÃ. |

Index: `code` unique mỗi collection; `{branchCode, order}` trên packages; `{packageCode, order}`
trên labels.

### 2.2 Course (module `courses/src/modules/course`) — thêm 2 field, không migration

```ts
@Prop({ type: [String], default: [] }) onboardingLabelCodes: string[];   // nhãn chi tiết (vấn đề)
@Prop({ type: [String], default: [] }) onboardingDesireCodes: string[];  // mã gói (mong muốn)
CourseSchema.index({ onboardingLabelCodes: 1, status: 1 });
CourseSchema.index({ onboardingDesireCodes: 1, status: 1 });
```
`onboardingSymptoms` cũ GIỮ NGUYÊN (app cũ ngoài thị trường còn gọi `?onboardingSymptoms=`),
admin đánh dấu "legacy". Khoá chưa có trong sheet (coming soon/draft) rỗng cả hai field.

### 2.3 Câu trả lời của user — module mới `src/modules/onboarding-answer/`

Collection `onboarding_answers`, một doc / user (`userId` unique):

```ts
userId: ObjectId; branchCodes: string[] /* theo thứ tự chọn */; packageCodes: string[] /* theo thứ tự chọn */;
desireCode: string | null; reminderEnabled: boolean; reminderTime: 'HH:mm' | null;
recommendedCourseIds: string[]; chosenCourseId: string | null; ageKey?: string; completedAt: Date | null;
```
Thêm trên `User`: `@Prop({ type: String, default: null }) studyReminderTime: string | null` (HH:mm,
bước 15 phút, index) — dispatcher noti đọc trực tiếp trên users để dùng chung
`findPushCandidatesByTimezones(zones, limit, extraFilter)`. `reminderEnabled=false` → `null`.

### 2.4 `onboarding-config` (singleton copy) — thêm 4 section, sửa 1 bug

Giữ 9 section cũ (app cũ còn đọc `paths.items`). Thêm `desire`, `how`, `reminder`, `loading`
(heading/headingHighlight/helper/cta + `how.steps[4]{title,body}`, `reminder.presets[3]{label,time}`,
`loading.lines[4]`), tái dùng `habit` cho S5 (vấn đề), `pick` cho S10 (kết quả), `notif` cho thẻ
preview S8. **Bug tiện tay:** `updateConfig()` không copy `showPaywallAfterOnboarding` vào patch →
toggle admin chưa bao giờ lưu; sửa luôn.

## 3. Luật nghiệp vụ

### 3.1 Câu 1 — Lĩnh vực (S4)
Multi-select, KHÔNG giới hạn (bỏ cap 2). Chỉ hiện nhánh `isSelectable && isActive`. **Giữ thứ tự
user chọn** — luật câu 2 dựa vào đó.

### 3.2 Câu 2 — Vấn đề (S5), luật của BA
Chỉ hiện gói thuộc các nhánh đã chọn. Tối đa 10 lựa chọn, chia theo thứ tự chọn nhánh:

| Số nhánh | Nhánh 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| 1 | toàn bộ | | | | |
| 2 | 5 | 5 | | | |
| 3 | 4 | 3 | 3 | | |
| 4 | 3 | 3 | 2 | 2 | |
| 5 | 2 | 2 | 2 | 2 | 2 |

Cài đặt = **round-robin theo thứ tự chọn nhánh**, mỗi nhánh lấy gói theo `order`, dừng ở 10 (đúng
bảng trên; demo cũng làm vậy). Nhánh hết gói sớm (Tư duy chỉ có 3) thì các nhánh còn lại lấp cho
đủ 10 — BA chưa nói khác, chọn theo demo. Multi-select, giữ thứ tự chọn.

### 3.3 Câu 3 — Mong muốn (S6), single-select
Gọi n = số gói đã chọn ở câu 2:
- n = 1 → toàn bộ mong muốn của **cùng nhánh** với gói đó (mỗi gói trong nhánh 1 mong muốn).
- n = 2 → 2 mong muốn tương ứng + với **mỗi** gói, 1 mong muốn random từ gói khác cùng nhánh
  (chưa có trong danh sách) → tối đa 4. (Ảnh BA ghi "(tổng là 2)" — đọc là 2 random; nếu BA ý
  khác chỉ chỉnh helper.)
- n ≥ 3 → chỉ các mong muốn tương ứng.
Random ổn định trong một phiên (seed theo bộ gói đã chọn) để quay lại màn không đổi thứ tự.

### 3.4 Gợi ý khoá (S9→S10), chạy SERVER
Input: `packageCodes` (thứ tự), `desireCode`. L = hợp các `labels` của các gói đã chọn.
Ứng viên: khoá `published`, hiện được ở thị trường của user (`withMarketVisibility`), và
(`onboardingLabelCodes ∩ L ≠ ∅` HOẶC `desireCode ∈ onboardingDesireCodes`).
Xếp hạng theo ba TẦNG, rồi mới so trong tầng:
- Tầng 0: khớp **cả** mong muốn **và** ≥1 nhãn vấn đề; tầng 1: chỉ khớp mong muốn; tầng 2: chỉ
  khớp nhãn vấn đề.
- Trong tầng, so lần lượt: (a) số gói đã chọn mà khoá chạm được (≥1 nhãn của gói) — nhiều hơn
  trước; (b) số nhãn trùng — nhiều hơn trước; (c) chạm gói được chọn SỚM hơn → trước;
  (d) `numberOfLesson > 0` trước; (e) `title.vi`.
Lấy 3. Thiếu → bù bằng khoá published có `onboardingDesireCodes` thuộc các nhánh đã chọn, rồi khoá
published bất kỳ (theo `createdAt` mới nhất). Trả kèm `matchReason` để app hiện "vì bạn chọn …".
Card 1 = "Phù hợp nhất". Ghi `recommendedCourseIds` vào answers.

### 3.5 Nhắc học theo giờ (S8)
Mặc định 21:00; 3 khung nhanh Sáng 07:00 / Trưa 12:30 / Tối 21:00; bánh xe giờ + phút bước 15.
"Bật thông báo" = xin quyền OS (như P4 cũ) + gửi `reminderEnabled=true, reminderTime`. "Để sau" =
`reminderEnabled=false`. Server: type noti mới `onboarding_study_reminder` (xem §4.3).

### 3.6 Sau kết quả
S10 "Học bài đầu tiên" → ghi `chosenCourseId` → S11 chọn theme → **Home** (không vào course
như hiện tại). Giữ paywall-after-onboarding gate như cũ.

## 4. API

Mọi route dưới `/api/v1`, bọc envelope `{statusCode,message,data}` trừ tải file (`@Res()`).

### 4.1 `onboarding-taxonomy`
| Method | Path | Guard | Trả |
|---|---|---|---|
| GET | `/onboarding-taxonomy` | `@Public` | `{ branches[], packages[] }` — chỉ active, sort `order`; KHÔNG kèm labels |
| GET | `/onboarding-taxonomy/admin` | Auth | `{ branches[], packages[], labels[] }` đủ, kể cả inactive |
| PUT | `/onboarding-taxonomy` | Auth | body = cây đầy đủ → validate → **thay toàn bộ** 3 collection |
| POST | `/onboarding-taxonomy/import` | Auth, `FileInterceptor('file')` | xlsx → trả xlsx kết quả (Course ID đã điền), header `X-Import-Warnings` |
| GET | `/onboarding-taxonomy/export` | Auth | xlsx dữ liệu hiện tại (cùng builder với template) |
| GET | `/onboarding-taxonomy/template` | Auth | xlsx mẫu = export (rỗng thì chỉ header + 1 dòng ví dụ) |

Validate PUT/import: code unique toàn file; `package.branchCode` tồn tại; `label.packageCode` tồn
tại; mỗi gói ≥1 nhãn; `problemLabel.vi`/`desireLabel.vi` không rỗng; định dạng mã: nhánh
`^[A-Z]{2,4}$`, gói `^[A-Z]{2,4}-\d+$`, nhãn `^[A-Z]{2,4}\d{2,}$`; `reminderTime`
`^([01]\d|2[0-3]):(00|15|30|45)$`.

**Import xlsx** (dùng `courses/src/modules/import/excel-import.util.ts`, `import * as ExcelJS`):
- Sheet `Nhánh`: `Mã nhánh | Tên nhánh (vi) | Tên nhánh (en) | Mô tả ngắn (vi) | Mô tả ngắn (en) | Thứ tự | Hiện ở câu 1 (Y/N) | Chủ đề ID (tuỳ chọn)`.
- Sheet `Gói nhãn`: `Mã nhánh | Mã gói | Vấn đề — đáp án câu 2 (vi) | … (en) | Mong muốn — đáp án câu 3 (vi) | … (en) | Nhãn chi tiết (vi) | Mã nhãn chi tiết | Thứ tự` — hai cột nhãn ngăn bằng `|`, số phần tử phải bằng nhau. Chấp nhận cả header của sheet gốc (không hậu tố `(vi)`) và cột `(zh)/(ja)/(ko)` tuỳ chọn.
- Sheet `Mapping Khoá học`: `Course ID (tuỳ chọn) | Khoá học | Nhánh nội dung | Trạng thái (tham khảo) | Mã nhãn vấn đề | Mã gói mong muốn`. Khớp theo `Course ID`; trống thì khớp `title.vi` (trim, bỏ phân biệt hoa thường, gộp khoảng trắng). Mã không có trong taxonomy → **lỗi, huỷ cả import**; khoá không tìm thấy → **cảnh báo, bỏ qua dòng**, ghi vào sheet `import_warnings`. Khoá không có trong sheet giữ nguyên tag.
- Cột dẫn xuất của sheet gốc (Số nhãn…, Khoá mang nhãn…, Gói tới được, Trong đó gán thêm tay) bị bỏ qua.
- Import taxonomy là **thay toàn bộ** (như PUT). Code bị xoá còn nằm trên course → dangling, thuật toán bỏ qua.

### 4.2 `onboarding-answer`
| Method | Path | Guard | Ghi chú |
|---|---|---|---|
| POST | `/onboarding-answers` | Auth (token ẩn danh đủ) | body mọi field optional: `branchCodes, packageCodes, desireCode, reminderEnabled, reminderTime, chosenCourseId, ageKey`; upsert theo `requestService.user`; đồng bộ `User.studyReminderTime`; **luôn** trả `{ answers, recommendations[] }` (tính lại từ answers đã merge) |
| GET | `/onboarding-answers/me` | Auth | answers + recommendations |

`recommendations[]`: `_id, title, description, image, categoryId, numberOfLesson, status,
matchReason: { desire: boolean, labelCodes: string[], packageCodes: string[] }`.

### 4.3 Noti `onboarding_study_reminder` — sao y `coach_plan_reminder`
- `NotificationType.ONBOARDING_STUDY_REMINDER = 'onboarding_study_reminder'` (append), seed
  `enabled:false, localHour:0 (trơ), deeplink: HOME`, 5 locale, tiêu đề/nội dung khớp thẻ preview
  của design ("Đến giờ tập trung 🌟" / "Bài học 2 phút của bạn đã sẵn sàng"), biến `{user_name}`, `{course_name}`.
- `notification-dispatch.service.ts` bỏ qua type này trong vòng template (như dòng 141 với coach).
- `UserRepository.distinctStudyReminderTimes()` (`$group` trên `studyReminderTime`, ≤96 giá trị).
- `onboarding-answer/onboarding-study-reminder.dispatcher.ts`: `@Cron('* * * * *')` → không có giờ
  nào → thoát; template tắt → thoát; mỗi giờ: `dispatchService.zonesDueAt(h,m,now)` →
  `findPushCandidatesByTimezones(zones, undefined, {studyReminderTime:'HH:mm', ...segmentFilter})`
  (segment qua `SegmentMemberFilterService`, KHÔNG `SegmentService` — request-scoped giết cron) →
  `pickVariant` với `{user_name, course_name}` (`course_name` = `chosenCourseId` hoặc
  `recommendedCourseIds[0]`, theo `language`) → `dispatchService.sendDirect({...})` (được sẵn: 1
  lần/type/ngày, trần 4/ngày, claim, FCM, prune token, log).
- Deeplink tái dùng `home` → **không cần release app** cho phần noti.

## 5. Admin (hddhistory-admin)
1. Trang mới **"Onboarding Taxonomy"** (`/onboarding-taxonomy`, sidebar nhóm Onboarding): nút Tải mẫu /
   Import Excel (`ExcelImportButton`) / Export / Lưu; cây Nhánh → Gói → Nhãn sửa inline (vi/en,
   order, active, chủ đề typeahead cho nhánh); lưu bằng `PUT` cây đầy đủ.
2. `CourseModal`: khối mới "Nhãn onboarding" — 2 Autocomplete multi: *Nhãn vấn đề (chi tiết)* nhóm
   theo gói, *Mong muốn (gói)* nhóm theo nhánh; nguồn `GET /onboarding-taxonomy/admin`. Khối
   "Onboarding Symptoms" cũ giữ, ghi "legacy — app cũ".
3. Trang Thông báo định kỳ: thêm `"onboarding_study_reminder"` vào union + `TYPE_LABELS`
   ("8. Nhắc học theo giờ đã chọn (onboarding)"), `TYPE_VARIABLES`, `TYPE_HINTS` (ô giờ trơ, giờ
   lấy theo user).
4. Trang Onboarding Config: 4 accordion mới (Mong muốn S6 / HDDhistory dạy thế nào S7 / Nhắc nhở S8 /
   Đang tạo lộ trình S9), đổi nhãn accordion `habit` → "Câu 2 — Vấn đề (S5)", `pick` → "Kết quả
   (S10)", `paths` items → "legacy".

## 6. Flutter (hddhistory-flutter)

### 6.1 Bước mới
`p1Intro, p2Name, p3Age, p4Branches, p5Problems, p6Desire, p7How, p8Reminder, p9Loading,
p10Result, p11Theme`. Thanh tiến độ 7 nấc từ S2→S8 (name=1 … reminder=7). Màn xin quyền noti cũ
(p4) gộp vào p8. Back: chặn ở p9/p10 (như p8 cũ).

### 6.2 Dữ liệu
`lib/src/onboarding/`: thêm `OnboardingTaxonomyEntity{branches, packages}`, `OnboardingAnswersRequest`,
`OnboardingRecommendationEntity`, use case `GetOnboardingTaxonomyUseCase`,
`SubmitOnboardingAnswersUseCase`; endpoint `onboardingTaxonomy`, `onboardingAnswers`. Config
entity thêm `desire/how/reminder/loading`. Taxonomy cache local như config; lỗi tải → inline error +
Thử lại ở S4 (không có fallback enum nữa).

### 6.3 Luật thuần (unit test được)
`OnboardV2SelectionRules.problemOptions(taxonomy, branchCodesOrdered)` (§3.2),
`.desireOptions(taxonomy, packageCodesOrdered, seed)` (§3.3). Cubit chỉ gọi helper.

### 6.4 Trang theo design
- S4 hàng icon + label + sub, viền gradient khi chọn (tái dùng `OnboardV2SelectableOptionRow` mở
  rộng `subtitle`). Tiêu đề "{tên} muốn cải thiện điều gì?".
- S5 chip `Wrap` bo tròn; S6 hàng + check tròn; S7 4 bước đánh số (Hiểu/Thử/Ôn/Dùng);
- S8 bánh xe hh:mm (`ListWheelScrollView`, 24 × 4 giá trị) + 3 chip khung giờ + thẻ preview
  (`OnboardV2NotificationPreview` sẵn có) + CTA "Bật thông báo" / "Để sau";
- S9 4 dòng tick lần lượt (≥2,4 s, chờ API xong mới sang); S10 tái dùng carousel P8 cũ, badge
  "PHÙ HỢP NHẤT" ở card 1, CTA "Học bài đầu tiên"; S11 giữ.
- Copy: l10n 5 locale là fallback; `onbCopy` đọc section config mới.

### 6.5 Dọn
Xoá path-map (page + 4 widget p6), symptom page, path selection page, `OnboardV2PathResolver`,
`OnboardV2SymptomSelectionMapper`, `OnboardV2RandomCoursePicker`, phần paths/symptoms của
`OnboardV2ConfigMapper`, 4 file scaffold chết (`onboard_v2_api/entity/repository/usecases`). Enum
`OnboardingPath/OnboardingSymptom` GIỮ trong `course_model.dart` (CourseModel còn decode
`onboardingSymptoms`). `UserState.onboardingPathOrder: List<OnboardingPath>` →
`onboardingCategoryOrder: List<String>` (categoryId từ `branch.categoryId`), `home_state.dart`
xếp theo id thay cho enum. Tracking: page name mới, gửi mã thay enum; thêm
`onboardV2P10View/onboardV2P11View`.

## 7. Thứ tự deploy
API trước (thuần cộng thêm: app cũ vẫn chạy `GET /onboarding-config` + `?onboardingSymptoms=`),
import `onboarding-taxonomy-template.xlsx` trên admin dev, gắn `categoryId` cho 5 nhánh, bật noti
type 8 khi muốn; rồi admin; rồi Flutter. API và Flutter KHÔNG bắt buộc đi cùng.

## 8. Kiểm chứng
- API: `npm run build` (strict), spec cho `OnboardingRecommendationService.rank()` và parser import
  (mock repo); boot dev + `curl` 3 endpoint bằng token ẩn danh.
- Admin: `npx tsc --noEmit`; import file mẫu trên admin dev, xem tree + CourseModal.
- Flutter: `flutter analyze`, unit test `OnboardV2SelectionRules` (bảng §3.2, 3 nhánh §3.3),
  chạy simulator hết 12 màn (dev api).

## 9. Chưa chốt / rủi ro
- Luật câu 3 khi chọn 2 gói (§3.3) đọc theo cách hợp lý nhất; BA xác nhận sau.
- `MAX_NOTIFICATIONS_PER_DAY = 4`: type 8 chịu trần chung; nếu bật đủ 7 type kia thì có thể bị
  rơi âm thầm — quyết định khi bật.
- `findPushCandidatesByTimezones` không phân trang (trần 5000/zone group/tick) — giống mọi type khác.
