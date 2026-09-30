# Sổ tay + Hành trình tuần qua (weekly recap)

Ngày: 2026-08-20 · Stack: `hddhistory-api` + `hddhistory-flutter`
Nguồn design: `HDDhistory - Library.html` (Claude Design), pin `week-wrap`, `wrap-list`,
`week-wrap-monday`, `week-wrap-locked`, `week-wrap-banner-new`.

Mỗi thứ Hai, tuần vừa xong của người học được gói lại thành **một poster 9:16
kiểu scrapbook**. Poster đó vào **Sổ tay** và ở lại đó. Banner trên màn Library
là cửa vào, popup lúc mở app là lời mời.

## Quyết định sản phẩm (chốt 2026-08-20)

| Câu hỏi | Chốt |
|---|---|
| Recap sinh ra ở đâu | **Server, lưu thành document riêng mỗi tuần.** Không tính lại mỗi lần đọc — số liệu trên một poster đã chia sẻ ra ngoài không được phép đổi về sau. |
| Sinh lúc nào | **Lazy, khi client đọc `current`.** Không cron — xem "Vì sao không cron" bên dưới. |
| Tuần nào không có hoạt động | **Không có recap.** Ghi một doc `hasActivity: false` để không aggregate lại, và doc đó không bao giờ xuất hiện ở đâu. |
| Popup thứ Hai | **Lần mở app đầu tiên mỗi ngày, T2→CN, cho tới khi xem.** "Xem hành trình" tắt vĩnh viễn; "Để sau" chỉ im hết hôm nay, sáng mai nhắc lại — `dismissedAt` được server DỜI theo mỗi lần bấm, còn `viewedAt` ghi đúng một lần. (Chốt lại 2026-08-20 theo spec gốc, thay quyết định "hiện đúng 1 lần" buổi trưa.) |
| Cờ "đã xem" lưu ở đâu | **Server, theo user.** Sống qua cài lại app và đồng bộ nhiều thiết bị — đúng bài học từ vụ onboarding bị lặp lại sau khi cài lại. |
| Sổ tay lưu gì | **Mọi tuần có recap**, kể cả tuần user chưa mở popup. Bỏ qua một tuần không làm mất tuần đó. |
| Nút Sổ tay ở Library | Chỉ hiện khi `archiveCount > 0`. |
| Câu động viên | **Template theo ngưỡng, dựng ở client.** Server chỉ gửi số. Đổi copy hay thêm locale không chạm API. |
| Chia sẻ | Làm đủ 4 nút: Tải xuống, IG Story, FB Story, Thêm. |
| Chữ trên poster | Artwork = tầng cố định (giấy, hoạ tiết, 7 nhãn, câu quote). **Mọi thứ mang dữ liệu là slot động.** |
| Số artwork | **5 bản, mỗi locale một bản** (nhãn bake trong ảnh). |

## Trục xoay của thiết kế: poster là một artwork rỗng + 17 slot

Artwork designer gửi là **template rỗng có chủ ý**: tem trống, notepad trống,
bong bóng thoại trống, polaroid trống, dòng kẻ trống. Đó là tầng cố định.

Nhưng nó đang bake **3 thứ mang dữ liệu**, và cả 3 đều phải bóc ra:

| Đang bake | Nếu để nguyên |
|---|---|
| `Tuần 01` | Sai từ tuần thứ 2 |
| `Tháng 8` · `2026` | Sai từ tháng sau |
| `12 13 14 15 16 17 18` | Sai mỗi tuần |

Dãy ngày là chỗ hỏng nặng nhất, vì **7 chip cảm xúc đè lên đúng 7 ô ngày đó**
(cùng rect, `top 23.6%`, `left 62.8%` + bước `4.84%`). Ngày có mood thì chip che
mất số; ngày không có mood thì để hở số ra — đó là lý do design chỉ cấp 6 chip
cho một tuần 7 ngày. Số ngày mà cố định thì chip đè lệch ngày, và người học nhìn
thấy tâm trạng của mình gán sai ngày.

Câu quote (`"Không cần thấy hết cầu thang…"`) **ở lại trong ảnh**: đó là copy biên
tập, không phải dữ liệu của user.

### 17 slot

