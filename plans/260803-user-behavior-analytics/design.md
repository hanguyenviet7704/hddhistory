# Đo hành vi người dùng trong admin: tab "Hành vi" trên trang user progress

Spans **hddhistory-flutter**, **hddhistory-api**, **hddhistory-admin**. Viết 2026-08-03.

## Yêu cầu

Từ trang `admin/progress/user/:userId` ("User learn progress"), người vận hành
muốn đọc được **hành vi** của đúng user đó, chi tiết hết mức có thể, dựa vào các
event tracking mà app đang bắn: họ mở app lúc nào, đi qua screen nào, bấm gì, dừng
ở bước nào, mỗi phiên dài bao lâu.

Hôm nay trang đó chỉ có dữ liệu progress server-side (bảng course + stop-at +
completed levels + feedback). Không có event nào.

## Trạng thái trước khi làm

- **hddhistory-flutter đã bắn đủ event.** `lib/core/constants/manual/tracking_key.dart`
  có ~442 hằng số event, đã được align chính xác theo sheet "[HDDhistory] Event Tracking"
  (7 tab: Onboarding, Home, Learning, Explore, Habit, Profile, Live Activity).
  Screen view có sẵn miễn phí: `route_observer_service.dart` gọi
  `trackScreenView(route.settings.name)` mỗi lần điều hướng.
- **Event chỉ đi tới Firebase Analytics.** `AppTrackingService` inject
  `@Named(DIKey.firebaseAnalyticsService)` — tức `CompositeTrackingService` **không
  được dùng ở đâu cả**, và `SentryTrackingService` thực tế không nhận event nào dù
  DI có khai báo. Không có sink nào về hddhistory-api.
- **Đã có một event inspector trong app (DEV-only).** `BaseTrackingService.trackEvent`
  mirror mọi event vào `EventInspectorStore` khi flavor là dev. Đây là bằng chứng
  rằng `BaseTrackingService` là choke point duy nhất mọi event đi qua.
- **hddhistory-api chưa có module analytics.** 13 module trong `src/modules/`, không có
  chỗ nào nhận event từ client.
- **Admin**: `progress/user/:userId` → `UserProgressSummaryList.tsx` (855 dòng),
  `progress/user/:userId/course/:courseId` → `UserProgressDetail.tsx`.

### Ràng buộc kỹ thuật đã kiểm chứng

- **Firebase Analytics không có API đọc event-level.** GA4 Data API chỉ trả báo cáo
  tổng hợp và không lọc được theo một `user_id`. Đường duy nhất để lấy từng event
  của từng user từ Firebase là bật GA4 → BigQuery export rồi query `events_*`.
- **BigQuery export không backfill.** Bật hôm nay chỉ có dữ liệu từ hôm nay. Không
  hướng nào lấy lại được event lịch sử — cả sink tự làm cũng vậy.
- **Cả 3 flavor dùng chung một Firebase project** `meup-bf64f` (so
  `android/app/src/{dev,stg,prod}/google-services.json`). Phân biệt môi trường bằng
  default param `app_env` mà `FirebaseAnalyticsService._setDefaultEventParameters`
  đã set sẵn (cùng với `device_id`, `app_version`, `user_id_param`).
- **Guest cũng có userId thật.** App gọi `loginAnonymous` ngay từ đầu; user schema
  có `anonymous: boolean`. Quan trọng hơn: **nâng cấp guest → user thật là in-place**,
  giữ nguyên `_id` (`auth.service.ts` xử lý `anonymousUserId`, set `anonymous: false`),
  nên event của khách tự thuộc về user sau khi họ đăng ký — **không cần merge userId**.
- `ILocalStoreService` (`lib/config/services/device/local_store_service.dart`) có
  `setList`/`getList` — đủ để persist queue offline, không cần thêm dependency.
- `IDeviceInfoService.deviceToken` là deviceId sẵn có. Trên Android nó dẫn xuất từ
  SSAID nên đổi sau khi cài lại app; đây là giới hạn đã biết, không xử lý ở đây.

## Quyết định thiết kế

**Tự dựng sink về hddhistory-api, không kéo từ BigQuery.**

Cân nhắc đã loại:

| Hướng | Loại vì |
|---|---|
| Kéo từ BigQuery | Daily export trễ tới ~24h — mở trang một user vừa test xong mà mai mới thấy event thì mất hẳn công dụng điều tra. Streaming export gần real-time nhưng tính phí, và mỗi lần mở trang là một query scan theo partition ngày (chậm vài giây, tính tiền theo GB). `event_params` nested phải `UNNEST`, GA4 lại cắt param dài và giới hạn 25 param/event. |
| Hybrid BQ → cron ETL → Mongo | Được cả real-time-đủ-dùng và query nhanh, nhưng nhiều bộ phận nhất (export + service account + cron + Mongo) cho cùng một kết quả mà sink trực tiếp làm được với ít hơn một nửa. |

Sink tự làm đổi lại bằng việc **cần release app mới** (dev build có ngay), và
thêm traffic + storage cho api. Đó là cái giá đã chấp nhận.

**Cắm sink ở DI, không sửa call site.** Vì `BaseTrackingService` là choke point và
`CompositeTrackingService` đã tồn tại, chỉ cần thêm một service vào composite rồi
trỏ `AppTrackingService` vào composite đó. Cả ~442 event hiện có và mọi event thêm
sau này tự động có mặt, không phải sửa một call site nào.

**Lưu Mongo, không MySQL.** `params` là bag key-value tự do (schemaless), ghi nhiều
đọc theo user, và cần TTL tự dọn — đúng thế mạnh Mongo. MySQL sẽ phải hoặc dựng
bảng key-value phụ hoặc nhét JSON vào text.

**Session tính ở lúc đọc, không lưu bảng riêng.** Group theo `sessionId`, lấy
min/max `clientTs`. Không có hai nguồn sự thật phải đồng bộ.

**TTL 90 ngày, bật cả 3 flavor.**

## Contract

### Collection `user_events` (Mongo)

| field | type | ghi chú |
|---|---|---|
| `userId` | ObjectId | luôn có (xem "Định danh và vòng đời userId") |
| `deviceId` | string | lưu để debug và để đối chiếu nhiều danh tính trên cùng máy |
| `sessionId` | string | uuid do client sinh |
| `name` | string | tên event, đúng chuỗi đã bắn lên Firebase |
| `kind` | `'event' \| 'screen'` | screen đến từ `trackScreenView` |
| `params` | Mixed | nguyên vẹn, không cắt như GA4 |
| `clientTs` | Date | trục sắp timeline |
| `serverTs` | Date | trục TTL |
| `appEnv` | string | dev / stg / prod |
| `appVersion`, `platform` | string | |

Index:
- `{ userId: 1, clientTs: -1 }` — truy vấn chính của admin
- `{ userId: 1, sessionId: 1, clientTs: 1 }` — đọc event trong một session
- `{ serverTs: 1 }` với `expireAfterSeconds: 7776000` (90 ngày)

Không index `deviceId`: chưa có màn hình nào tra theo máy. Thêm khi cần.

Schema extends `AbstractSchema` của `src/base/database/mongodb/`, repository extends
`AbstractRepository` — repository là tầng duy nhất chạm DB, service không được
`InjectModel`.

### Ingest — `POST /api/v1/analytics/events`

Auth: `AuthGuard` bình thường (app luôn có token nhờ `loginAnonymous`). `userId`
lấy từ token, **không** nhận từ body.

```jsonc
{
  "deviceId": "abc123",
  "appEnv": "dev",
  "appVersion": "1.12.0",
  "platform": "ios",
  "events": [
    {
      "name": "keypoint_start",
      "kind": "event",
      "sessionId": "9f2c…",
      "clientTs": 1780000000000,
      "params": { "course_id": "…", "course_name": "…", "keypoint_name": "…" }
    }
  ]
}
```

Giới hạn: tối đa 200 event mỗi request; `params` serialize quá 8KB thì cắt bớt
key lớn nhất và thêm `params._truncated = true` — giữ event, không bỏ.

Trả `{ accepted: <number> }`. Không trả lỗi nghiệp vụ nào ngoài 400 (DTO sai) và
401 — client không có nhánh xử lý nào khác.

Vì `userId` suy ra từ token của **request**, client bắt buộc phải flush queue
**trước** khi userId đổi (xem luật ở mục dưới), nếu không event của user cũ sẽ bị
gán cho user mới.

### Đọc (admin, role admin)

