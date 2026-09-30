# Carousel banner Home + upload nhiều slide trên admin

Ngày: 2026-08-11 · Stack: `hddhistory-api` + `hddhistory-admin` + `hddhistory-flutter`

## Vấn đề

Khu banner trên Home chỉ chứa **một** ảnh (`imageUrl` + `linkUrl` + `countries`),
nên mỗi lần chạy nhiều chiến dịch song song phải chọn một cái để hiện. Muốn một
carousel nhiều slide, và admin upload được ảnh cho từng slide.

## Quyết định sản phẩm (chốt 2026-08-11)

| Câu hỏi | Chốt |
|---|---|
| Mỗi slide có gì riêng | **Ảnh + link + danh sách thị trường riêng.** Server lọc theo người xem trước khi trả về, nên dots đếm đúng số slide họ thật sự thấy và một config phục vụ mọi thị trường. |
| Carousel chạy thế nào | **Tự chạy 5s, vòng lặp, có dots.** Người dùng chạm thì dừng tự chạy. **Một slide = không dots, không timer** — y hệt banner hiện tại. |
| Bật/tắt | **Công tắc riêng mỗi slide + công tắc tổng** (kill switch cả khu). Không có lịch chạy theo ngày. |
| Số slide tối đa | 10 |

## Ràng buộc không thương lượng: app 1.5.0 đang chạy production đọc `imageUrl`

Response **phải** tiếp tục có `imageUrl`/`linkUrl`. Chúng thành **mirror của slide
đầu tiên mà CHÍNH người xem đó thấy** — nên app cũ vẫn có banner và vẫn đúng thị
trường. Chiều ngược lại (app mới, API chưa deploy): `slides` rỗng nhưng `imageUrl`
có giá trị → coi như một slide duy nhất. Không cần migration DB, không mất banner
đang cấu hình.

## Hai đường đọc — chỗ dễ vỡ nhất

- `GET /home-banner` (app, `@Public`): `slides` **đã lọc** theo thị trường người xem.
- `GET /home-banner/config` (admin, cần auth): config **raw**.

Nếu admin dùng chung đường đã lọc thì mở admin từ VN sẽ **không thấy** slide chỉ
nhắm JP — và sẽ tưởng nó bị mất.

## Đơn vị

**hddhistory-api**
- `schema/home-banner-config.schema.ts`: thêm subdocument `HomeBannerSlide`
  `{ imageUrl, linkUrl, countries[], enabled }` và `slides: HomeBannerSlide[]`.
  Giữ `imageUrl`/`linkUrl`/`countries` cũ ở mức document làm seed cho fallback.
- `home-banner.util.ts`: `resolveConfiguredSlides(config)` (một chỗ duy nhất chứa
  luật fallback "chưa có slides thì banner cũ là slide 1") + `visibleSlidesFor(slides,
  markets)` (bỏ slide tắt, bỏ slide chưa có ảnh, lọc thị trường bằng
  `isBannerVisibleInMarkets` đã có).
- `dto`: `slides?` với `@ValidateNested`, `@ArrayMaxSize(10)`; `countries` mỗi slide
  chuẩn hoá bằng `normalizeCountryCodes` khi ghi.
- `service`: `getConfigFor` trả `slides` đã lọc + mirror slide đầu; `getRawConfig`
  cho admin.

**hddhistory-admin** — `HomeBannerPage`: danh sách card slide (preview 390×78, TẢI ẢNH LÊN
dùng lại `cloudflareService` folder `home-banner`, URL ảnh, link, ô thị trường, công
tắc, xoá), kéo thả đổi thứ tự bằng dnd-kit, nút Thêm slide (tối đa 10). Đọc từ
`/home-banner/config`.

**hddhistory-flutter** — `HomeBannerEntity.slides` + `effectiveSlides` (fallback về
`imageUrl` khi `slides` rỗng); `HomeBannerCard` thành `PageView` + dots + timer 5s,
giữ nguyên `78.h` / bo `18.r` / `launchURL()`.

## Verify

- api: `tsc --noEmit` + `home-banner.util.spec.ts` (mở rộng bộ 15 test sẵn có).
- flutter: `flutter analyze` + widget test (đếm dots, một slide không dots, fallback).
- admin: `npx tsc --noEmit`.
- Sau deploy: `curl -H "lang: vi" .../home-banner` phải thấy slide VN; đổi `lang: ja`
  thấy slide JP.
