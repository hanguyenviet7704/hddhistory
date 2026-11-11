# Link dẫn vào từng màn của app, sinh từ Admin

Ngày: 2026-08-14 · Stack: `hddhistory-flutter` + `hddhistory-api` + `hddhistory-admin` + `web-download-link`

Marketer cần tự lấy được một URL dẫn thẳng vào một màn cụ thể của app, để dán vào
push notification, vào ô `linkUrl` của banner/popup trong admin, vào bài Zalo/Facebook,
và vào email CSKH 1-1.

## Quyết định sản phẩm (chốt 2026-08-14)

| Câu hỏi | Chốt |
|---|---|
| Link dán vào đâu | Cả 4: push notification, ô cấu hình trong admin, marketing ngoài (Zalo/FB/QR), email 1-1 |
| Chưa cài app thì sao | Ra store như hiện tại. **Không làm deferred deep link** ở v1 — người mới cài bắt buộc qua onboarding trước, và iOS không còn cơ chế nào rẻ (Firebase Dynamic Links đã shutdown 8/2025) |
| Đích cần có | Màn chung không tham số + course cụ thể + lesson/keypoint cụ thể + paywall có variant |
| Thống kê | Giai đoạn 1 đo bằng event trong app. Giai đoạn 2 mới thêm đích vào `/r/<slug>` để có thống kê server-side cho khách lạ |
| Quan hệ với trang "Link tải app" | Trang mới, độc lập. `/r/<slug>` giữ nguyên nghĩa "link tải app", không nhập nhằng hai việc vào một trang |

## Trục xoay của thiết kế: link mang KHOÁ, không mang route path

`https://meup.training/open/paywall` — không phải `.../open/paywall-page`, không phải
`.../paywall` trần.

Mọi hệ quả rơi ra từ đúng lựa chọn này:

- **Đổi tên route trong Flutter không làm chết link đã phát ra.** Link đã in QR, đã
  gửi push, đã dán vào bài Zalo thì không rút lại được. Đây chính là lý do
  `NotificationDeeplink` trong `notification.enum.ts` đã cố tình gửi destination
  tượng trưng thay vì path — thiết kế này chỉ mở rộng cùng nguyên tắc ra ngoài app.
- **Tập khoá là đóng và có thể liệt kê**, nên admin dựng được dropdown và server
  validate được — không thể làm thế với path tự do.
- **Tiền tố `/open/` giữ chỗ cho web.** `meup.training` còn là domain marketing;
  path trần sẽ đụng `/pricing`, `/blog` sau này. Và nó cho `index.html` **một** chỗ
  duy nhất để nhận ra "URL này là link vào màn, không phải link tải".

Hai dạng URL cho hai ngữ cảnh, cùng một bảng khoá:

```
https://meup.training/open/<key>?<param...>&c=<campaign>   ← phát ra ngoài
hddhistory://open/<key>?<param...>                                ← dán vào ô linkUrl trong admin
```

`c=` là nhãn campaign tự do, **chỉ** đi vào event tracking; app không đọc nó để điều
hướng. Trên Android nó còn sống sót qua lượt cài vì `index.html` đã forward
`location.search` vào `referrer` của Play.

Ba dạng cũ — `hddhistory://`, `hddhistory://paywall`, `hddhistory://course-roadmap?...` — **phải chạy
nguyên**: cấu hình banner và popup đang chạy production đã dùng chúng.

### Không phải sửa `.well-known/`

AASA khai `paths: ["*"]` và AndroidManifest khai `pathPrefix="/"` với `autoVerify`,
nên `/open/*` đã được cả hai nền tảng nhận. nginx cũng không cần `location` mới:
catch-all `try_files $uri /index.html` đã phục vụ `/open/paywall`. Đây là điều tốt và
cũng là điều dễ vô tình làm hỏng — đừng thêm `location` nào chen trước hai block
`location =` của `.well-known`.

### Sự thật về tracking phải nói rõ

**Khi app đã cài, server không bao giờ thấy click đó.** iOS/Android chặn URL ở tầng
OS và giao thẳng cho app — không có HTTP request nào tới meup.training. Nên "đếm
click server-side" cho deeplink chỉ đếm được người **chưa** cài app. Đếm người đã cài
bắt buộc phải bắn event từ trong Flutter. Đó là lý do giai đoạn 1 không có bảng thống
kê trong admin, và lý do đó không phải là thiếu sót của thiết kế.

## Danh mục đích v1

