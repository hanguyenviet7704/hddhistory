# A/B test nội dung khoá học (design + trạng thái, 2026-09-08/09)

Nguồn: owner yêu cầu "A/B test nội dung khoá học như kiểu cái paywall". Dựng
trên phiên bản nội dung theo tag (`plans/260907-course-content-versions/`): hai
tag của cùng một khoá làm hai nhánh.

## 1. Không dựng framework

`PaywallBodyExperimentDto` ghi rõ chủ ý: *"deliberately one-off and not a
general experiment framework — a second test would want its own metric and its
own readout"*. Đây là đợt test **thứ hai, có chỉ số và bảng đọc riêng**, chỉ
dùng chung hai thứ:

- `experimentBucket(key, viewerId)` — tách từ private `bucketOf` của paywall ra
  `@utils`. Hàm băm không phải framework, nhưng phải là MỘT bản: hai bản lệch
  nhau làm một trong hai đợt bị lệch nhánh mà màn cấu hình vẫn thấy đúng tỉ lệ.
- `UserEventRepository.countUsersByParam` — đã tổng quát sẵn, đếm số NGƯỜI theo
  giá trị một param, lọc thêm theo `params.*`. Không viết aggregation mới.

**Không có bảng gán nhánh.** Nhánh tính lại bằng hash mỗi lần resolve: ổn định
cho một người, không sinh row, tra lại được chỉ từ `key` + `userId`. Đây là chỗ
sửa lại thiết kế cũ của tôi (bản trước ghi "thêm 1 collection gán nhánh").
Cũng vì thế **`key` phải đổi mỗi đợt** — dùng lại là trả mọi người về đúng
nhánh cũ, biến đợt mới thành phần tiếp của đợt cũ.

## 2. Quyết định đã chốt với owner

| | |
|---|---|
| Chỉ số | Phễu **hoàn thành keypoint**, kèm ba tín hiệu âm |
| Phạm vi | **Một đợt phủ nhiều khoá**, mỗi khoá khai hai tag |
| Ai vào đợt | **Chỉ người bắt đầu khoá từ khi đợt mở** |

Một người ở **cùng một nhánh xuyên mọi khoá** trong đợt (hash chỉ ăn `key` +
`userId`), nên đo được một *lối viết* thay vì chỉ một khoá, và cỡ mẫu được gộp.

Điều kiện "bắt đầu khoá từ khi đợt mở" so `UserProgress.createdAt` với
`startedAt`. Chọn mốc *bắt đầu* thay vì "chưa có tiến trình" vì nó **ổn định
khi user học tiếp** — nếu không, họ sẽ bị lật ra khỏi test ngay sau keypoint đầu
và nội dung đổi lần nữa.

## 3. Đường đọc

Toàn bộ quyết định nằm trong `resolveVersionRequest` — hàm thuần, 23 test. I/O
(tra đợt, tra tiến trình) ở `ContentSource` rồi truyền sự kiện vào, giống cách
`segment-match.util.ts` tách đường serve khỏi đường đếm.

```
có ?version= từ panel      → tag đó            (panel luôn thắng)
khoá không trong đợt        → currentVersionId
không có id ổn định (khách) → currentVersionId
tiến trình có TRƯỚC đợt     → currentVersionId
thiếu một nhánh (tag đã xoá)→ currentVersionId  (fail closed)
còn lại                     → bucket < percentB ? tagB : tagA
```

`?version=current` trả **con trỏ** đang phát hành, không phải nhánh: khi đợt
đang chạy thì "cái user thật thấy" phụ thuộc id từng người, không có một câu
trả lời.

**Chặn sớm trên đường nóng.** `factsFor` chạy trên MỌI lượt đọc nội dung, và
phần lớn khoá không nằm trong đợt nào. Nên nó kiểm danh sách khoá-đang-trong-đợt
trước (cache 30s) thay vì query đợt cho từng lượt đọc màn chính.
`invalidateArmCache` là API thật, gọi khi bật/tắt đợt để có hiệu lực ngay.

## 4. Cái bẫy đã sập vào: event khai mà không bắn

Hai trong bảy event tôi chọn cho phễu **không bao giờ được gửi**:

