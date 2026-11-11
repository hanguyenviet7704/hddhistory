# Paywall: bộ gói theo entry point + dọn lệch schema

Spans **hddhistory-api**, **hddhistory-admin**, **hddhistory-flutter**. Viết 2026-08-03.

## Yêu cầu

User đi từ roadmap course, học hết một keypoint rồi sang card của keypoint tiếp
theo → mở paywall **chỉ hiển thị gói tháng**. User chủ động bấm từ trang Profile
→ hiển thị **đầy đủ các gói**.

Nói cách khác: cùng một paywall, **danh sách gói thay đổi theo entry point**.

## Trạng thái trước khi làm

- `PaywallEntryPoint` (9 giá trị) đã tồn tại nhưng **chỉ dùng cho tracking** —
  `ResolvePaywallStrategyUsecase` không đọc nó.
- Gate `inLessonPaywall` (`enabled`/`keypointOrdinal`/`afterCards`) đã có và đã
  bắn đúng thời điểm cần, nhưng `keypointOrdinal` **đếm theo bài học**, không
  theo keypoint.
- Config `paywall_config` do MySQL làm source of truth (`paywall_configs`,
  append-only), admin sửa qua `/paywall-config`, app đọc qua
  `GET /api/v1/paywall-config/mobile`.

### Ràng buộc kỹ thuật đã kiểm chứng

| Dữ kiện | Bằng chứng |
| --- | --- |
| App **không có** field kỳ hạn có cấu trúc | `IapProductEntity` không có `period`; `periodLabel` dò substring `'1y'`/`'month'`/… trong `productId` và mọi nhánh trả về "/tháng" |
| ⇒ "chỉ gói tháng" phải là danh sách SKU tường minh | không thể lọc động theo kỳ hạn |
| `resolvedPaywallConfig` là getter **đồng bộ**, prefetch một lần lúc app start | `iap_cubit.dart:76`, `app_service.dart:114` |
| ⇒ không thể resolve variant server-side theo entry point | mỗi lần mở paywall sẽ thành một round-trip, offline không có gì rơi về |
| Schema `paywall_config` đang được khai báo bằng tay ở **4 nơi** | Flutter parser, API DTO, API `validateShape`, admin interface+draft |

## Quyết định thiết kế

1. **Strategy quyết định nội dung + bộ SKU; entry point chỉ chọn variant của bộ
   SKU đó.** Mỗi strategy (`defaultUser`, mỗi `impressionRule`, `saleEvent`)
   khai báo thêm `compactProducts`. Sale event và ưu đãi newUser vì thế vẫn tới
   được user đang học (với gói tháng giảm giá), và copy 5 ngôn ngữ không phải
   viết lại cho từng entry point.
2. **Map `entryPointVariants` nằm trong config, admin sửa được.** Đổi hành vi =
   publish một version mới, không cần release app. Quyết định "entry point nào
   rút gọn" là quyết định thương mại, không nên chôn trong enum của client.
3. **Mặc định khi ship: chỉ `inLesson` là `compact`**, 8 entry point còn lại
   `full` — giữ nguyên hành vi hiện tại ở mọi chỗ đang chạy.
4. **UI khi chỉ có 1 gói: không đổi gì.** Vẫn là `_PaywallInlinePlans` với danh
   sách một phần tử.
5. **Không bump `schemaVersion`.** Không có dòng code nào branch theo nó.
6. **Không giới hạn `compactProducts` đúng 1 phần tử.** "Chỉ gói tháng" là lựa
   chọn vận hành, không phải luật của schema.

## Contract

Ba thay đổi, tất cả optional và tương thích ngược — một config chưa có field mới
chạy **giống hệt hôm nay**.

```jsonc
{
  "schemaVersion": 1,
  "enableLessonLock": true,
  "lessonLock": 3,                       // số nguyên (bug 1)

  "entryPointVariants": {                // MỚI — thiếu key ⇒ "full"
    "inLesson": "compact",
    "courseRoadmap": "full", "autoOpen": "full", "profile": "full",
    "settingPre": "full", "manageSubscription": "full",
    "habit": "full", "theme": "full", "other": "full"
  },

  "inLessonPaywall": { "enabled": true, "keypointOrdinal": 2, "afterCards": 1 },

  "saleStrategy": {
    "defaultUser": {
      "content": { "en": {…}, … },
      "products":        [ {1y}, {3m}, {1m} ],
      "compactProducts": [ {1m} ]        // MỚI, optional
    },
    "newUser": {
      "enabled": true, "windowDays": 7,  // ≥1 bắt buộc khi enabled (bug 3)
      "content": { … },
      "impressionRules": [
        { "fromImpression": 1, "content": {…},
          "products": [ … ], "compactProducts": [ {1m} ] }   // MỚI, optional
      ]
    },
    "saleEvent": {
      "enabled": true, "campaignId": "…",
      "startAtUtc": "…", "endAtUtc": "…",       // bắt buộc khi enabled (bug 4)
      "appliesTo": ["defaultUser", "newUser"],  // enum array (bug 2)
      "content": { … },
      "products": [ … ], "compactProducts": [ {1m} ]         // MỚI, optional
    }
  }
}
```

