# Voiceover batch: tăng tốc + thấy rõ item đang dub

**Ngày:** 2026-07-30 · **Stack:** hddhistory-api + hddhistory-admin

## Vấn đề

Admin báo: "dub này hiện đang rất lâu luôn và không biết cái nào đang trong
tiến trình". Trạng thái lúc báo: 800 done / 135 stale / 1190 failed / 270 none
trên 2395 ô (keypoint × 5 ngôn ngữ) ⇒ ~479 keypoint.

### Vì sao lâu (đo thật với `msedge-tts` của repo)

| Phép đo | Kết quả |
|---|---|
| 5 ngôn ngữ, 1 card, tuần tự | 26.5s (vi 18.2s do handshake lần đầu; còn lại 1.5–3.3s) |
| Đúng 5 call đó, song song | 1.1s |
| 16 request song song | 16/16 OK, median 1.5s, max 15.2s |
| File "cả keypoint" (6 card ghép) | 7.8s ≈ tổng 6 card riêng lẻ |

1. **Concurrency = 1 ở mọi tầng.** `VoiceoverJobService.runGlobal` chạy course →
   keypoint tuần tự, `VoiceoverService.generateForKeypoint` chạy tiếp lang →
   card tuần tự, mỗi card synth rồi upload R2 nối tiếp. ~35 synth/keypoint ×
   ~100s ⇒ **~13 giờ** cho một lần force dub all.
2. **Synth gấp đôi lượng audio**: ngoài clip từng card còn synth 1 file cả
   keypoint cho `audio.url` (app build cũ). Quyết định: **giữ nguyên** (xem
   "Đã cân nhắc và loại").
3. **Chính màn hình theo dõi làm job chậm thêm**: poll 3s gọi
   `GET /voiceover/status`, endpoint đó quét lại toàn catalog mỗi lần
   (~479 keypoint × 2 query Mongo + sha256 × 5 lang), cùng event loop với job.

### Vì sao không biết cái nào đang chạy

- Nút **Dub** từng dòng tạo job *per-course*, nhưng trang batch chỉ poll job
  *global* (`status.job`); `rowDubbing` spinner tắt ngay trong `finally`. Chỉ
  thấy nếu mở đúng modal "Chi tiết" của course đó.
- Banner global chỉ in `currentCourseId` thô — không tên course, không keypoint,
  không ETA. `currentKeypointId` chỉ có ở per-course job.
- **Job state nằm trong RAM 1 process** → deploy/restart là mất sạch, không
  resume. Với 13 giờ thì job gần như không bao giờ chạy hết. Nhiều replica thì
  POST vào replica A, GET status vào replica B → `job: null`.

## Thiết kế

### 1. Song song hóa trong `generateForKeypoint`

`@utils/concurrency` → `runWithConcurrency(tasks, limit)`: pool giữ tối đa
`limit` task in-flight, kết quả index-aligned, một task reject không giết pool.

Mỗi keypoint dựng danh sách task phẳng (5 lang × (N card + 1 file whole)) rồi
chạy qua pool `VOICEOVER_CONCURRENCY` (env, **default 6** — bench cho thấy 16
vẫn 16/16 OK nhưng tail latency vọt lên 15s; 6 giữ median thấp và để API còn
phục vụ app).

**Bug phải sửa kèm:** `segmentUrls`/`segmentHashes` hiện `push` theo thứ tự →
phải gán theo index trên mảng cấp sẵn, nếu không kết quả lệch card khi song song.

**Keypoint vẫn tuần tự** — cố ý: 35 task/keypoint đã đủ bão hòa pool, và giữ
được nghĩa "keypoint đang dub" cho UI.

Kỳ vọng: **~13h → ~1.5–2h**.

### 2. Tách endpoint poll khỏi endpoint quét

| Endpoint | Vai trò |
|---|---|
| `GET /voiceover/job` (mới) | Chỉ job snapshot, O(1) — poll 3s đánh vào đây |
| `GET /voiceover/status` | Vẫn là "Quét", chỉ khi bấm nút / load lần đầu |

Gỡ luôn O(2N) trong `getCourseStatus`: 3 query/course
(`findKeypointIdsByCourse` + `findAudioByIds` + `findNarratableByKeypoints`)
thay cho `1 + 2N`.

### 3. Job state xuống Mongo

`voiceover/schema/voiceover-job.schema.ts` + `voiceover/repository/` (đúng
layering: chỉ repository chạm DB). Collection `voiceover_jobs`, một document /
scope, unique index `{ scope, courseId }`.

- **`heartbeatAt`** ghi ở mỗi biên keypoint (479 write/1.5h). Job `running` mà
  heartbeat cũ hơn 2 phút = process đã chết → báo `interrupted`, không treo
  "đang chạy" mãi.
- **Single-flight atomic**, không đọc-rồi-ghi:
  `findOneAndUpdate({ scope, courseId, $or: [status ≠ running, heartbeat stale] }, seed, { upsert: true })`.
  Doc live thì filter không khớp → upsert insert → duplicate key (11000) →
  hiểu là "đã có job chạy". Chặn double-start khi bấm 2 lần / 2 replica.
- **Resume**: `doneCourseIds` cho bỏ qua nhanh course đã xong; phần dở thì
  hash-skip sẵn có tự lo. Không cần endpoint riêng — bấm lại "Dub những cái cần"
  là claim thành công vì heartbeat đã stale.
- `totalKeypoints` tính trước bằng **một** aggregation
  (`LessonRepository.countKeypointsByCourse`) để ETA có mẫu số ổn định, thay vì
  cộng dồn như hiện tại.

### 4. Admin: badge từng dòng + banner chi tiết

- Poll `GET /voiceover/job`; bỏ `rowDubbing` giả — trạng thái dòng lấy từ job feed
  nên dub theo dòng hiện ngay trên bảng.
- Cột badge: `Đang dub` / `Đang chờ` / `Xong`.
- Banner: `Đang dub · {tên course} ({x}/{y}) · keypoint {tên keypoint} ({a}/{b}) · còn ~{ETA}`.
- Job `interrupted`: banner cảnh báo + nút chạy tiếp.

### 5. Trả lời dứt điểm 1190 Failed

`GET /voiceover/status` trả thêm `topErrors` (gom `audio.error[lang]` theo số
lượng). Bench local 21 call 0 lỗi ⇒ endpoint Edge hiện ổn; nghi ngờ là error sót
từ đợt Google Chirp3-HD (đợt đó fail 1634/2395) chưa được dub lại. `topErrors`
chốt được giả thuyết này mà không cần đọc log hosted.

## Đã cân nhắc và loại

- **Ghép clip card thành file whole** (Buffer.concat, cắt thêm ~50% synth):
  loại — chọn giữ chất lượng file liền mạch của `audio.url`.
- **BullMQ + Redis**: loại — phải thêm Redis vào hạ tầng dev+prod cho một tác vụ
  admin thỉnh thoảng mới chạy.
- **Song song cả ở tầng keypoint/course**: loại — mất nghĩa "keypoint đang dub",
  mà pool 35 task/keypoint đã đủ bão hòa.

## Verify

`npx tsc --noEmit` (hook tự chạy) + spec nhắm `runWithConcurrency`. Không chạy
full jest/flutter suite trên máy này (RAM).
