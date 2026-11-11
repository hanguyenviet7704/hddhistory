# Khoá theo lượt user: 1 keypoint miễn phí mỗi ngày

Ngày: 2026-08-12 · Sửa luật 2026-08-21 · Stack: `hddhistory-api` + `hddhistory-flutter` + `hddhistory-admin`

## Sửa luật (chốt 2026-08-21): vé tính khi HỌC HẾT, không phải khi vượt thẻ khoá

Vé của ngày bị tiêu khi user **hoàn thành** một keypoint, tức đúng lúc app gọi
`PUT /courses-user-progress/keypoints` với `passed: true`. Hệ quả:

| | Trước 2026-08-21 | Từ 2026-08-21 |
|---|---|---|
| Cái gì tiêu vé | vượt qua thẻ khoá | **hoàn thành keypoint** |
| Khi còn vé | vẫn cap ở thẻ khoá cho tới lúc claim | **mở trọn vẹn mọi keypoint**, không cap |
| Đọc dở rồi thoát | mất vé nếu đã vượt thẻ khoá | **không mất gì** |
| Hết vé | khoá từ thẻ `afterCards` | y như cũ |
| Ôn bài đã hoàn thành | miễn phí | y như cũ |

**Đánh đổi đã nói trước khi làm, chủ sản phẩm chốt vẫn làm:** ai không bấm hoàn
thành thì đọc bao nhiêu keypoint cũng được — tường chỉ dựng lên sau keypoint hoàn
thành đầu tiên trong ngày. Đây là lựa chọn "chỉ thu tiền khi user thật sự nhận
được giá trị", không phải sơ suất.

Chỗ ghi vé: `UserProgressService.spendDailyQuotaOnCompletions` →
`KeypointQuotaLedgerService.recordCompletion`. Sổ ghi (`keypoint_daily_claims`) từ
nay là **danh sách keypoint đã hoàn thành trong ngày**; giới hạn `freeKeypointsPerDay`
được áp lúc ĐỌC sổ, không phải lúc ghi — một keypoint đã học xong là sự thật, từ
chối ghi chỉ làm sổ lệch với tiến độ của chính user.

`POST /keypoint-access/:id/claim` giữ lại nhưng **không tiêu gì**: bản app đã phát
hành vẫn gọi nó khi cú vuốt chạm tường, và câu trả lời bây giờ chỉ là "ngày còn chỗ
hay không". Bản app hiện tại không bao giờ chạm tới nó vì còn vé thì `cardCap: null`.

Module: sổ ghi tách thành `KeypointQuotaLedgerModule` — một **module lá**, không
import module nào khác. `UserProgressModule` phải import được nó, mà
`KeypointAccessModule` thì đã import `UserProgressModule`; nếu để chung một module
thì `PaywallConfigModule → AuthModule → UserProgressModule` khép thành vòng và app
crash-loop lúc boot (tsc lẫn `nest build` đều không thấy).

## Luật gốc (chốt 2026-08-12)

Người **chưa premium** mỗi ngày đọc miễn phí **1 keypoint** trọn vẹn. Mọi keypoint
khác trong ngày đọc được 2 thẻ rồi khoá từ **thẻ 3**. Hôm sau lại có 1 vé mới.

| Câu hỏi | Chốt |
|---|---|
| Cái gì tiêu vé | ~~**Vượt qua thẻ 3** của một keypoint~~ → xem mục sửa luật 2026-08-21 ở trên. Mở keypoint rồi thoát không mất gì. |
| Quan hệ với `inLessonPaywall` | **Thay hẳn.** Rule cũ tắt (vẫn còn trong config để bật lại). |
| "Ngày" theo múi giờ nào | **Ngày của chính user**, từ header `x-timezone-offset` app đã gửi sẵn — đúng cách learning streak bucket. Giờ server sẽ tính sai cho mọi user không ở múi giờ server. |
| Đọc lại bài đã hoàn thành | **Không tiêu vé, mở tự do.** Vé chỉ dành cho nội dung MỚI — không phạt người quay lại ôn bài. |

## Cơ chế: một claim mỗi ngày, do unique index cưỡng chế

```
keypoint_daily_claims { userId, dayKey:'2026-08-12', keypointId, claimedAt }
unique index (userId, dayKey)
```

Claim = upsert `$setOnInsert`. Keypoint ĐẦU TIÊN đòi vượt thẻ 3 trong ngày thắng
**nguyên tử**; keypoint thứ hai thấy hàng đó đã thuộc keypoint khác → từ chối.
Chính cái index là thứ cưỡng chế "1 vé/ngày", nên hai request đồng thời từ hai
thiết bị không thể cùng thắng — thứ mà một chuỗi if-else đọc-rồi-ghi không đảm bảo
được.

## Hai endpoint, theo đúng nhịp người dùng

