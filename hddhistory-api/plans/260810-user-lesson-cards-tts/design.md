# Bài tự tạo v2 — 10 card tóm tắt + lồng tiếng

Ngày: 2026-08-10 · Repo: `hddhistory-api` + `hddhistory-flutter` (admin không đổi)
Tiếp nối: `plans/260810-user-content-import/design.md` (bản v1 đã ship)

## 1. Vấn đề

Bản v1 sinh bài 3500–5000 từ và hiển thị bằng **một trang cuộn liền**, khác hẳn
luồng học chính vốn là bộ bài card vuốt dọc. Hai hệ quả:

- **Lạc lõng.** Người dùng học bằng bộ bài card ở mọi chỗ khác trong app; một màn
  đọc khác kiểu đọc như một tính năng của sản phẩm khác ghép vào.
- **Không nghe được.** Luồng chính có lồng tiếng, phát nền, điều khiển từ màn
  khoá. Bài do chính người dùng mang vào thì không — trong khi đó mới là thứ họ
  muốn nghe lúc đi đường.

Ép nguyên 3500–5000 từ vào khuôn card hiện tại không phải lời giải: card trong
luồng chính cắt theo **ranh giới do biên tập viên soạn**, một card một
"document". Bài sinh ra không có ranh giới đó, và nếu cắt nhỏ tương đương thì một
bài nở thành hàng trăm card.

## 2. Quyết định sản phẩm (chốt 2026-08-10)

| Câu hỏi | Chốt |
|---|---|
| Độ dài bài | **1200–2000 từ**, bỏ mốc 3500–5000 của v1 |
| Số card | **Đúng 10**, mỗi card một ý |
| Phần ↔ card | **Một phần = một card**, ánh xạ 1:1 xuyên suốt. `sections[i]` là card thứ `i`, cue thứ `i`, và `stopAtSectionIndex` chính là chỉ số card |
| Kiểu đọc | Bộ bài vuốt dọc, mượn ngôn ngữ thị giác của luồng chính |
| Lồng tiếng | Có, một file cho cả bài, cue theo chỉ số card |
| Lúc nào dub | **Sau khi bài đã lưu xong**, không chờ dub mới trả bài |
| Job chạy ngầm | Có. Người dùng thoát sheet, thoát app đều được |
| Báo khi xong | **Popup in-app** trên shell, cùng khuôn `StreakPopupHost` |
| Push notification | **Chưa làm.** Để sau, xem mục 7 |

## 3. Đổi gì ở hddhistory-api

### 3.1 Ba hằng số và một câu prompt

`learning-import.config.ts`:

```
targetWordCount:      { min: 3500, max: 5000 }  ->  { min: 1200, max: 2000 }
targetSectionCount:   { min: 5,    max: 8    }  ->  { min: 10,   max: 10   }
minAcceptedWordCount: 3000                      ->  900
```

`lesson-generation.prompt.ts` đổi từ "5–8 phần" sang **"đúng 10 phần, mỗi phần
trình bày trọn một ý"**. Ngưỡng chấp nhận vẫn thấp hơn mục tiêu vì lý do cũ: mô
hình thường hụt so với số từ yêu cầu, và bài 1000 từ vẫn là bài tốt — ngưỡng đó
để bắt ca "tài liệu nguồn gần như rỗng", không phải để bắt bẻ vài trăm từ.

**`buildLessonPrompt` phải sửa code, không chỉ sửa hằng số.** Hiện nó dựng câu
`"Between {min} and {max} sections"`; với `min === max` câu đó thành "Between 10
and 10 sections", vừa lủng củng vừa yếu hơn một mệnh lệnh dứt khoát. Khi hai đầu
bằng nhau thì dựng `"Exactly {n} sections"`.

Không đổi gì khác trong đường sinh bài. `normalizeGeneratedLesson` giữ nguyên —
nó không bao giờ kiểm số phần, và cố tình như vậy (xem docblock của nó).

### 3.2 Trường `audio` trên `user_lessons`

```ts
interface IUserLessonAudio {
  url: string;          // file merged, đã appendVersion(hash)
  durationMs: number;
  cues: { sectionIndex: number; startMs: number; durMs: number }[];
  voice: string;
  hash: string;
}
```