- `GET /api/v1/analytics/users/:userId/summary?from&to&appEnv&funnelPrefix`
  → `{ activeDays, sessions, totalDurationMs, avgSessionMs, totalEvents, lastActiveAt, platforms[], appVersions[], funnelFirstSeen: [{ name, at }], topScreens: [{ name, count }], topEvents: [{ name, count }] }`
  `funnelFirstSeen` là lần đầu mỗi event khớp `funnelPrefix` (mặc định `obd_`) xuất
  hiện. API **không** biết thứ tự các bước — thứ tự nằm ở admin, vì nó đổi mỗi lần
  onboarding đổi và không đáng một lần deploy api.
- `GET /api/v1/analytics/users/:userId/sessions?from&to&appEnv&limit`
  → `{ items: [{ sessionId, startAt, endAt, durationMs, eventCount, firstScreen, lastScreen, appEnv, appVersion, platform }], truncated }`
  Không cursor: một khoảng 90 ngày nhiều nhất vài trăm session, `limit` (mặc định
  100, tối đa 200) chặn phần còn lại và `truncated` nói cho admin biết để thu hẹp
  khoảng ngày — thay vì im lặng cắt bớt.
- `GET /api/v1/analytics/users/:userId/events?sessionId&namePrefix&kind&cursor&limit`
  → `{ items: [{ name, kind, clientTs, params }], nextCursor }`
  `sessionId` **bắt buộc** — endpoint này luôn đọc trong phạm vi một session.

Cursor là `clientTs` của phần tử cuối (keyset), không dùng `skip`.

Bộ lọc theo nhóm event và theo tên chỉ áp ở endpoint `events`, tức **lọc trong
session đang mở** — không dùng để lọc danh sách session. Map "nhóm → prefix tên
event" nằm ở admin (`analyticsGroups.ts`), API chỉ nhận `namePrefix` thô, nên thêm
nhóm mới không phải deploy api.

## Định danh và vòng đời userId

Mục tiêu: timeline của một user bắt đầu từ **lần mở app đầu tiên**, thấy được cả
phần onboarding của lúc còn là khách. Đạt được mà không cần cơ chế merge nào, nhờ ba
luật sau:

1. **Event bắn trước khi có token vẫn giữ trong queue.** Lần mở app đầu tiên bắn
   `splash_scr_view`… trước khi `loginAnonymous` xong; chúng nằm trong queue và đi
   cùng batch đầu tiên sau khi có token, nên được gắn đúng userId của guest vừa tạo
   — cùng một người. Nếu app bị kill trước đó, queue đã persist trên disk và lần mở
   sau `loginAnonymous` trả lại đúng guest cũ trên cùng máy.
2. **Flush trước khi userId đổi.** `setUserId(newId)` và `resetUser()` đều flush
   queue bằng token đang hiệu lực **trước** khi đổi, rồi mới xoá `sessionId`. Đây là
   luật giữ cho event không bị gán sai chủ khi logout rồi đăng nhập account khác.
3. **Nâng cấp guest là in-place** — cùng `_id`, chỉ `anonymous: false`. Không phải
   làm gì: timeline chạy liền mạch qua mốc đăng ký.

Đăng nhập vào một account cũ **khác** trên máy đang có guest → hai `_id` khác nhau
và **không** trộn. Event của guest vẫn xem được ở trang của guest user đó. Đây là
chủ ý — máy dùng chung không được lẫn danh tính.

## Thay đổi theo repo

### hddhistory-flutter

- `lib/config/services/tracking/backend_tracking_service.dart` — mới.
  `BackendTrackingService extends BaseTrackingService`, override `trackEvent`,
  `trackScreenView`, `setUserId`, `resetUser`. Giữ queue trong RAM + mirror ra
  `ILocalStoreService` (key mới trong `local_store_key.dart`).
  - Flush khi: queue đủ 20 event, hoặc timer 15s, hoặc `AppLifecycleState.paused`,
    hoặc trước logout (`resetUser`).
  - `sessionId`: uuid mới khi app foreground sau >30 phút ở background (cùng quy
    ước session của GA4).
  - `setUserId` và `resetUser` → **flush trước rồi mới đổi/xoá**, để không gán event
    của user cũ cho user mới (luật 2 ở mục Định danh).
  - Mọi thứ fire-and-forget, `try/catch` im lặng + `unawaited`, đúng pattern các
    `*Tracking` helper hiện có. Lỗi tracking không bao giờ nổi lên UI.