### Luật quyết định

Thứ tự chọn strategy **không đổi**: `saleEvent` → `newUser` → `defaultUser`.
Sau khi có strategy thắng mới tra variant:

```
variant = entryPointVariants[entryPoint.name] ?? full

nếu variant == compact
  và strategy.compactProducts không rỗng
  và product ids của nó hợp lệ (đủ id cho platform, không trắng, không trùng)
    → dùng compactProducts
ngược lại
    → dùng products   (đường rơi về, không bao giờ để paywall trắng)
```

Rơi về `products` xảy ra ở **cả ba** trường hợp: thiếu field, mảng rỗng, và ids
không hợp lệ. Chỉ khi `products` cũng không hợp lệ thì strategy mới thành
`invalid` — giữ đúng invariant "một SKU thiếu không bao giờ được làm trắng
paywall" của `plans/260727-voucher-paywall-config-affiliate/design.md`.

### Variant phải nằm trong signature

`IapCubit.loadIapProducts` bỏ qua việc fetch lại khi
`state.paywallStrategySignature` không đổi. Nếu variant không vào
`ResolvedPaywallStrategyEntity.signature` thì mở paywall từ Profile (full) rồi
mở từ in-lesson (compact) sẽ **dùng lại danh sách gói cũ**. Vì vậy `signature`
phải gồm cả `variant`.

### Thứ tự set entry point trong luồng autoOpen

`_prepareAutoOpenPaywall` hiện gọi `loadIapProducts()` **trước**
`setPaywallEntryPoint(autoOpen)`, nên lần load đó chạy với entry point cũ. Đảo
lại: set entry point trước khi load, và trả về giá trị cũ nếu prepare thất bại
(để tracking không bị nhiễm một autoOpen chưa từng mở).

## Sáu bug lệch schema sửa kèm

| # | Bug | Sửa ở đâu |
| --- | --- | --- |
| 1 | `lessonLock`: admin coi là JSON blob, API+Flutter là số nguyên. Nhập JSON → 400; để trống → field bị lược → Flutter đọc `0` → khóa toàn bộ course, tap bài đầu không phản ứng (`ignoreTap`) | admin: textarea → input số. API: `validateShape` bắt buộc `lessonLock` khi `enableLessonLock`. Admin cảnh báo khi = 0 (nghĩa là khóa cả khóa học) |
| 2 | `appliesTo`: admin free-text, API `unknown`, Flutter cần `List<'defaultUser'\|'newUser'>`. Nhập `all` → sale event không bao giờ chạy, không lỗi ở đâu | API: `@IsEnum(..., {each:true})` + `validateShape` bắt buộc non-empty khi enabled. Admin: 2 checkbox |
| 3 | `newUser.windowDays` bỏ trống → Flutter `windowDays=0` → luôn `defaultUser` → toàn bộ `impressionRules` chết im lặng | API + admin: bắt buộc ≥1 khi `newUser.enabled` |
| 4 | `saleEvent.enabled` mà thiếu `startAtUtc`/`endAtUtc` → Flutter drop cả object | API + admin: bắt buộc, parse được, `start < end` khi enabled |
| 5 | `sessionRolloutPercent` được `@IsNumber()` cho phép decimal; Flutter yêu cầu `rawPercent is int` → `50.5` tắt autoOpen im lặng | API: `@IsInt()`. Admin: parse int |
| 6 | `keypointOrdinal` đếm theo **bài học** thay vì keypoint | Flutter: `_isPaywallGatedKeypoint` đếm keypoint. Cập nhật doc comment ở cả 3 repo + nhãn admin |

### Cảnh báo di trú cho bug 6

Sửa bug 6 **đổi nghĩa của giá trị đang lưu**. Nếu prod đang bật
`inLessonPaywall` với `keypointOrdinal: 2` hiểu theo nghĩa cũ (bài học thứ 2),
sau khi sửa nó thành keypoint thứ 2 — gate bắn sớm hơn. Phải đọc config đang
live và chốt lại con số khi publish. Không tự đổi giá trị trong code.

### Cảnh báo cho bug 2 với version cũ

`POST /paywall-config/restore/:version` re-validate qua `validateShape` (không
qua DTO pipe). Một version cũ có `appliesTo: "all"` sẽ **bị từ chối** sau thay
đổi này. Đó là hành vi đúng: version đó chưa bao giờ chạy được trên client.

## Thay đổi theo repo

### hddhistory-api