Đơn giản hơn `IKeypointAudio` ở hai chỗ, và cả hai đều do bản chất dữ liệu chứ
không phải cắt bớt cho nhanh: bài tự tạo **chỉ có một ngôn ngữ** (`outputLocale`
là chuỗi, không phải `ITranslation`) nên không cần map 5 locale; và cue khoá theo
**chỉ số phần** chứ không phải cặp `(learningItemId, documentIndex)` vì bài tự
tạo không có learning item.

Thêm `audioStatus: 'none' | 'processing' | 'ready' | 'failed'` (mặc định `none`).
Lưu trên **lesson** chứ không phải trên job, vì bài sống lâu hơn job — job có thể
bị dọn, còn nút tai nghe vẫn phải biết có audio hay không.

### 3.3 `TtsModule` tách ra khỏi `VoiceoverModule`

`TtsService` hiện là provider riêng của `VoiceoverModule` và không export.
`TtsService.synthesizeMp3(text, lang, rate?, voiceName?)` vốn đã là hàm thuần
`(chuỗi, ngôn ngữ) → Buffer` — không dính gì tới keypoint.

Tách thành `TtsModule` chỉ gồm `TtsService` + `ConfigurationProvider`;
`VoiceoverModule` và `LearningImportModule` cùng import nó. **Không** cho
`LearningImportModule` import thẳng `VoiceoverModule`, vì module đó kéo theo
`CourseModule`, `KeypointModule`, `LessonModule`, `LearningItemModule` — nặng và
dễ tạo vòng lặp phụ thuộc.

### 3.4 `UserLessonVoiceoverService`

Một pha, chạy fire-and-forget sau khi lesson đã lưu:

1. Đọc lesson; nếu `outputLocale` không thuộc 5 locale đã map thì đánh `failed`
   và dừng — `resolveVoiceName` sẽ ném lỗi.
2. Đánh `audioStatus: 'processing'`.
3. Mỗi phần → một đoạn narration: tiêu đề phần + các đoạn văn nối bằng `\n\n`,
   qua `stripHtml` rồi `sanitizeForNarration` (**tái dùng nguyên, không sửa**).
4. `TtsService.synthesizeMp3` cho từng đoạn, chạy song song tối đa 4 — thấp hơn
   mức 6 của voiceover vì đây là job nền chạy cùng lúc với các import khác.
5. Upload từng clip: `voiceover/user-lesson/<lessonId>/<i>.mp3`.
6. `ffprobe` lấy độ dài thật từng clip → `buildCues` (**tái dùng**).
7. `ffmpeg -f concat -c copy` → `voiceover/user-lesson/<lessonId>/merged.mp3`,
   URL qua `appendVersion(hash)` vì key là tất định và cache vĩnh viễn.
8. `$set { audio, audioStatus: 'ready' }`. Hỏng ở bất kỳ bước nào →
   `$set { audioStatus: 'failed' }`, ghi log, **không** ném lên trên.

### 3.5 Dub chạy sau khi bài đã xong, không chen vào giữa

`LearningImportRunnerService` sau khi lưu lesson và đánh job `completed` thì bắn
`setImmediate` gọi `dubLesson(lessonId)`.

Job **không** có stage `dubbing`. Hai tín hiệu tách bạch: job `completed` nghĩa
là *bài đã đọc được* (popup bật lúc này), còn `lesson.audioStatus === 'ready'`
nghĩa là *nghe được* (nút tai nghe hiện lúc này).

Lý do không dub trong cùng job: `msedge-tts` là endpoint không chính thức của
Microsoft, không cam kết, và docblock trong `tts.service.ts` ghi rõ *"dành cho
sinh hàng loạt trước, không bao giờ đặt trên đường request của người dùng"*. Nếu
dub hỏng mà nó nằm trong job thì người dùng mất cả bài lẫn tiếng; tách ra thì họ
vẫn có bài, chỉ thiếu tiếng.

### 3.6 Response

`GET /user-lessons/:id` trả thêm `audio` và `audioStatus`. `GET /user-lessons`
(danh sách) chỉ trả thêm `audioStatus` — không kèm `cues`, vì thẻ trên danh sách
chỉ cần biết có nên vẽ biểu tượng tai nghe hay không.

**Cạm bẫy:** `LIST_PROJECTION` trong `user-lesson.repository.ts` liệt kê tường
minh từng trường; quên thêm `audioStatus` vào đó thì danh sách sẽ luôn trả về
`undefined` và biểu tượng tai nghe không bao giờ hiện — không lỗi, không cảnh
báo, chỉ là im lặng sai.

## 4. Đổi gì ở hddhistory-flutter