```
keypoint_exercise_scr_view  0 caller  → không tồn tại trong luồng app
keypoint_report_click       0 caller  → app bắn keypoint_menu_report_click
```

Đúng cái mà comment trên `PAYWALL_EXPERIMENT_EVENTS` cảnh báo: gõ sai không làm
gì fail, nó trả về một con số 0 trông rất thật. Cách kiểm: lần từng hằng số
trong `tracking_key.dart` ra phương thức của `app_tracking_service.dart`, rồi
**đếm call site trong `lib/src`** — có hằng số và có phương thức vẫn chưa nghĩa
là có bắn.

Phễu chốt lại, cả bảy đã xác minh có chảy từ UI:

```
roadmap_scr_view → keypoint_intro_scr_view → keypoint_read_scr_view
                                            → keypoint_complete_click
âm: keypoint_complete_skip · keypoint_exit_popup_view · keypoint_menu_report_click
```

Bước giữa là **đọc nội dung**, không phải "vào bài tập" — với A/B *nội dung* thì
"có đọc bài không" còn gần với thứ đang test hơn.

## 5. Flutter: ba chỗ đóng dấu, chỗ thứ ba dễ bỏ sót

App nhớ nhánh theo `courseId` (`ContentExperimentTracker`) rồi trộn
`content_experiment_key` + `content_variant` vào params. Đóng dấu ở **ba** hàm
dựng params dùng chung:

- `_courseParams`, `_keypointParams` trong `app_tracking_service.dart`
- `LessonTracking.keypointParams()` — **đường tracking thứ hai**, không đi qua
  service, và `keypoint_complete_skip` chỉ bắn qua đó.

Nhớ theo `courseId` chứ không nhớ trần: dán nhánh khoá A lên event khoá B là
làm bẩn số liệu rất khó truy. `paramsFor` trả rỗng khi id không khớp.

## 6. Cỡ mẫu: không dùng con số của paywall

Panel paywall nói ~5.000 người/nhánh, đúng cho chuyển đổi mua ~3%. Phễu ở đây
là hoàn thành keypoint với tỉ lệ hàng chục %, nên số được tính tại chỗ bằng xấp
xỉ **n ≈ 16·p(1-p)/δ²** (80% power, 95% tin cậy): ~1.600 người/nhánh để phân
biệt 50% với 55%, ~4.500 cho chênh 3 điểm.

## 7. Việc không làm

Nhiều hơn hai nhánh · đợt theo segment (trộn hai biến một lúc) · chặn cứng việc
phát hành tag mới giữa đợt (chỉ cảnh báo như paywall — hai tag của nhánh là khai
tường minh nên phát hành tag mới không đổi nhánh, chỉ đổi cái người ngoài đợt
thấy) · A/B cho list xuyên khoá (thẻ đã lưu / study journal vẫn đọc
`currentVersionId`, nên title thẻ đã lưu có thể là bản đã phát hành trong khi
bài học hiện nhánh B — id chia sẻ nên thường trùng, khác nhau thì lệch nhỏ).

## 8. Trạng thái

Cả ba stack ĐÃ PUSH develop 2026-09-08/09, **chưa deploy, chưa verify trên dữ
liệu thật**:

- api `c5fc6c7` (tách hàm băm) · `3af1df2` (A/B) · `c4c856c` (sửa phễu)
- admin `fcb4388` (trang) · `7083329` (nhãn cột)
- flutter `52392c40` (đóng dấu event)

Gate: `npm run build` xanh · 537 test api pass (chỉ còn `week-recap` fail sẵn từ
`97b5d33`) · boot thật 25 module không lỗi DI · quét 96 module sạch, sweep đã
self-test · admin `tsc` 0 lỗi + render test · flutter `analyze` không lỗi mới +
7/7 test tracker.

**Chưa làm:**
- Chạy thử một đợt thật rồi đọc bảng: cần app có bản mới lên trước, không thì
  bảng toàn 0. Vì thế đợt tạo ra luôn ở trạng thái TẮT.
- Chưa có phần TẮT đợt theo thời gian (`endedAt` có trong schema nhưng không ai
  ghi) và chưa có nút xoá đợt.
