# Banner Home — nhắm theo quốc gia

Ngày: 2026-08-10 · Repo: `hddhistory-api` + `hddhistory-admin` + `hddhistory-flutter`
Tiếp nối feature banner Home đã ship 2026-08-08.

## 1. Yêu cầu

Banner Home chỉ hiện ở những quốc gia admin chọn — Việt Nam, hoặc một tập bất kỳ.
Để trống thì hiện ở mọi nơi.

## 2. Quyết định (chốt 2026-08-10)

| Câu hỏi | Chốt |
|---|---|
| Nguồn tín hiệu | `cf-ipcountry` (Cloudflare, theo IP thật) |
| Dự phòng | Vùng thiết bị do app gửi lên, khi header vắng mặt |
| Không xác định được quốc gia | **Ẩn**, nếu banner đang nhắm mục tiêu |
| Kiểu danh sách | Chỉ danh sách cho phép. Rỗng = mọi quốc gia |
| Ai quyết định hiện/ẩn | Server |
| Cache | `private` thay cho `public` |

## 3. Vì sao IP chứ không phải locale

Theo IP là *đang ở đâu*; theo locale là *máy cài theo nước nào*. Một người Việt sang
Nhật chơi: theo IP thì thôi thấy banner Việt Nam, theo locale thì vẫn thấy.

Banner khuyến mãi gắn với thị trường — giá, thanh toán, quy định — nên vị trí đúng
hơn ngôn ngữ. Và `cf-ipcountry` gần như miễn phí: module `download-link` đã đọc nó
(`download-link-redirect.controller.ts`), không thêm thư viện hay dịch vụ nào.

## 4. Rỗng nghĩa là mọi nơi

Bản ghi đang chạy không có trường `countries`; đọc lên thành `[]`, banner tiếp tục
hiện y như trước. **An toàn theo cấu tạo, không cần migration** và không có khoảnh
khắc banner biến mất vì dữ liệu cũ chưa kịp điền.

## 5. Không xác định được thì ẩn

Cloudflare trả `XX` cho IP không rõ và `T1` cho Tor; cả hai tính là không xác định,
cùng với trường hợp header vắng mặt và app không gửi vùng thiết bị.

Khi danh sách rỗng thì câu hỏi không đặt ra — hiện. Khi danh sách có nội dung, admin
đã nói rõ "chỉ những nước này", nên hiện cho một người mà ta không biết ở đâu là làm
trái chỉ thị đó. Giá phải trả: chạy local không qua Cloudflare sẽ không thấy banner
có nhắm mục tiêu. Chấp nhận được — để trống danh sách là thấy ngay.

## 6. Cache: `public` phải đổi thành `private`

Endpoint là `@Public()` kèm `Cache-Control: public, max-age=60`. Phản hồi khác nhau
theo quốc gia cộng cache dùng chung — chính Cloudflare ở phía trước — là công thức
để một người ở Nhật nhận bản đã cache của người ở Việt Nam. Hỏng im lặng: không lỗi,
không log, chỉ lộ khi có người ở nước ngoài kêu.

Đổi sang `private, max-age=60`: máy người dùng vẫn cache, cache dùng chung thì không.

**Bỏ ý memo trong tiến trình** (sửa khi triển khai). Thiết kế ban đầu định bù phần
cache mất đi bằng memo 60 giây, nhưng `HomeBannerService` inject `RequestService`
nên nó *đã* là request-scoped — memo đặt ở đó sẽ là memo mỗi request, tức không memo
gì cả. Gỡ ràng buộc đó ra chỉ để thêm một tầng cache chưa đo đạc là tối ưu hoá mò, và
cache là nơi lỗi dữ liệu cũ sinh sống: admin bật banner rồi ngồi đợi 60 giây không
hiểu sao chưa thấy.

Cái còn lại là mỗi lần mở Home đọc một document singleton có index — Mongo xử lý mức
đó không đáng kể, và cache phía máy người dùng vẫn hấp thụ các lần mở lại trong vòng
một phút. Đo rồi hẵng tối ưu.

Hai hướng đã cân và loại:

- **`Vary: CF-IPCountry`** giữ được cache dùng chung, nhưng Cloudflare không cache
  theo header `Vary` tuỳ ý một cách đáng tin. Không nên đặt cược vào đó.
- **Trả danh sách nước cho client tự lọc** giữ phản hồi giống nhau cho mọi người,
  nhưng client không thể tự biết quốc gia theo IP — quay lại vạch xuất phát.

## 7. Hình dạng phản hồi

`GET /api/v1/home-banner` trả thêm hai trường:

- `countries: string[]` — thô, để admin sửa.
- `visible: boolean` — đã tính cho chính người đang gọi.

**Không sửa `enabled` theo người xem**, dù đó là cách ít việc nhất. Admin đọc chung
endpoint này (`hddhistory-admin/src/services/homeBannerService.ts`); nếu `enabled` mang
nghĩa khác nhau tuỳ ai hỏi thì trang admin sẽ hiện "đang tắt" cho một banner đang
bật, chỉ vì người quản trị ngồi ngoài vùng nhắm.

## 8. Phân tầng

Controller đọc header và truyền quốc gia xuống; service quyết định. Đọc header đúng
là việc của tầng transport.

Phép so khớp tách thành hàm thuần trong `home-banner.util.ts`, kiểm bằng spec — đây
là phần dễ sai nhất (chuẩn hoá mã, `XX`/`T1`, danh sách rỗng) và cũng là phần kiểm
được mà không cần mạng hay DB.

## 9. Admin và app

**Admin**: ô chọn nhiều quốc gia có tìm kiếm (MUI Autocomplete) trên danh sách ISO
đóng gói sẵn, kèm chú thích "để trống = mọi quốc gia".

**App**: getter `isVisible` đổi từ `enabled && imageUrl.isNotEmpty` sang
`visible && imageUrl.isNotEmpty` (`home_banner_entity.dart:19`). Thêm việc gửi vùng
thiết bị lên làm dự phòng — một header, đặt cạnh header `lang` đã có.

## 10. Không làm

Không thống kê lượt xem theo quốc gia, không lên lịch theo thời gian, không nhắm
theo phiên bản app hay trạng thái premium, không danh sách loại trừ. Mỗi thứ thêm
vào là một nhánh nữa phải kiểm, và chưa cái nào có người cần.

## 11. Kiểm chứng

`npx tsc --noEmit` + spec cho hàm so khớp thuần (hddhistory-api), `npx tsc --noEmit`
(hddhistory-admin), `flutter analyze` sau codegen (hddhistory-flutter).

Đầu-cuối chỉ kiểm được sau khi deploy api-dev, vì `cf-ipcountry` chỉ tồn tại khi
traffic đi qua Cloudflare.