### 4.1 Bộ bài thay cho trang cuộn

`lesson_reader_page.dart` bị thay bằng `lesson_deck_page.dart`: vuốt dọc, mỗi
card là một phần, nội dung dài cuộn **bên trong** card, card hai bên ló mép.

**Không cắm vào `KeypointCardCubit`.** Cubit đó đòi `LessonCubit` + `TheoryCubit`
+ `LessonAudioCubit`, dựng card từ state của lesson, và mang theo cổng paywall
trong bài. Repo đã có tiền lệ y hệt: màn quiz của Habit viết lại deck thay vì tái
dùng, lý do ghi ở docblock `habit_quiz_page.dart`. Thay vào đó copy **phần xử lý
cử chỉ** (`_resolveDragMode` / `_settleDrag`, slop 8, ngưỡng 70, snap 420ms,
viewport 0.937) và khung `LessonContentCard`, rồi viết `UserLessonDeckCubit`
riêng (~150 dòng).

Bộ bài này đơn giản hơn bản gốc ở một điểm quan trọng: **không có cổng chặn**.
Bài tóm tắt không có câu hỏi, nên cả 10 card mở sẵn, không có `revealBound`,
không có paywall trong bài. Vuốt tự do hai chiều.

Giữ lại: thanh pip tiến độ (một pip mỗi card, bấm được để nhảy), card cuối có nút
Continue quay về danh sách, gợi ý vuốt ở hai card đầu.

`stopAtSectionIndex` giữ nguyên tên và ý nghĩa — giờ nó chính là chỉ số card.
Không đổi API.

### 4.2 Audio: cubit riêng, lái handler có sẵn

`lib/src/src.dart` **có** export `lesson/lesson.dart`, nên `learning_import` nhìn
thấy `LessonAudioHandler` — singleton toàn app, đăng ký ở `app_service.dart`, API
(`loadItem`, `play`, `pause`, `seek`, `setSpeed`) hoàn toàn không dính keypoint.

Nên viết `UserLessonAudioCubit` nhỏ lái thẳng handler đó. **Không mở rộng
`LessonAudioCubit`, không dời file nào** — mảng "nghe liên tiếp xuyên keypoint"
vừa đẩy lên develop hôm nay và chưa verify trên máy thật; thiết kế này không chạm
vào nó một dòng.

Được sẵn: phát nền, điều khiển màn khoá, tua tới/lui, đổi tốc độ.

Card đi theo giọng đọc: mỗi tick vị trí, tìm cue chứa vị trí đó → nhảy deck. Cùng
ý tưởng merged mode nhưng đơn giản hơn nhiều vì cue chỉ có `sectionIndex`.

Nút bật/tắt narration copy hình dáng `KeypointNarrationToggle` (vòng tròn tai
nghe thu gọn → viên thuốc có nút tạm dừng và chip tốc độ); không tái dùng được vì
widget đó nằm trong `keypoint_card_shell.dart` và đọc `KeypointCardCubit`.

**Một hệ quả phải nói rõ:** handler là player đơn. Mở bài tự tạo trong lúc đang
nghe keypoint sẽ thay nguồn, tức dừng narration của bài kia. Đây vốn là mô hình
sẵn có ("mỗi lúc một giọng đọc"), không phải khiếm khuyết mới, nhưng nó là hành vi
cần kiểm khi test.

### 4.3 `ImportDonePopupHost`

Gắn ở `lib/core/utils/layouts/scaffod_layout.dart`, cạnh `StreakPopupHost` và
`GiftPopupHost` — bọc shell chứ không bọc Home, để nó sống khi người dùng đang ở
bất kỳ tab nào.

Nghe `LearningImportCubit` (vốn `@lazySingleton`, sống suốt vòng đời app):

- job lật sang `completed` → popup "Bài học đã sẵn sàng", tên bài, nút **Đọc
  ngay** (vào thẳng bộ bài) và **Để sau**.
- job lật sang `failed` / `interrupted` → popup câu lỗi tương ứng + nút thử lại.
- Mỗi job chỉ báo **một lần**; ghi id job đã báo vào `ILocalStoreService` để mở
  lại app không bật lại popup cũ.

Sheet import bỏ phần tự nhảy vào bài khi xong. Giờ nó chỉ nhận nguồn và hiện tiến
độ **nếu** người dùng còn ở lại; đóng đi thì popup lo bàn giao.