| # | Slot | Field | Nguồn |
|---|---|---|---|
| 1 | `Tuần NN` | `weekNumber` | ordinal theo user, gán lúc sinh, bất biến |
| 2 | Lịch: tháng | `weekStart` | — |
| 3 | Lịch: năm | `weekStart` | — |
| 4 | Lịch: 7 số ngày | `days[].date` | — |
| 5 | Lịch: chip cảm xúc | `days[].mood` (1..3) | `habit_checkins.mood` |
| 6 | 3 dòng bài học: ảnh | `lessons[].image` | `user_progress` |
| 7 | 3 dòng bài học: tên khoá | `lessons[].courseTitle` | `user_progress` |
| 8 | 3 dòng bài học: tên bài | `lessons[].lessonTitle` | `user_progress` |
| 9 | Polaroid | `favouriteCourse.image` | `user_progress` |
| 10 | Tên khoá ưa thích | `favouriteCourse.title` | `user_progress` |
| 11 | Câu động viên | template ← `stats.activeDays` | slang, client |
| 12 | `CHUỖI` | `stats.streakDays` | chuỗi liên tiếp dài nhất trong tuần |
| 13 | `THÓI QUEN` | `stats.habitsKept` | `habit_checkins` |
| 14 | `BÀI HỌC` | `stats.keypoints` | `user_progress` |
| 15 | `PHÚT HỌC` | `stats.minutes` | `user_progress` |
| 16 | Danh sách thói quen | `habits[].title` (3 dòng) | `habit_checkins` |
| 17 | Dòng "và nhiều thói quen khác…" | suy ra `habits.length > 3` | slang, client |

Header màn hình `Tuần qua của {name}` lấy từ user hiện tại, không nằm trên poster.

### Khi dữ liệu không đủ lấp slot

Poster có chỗ cố định cho 3 bài học và 3 thói quen, nhưng một tuần thật thì
thường không tròn như vậy. Luật: **thiếu thì để hở artwork ra, không bao giờ vẽ
placeholder**. Notepad có 1 bài thì vẽ 1 dòng và hai dòng kẻ còn lại để trống —
đó vốn là notepad kẻ dòng, một dòng trống đọc ra là giấy chưa viết, còn một dòng
"—" đọc ra là app lỗi. Không có habit nào thì bỏ luôn dòng "và nhiều thói quen
khác…". Không có khoá ưa thích (tuần chỉ có habit, không học bài) thì polaroid để
trống. Chỉ số bằng 0 vẫn in số `0` — con tem rỗng nhìn như chưa tải xong.

Một tuần chỉ có habit và không có bài học nào **vẫn là recap**: `hasActivity`
tính cả habit check-in.

Payload gửi **cả 5 chỉ số** (`streakDays`, `habitsKept`, `keypoints`, `minutes`,
`activeDays`) dù poster chỉ vẽ 4. Nếu caption trên tem đổi nghĩa thì sửa binding
ở client, không phải sửa API và không phải migrate document cũ.

## Đơn vị

### hddhistory-api — module `week-recap`

Đặt cạnh `study-journal` trong `courses/src/modules/progress/src/modules/`: cùng
đọc `user_progress` + `habit_checkins`, và `study-journal` đã có tiền lệ một
repository trong `progress` đọc collection của `habit`.

**Collection `week_recaps`**, unique index `{userId, weekStart}`:

```
userId, weekStart, weekEnd, tzOffset, weekNumber, hasActivity,
stats:    { activeDays, streakDays, habitsKept, keypoints, minutes }
days:     [{ date, active, mood? }]        // đúng 7 phần tử
lessons:  [{ courseId, courseTitle, image, lessonId, lessonTitle }]
favouriteCourse: { courseId, title, image }
habits:   [{ habitId, title, doneCount }]
viewedAt, dismissedAt, generatedAt
```

Định nghĩa các chỉ số:

- `active` = ngày có ít nhất một keypoint submission, một habit check-in `done`,
  **hoặc** một mood đã ghi. Tính cả mood vì poster vẽ chip cho ngày đó — một chip
  nằm trên ngày mà 4 con tem coi là không hoạt động thì đọc ra là một trong hai
  cái sai.
- `hasActivity` suy ra từ chính 7 ngày (`days.some(active)`), không từ hai list
  nguồn, nên nó không bao giờ lệch với cái lịch mà poster vẽ. Tuần chỉ có habit
  và không học bài nào **vẫn là recap**.
- `streakDays` = **chuỗi ngày active liên tiếp dài nhất trong tuần** (giả định —
  xem "Còn treo"). Không dùng streak toàn cục: tuần kết bằng một ngày nghỉ thì
  streak toàn cục về 0 và con số trên poster sẽ mâu thuẫn với dãy chip ngay bên
  trên nó.