- `lib/config/di/tracking_di.dart` — `DIKey.trackingService` đổi thành
  `Composite([firebaseAnalyticsService, backendTrackingService])`; thêm
  `DIKey.backendTrackingService`. Sentry giữ nguyên ngoài composite (hiện cũng
  không nhận event, không đổi hành vi).
- `lib/config/services/tracking/app_tracking_service.dart` — constructor inject
  `@Named(DIKey.trackingService)` thay cho `firebaseAnalyticsService`. Đây là **một
  dòng** và là toàn bộ chỗ nối; không call site nào phải sửa.
- Gửi bằng `Dio` (`DIKey.appDio`) ngay trong service, **không** tạo feature Clean
  Architecture riêng: `services.dart` không có `part '*.g.dart'` nên Retrofit không
  sinh được ở đó, và dựng cả barrel + freezed + usecase cho một lời gọi POST là
  thừa. Dio không lọt ra ngoài tầng hạ tầng — cùng cách `FirebaseAnalyticsService`
  dùng SDK Firebase trực tiếp. Thêm `analyticsEvents` vào `endpoint.dart`.
- **Không POST khi `AppGlobalValue.accessToken` rỗng.** `AppInterceptor` biến 401
  thành clear-session + toast "hết phiên" + nhảy về Welcome; một request tracking
  chạy nền không được phép làm điều đó. Event bắn trước khi có token nằm chờ trong
  queue (luật 1 ở mục Định danh).
- `CompositeTrackingService.trackEvent`/`trackScreenView` **bỏ lời gọi `super`**:
  `BaseTrackingService` mirror vào Event Inspector (DEV) và các service con đã làm
  việc đó rồi — gọi thêm sẽ hiện mỗi event hai lần.
- Chạy `dart run build_runner build --delete-conflicting-outputs` sau khi sửa DI,
  rồi `dart run slang` (build_runner xoá `l10n.g.dart`; lỗi "Asset already exists"
  ở file đó là noise đã biết).

### hddhistory-api

Module mới `src/modules/analytics/`:

```
analytics.module.ts
analytics.controller.ts        ingest + 3 route đọc
analytics.service.ts           batch validate, cắt params, tính summary/session
repository/user-event.repository.ts
schema/user-event.schema.ts
dto/ingest-events.dto.ts, get-user-events.dto.ts, get-user-sessions.dto.ts
interface/user-event.interface.ts
```

- `summary` và `sessions` chạy bằng aggregation pipeline trong repository
  (`$match` theo `userId` + khoảng ngày → `$facet` cho totals/activeDays/sessions/
  topScreens/topEvents/funnelFirstSeen). Service chỉ ghép và kiểm quyền.
- **Chặn quyền đọc bằng role ADMIN, kiểm trong service.** `RoleGuard` có sẵn nhưng
  không controller nào dùng nó, và JWT payload (`id`, `deviceId`, `email`, `name`,
  `anonymous`) **không mang `role`** — nên guard đó sẽ chặn tất cả. Service đọc
  `role` từ user document qua `UserRepository` (một DB hit mỗi request đọc; admin
  gọi rất thưa). Không nhân bản lỗ hổng của các endpoint admin hiện có, vốn chỉ có
  `AuthGuard` và cho bất kỳ user app nào đọc dữ liệu người khác.
- Route ingest chỉ cần `AuthGuard`.
- Đăng ký module trong `app.module.ts`. Không cần migration (Mongo, additive).

### hddhistory-admin

- `src/services/analyticsService.ts` — 3 hàm gọi qua `axiosClient`, theo pattern
  `userProgressService.ts`. Không thêm Redux slice; state ở component như mọi trang
  khác.
- `src/types/interface/analytics.interface.ts` và `src/config/analyticsGroups.ts`
  (map nhóm → prefix tên event).
- `src/pages/user-progress/UserProgressSummaryList.tsx` — thêm hai tab ở đầu trang:
  **Tiến độ** (toàn bộ nội dung hiện tại, không đổi) và **Hành vi**. Tab Hành vi
  chỉ gọi API khi được mở lần đầu.
