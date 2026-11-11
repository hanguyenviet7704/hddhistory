# Progressive import: mở bài sớm, gen ngầm phần còn lại, audio đảm bảo

*2026-08-13 — approved in-chat (user): mở sớm = keypoint đầu đủ text + tiếng; roadmap
vẽ đủ node theo outline; sweep chỉ áp dụng bài của pipeline mới; cap video 2h
(chi phí đo thực tế ~1k VND/video 2h — user).*

## Vấn đề

1. **Bài mới vẫn ra đời không có tiếng.** Dub là one-shot: 3 lần retry mỗi card rồi
   `audioStatus: failed` vĩnh viễn; job chỉ đợi dub 3 phút (`DUB_DEADLINE_MS`) rồi
   complete, dub "mồ côi" chạy tiếp — một lần deploy/restart giữa chừng là mất tiếng
   mãi mãi, không có cơ chế nào dub lại.
2. **Video dài chờ lâu.** Cap 30' là cap chi phí thời cào transcript; giờ Gemini xem
   thẳng video, một video 2h ~1k VND — cap thật sự cần là trải nghiệm chờ, và câu
   trả lời đúng là đừng bắt chờ cả bài.

## Thiết kế

### Phase 1 — "first bite" (trong job, như cũ)

`generateOpening()`: MỘT call Gemini trả `{title, description, keypointPlan[] (tên
toàn bộ keypoint), keypoints[0] trọn vẹn}`. Lưu lesson với
`contentStatus: 'partial'`, `plannedKeypointTitles`, `generation: {attempts: 0}`.
Dub keypoint 0 (deadline 3' như cũ). `clearDraft` → job **COMPLETED**. Popup "bài
sẵn sàng" giờ nghĩa là: keypoint đầu đọc được và nghe được.

### Phase 2 — "remainder" (ngoài job, sở hữu bởi sweep)

`UserLessonCompletionService.continueGeneration(lessonId)`:
- claim atomic (`generation.heartbeatAt` stale/null → set now) để hai instance /
  sweep + fire-and-forget không chạy đôi;
- dựng lại `ResolvedSource` từ `lesson.source` (KHÔNG check lại độ dài — đã qua cửa
  lúc tạo job);
- `generateContinuation()`: call Gemini thứ hai, context = title + outline + toàn văn
  keypoint đã có, yêu cầu viết tiếp các keypoint còn thiếu đúng theo outline;
- append keypoints, tính lại wordCount/estimatedMinutes, floor
  `minAcceptedWordCount` enforce ở ĐÂY (trên tổng bài) — first bite chỉ enforce shape;
- `contentStatus: 'complete'`, dub các keypoint còn thiếu;
- lỗi ở bất kỳ đâu: ghi `attempts++`, `lastAttemptAt`, heartbeat null — sweep thử lại.

### Sweep — `UserLessonCompletionSweep` (@Interval 2')

Chỉ nhắm lesson có `generation != null` (bài của pipeline mới — bài cũ không có field
này, đúng quyết định "chỉ bài mới"):
- `contentStatus: 'partial'` ∧ heartbeat stale/null ∧ backoff(attempts) đã qua →
  `continueGeneration`;
- `contentStatus: 'complete'` ∧ audio chưa phủ hết keypoints → `dubMissingKeypoints`.
Backoff: `min(2^attempts, 32)` phút; không có trần bỏ cuộc — "luôn phải đầy đủ nội
dung và âm thanh" là yêu cầu sản phẩm. Mỗi tick xử lý tối đa 2 lesson.

### Audio semantics

- `audio.keypoints` giờ được ghi TỪNG PHẦN (union theo `keypointIndex`); version hash
  per-keypoint (`f(voice, scripts của keypoint)`) thay cho hash cả bài — re-dub một
  keypoint đổi đúng URL keypoint đó.
- `audioStatus: ready` = "có ít nhất keypoint 0 nghe được" (điều kiện mở bài).
  Độ phủ đầy đủ đo bằng `audio.keypoints` vs `keypoints.length` (sweep dùng cái này,
  không dùng audioStatus). `failed` chỉ còn cho hai lỗi không thể chữa: locale không
  có narrator, bài không có gì để đọc.

### Cap video

`maxVideoSeconds: 2 * 60 * 60`. 2h ≈ ~640k token input, dưới trần 1M của model; chi
phí đo thực ~1k VND/lượt. Quota tuần vẫn là phanh tổng.

### App (hddhistory-flutter)

- `UserLessonEntity/model`: thêm `contentStatus`, `plannedKeypointTitles`; helper
  `keypointReady(i)` = có keypoint i ∧ có audio entry cho i.
- Roadmap bài tự tạo: vẽ đủ node theo `plannedKeypointTitles`; node chưa ready =
  "Đang tạo..." (xám, không bấm); tự refetch chu kỳ ~8s khi còn `partial`.
- `keypoint_complete._startNextKeypoint` (nhánh imported): next keypoint chưa ready →
  quay về roadmap của bài (đường đã có).
- l10n: key mới add đủ 5 locale.

## Không làm

- Không re-dub bài cũ (quyết định của user), không migrate shape 10-card phẳng.
- Không đổi UX popup/toast — job semantics giữ nguyên, chỉ hoàn thành sớm hơn.
- Không stream structured-output (partial-JSON parsing mong manh; hai call đủ tốt).

## Files

hddhistory-api: `learning-import.config.ts`, `enum`, `interface`, `schema/user-lesson`,
`repository/user-lesson`, `ai/*` (types, prompt, gemini), `learning-import-runner`,
`audio/user-lesson-voiceover`, MỚI `user-lesson-completion.service.ts` +
`user-lesson-completion.sweep.ts`, `user-lesson.service`, module.

hddhistory-flutter: `user_lesson_model/entity` (+codegen), `user_lesson_roadmap_page`,
`keypoint_complete_page` (guard), i18n yaml ×5 + slang.

## Addendum 2026-08-13 (chiều): opening = 2 keypoint, không phải 1

User call sau khi thấy bản chạy: một keypoint buffer là quá mỏng — đọc xong
keypoint 1 trước khi continuation kịp về là đụng tường "Đang tạo…". Phase 1 giờ
viết + dub **`openingKeypointCount: 2`** keypoint (clamp theo plan) rồi mới báo
job completed; schema opening đổi `firstKeypoint` → `openingKeypoints[]`.
Continuation/sweep không đổi — chúng vốn tính từ `written.length`.

Cùng đợt: audio-gate phía app chỉ áp khi `contentStatus: partial` (7e6c5947) —
bài cũ thiếu tiếng vĩnh viễn không được đeo mặt nạ "Đang tạo…".

## Addendum 2026-08-13 (tối): STREAM một call — roadmap trước, keypoint nhỏ giọt

Thay kiến trúc 2 call (opening + continuation) ở phần trên: user muốn roadmap
hiện TRƯỚC rồi keypoint (chữ + tiếng) nở dần, và phương án rẻ+nhanh nhất là
`streamGenerateContent` MỘT call — video chỉ bị "xem" một lần (~1k VND/2h giữ
nguyên), outline chảy ra trước (`propertyOrdering` ép thứ tự field), mỗi
keypoint đóng object là commit + dub ngay.

- `LessonStreamAssembler`: scanner string/escape/bracket-depth + repair-and-parse
  phần đã quét; outline bắn khi mảng `keypoints` mở (mảng root thứ 2), keypoint
  bắn khi object của nó đóng. Spec 8 case cắt chunk ác ý.
- Runner: onOutline = khai sinh lesson (partial, 0 keypoint, art + plan) → claim
  generation → clearDraft → job COMPLETED. onKeypoint = normalize từng cái, pin
  title theo plan, chia art, `writeBody` (COMPLETE khi đủ plan), dub qua chain
  tuần tự không chặn stream. Post-stream: patch usage (đủ cả stream), xả dub
  chain + một lượt dub vét, release claim; thiếu keypoint → gọi continuation
  ngay.
- Continuation batch + sweep GIỮ NGUYÊN làm lưới an toàn: stream đứt ở đâu,
  sweep viết nốt từ đó. `openingKeypointCount` (addendum chiều) bị gỡ — thay
  bằng drip từng keypoint.
- Lỗi sau khi job đã COMPLETED không bao giờ stamp FAILED — nhả claim cho sweep.