- `keypoints` = số keypoint submission trong tuần (giả định — xem "Còn treo").
- `minutes` = tổng `minutes` ước tính của các keypoint đó, đúng cách
  `study-journal` đang tính.
- `habitsKept` = số habit khác nhau có ít nhất một check-in `done`.
- `habits[]` sắp theo `doneCount` giảm dần; client lấy 3 dòng đầu.
- `favouriteCourse` = khoá có nhiều keypoint nhất trong tuần, đồng hạng thì nhiều
  phút hơn.
- `lessons[]` = 3 lesson khác nhau được học gần nhất trong tuần.
- `weekNumber` = `số recap có hoạt động đã có + 1`, gán một lần lúc sinh. Đây là
  "poster thứ N của bạn", không phải số tuần ISO: người bỏ một tuần vẫn đi tiếp
  từ `Tuần 02` sang `Tuần 03` chứ không nhảy số.

**Endpoint** (controller mới, cùng path `courses-user-progress`):

| Route | Trả |
|---|---|
| `GET /week-recap/current?tzOffset=` | `{ recap \| null, archiveCount }` — sinh recap tuần trước nếu chưa có |
| `GET /week-recap?page=&tzOffset=` | Danh sách cho Sổ tay, mới nhất trước |
| `GET /week-recap/:id` | Một recap |
| `POST /week-recap/:id/viewed` | Đóng popup vĩnh viễn, bật pill MỚI cho hôm nay |
| `POST /week-recap/:id/dismissed` | "Để sau" — cũng đóng popup vĩnh viễn |

`current` trả kèm `archiveCount` để client quyết định nút Sổ tay và nút "Xem lại
các tuần trước" trong popup lock mà không cần gọi thêm lần nữa.

**Snapshot đóng lại sau 3 ngày, không phải ngay lập tức.** Recap mà người học
**chưa từng được cho xem** thì còn được dựng lại, và chỉ trong vòng 3 ngày kể từ
lúc tuần đóng. Lý do: dữ liệu về muộn là chuyện thật — check-in ghi lúc offline,
một loạt keypoint sync chậm một ngày — và một poster chưa ai thấy thì chưa có gì
phải bảo vệ. Đúng ba ngày, đúng lý lẽ với `AnalyticsRollupService.BACKFILL_DAYS`.
Hết cửa sổ đó thì đóng vĩnh viễn dù đã xem hay chưa: một poster còn có thể đổi
sau một tháng thì không còn là snapshot. `replaceUnseen` chốt điều này ở tầng
query bằng `$exists: false` trên cả hai mốc, nên một request tới sau khi người
học vừa mở poster sẽ không tìm thấy gì để ghi — số họ đã thấy, và có thể đã chia
sẻ, không bao giờ bị viết lại dưới chân họ. Dựng lại **không đánh số lại**; ngoại
lệ duy nhất là tuần ban đầu bị chốt là rỗng mà sau đó có hoạt động — tuần đó chưa
có số và giờ mới được cấp.

**`weekOffset=0` xem tuần đang chạy.** Mặc định là `1`, tức tuần đã đóng. `0` trả
tuần còn dở dưới dạng **preview: tính sống mỗi lần gọi, không ghi, không cấp số**.
Không ghi là điều kiện bắt buộc — ghi thì một tuần chưa xong sẽ có `weekNumber` và
một ô trong Sổ tay mà recap thật của thứ Hai sẽ đâm vào. Đây cũng là cách duy nhất
để xem dữ liệu mood đi hết đường từ check-in tới poster mà không phải đợi thứ Hai.

**Vì sao không cron.** Ranh giới tuần là ranh giới **địa phương của người học**,
và `@Cron` trong repo này là singleton không được phụ thuộc `RequestService`
(`Scope.REQUEST` bubble lên trên graph và giết luôn cái `@Cron` bên dưới — đã bị
và có cảnh báo ở `notification-campaign.service.ts:60` và `segment.module.ts:40`).
Một cron chạy 00:30 giờ Việt Nam sẽ chốt tuần sai cho mọi user ngoài múi giờ đó.
Client thì đã luôn gửi `tzOffset` như `study-journal` đang làm, nên sinh lúc đọc
vừa đúng múi giờ vừa chỉ tốn cho user thật sự mở app. Upsert trên unique index
`{userId, weekStart}` lo phần hai request đồng thời.

Lần gọi đầu tiên **chỉ sinh tuần liền trước**, không backfill toàn bộ lịch sử.

`tzOffset` được lưu lại cùng doc. User bay sang múi giờ khác thì tuần đã chốt
không sinh lại.