**Nếu người dùng vẫn đang mở sheet lúc job xong**: sheet tự đóng, rồi popup bật
lên như mọi trường hợp khác. Một đường bàn giao duy nhất, không phải hai — nếu để
sheet tự xử lý khi đang mở và popup xử lý khi đã đóng thì có hai đoạn code cùng
làm một việc, và cái ít chạy hơn sẽ là cái hỏng mà không ai biết.

### 4.4 Hỏi lại tiến độ khi app quay lại foreground

Khi app xuống nền, iOS treo tiến trình và `Timer` ngừng — vòng lặp hỏi tiến độ
chết im, và nếu không xử lý thì người dùng quay lại thấy màn chờ đứng yên vĩnh
viễn.

`LearningImportCubit` quan sát vòng đời app; mỗi lần lên foreground, nếu còn job
đang chạy thì hỏi lại ngay một phát rồi mới bật lại timer. Đây là thứ làm kịch
bản "thoát app rồi quay lại" chạy trọn vẹn mà chưa cần push.

### 4.5 i18n

Khoá mới cho popup, deck và audio, thêm vào **cả 5 locale** — thiếu một locale
thì nó lặng lẽ rơi về tiếng Anh chứ không báo lỗi. Khoá của v1 giữ nguyên.

## 5. Admin

Không đổi. Trang chi tiết vẫn đọc được toàn văn bài; số phần đổi từ 5–8 thành 10
là chuyện dữ liệu, không phải chuyện code.

## 6. Không làm (YAGNI)

- **Cue theo từng đoạn văn.** Một cue mỗi card là đủ để card đi theo giọng.
- **Dub lại khi sửa.** Bài tự tạo là bất biến, không có đường sửa.
- **Bộ chọn giọng / nhiều giọng.** Một giọng nữ cố định mỗi ngôn ngữ, như
  voiceover hiện tại.
- **Nghe liên tiếp nhiều bài tự tạo.** Chuỗi nghe xuyên keypoint là chuyện của
  luồng chính; bài tự tạo không có thứ tự nên không có "bài kế tiếp".
- **Tái dùng `KeypointCardShell`.** Xem 4.1.

## 7. Push notification — để sau, có chủ đích

Hạ tầng có sẵn (Firebase Admin bên API, trang `/notifications` bên admin) nên
việc này khả thi, nhưng chưa làm ở vòng này.

Lý do: sinh bài mất 2–4 phút, cộng lồng tiếng nữa — đủ lâu để người dùng bỏ đi
làm việc khác, nhưng phần lớn sẽ quay lại app trong cùng phiên, và mục 4.4 đã phủ
trọn kịch bản đó. Push chỉ thêm giá trị cho nhóm đóng app rồi quên hẳn. Đo bằng
số liệu thật rồi quyết, thay vì đoán trước.

Khi làm thì phần việc là: gửi push từ `dubLesson` hoặc từ runner, và xử lý deep
link để bấm vào notification là vào thẳng bộ bài.

## 8. Rủi ro đã biết

**`msedge-tts` không có cam kết.** `audioStatus: 'failed'` là kết cục bình thường
chứ không phải sự cố. Giao diện phải coi "bài không có tiếng" là trạng thái hợp
lệ, không phải lỗi cần báo động.

**Hai cubit dùng chung một handler.** Xem 4.2 — phải kiểm bằng tay.

**`scaffod_layout.dart` là file dùng chung**, sửa nó ảnh hưởng mọi tab. Thay đổi
chỉ là thêm một widget bọc, cùng khuôn hai host đã có, nên rủi ro thấp — nhưng nó
vẫn là file mà một lỗi sẽ hiện ra ở khắp nơi.

**ffmpeg không có trên máy dev này.** Bước ghép chỉ chạy được ở server, y như
voiceover hiện tại. Không kiểm được đầu-cuối tại chỗ.

## 9. Kiểm chứng

| Việc | Cách |
|---|---|
| hddhistory-api biên dịch | `npx tsc --noEmit`, `nest build` |
| Đồ thị DI | boot riêng module như lần v1 |
| Logic thuần | spec cho bộ dựng đoạn narration + phép tính cue |
| hddhistory-flutter | `dart run build_runner build`, `dart run slang`, `flutter analyze` |
| Đầu-cuối | chỉ làm được trên api-dev, cần `GEMINI_API_KEY` + ffmpeg server |

Không chạy `npm test` hay `flutter test` toàn bộ trên máy này (hết RAM); chỉ chạy
đúng file cần.