| Khi nào | Gọi | Trả |
|---|---|---|
| Vào keypoint | `GET /keypoint-access/:keypointId` | `cardCap: null` (mở hết) hoặc `2` (khoá từ thẻ 3) + `reason` + `quota` |
| Cố qua thẻ 3 khi cap=2 | `POST /keypoint-access/:keypointId/claim` | `granted: true` → cap thành null, đọc tiếp; `false` → mở paywall |

`cardCap: null` khi: premium · keypoint này đã là vé hôm nay · keypoint đã hoàn
thành trước đó · rule tắt trong config.

## Ba đánh đổi, nói rõ để sau này không ai tưởng là bug

1. **Đây là lần đầu khoá này là khoá thật.** Rule cũ tính hoàn toàn trên client
   (`KeypointCardShell._inLessonPaywallCap` đọc config rồi tự suy), nên sửa response
   config là mở hết. Cái mới server cưỡng chế.
2. **Lỗi mạng thì MỞ, không khoá.** `GET /keypoint-access` fail → không cap, theo
   đúng nguyên tắc code hiện tại đã ghi: *"a paywall that cannot be evaluated must
   not be able to lock content away"*. Mạng chập chờn có thể lọt vài lượt đọc; chiều
   ngược lại là khoá nội dung của người đã trả tiền.
3. **Một kẽ không bịt được hoàn toàn:** `dayKey` tính từ offset do client gửi. Ai
   sửa offset qua lại quanh nửa đêm có thể lấy thêm khoảng một vé mỗi ngày thật —
   đúng bằng mức phơi ra mà streak đang chấp nhận. Bịt cứng bằng giờ server thì sai
   với mọi user ngoài múi giờ server, tệ hơn.

## Đơn vị

**hddhistory-api — module `keypoint-access`**
- `schema/keypoint-daily-claim.schema.ts` + unique index (userId, dayKey).
- `keypoint-access.util.ts`: `dayKeyFor(now, offsetMinutes)` +
  `resolveTimezoneOffsetMinutes(header)` — thuần, có spec.
- `keypoint-access.service.ts`: quyết `cardCap` và thực hiện claim. Đọc premium qua
  `SubscriptionService`, "đã hoàn thành" qua `UserProgressRepository.findPassedKeypointIds`
  (đã có sẵn), config qua `paywall_config`.
- Import `AuthModule` (mọi route sau `AuthGuard`), `SubscriptionsModule`,
  `UserProgressModule` — theo đúng khuôn `habit-practice.module.ts`.

**paywall_config** — block mới `dailyKeypointQuota { enabled, freeKeypointsPerDay: 1, afterCards: 3 }`.

Hai chỗ số học này sai ở lần đầu, sửa 2026-08-12 sau khi test trên máy:

- `afterCards: 3` đọc là "khoá **đứng ở** thẻ 3" (1-based, đúng chữ trên admin), nên
  cap = `afterCards - 2` = 1: đọc được thẻ 1 và 2. Bản đầu để `- 1` nên user lướt
  **qua** được đúng cái thẻ đáng lẽ bị khoá. Lưu ý `inLessonPaywall.afterCards` mang
  nghĩa KHÁC — nó **đếm số thẻ được đọc** — hai field giống tên mà khác nghĩa.
- `freeKeypointsPerDay > 1` bản đầu không thể có hiệu lực: mỗi (user, ngày) chỉ có
  **một** hàng claim với **một** `keypointId`, nên đặt 3 trên admin vẫn chỉ được 1.
  Nay hàng-của-ngày giữ `keypointIds: string[]`, cấp vé bằng `$addToSet` dưới một
  chốt kích thước trong filter — không cần đổi index (đổi index thành
  `(userId, dayKey, keypointId)` sẽ để lại index unique cũ trên mọi DB đã deploy và
  vẫn âm thầm chặn ở 1).

**hddhistory-flutter** — `KeypointCardShell` thôi tự tính cap từ config, đọc `cardCap` từ
server; trước khi mở paywall thì thử claim. `KeypointCardCubit.setPaywallCardCap`
giữ nguyên — nó vẫn là điểm cưỡng chế duy nhất cho mọi đường di chuyển deck (swipe,
pip tap, giọng đọc lật trang, quay lại từ nền), nên không phải sửa 4 chỗ.

**hddhistory-admin** — mục "Khoá theo lượt ngày" trong trang Cấu hình paywall.

## Verify

- api: `tsc` + spec cho `dayKeyFor` (đổi ngày theo offset, biên nửa đêm) và cho luật
  claim (vé đã thuộc keypoint khác → từ chối; cùng keypoint → cho tiếp).
- flutter: `analyze` + unit test cho việc map `cardCap` từ response sang cap của deck.
- Sau deploy (luật 2026-08-21): user thường mở keypoint A → đọc trọn vẹn, không gặp
  khoá → **hoàn thành A** → mở keypoint B thấy khoá ở thẻ 3 → quay lại A vẫn đọc
  được → hôm sau B đọc được. Và: mở B, đọc vài thẻ rồi thoát **không** tiêu vé.