- `src/pages/user-progress/behavior/` — component mới cho tab:
  - Bộ lọc (nằm trong `UserBehaviorTab`) — khoảng thời gian (7/30/90 ngày, tuỳ
    chọn) và `appEnv` áp cho cả tab; dropdown nhóm event chỉ là **preset điền
    nhanh** cho ô "tên event bắt đầu bằng", và cả hai chỉ lọc event bên trong
    session đang mở (nhãn ghi rõ để không ai tưởng nó lọc cả tab). Một control
    thay vì hai đường lọc chồng nhau.
  - `BehaviorMetrics` — 6 ô: ngày active · session · tổng thời lượng · TB/session ·
    tổng event · hoạt động cuối (kèm platform + app version).
  - `OnboardingFunnel` — các bước theo thứ tự, tick bước đã qua, đánh dấu bước dừng.
  - `BehaviorDistribution` — hai bảng top 10 screen / top 10 event.
  - `SessionTimeline` — danh sách session thu gọn (`giờ bắt đầu–kết thúc · thời
    lượng · số event · screen đầu tiên`), mở ra để xem event trong session:
    `hh:mm:ss` · badge kind · tên event · tóm tắt param quan trọng
    (`course_name`/`lesson_name`/`keypoint_name` nếu có) · bấm tiếp xem full JSON.
    Event có `course_id`/`lesson_id` link sang trang course/lesson trong admin.
    "Tải thêm" theo cursor, 50 bản ghi mỗi lần.
- `src/config/analyticsFunnel.ts` — thứ tự 17 bước onboarding (lấy từ nhóm
  `onboardV2P1..P9` trong `tracking_key.dart`), preset prefix nhóm event, danh sách
  `appEnv` và preset khoảng ngày. **Đổi luồng onboarding thì phải sửa file này**,
  nó không tự suy ra được từ dữ liệu.

Lý do timeline theo session chứ không phải một dòng chảy event phẳng: một user học
vài ngày là hàng nghìn event — tải phẳng vừa chậm vừa không đọc nổi, còn session là
đúng đơn vị "một lần dùng app".

## Xử lý lỗi

- **App**: ingest fail → batch được trả lại **đầu** queue (giữ thứ tự) và persist ra
  disk, thử lại ở lần flush sau; queue cắt trần 2000 event (vượt thì bỏ event **cũ
  nhất**, để hành vi gần đây luôn tới). Không log ồn, không toast, không throw.
  Khi userId đổi mà flush không gửi được, phần còn lại **bị xoá** — thà mất vài
  event cuối phiên hơn là gán chúng cho người khác.
- **API**: batch >200 event hoặc DTO sai → 400. Một event trong batch hỏng (thiếu
  `name`/`clientTs`) → bỏ riêng event đó, vẫn nhận phần còn lại và trả `accepted`
  nhỏ hơn số gửi. `insertMany({ ordered: false })` lỗi một phần cũng trả số đã lưu
  thay vì 500 — nếu không app sẽ retry batch đã nằm trong DB.
- **Admin**: mỗi khối trong tab có state riêng — summary lỗi không làm timeline
  trắng. Empty state ghi rõ *"Chưa có dữ liệu hành vi — sink event chỉ có dữ liệu từ
  bản build có tracking backend trở đi"*, vì không backfill được và người xem rất
  dễ tưởng hệ thống lỗi.

## Kiểm chứng

- `npx tsc --noEmit` trong `hddhistory-api` và `hddhistory-admin`.
- `flutter analyze lib/` trong `hddhistory-flutter`.
- Chạy dev build trên simulator: bấm qua vài screen (home → roadmap → keypoint),
  kill app rồi mở lại (kiểm tra queue persist), bật máy bay rồi bấm tiếp (kiểm tra
  retry). Sau đó mở tab Hành vi của đúng user đó trong admin dev và đối chiếu với
  Event Inspector trong app — hai bên phải khớp tên event và thứ tự.
- Không chạy `npm test` / `flutter test` trên máy này (hết RAM).

## Ngoài phạm vi

- Dashboard tổng hợp nhiều user (funnel/retention/cohort) — trang riêng, việc khác.
- Bật GA4 → BigQuery export. Nếu sau này cần phân tích lịch sử dài hạn thì bật, và
  nên bật sớm vì không backfill; nhưng nó không thay thế sink này.
- Sửa việc `deviceId` trên Android đổi sau khi cài lại app.
- Đưa `SentryTrackingService` vào luồng event.