| Nhóm | key | Tham số | Cách đi |
|---|---|---|---|
| Tab | `home` | — | `HomeRoute().go()` |
| Tab | `explore` | — | branch 3 (grid Khám phá) |
| Tab | `habit` | — | branch 4 |
| Tab | `profile` | — | branch 2 |
| Tab | `library` | — | branch 5 — tách khỏi Profile 2026-08-14, `myLessons` nằm trong đây |
| Học | `course-roadmap` | `courseId?` | Không truyền → roadmap của course đang chọn |
| Học | `lesson` | `courseId`, `keypointId?` | Qua roadmap rồi mở bài — dùng lại `setPendingResumeKeypointId` |
| Học | `category-courses` | `categoryId` | Grid đầy đủ của một chủ đề |
| Tiền | `paywall` | `variant?` (`full`\|`compact`) | Push lên trên, không relocate |
| Tiền | `manage-subscription` | — | dưới tab Profile |
| Engagement | `daily-warm-up` | — | dưới tab Home |
| Engagement | `learning-streak` | — | dưới tab Home |
| Engagement | `daily-check-in` | — | dưới tab Habit |
| Nội dung riêng | `my-lessons` | — | dưới tab Profile |
| Nội dung riêng | `import-lesson` | — | dưới tab Explore |
| Cài đặt | `notification-setting` | — | cho CSKH 1-1 |
| Cài đặt | `change-language` | — | cho CSKH 1-1 |

Thêm một key về sau = một dòng trong enum Flutter + một `case` + một dòng trong danh
mục ở API. Không phải thiết kế lại.

## Hai quy tắc bắt buộc

1. **Khoá lạ → về Home, nhưng CHỈ khi app đã qua splash và đang ở vùng đã đăng
   nhập.** Hôm nay code đứng im (`deeplink_cubit.dart` chỉ `LogDev.warning` rồi
   thoát), nghĩa là bản app cũ nhận link tới màn mới sẽ mở app rồi treo đúng chỗ
   người dùng đang đứng — không ai biết có gì vừa hỏng. Với app đang mở thì về Home
   sai ít hơn.

   Nhưng **cold start thì phải trả `false`**, để splash/onboarding tự lo. `initialLink()`
   dùng giá trị trả về này để biết deeplink có chiếm quyền điều hướng hay không; nếu
   khoá lạ cũng "chiếm" thì một người vừa cài app, mở từ link mà bản app của họ chưa
   hiểu, sẽ bị `.go(Home)` **đè lên onboarding**. Cùng một cái guard của quy tắc
   pre-auth bên dưới quyết định cả hai trường hợp — không phải hai cơ chế.

   Cùng lý do đó, mọi đích **đều** phải trả `false` khi đang ở vùng pre-auth, kể cả
   đích hợp lệ. Deeplink không được vượt lên trước onboarding.
2. **Không bao giờ đi vòng qua gate.** `lesson` tới một bài premium mà người dùng
   chưa mua thì roadmap tự xử theo luật lock/paywall sẵn có. Deeplink là đường đi,
   không phải chìa khoá.

## Đơn vị

### hddhistory-flutter — registry đích (phần nặng nhất, phải xong trước)

Hôm nay app chỉ nhận **3** đích: `/` (home), `/paywall`, và `/course-roadmap` (chỉ khi
kèm `source=live_activity` hoặc param của home widget). Mọi path khác rơi vào nhánh
"unsupported". Không có phần này thì trang admin chỉ sinh ra link chết.

**File mới** `lib/config/services/deeplink/deeplink_destination.dart` (part của
`services.dart`):

- `enum DeeplinkDestination` — 17 khoá ở bảng trên, mỗi cái có `value` + `tryFromValue`.
- `class DeeplinkTarget { destination, params }` với `tryParse(Uri)`: bỏ tiền tố
  `/open/`, và **nhận cả dạng cũ không tiền tố** để `hddhistory://paywall` trong config
  production vẫn chạy.

**Sửa `deeplink_cubit.dart`**: `_handleNormalRoute()` (hiện là `switch` 2 nhánh) thành
`_handleDestination(DeeplinkTarget)`. Thứ tự ưu tiên trong `handleRoute()` giữ nguyên:
`_handleLiveActivityRoute()` → `_handleShellRoute()` → `_handleDestination()`. Hai
handler đầu khoá theo `source=`/`widgetType=` và mang analytics riêng của chúng, phải
tiếp tục thắng.

**Ba cái bẫy điều hướng phải encode, không phải tuỳ tâm:**

- **Đổi branch bằng `.go()` khi branch đích đã khớp thì KHÔNG phát event route nào.**
  Mọi đích đổi branch phải gọi `PageCubit.setCurrentRouteName(RouteNamed.x)` **trước**
  `.go()` — đúng như `_openCourseRoadmap()` đang làm. Bỏ sót thì nav nổi hiện sai tab
  và màn đích không "nhận" tên của mình.
