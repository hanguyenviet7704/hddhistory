# Promo campaign settings — banner/popup nâng cấp + hệ thống Segment

Ngày: 2026-08-14 · Trạng thái: Phase 1 ĐÃ push (api b017a6d, admin 8dc5bd3,
flutter ce65a5ba). Phase 2–3 code cùng ngày ("có code hết đi"): segment module
v1 với 10 tiêu chí có dữ liệu; gender/user_level/user_study_sources vẫn ngoài
v1 vì chưa thu thập.
Spec gốc: 2 ảnh "Popup settings / Banner settings" + "Segment settings" (user
gửi 2026-08-14). User đã chốt: **bỏ Vị trí treo** (giữ nguyên slot Home),
**bỏ Trigger + Frequency** của popup.

## Phase 1 — Banner & Popup thành campaign đúng nghĩa (KHÔNG cần Segment)

Hiện trạng: banner = singleton config + mảng `slides` (image/link/countries/
enabled); popup = singleton, ĐÚNG MỘT popup (image/link/countries/enabled),
click retire per-user qua `home_popup_clicks` keyed `campaignKey`
(= sha1(image|link) cắt 16 hex — xem home-popup.util.ts).

Thêm cho MỖI slide banner và MỖI popup:

| Field spec | Cài đặt |
|---|---|
| Name | `name: string` — nhãn quản trị, không hiển thị trong app |
| Language | `locales: string[]` allow-list (`vi`, `en`, …). RỖNG = mọi ngôn ngữ. Lọc server-side theo header `lang` app đã gửi sẵn — cùng cơ chế `countries`. KHÔNG làm map dịch per-locale: copy vẫn nướng vào ảnh, mỗi ngôn ngữ là một slide/popup riêng |
| Segment | Phase 2 (`segmentIds`), tạm thời `countries` + `locales` là targeting |
| Start/End Date | `startAt`/`endAt: Date \| null` — lọc theo giờ server lúc đọc |
| Trạng thái | đã có (`enabled` per-item + kill switch doc-level) |
| Thứ tự treo (banner) | đã có = vị trí trong mảng slides |
| Mức độ ưu tiên | `priority: number` (cao hơn hiện trước; hoà thì giữ thứ tự mảng). Popup: sort priority → chọn popup ĐẦU TIÊN user chưa click — app vẫn nhận đúng 1 popup, contract không đổi |
| Statistics | xem dưới |

**Popup đa campaign**: thêm `popups: HomePopupItem[]` vào document singleton
(pattern y hệt `slides` của banner — save-as-unit, không cần collection mới).
Doc cũ (field phẳng) resolve thành item 1 — cùng thủ thuật
`resolveConfiguredSlides`, không cần migration. Field phẳng vẫn được mirror
từ item được chọn cho app build cũ.

**Statistics (Impressions / Clicks / CTR)**:
- Identity = `campaignKey` (hash nội dung) cho CẢ banner slide lẫn popup —
  không thêm id mới, đổi ảnh/link = campaign mới, đúng ngữ nghĩa hệ click
  hiện có.
- Module mới `promo-stats`: collection `home_promo_stats`
  `{kind: 'banner'|'popup', campaignKey, date 'YYYY-MM-DD' (UTC), impressions,
  clicks}`, unique index (kind, campaignKey, date), ghi bằng `$inc` upsert —
  cố tình TÁCH khỏi config doc vì config save wholesale sẽ nuốt counter.
- Endpoint mới (public như GET, fire-and-forget từ app):
  `POST /home-banner/impression|click {campaignKey}`,
  `POST /home-popup/impression {campaignKey}`. Popup click giữ nguyên
  `POST /home-popup/click` (retire per-user) và $inc thêm counter.
- Admin: `GET .../config` đính kèm `stats` per campaignKey
  `{impressions, clicks, ctr}`. Popup clicks đọc từ counter (đồng nhất);
  số "unique tappers" = count `home_popup_clicks` nếu cần sau.
- Impression đếm thô mỗi lần hiển thị (không dedupe device) — đủ cho CTR.

Flutter: model thêm `campaignKey`; bắn impression khi slide/popup hiện
(1 lần/phiên/campaign), click khi tap. Popup click đã có sẵn markClicked.

## Phase 2 — Segment (chờ duyệt design này)

Module `segment` (Mongo, collection `segments`): `name` + object `criteria`,
mọi tiêu chí optional, AND với nhau; tiêu chí rỗng = không lọc.

Đối chiếu spec ↔ dữ liệu ĐÃ CÓ trên `users` (user.schema.ts):

| Tiêu chí spec | Nguồn dữ liệu | Khả thi |
|---|---|---|
| First Session | `createdAt` | ✅ |
| Last Session | `lastAction.time` / `updatedAt` | ✅ |
| Language | `language` | ✅ |
| Country | `country` | ✅ |
| Device Type | `devices[].pushPlatform` ('ios'/'android') | ✅ |
| Lifecycle Stage D0–D30 | tính từ `createdAt` (số ngày từ first session) | ✅ derived |
| user_id | `_id` allow-list | ✅ |
| user_goal | `onboarding.learningGoal` (id câu trả lời onboard_v2) | ✅ |
| user_topic_follow | `onboarding.categoryWantToMaster` (map "chủ đề") | ✅ |
| user_type | `anonymous` (guest) + premium từ MySQL `subscriptions` (is_pro_lifetime/is_pro_subscription/is_free_logged_in/is_free_guest) | ✅ cross-DB |
| **Gender** | field `gender` CÓ trong schema nhưng **chưa nơi nào thu thập** (onboarding không hỏi, profile edit không có) | ⚠️ để ngoài v1 |
| **user_level** (beginner→advanced) | **không tồn tại** — onboarding không hỏi level | ⚠️ cần thêm câu hỏi onboarding hoặc suy từ progress |
| **user_study_sources** | **không thu thập** | ⚠️ để ngoài v1 |

Đánh giá membership: theo 2 đường —
1. **Per-user lúc serve banner/popup**: user hiện tại + premium status (đã có
   trong request context) match criteria trực tiếp → rẻ, không cần materialize.
2. **Đếm cả segment (stats/admin)**: aggregation trên `users`; riêng user_type
   pro cần set userId premium từ MySQL (query subscriptions active) —
   chấp nhận chậm, chỉ chạy trong admin.

Banner slide / popup item thêm `segmentIds: string[]` (RỖNG = mọi người,
match BẤT KỲ segment nào trong list).

## Phase 3 — Segment statistics

- Số user hiện tại: aggregation on-demand (nút refresh, không auto).
- Biểu đồ tăng trưởng theo thời gian: cron 1 lần/ngày snapshot count mỗi
  segment vào `segment_stats` (không backfill được quá khứ — chart bắt đầu
  từ ngày tạo segment).
- Venn overlap: on-demand đếm |A∩B| cho các cặp segment được chọn trong admin
  (chỉ vẽ pairwise, không vẽ n-way).

## Ngoài phạm vi (user đã bỏ)
- Vị trí treo (banner/popup vẫn chỉ ở Home).
- Trigger + Frequency của popup (giữ logic hiện tại: hiện khi vào Home,
  click thì thôi).