- `dto/paywall-config.dto.ts`
  - `PaywallProductVariant` enum (`full` | `compact`)
  - `PaywallAudienceSegment` enum (`defaultUser` | `newUser`)
  - `PaywallEntryPointVariantsDto`: 9 field optional, mỗi field `@IsEnum(PaywallProductVariant)`
    — class tường minh thay vì `Record<string,string>` để `whitelist: true` lọc
    được key lạ và Swagger tự tả được
  - `compactProducts?: PaywallProductRefDto[]` trên `PaywallDefaultUserDto`,
    `PaywallImpressionRuleDto`, `PaywallSaleEventDto`
  - `appliesTo`: `unknown` → `PaywallAudienceSegment[]`
  - `sessionRolloutPercent`: `@IsNumber()` → `@IsInt()`
  - cập nhật doc comment `keypointOrdinal`
- `paywall-config.service.ts`
  - `validateShape`: thêm luật cho bug 1/2/3/4 và cho `compactProducts` (nếu có
    thì mỗi dòng phải có ≥1 id)
  - `collectProductRefs`: thêm `compactProducts` của defaultUser, từng
    impression rule, và saleEvent (khi enabled) → chịu đúng guard tồn tại +
    active trong `iap_products`
- `paywall-config.service.spec.ts`: ca test cho từng luật mới

Không có migration: `config` là cột `json`.

### hddhistory-admin

- `types/interface/paywall-config.interface.ts`: `lessonLock?: number`,
  `appliesTo?: PaywallAudienceSegment[]`, `compactProducts?` ×3,
  `PaywallProductVariant`, `PaywallEntryPoint`, `entryPointVariants?`
- `pages/paywall-config/paywallConfigDraft.ts`
  - `lessonLockText: string` → `lessonLockCount: string`
  - `saleEvent.appliesTo: string` → `appliesToDefaultUser`/`appliesToNewUser: boolean`
  - `compactProducts: ProductRefDraft[]` trên 3 draft
  - `entryPointVariants: Record<PaywallEntryPoint, PaywallProductVariant>`
  - `toDraft`/`fromDraft`/`validateDraft` cập nhật tương ứng — `validateDraft`
    vẫn mirror `validateShape` field-for-field
- UI: `GeneralSection` (input số + cảnh báo `lessonLock = 0`, sửa nhãn
  keypoint), `DefaultUserSection`/`ImpressionRuleCard`/`SaleEventSection` (thêm
  `ProductRefsEditor` thứ hai cho `compactProducts`), `SaleEventSection`
  (checkbox `appliesTo`), `EntryPointVariantsSection` mới (bảng 9 dòng)

### hddhistory-flutter

- `src/common/domain/entities/paywall_config_entity.dart`
  - `enum PaywallProductVariant { full, compact }`
  - `entryPointVariants: Map<String, PaywallProductVariant>` — key là
    `PaywallEntryPoint.name`, cố ý dùng `String` để `common` không phụ thuộc
    enum của `monetization`
  - `compactProducts` trên `PaywallDefaultUserStrategyEntity`,
    `PaywallImpressionRuleEntity`, `PaywallSaleEventStrategyEntity`
  - parser: value lạ → bỏ qua (⇒ getter trả `full`)
  - extension `variantForEntryPoint(String name)`
- `src/monetization/domain/entities/resolved_paywall_strategy_entity.dart`:
  `variant` + đưa vào `signature`
- `src/monetization/domain/usecases/resolve_paywall_strategy_usecase.dart`:
  `ResolvePaywallStrategyParams.entryPointName`, chọn variant + đường rơi về
- `src/monetization/presentation/cubits/iap_cubit.dart`: truyền entry point vào
  params; đảo thứ tự set entry point trong `_prepareAutoOpenPaywall`
- `src/lesson/presentation/widgets/layouts/keypoint_card_shell.dart`:
  `_isPaywallGatedKeypoint` đếm keypoint

Không có key l10n mới (UI không đổi copy). Cần `build_runner` (freezed +
json_serializable), **không** cần `slang`.

## Xử lý lỗi

| Tình huống | Hành vi |
| --- | --- |
| `entryPointVariants` thiếu / key thiếu / value lạ | entry point đó = `full` |
| `compactProducts` thiếu / rỗng | dùng `products` |
| `compactProducts` có nhưng ids không hợp lệ | dùng `products` |
| `products` cũng không hợp lệ | `invalid('invalid_product_ids')` như hôm nay → paywall hiện lỗi + Retry |
| SKU trong `compactProducts` bị xóa/inactive sau khi publish | admin không cho publish; nếu xảy ra sau đó thì store không trả product → `empty_products` như hôm nay |

## Kiểm chứng

- hddhistory-api: `npx tsc --noEmit`; `npm test -- src/modules/paywall-config/paywall-config.service.spec.ts` (một file, không chạy cả suite)
- hddhistory-admin: `npx tsc --noEmit`
- hddhistory-flutter: `dart run build_runner build --delete-conflicting-outputs`; `flutter analyze`
- Trên simulator: mở paywall từ Profile (đủ gói) rồi từ in-lesson (một gói) trong
  **cùng một session** — đây là ca mà signature phải khác nhau, và cũng là ca duy
  nhất chỉ sim mới phát hiện được.