- `AppConfig.instance.context` có thể null (deeplink tới trước khi navigator sẵn
  sàng) → log + trả `false`, giữ đúng pattern hiện có.
- Cubit lấy qua `AppDI.injector.get<T>()`, không tạo mới.

**Giữ link lại khi đang ở vùng pre-auth.** `handleRoute()` hôm nay chỉ chặn ở
`isPassSplashScreen`. Onboarding diễn ra **sau** splash, nên một deeplink tới lúc
người dùng đang onboarding sẽ `.go()` và giật họ ra khỏi luồng. Thêm: nếu route hiện
tại nằm trong `preAuthRouteNames` thì giữ `_serviceRoutePath`, và `DeeplinkCubit`
lắng `PageCubit` để replay khi rời vùng pre-auth. Lắng stream chứ không gọi từ chỗ
onboarding xong — để không phải đi tìm hết mọi đường ra của onboarding.

**Event mới** `deeplink_open` với `{destination, campaign, resolved, reason}`. Đây là
cách duy nhất đếm được người đã cài app. Tên event mới cần thêm vào sheet
"[HDDhistory] Event Tracking" cho khớp.

**Không có l10n mới** — thiết kế này không thêm màn nào, chỉ thêm đường tới màn đã có.

### hddhistory-api — module `deeplink` (danh mục, không DB)

`src/modules/deeplink/`: `deeplink.module.ts`, `deeplink.controller.ts`,
`deeplink.catalog.ts` (một `const` tĩnh), `dto/`.

`GET /api/v1/deeplink/destinations` trả:

```ts
{ key, label, group, minAppBuild, note?, params: [{ name, required, picker, options? }] }
```

`picker` nói cho admin biết render gì: `course` | `category` | `keypoint` | `select` |
`text`. Với `select` thì `options` mang sẵn các giá trị hợp lệ — `variant` của paywall
là `["full", "compact"]`, và đó phải là danh sách server khai, không phải hằng số gõ
lại trong admin.

- **Không entity, không repository, không migration.** Là một hằng số phục vụ qua
  HTTP. Đặt ở API chứ không hardcode trong admin vì API được deploy dày hơn admin
  nhiều, và vì giai đoạn 2 sẽ cần đúng danh mục này để validate `destinationKey` của
  `/r/<slug>` — một nguồn sự thật, không phải hai.
- `@UseGuards(AuthGuard)` — **và `deeplink.module.ts` PHẢI `imports: [AuthModule]`**.
  Thiếu là app crash-loop lúc boot, `tsc --noEmit` và `nest build` đều không thấy.
  Đây là lỗi đã gặp ở module mới trong repo này.
- **API không dựng URL.** Admin dựng, giống `buildDownloadLinkUrl` đang làm, với lý do
  đã ghi ở đó: entitlement iOS là `applinks:meup.training` không wildcard, nên admin
  không được hiện một host mà app chưa claim.

`minAppBuild` không phải trang trí: không có nó, marketer sẽ gửi link tới màn mới cho
80% người đang dùng bản cũ và tất cả rơi về Home mà không ai hiểu tại sao.

### hddhistory-admin — trang "Link vào màn"

- `src/pages/deeplinks/DeeplinkGenerator.tsx`
- route `deeplinks` trong `src/routes/index.tsx` (cạnh `download-links`, trong
  `ProtectedRoute`)
- sidebar nhóm **Operations**, ngay dưới "Link tải app": `{ name: "Link vào màn", icon: LinkIcon, path: "/deeplinks" }`
- `src/services/deeplinkService.ts` + `src/types/interface/deeplink.interface.ts`,
  `DEEPLINK_BASE = "https://meup.training/open"`

Bố cục hai phần, phần trên trả lời đúng "GIẢI PHÁP NGẮN HẠN" trong sheet gốc:

1. **Bảng màn phổ biến** — các key không tham số, mỗi dòng một nút Copy. Trường hợp
   thường gặp nhất không phải mở form nào cả.
2. **Form sinh link** — chọn màn → form param tự dựng theo `params[].source` (picker
   course/category/keypoint dùng service đã có) → ô campaign → **hai** ô kết quả
   read-only kèm nút Copy: link web `https://…` và link trong app `hddhistory://…`.

Các trạng thái phải có: đang tải danh mục, tải danh mục lỗi, chưa chọn màn, thiếu
param bắt buộc (chặn Copy + báo tại chỗ), và chú thích `minAppBuild` của màn đang chọn.

QR code: **chưa làm** ở v1 (cần thêm lib). Khi cần thì `/r/<slug>` của giai đoạn 2 là
chỗ đúng để in QR, vì QR đã in thì phải đổi được đích.

