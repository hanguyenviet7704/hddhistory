# Popup khuyến mãi trên Home, ngừng hiện sau khi user đã click

Ngày: 2026-08-11 · Stack: `hddhistory-api` + `hddhistory-admin` + `hddhistory-flutter`

## Quyết định sản phẩm (chốt 2026-08-11)

| Câu hỏi | Chốt |
|---|---|
| Điều kiện dừng | **Click vào ảnh** → không hiện lại nữa. **Đóng (X / bấm ra ngoài)** → lần mở app sau vẫn hiện (đóng = "để sau"). |
| Tần suất | Tối đa **1 lần mỗi lần mở app**. Latch in-memory, không lưu — "phiên" = một lần mở app. |
| Cờ "đã click" lưu ở đâu | **Server, theo user.** Sống qua cài lại app và đồng bộ nhiều thiết bị. |
| Nội dung | **Một ảnh + link.** Bấm vào ảnh chính là click. App tự vẽ nút X. Không có ô nhập text — text sẽ cần đủ 5 locale app đang ship. |
| Nhắm thị trường | Dùng lại đúng luật của banner (IP / region máy / ngôn ngữ app). |

## Trục xoay của thiết kế: `campaignKey` là hash của NỘI DUNG

`campaignKeyFor(imageUrl, linkUrl)` = 16 hex đầu của sha1. Không lưu trong config,
tính lúc đọc. Mọi hành vi theo thời gian của popup rơi ra từ đúng lựa chọn này:

- Đổi ảnh **hoặc** link → key đổi → người đã click chiến dịch cũ **thấy** chiến
  dịch mới. Admin không phải nhớ bấm gì — đó là chỗ chết của mọi field "campaign
  id" nhập tay: quên một lần là chiến dịch mới không bao giờ tới đúng nhóm người
  dễ convert nhất.
- Quay lại dùng ảnh + link cũ → key cũ trở lại → người đã click **đúng** offer đó
  không bị hỏi lại. Một biến `version` tăng dần không diễn tả được điều này.
- Bật/tắt hay sửa danh sách thị trường **không** đổi key: chúng không đổi thứ đang
  được offer.

Không có ảnh = không có key = không có chiến dịch để định danh.

## Đơn vị

**hddhistory-api — module `home-popup`** (sibling của `home-banner`, cùng khuôn)
- `home_popup_configs` singleton `{enabled, imageUrl, linkUrl, countries[]}`.
- `home_popup_clicks {userId, campaignKey}` + unique index — **collection riêng**,
  không nhét mảng vào `users`: `users` bị đọc/ghi ở gần như mọi feature, và một ảnh
  quảng cáo không phải lý do để nới blast radius đó. Đọc = một `exists` có index.
- `GET /home-popup` — **cần auth** (khác banner vốn `@Public`): câu trả lời phụ
  thuộc người hỏi. Trả `visible` đã tính đủ 4 điều kiện (kill switch, có ảnh, khớp
  thị trường, chưa click) nên app không tự suy gì.
- `POST /home-popup/click {campaignKey}` — idempotent qua upsert. Nhận key **từ
  client** chứ không tự tính lại: user click cái họ ĐANG thấy, không phải cái admin
  vừa publish mấy giây trước. Vì thế key bị chặn theo shape (`^[0-9a-f]{16}$`).
- `GET /home-popup/config` + `PUT /home-popup` cho admin.

**Dọn nợ có mục đích:** `resolveViewerMarkets` / `isVisibleInMarkets` /
`normalizeCountryCodes` chuyển từ `home-banner` sang `src/utils/viewer-market.util.ts`
theo đúng luật repo tự đặt ("chỉ move vào utils khi đã thật sự dùng chung"). Đổi tên
`isBannerVisibleInMarkets` → `isVisibleInMarkets` vì giờ không riêng banner.

**hddhistory-flutter** — entity/model/usecase trong `lib/src/home`; `HomePromoPopupHost`
bọc Home, gọi usecase sau frame đầu, latch static in-memory. Bấm ảnh → bắn POST
(không await) → pop → mở link.

`HomePopupEntityX.isVisible` **chặt hơn** banner: banner fallback về `enabled` khi
`visible` null (API cũ), popup thì không. Một modal chen ngang trên API chưa có
endpoint click sẽ không bao giờ retire được — im lặng nghĩa là đừng hiện.

**hddhistory-admin** — trang "Popup Home" cạnh "Banner Home": công tắc, upload ảnh (folder
`home-popup`), link, ô thị trường. Hiện `campaignKey` hiện hành và **cảnh báo trước
khi Lưu** nếu ảnh/link đã đổi ("lưu là bắt đầu chiến dịch mới").

## Verify

- api: `tsc` 0 lỗi trong `src/` · `home-popup.util.spec.ts` (10) +
  `viewer-market.util.spec.ts` + `home-banner.util.spec.ts` = 34 test pass.
- flutter: `analyze` 0 lỗi · `home_popup_entity_test.dart` + banner = 16 test pass.
- admin: `tsc` 0 lỗi.
- Sau deploy: bật popup trong admin → mở app thấy popup → bấm vào ảnh → mở lại app
  **không** thấy nữa; đóng bằng X thì mở lại app **vẫn** thấy; đổi ảnh trong admin
  thì thấy lại.