### hddhistory-flutter — feature `week_recap`

Feature mới `lib/src/week_recap/`, dựng theo đúng khuôn `study_journal`
(api Retrofit → repository → usecase → cubit), gồm 2 page và 6 widget:

| File | Vai trò |
|---|---|
| `pages/week_recap_page.dart` | Poster + thanh chia sẻ |
| `pages/week_recap_archive_page.dart` | Sổ tay, grid 2 cột |
| `widgets/week_recap_poster.dart` | Artwork + 17 slot |
| `widgets/week_recap_calendar.dart` | Khối lịch vẽ bằng code |
| `widgets/week_recap_banner.dart` | Banner trên Library |
| `widgets/week_recap_monday_popup.dart` | Popup thứ Hai |
| `widgets/week_recap_locked_popup.dart` | Popup "chưa tới thứ Hai" |
| `widgets/week_recap_popup_host.dart` | Host trên shell |

**Poster.** Box tỉ lệ `1080/1920`, `Stack` với mọi slot lấy từ **một bảng hằng
`_PosterSlots`** thay vì rải magic number khắp file. Cỡ chữ scale theo
`posterWidth / 350` — design vẽ trên poster rộng 350 trong frame 390, nên phải
scale theo bề rộng **poster**, không theo bề rộng máy.

**Chia sẻ.** `IMediaService` đã có sẵn gần hết:

- Tải xuống → `captureWidgetWithRepaintBoundary` + `saveImageToGallery`
- Thêm → `captureAndShareWithRepaintBoundary`, đúng đường mà
  `shareCourseStoryCard` đang dùng cho card 9:16
- `pixelRatio = 1080/350 ≈ 3.09` để ra đúng 1080×1920

IG Story và FB Story **đã có sẵn đường**, khác dự đoán ban đầu của spec:
`IStoryShareService` bridge sang channel `hddhistory/story_share`
(`ios/Runner/StoryShareChannel.swift`), đúng cái mà share card khoá học đang
dùng. Không phải viết platform channel mới, không phải sửa Info.plist hay
AndroidManifest. Không hand-off được thì fallback về share sheet hệ thống.

**Popup host.** Shell đang xếp 4 host độc lập (`ImportDone` → `WinBack` → `Gift`
→ `Streak`), mỗi cái tự latch một mình và không cái nào biết cái nào. Thêm host
thứ 5 là mở đường cho hai modal đè nhau. Nên thêm một latch dùng chung ở `core`
và cắm một dòng kiểm tra vào `StreakPopupHost` và `HomePromoPopupHost`: mỗi lần
mở app chỉ một modal được lên. Host recap đặt ngoài cùng, và chỉ raise khi đang
ở primary route (`PageCubit.isPrimaryRoute`) để không đè lên giữa một bài học.

**Route.** `WeekRecapRoute` và `WeekRecapArchiveRoute`, dùng `push` như
`LibraryHistoryRoute` — back về đúng chỗ vừa đi ra, và destination tự claim tên
route của nó (một `.go()` vào branch đã dựng không phát didPush).

**Tile trong Sổ tay** dùng chính artwork làm ảnh nền, không render lại poster cho
từng tuần: một grid 20 ô mà render 20 poster thì trả giá quá đắt cho một hình
thumbnail.

**l10n.** `assets/i18n/<locale>/week_recap.yaml` cho **cả 5 locale**
(`en`, `vi`, `zh`, `ja`, `ko`), rồi `dart run slang`.

**Assets.** `assets/images/week_recap/wrap_bg_<locale>.jpg` — JPEG q95 chứ không
PNG: bản PNG gốc 4,8MB/file, đủ 5 locale là ~24MB bundle cho một ảnh collage
không cần alpha; JPEG cùng ảnh ~1MB và không thấy khác biệt, kể cả sau khi luồng
share encode lại. Cộng file font brush script cho `Tuần NN`.

## Luật hiển thị

Ba trạng thái, quyết định ở client từ `viewedAt` / `dismissedAt` / `archiveCount`,
so theo **ngày địa phương**:

| Trạng thái | Banner | Chạm banner | Popup |
|---|---|---|---|
| Có recap, chưa xem | pill `MỚI` | Mở poster | Lần mở đầu mỗi ngày |
| Có recap, "Để sau" hôm nay (chưa xem) | pill `MỚI` | Mở poster | Im tới sáng mai |
| Có recap, xem **hôm nay** | pill `MỚI` | Mở poster | Không, vĩnh viễn |
| Có recap, xem từ ngày trước | default | Popup lock | Không |
| Không có recap | default | Popup lock | Không |