### web-download-link — thử `hddhistory://` trước khi ra store

Hôm nay `index.html` đẩy **mọi** khách mobile ra store, không thử scheme. Với link tải
thì vô hại; với link vào màn thì sai đích: trong webview Zalo/Facebook — nơi Universal
Link thường không nổ — người **đã cài app** bị đưa ra store.

Sửa trong đúng inline script ở đầu `<head>`, không thêm file, không thêm `location`
nginx:

```
nếu pathname bắt đầu bằng "/open/":
    nếu UA là in-app webview (FBAN/FBAV/Instagram/Zalo/Line):
        thử hddhistory://open/<phần còn lại><search>, rồi setTimeout 1200ms → store
    ngược lại:
        ra store ngay như hiện tại
```

Chỉ thử scheme trong webview là có chủ đích: ở Safari thật, Universal Link **có** nổ,
nên đến được `index.html` nghĩa là app chưa cài — thử scheme ở đó chỉ đổi lấy hộp
thoại "Safari cannot open the page" cho đúng nhóm người lẽ ra nên ra store ngay.

Phần này phải verify trên máy thật trong Zalo và Messenger; nếu không đáng tin thì bỏ,
hành vi rơi về đúng như hôm nay.

## Xử lý lỗi

| Tình huống | Hành vi | `reason` trong event |
|---|---|---|
| Khoá lạ, app đang mở ở vùng đã đăng nhập | về Home, trả `true` | `unknown_destination` |
| Khoá lạ, cold start / đang pre-auth | **không điều hướng**, trả `false` để splash lo | `unknown_destination_deferred` |
| Thiếu param bắt buộc | về Home, trừ khi có biến thể không param hợp lệ (`course-roadmap`) | `missing_param` |
| Course/category không tồn tại hoặc đã unpublish | về Home — giống `course_not_found` của luồng widget | `entity_not_found` |
| Bài bị lock / chưa mua | tới roadmap, để gate sẵn có xử | — (coi là thành công) |
| Đang ở pre-auth / onboarding | giữ lại, replay sau | — |
| Chưa có navigator context | log + bỏ, giữ nguyên hành vi hiện tại | `missing_context` |
| Offline | đích nằm trong URL nên vẫn điều hướng được; roadmap tự hiện trạng thái lỗi của nó | — |
| Nhận trùng initial link | `_lastHandledInitialUriKey` sẵn có đã chặn | — |

## Kiểm chứng

Máy này không chạy được full test suite (hết RAM) — theo CLAUDE.md.

- `npx tsc --noEmit` cho hddhistory-api và hddhistory-admin (hook `PostToolUse` tự chạy sau mỗi
  Edit/Write).
- `flutter analyze`.
- **Một** test đơn lẻ: `test/unit/common/deeplink_target_test.dart` cho
  `DeeplinkTarget.tryParse` — parse là hàm thuần và là đúng chỗ hỏng âm thầm. Ca phải
  có: `hddhistory://paywall` (dạng cũ), `hddhistory://` (home), `/open/lesson?courseId=&keypointId=`,
  khoá lạ, thiếu param bắt buộc.
- Verify trên simulator qua skill `sim-test`:
  `xcrun simctl openurl booted "hddhistory://open/<key>"` cho từng khoá — vòng lặp rẻ nhất
  để quét hết registry. Nhớ Simulator phải đang là app frontmost trước mỗi cú click.

## Thứ tự ship (quan trọng)

1. **hddhistory-flutter trước** — registry + release. Không có bản app hiểu khoá thì mọi
   link sinh ra đều chết.
2. **hddhistory-api** — danh mục (deploy độc lập được, không phá gì).
3. **hddhistory-admin** — trang sinh link. **Không ship trước** khi có bản Flutter mang
   registry đang live, nếu không marketer sẽ phát ra link mà không bản app nào hiểu.
4. **web-download-link** — sau cùng, sau khi verify trong webview thật.

## Ngoài phạm vi spec này

**Giai đoạn 2 (`/r/<slug>` có đích).** Thêm `destinationKey` + `destinationParams`
vào `app_download_links`; app bắt `/r/<slug>` (AASA `*` đã claim rồi), gọi
`GET /api/v1/r/:slug/resolve`, và chính cú resolve đó là cú đếm — cách duy nhất có
thống kê server-side cho cả người đã cài app. Kèm theo: đổi đích sau khi đã gửi push,
OG card riêng từng link, link ngắn để in QR. Danh mục ở API là thứ làm giai đoạn 2 rẻ.

**Deferred deep link** (chưa cài app → cài xong mở đúng màn). Cần Branch/AppsFlyer
cho iOS. Dự án riêng.
