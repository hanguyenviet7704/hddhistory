# Vbee cho lồng tiếng tiếng Việt (2026-09-09)

Thêm Vbee làm nhà cung cấp TTS **trả phí** cho **riêng tiếng Việt**, bật/tắt
**theo từng khoá học**. Bốn ngôn ngữ còn lại (`en`/`zh`/`ja`/`ko`) không đổi một
dòng nào — vẫn chạy Edge miễn phí.

Lý do phải làm theo khoá chứ không phải công tắc toàn cục: số điểm Vbee có hạn,
và yêu cầu là "trên production chỉ chuyển đổi voice mới với những khoá học được
chỉ định".

## Ràng buộc đã đo trên API thật (không phải đọc doc)

- **Realtime API (`mode: sync`) không dùng được**: trần 300 ký tự, một thẻ theory
  vượt xa. Nên dùng **Batch API** (`mode: async`) + **poll**.
- **Không cần webhook thật.** `webhookUrl` là field bắt buộc trong body, nhưng
  request gửi với URL giả vẫn chạy xong bình thường và đọc lại được qua
  `GET /v1/tts/requests/{id}`. Nhờ vậy dub chạy được từ máy local hoặc container
  không expose ra ngoài. Text ngắn trả `COMPLETED` ngay lần poll đầu.
- **`audioLink` là redirect** (`vbee.vn/s/...` → S3 presigned) và **hết hạn sau 3
  phút** → phải follow redirect và tải ngay.
- **Định dạng ra**: với `bitrate: 64, sampleRate: 24000` → MP3 24kHz/64kbps mono.
  Edge đang là 24kHz/**48**kbps. Vbee không có nấc 48 (chỉ 8/16/32/64/128), nên
  **không thể trộn clip Edge và Vbee trong cùng một ngôn ngữ** —
  `voiceover-merge.service.ts` ghép bằng `-c copy`.
- **`credit_factor` khác nhau theo giọng**: 1 (chuẩn), 2 ("nâng cao (Beta)"),
  3 ("2.0"). Chọn giọng chính là chọn giá, nên picker phải hiện hệ số.

## Cơ chế cốt lõi: định danh giọng có tiền tố

`audio.voices[lang]` lưu `vbee:<voiceCode>` thay vì tên giọng Edge.

Đây là mấu chốt của cả thiết kế: **ba cơ chế sẵn có tự ăn theo chuỗi này**, không
phải sửa gì thêm —

1. `sameVoice` (`voiceover.service.ts`) → đổi provider đọc ra như đổi narrator ⇒
   re-dub **cả ngôn ngữ**, nên không bao giờ còn clip hai bitrate nằm cạnh nhau.
2. `computeMergeHash(voices[lang], …)` → `merged.mp3` tự sinh lại.
3. Cột `done`/`stale` ở admin tự hiểu khoá cần dub lại.

`TtsService.synthesizeMp3` định tuyến theo tiền tố. Chữ ký không đổi ⇒
`learning-import` (cũng dùng `TtsModule`) không phải sửa và vẫn mặc định Edge.

## Các mảnh

| Mảnh | Chỗ |
|---|---|
| Client Vbee (submit → poll → download, phân loại lỗi vĩnh viễn/tạm thời) | `voiceover/vbee-tts.service.ts` |
| Định tuyến theo tiền tố giọng | `voiceover/tts.service.ts` |
| Cờ theo khoá | `Course.voiceoverViProvider` (`edge` mặc định — Mongo, **không cần migration**) |
| Giọng dùng chung + validate theo catalogue | `voiceover/voiceover-settings.service.ts`, collection `voiceover_settings` |
| File nguyên bài ghép bằng ffmpeg | `voiceover-merge.service.ts#concatSegmentsToWhole`, gọi ở PASS 2b |
| Hạn mức ký tự mỗi lần chạy | `VbeeBudget`, tạo 1 lần cho mỗi run ở `VoiceoverJobService` |
| Ước tính chi phí | `VoiceoverService.estimateCourseVbee` |
| Admin | `VbeeVoicePanel.tsx`, `VbeeDubConfirmDialog.tsx`, cột "Giọng vi" trong `VoiceoverBatch.tsx` |

## Hai quyết định tiết kiệm điểm

**1. Không TTS lần hai cho file nguyên bài.** Mỗi keypoint trước giờ tổng hợp
hai lần — theo thẻ (`segments`) và nguyên bài (`audio.url`, cho bản app cũ). Với
Edge lần hai miễn phí; với Vbee nó **gần như nhân đôi hoá đơn** (đo được: cả
catalogue tiếng Việt ~920k ký tự thẻ so với ~890k ký tự nguyên bài). PASS 2b ghép
các clip thẻ vừa gen bằng ffmpeg `-c copy` — cùng giọng, cùng chữ, cùng thứ tự,
tốn 0 ký tự.

Chốt chặn quan trọng: **nếu `plan.failure` có giá trị thì bỏ qua bước ghép**. Thẻ
lỗi sẽ giữ clip cũ (có thể là Edge 48kbps), và `-c copy` không nối được hai
bitrate thành file phát được.

**2. Hai pool riêng.** Edge chạy ở `VOICEOVER_CONCURRENCY` (6), Vbee ở
`VBEE_CONCURRENCY` (3) — Vbee trả 429 `TTS_CCR_MAX_LIMIT_REACHED` ở một trần
thấp hơn nhiều và không công bố. Gộp một pool thì hoặc bóp bốn ngôn ngữ miễn phí
xuống nhịp của Vbee, hoặc chọc Vbee ở nhịp của Edge.

## Ứng xử với lỗi

- **401/400 (token sai, voiceCode không tồn tại, hết credit) = vĩnh viễn**, không
  retry: thử lại không đổi được kết quả, và với trường hợp hết điểm thì càng vô
  duyên.
- **429 + 5xx = retry** có backoff kèm jitter, giống hệt đường Edge.
- Hết hạn mức ký tự **degrade y như một lần synth lỗi**: thẻ giữ clip cũ, ngôn
  ngữ báo failed kèm thông điệp. Tái dùng đúng nhánh catch sẵn có, nên không bao
  giờ ghi đè bằng clip rỗng.

## Còn phải làm / chưa verify

- Chưa chạy thử end-to-end trên dev: cần đặt `VBEE_APP_ID`/`VBEE_TOKEN` vào
  `.env` của api-dev, bật cờ cho 2–3 khoá, dub, rồi nghe + `ffprobe` file
  `merged.mp3` xem có liền mạch 24kHz/64kbps không.
- Thứ tự deploy: **API trước, admin sau** (whitelist DTO xoá âm thầm field lạ).
- Danh sách khoá "gen lại voice" (sheet BTV cột U) do BTV tự tick trên admin —
  cố ý không tự động hoá.