Pill `MỚI` chỉ ăn theo `viewedAt` — "Để sau" không phải là xem, nên không tắt
pill và cũng không hẹn ngày cho nó. Chạm banner mở poster **chỉ khi đang MỚI**;
banner default luôn ra popup lock, đường quay lại tuần đã xem là Sổ tay
(design's `tapWeekWrap` cũng tách đúng như vậy).

Popup lock chỉ hiện nút "Xem lại các tuần trước" khi `archiveCount > 0`. Nút Sổ
tay trên Library cũng theo đúng cờ đó.

## Còn treo

**Artwork + font — cập nhật 2026-08-20 tối.** Designer bóc TRẮNG chữ khỏi artwork
(`1890×3360`) và đồng thời **đưa toạ độ của từng nhãn vào markup** trong bản
design mới. Nên: **một artwork `wrap_bg.jpg` dùng chung cả 5 locale**, mọi chữ vẽ
từ l10n, và món nợ "artwork zh/ja/ko" tự biến mất. Bảng
`week_recap_poster_slots.dart` giờ là **số của design**, không còn đo bằng mắt —
ba vòng đo bằng mắt trước đó là ba vòng lệch.

Poster dùng 5 font, mỗi thứ một việc:

| Font | Việc | Trạng thái |
|---|---|---|
| `Space Mono` | mọi nhãn in hoa **+ toàn bộ khối lịch** (`THÁNG 8`, `T2…CN`, số ngày) | ✅ bundle, OFL |
| `Lumios Marker` | chữ tay: tên bài, câu động viên, tên khoá, 4 con số, danh sách | ✅ bundle |
| `Billock` | **số** trong `Tuần 01` | ✅ bundle — nhưng name table ghi *"personal use"* (Alit Design), **cần xác nhận license** |
| `Forward Serif` | chữ **"Tuần"** | ❌ `get_file` cap 192KB nên tải về bị cắt; cần designer gửi file |
| `MTD Adventures` | câu **quote** góc trên phải | ❌ chưa lấy |

Mulish không còn xuất hiện trên poster.

**Hai lỗi hình học đáng ghi lại** (loại không throw, chỉ âm thầm sai):
- CSS `top:` đặt **đỉnh** khối chữ. Canh giữa theo chiều dọc làm Billock (ascent
  cao) bị đẩy khỏi mép trên poster, `Stack` clip mất — tiêu đề mất nửa mà không
  có exception nào. Mọi slot tiêu đề giờ neo theo đỉnh.
- Chữ số trên tem cần `line-height: 0.75` của design; đó mới là thứ giữ chân chữ
  khỏi đè caption, không phải cỡ chữ (hạ cỡ là sai hướng).
- Dãy ô lịch **lệch phải** trong thẻ (chừa trái 6.1%, phải 0.4%); cột đối xứng
  trượt nửa ô ở phía Chủ Nhật.

**Hai giả định đang code theo**, cần xác nhận:

- `CHUỖI` = chuỗi ngày liên tiếp dài nhất trong tuần. Khớp với số 6 trên artwork
  khi T2–T7 active và CN trống.
- `BÀI HỌC` = keypoint, không phải lesson. 12 keypoint trong 84 phút là ~7
  phút/keypoint, hợp; 12 lesson trong 84 phút thì không.

**Toạ độ.** 14 slot lấy từ markup design đã đối chiếu khớp với artwork
(`left 8% top 42%` = đúng ô bong bóng; `64%/30.3%` = đúng khung polaroid;
`cx 15.1/40.3/62/83.7%` = đúng tâm 4 con tem; `left 14% top 81.9%` = đúng dòng kẻ
đầu). 3 slot mới (`Tuần NN`, tháng/năm, 7 số ngày) phải đo từ artwork gốc
1620×2880 khi có bản đã bóc chữ.

## Kiểm chứng

- `hddhistory-api`: `npm run build` — `tsconfig.build.json` bật `strict: true` còn
  `tsconfig.json` thì không, nên `tsc --noEmit` cho qua mà Jenkins vẫn fail.
  Một spec cho service: aggregation, "không active → không recap", đánh số tuần.
- `hddhistory-flutter`: `flutter analyze`, rồi chạy simulator soi poster — lệch toạ độ
  và tràn chữ chỉ hiện ra trên máy, `analyze` không bắt được.
- Không chạy full test suite trên máy này.
