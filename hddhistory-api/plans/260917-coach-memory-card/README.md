# Coach nhớ user: thẻ nhớ có cấu trúc + ngân sách cứng

2026-09-17. Owner: "muốn coach luôn nhớ cảnh của user nhưng phải rút gọn raw,
không thì tràn context". Yêu cầu đầy đủ, theo thứ tự owner chọn: nhớ ở **mọi
bước mọi luồng**, **trả lời được khi user hỏi**, và hiện ra ở **lời chào mở
phiên**. "Cảnh" = chuyện user tự kể (hoàn cảnh), không phải cảnh luyện tập.

## Tình trạng trước bản này

Tầng nhớ đã có từ 2026-09-04 (`plans/260904-coach-flows-v3`, mục "Memory layer
cho T3"): 5 collection, `mergeMemory` thuần, `ai.extractMemory`, `contextFor`.
Ba chỗ hở khiến "Coach không nhớ":

1. **Retrieval hẹp.** Khối `readerMemory` chỉ vào ĐÚNG MỘT prompt —
   `buildStoryTalkPrompt` (`coach-prompt.ts:706/743`). Sinh cảnh, bài học, câu
   kết, nhìn lại: không nhận gì.
2. **Extraction tăng bậc hai.** `extractFromSession` chạy mỗi
   `MEMORY_MIDSESSION_EVERY_LINES`=6 lượt và mỗi lần đọc **lại toàn bộ**
   transcript phiên + 40 memory (`coach-session.service.ts:2319`). Phiên Home 24
   lượt = đọc 6+12+18+24 = 60 dòng cho 24 dòng thật.
3. **Raw nhét thẳng + không ai dọn.** `priorLinesFor` query 30 dòng nguyên văn
   MỖI lượt (`:3497`) kể cả ở bước không có `priorBlock`. `findLiveForUser` sort
   `confidence:-1` nên dòng cũ đã lên 0.95 chiếm sạch 8 chỗ; không cap, không
   suy giảm theo `lastSeen`.

## Hướng đã chọn (A)

Nén ở chỗ RẺ (lúc kết phiên, off-clock), phát ở chỗ CẦN (thẻ dựng sẵn, cap cứng).
Tính chất mua được: **prompt size O(1) theo độ dài lịch sử** — user dùng 3 năm
prompt vẫn thế. Vector search vẫn hoãn (plan v3 đã xếp "để sau").

Đã cân nhắc và bỏ: (B) tóm tắt cuộn thuần — tóm tắt của tóm tắt trôi dần không
hồi được, không trả lời nổi câu hỏi cụ thể; (C) vector retrieval — thêm hạ tầng
+ một call embedding TRÊN clock của user, chưa bù nổi phức tạp ở vài trăm
dòng/user.

## 1. `coach_memory_cards`

Collection mới, 1 doc/user, trong module memory. KHÔNG nhét vào
`coach_profiles`: profile là điều user tự khai, thẻ là thứ dẫn xuất dựng lại
được — khác vòng đời, và không muốn mỗi lần kết phiên lại ghi đè doc đang bị đọc
mỗi lượt.

- `userId` (unique), `card: string` (cap `MEMORY_CARD_MAX_CHARS`=700),
  `greetingTopic: string|null` (≤80), `greetingLocale`, `greetingUsedAt`,
  `builtAt`, `builtFromSessionId`.
- Thẻ 4 khối, mỗi dòng ≤120 ký tự, cắt theo đúng ưu tiên khi tràn cap:
  1. NGƯỜI — nghề + ≤2 `context`
  2. ĐANG MUỐN — ≤2 goal active
  3. CẢNH GẦN ĐÂY — ≤3 episode gần nhất (`situation` + `emotion`)
  4. LẶP LẠI — ≤2 pattern `evidenceCount ≥ 2`
- `buildMemoryCard()` là **hàm thuần, 0 token AI**: `episodes.situation` và
  `memories.content` vốn đã là một dòng đã nén, không cần model nén lần hai.
  Pin bằng spec như `coach-memory-merge.spec.ts`.

## 2. Extraction tăng dần

- `coach_sessions` thêm `memoryExtractedAt` (phiên không còn TTL từ 2026-09-04
  nên watermark sống cùng phiên).
- `extractFromSession` đọc chỉ dòng sau watermark + 2 dòng trước đó làm ngữ
  cảnh. "Điều đã biết" truyền vào = thẻ nhớ + id/content rút gọn (cap 25, thay
  40 memory thô).
- Xong merge → set watermark → `rebuildCard(userId)` (4 query + nối chuỗi).

## 3. Thẻ vào prompt nào

CÓ thẻ: `buildStoryTalkPrompt` (thay `readerMemory`), `buildLessonTalkPrompt`,
`buildClosingLinePrompt`, `buildReflectPrompt` — toàn bộ chỗ user thật sự nói
chuyện.

KHÔNG thẻ: `buildSceneReactPrompt`/`SceneJudge`/`SceneScore` — người trong cảnh
diễn không được biết chuyện đời thật của user. Cộng `quizFeedback`, `risk`,
`transcribe`, `questionGuard`, `habitMatch` (`readerFacts` đủ).

**`buildSituationPrompt` cũng KHÔNG** — bản design đầu đã sai chỗ này. Cảnh sinh
ra được `cacheGenerated` lưu vào pool dùng chung theo
`(habit, locale, variant, audience, goalKey, slot)`, và pool đó là FALLBACK cho
user khác khi provider chết (`coach-situation.service.ts:175`). Nhét hoàn cảnh
riêng của user A vào prompt sinh cảnh = cảnh mang chuyện đời A vào pool và có
ngày phát cho user B. Muốn làm sau thì phải đánh dấu row `personal: true` để nó
không bao giờ vào pool dùng chung.

Bỏ `priorBlock` 30 dòng raw → `priorTail` = 6 dòng cuối của phiên liền trước,
và chỉ query khi prompt thật dùng.

Trung thực về token: story-talk giảm (~17 dòng memory + 30 dòng raw → ~10 dòng
thẻ + 6 dòng raw); 4 prompt kia mỗi cái +~200 token. Tổng có thể xấp xỉ hoặc
tăng nhẹ ở phiên ngắn. Cái mua được là **hết tăng theo lịch sử**.

## 4. Câu chào mở phiên

Ràng buộc: `reply` và `promptKey` KHÔNG BAO GIỜ cùng có giá trị — hợp đồng i18n
của Coach (`coach_model.dart:307`). Nên:

- Slang key mới `coach.prompt.hubBack` = "Hôm trước bạn kể chuyện {topic}. Hôm
  nay thế nào?" → server gửi `promptKey: hubBack` + `promptArgs: {topic}`. Khung
  câu cố định dịch đủ 5 locale; chỉ mảnh chủ đề là chữ sinh ra. Model không thể
  làm mất câu hỏi vì câu hỏi không do nó viết.
- `greetingTopic` sinh bằng cách **gộp vào `MEMORY_EXTRACTION_RESPONSE_SCHEMA`**
  ở lần extract tại END → 0 call Gemini thêm, 0 ms thêm trên đường `open` (đường
  đó đang 1–5s, không chạm).
- Chỉ cửa HOME (HUB/MOOD). Cửa LESSON/HABIT có câu mở riêng theo ngữ cảnh.
- Dùng một lần (`greetingUsedAt`). Chưa có gì, hoặc `greetingLocale` lệch locale
  hiện tại → về `coach.prompt.hub` như cũ.
- Flutter: 1 key × 5 YAML + `dart run slang`. Không chạm model, không
  build_runner. **API và Flutter phải lên cùng nhau** (client thiếu key = câu
  chào trống).

Đã bỏ: gửi `reply` = cả câu chào (zero Flutter change) — câu hỏi mở phiên khi đó
do model viết, sẽ có lần nó quên hỏi và user nhìn vào câu chào không có chỗ trả.

## 5. Tra cứu khi user hỏi

- Phát hiện ở server bằng **regex, không gọi AI**: "còn nhớ", "tôi/mình từng",
  "tôi đã kể", "lần trước", "hôm trước", "bạn biết gì về". Neo `\b`, chỉ áp ở
  bước có ô chữ tự do. Bẫy đã cắn ở `routeHub`: regex không neo bắt oan "trường
  hợp", "tập trung".
- Khớp → bóc từ khoá (bỏ stopword) → query `coach_episodes` + `coach_messages`
  trong cửa sổ 200 dòng gần nhất bằng regex trên `content`. Dùng index
  `{userId, createdAt:-1}` đã có; KHÔNG thêm text index (bắt Mongo trả giá ghi
  trên mỗi tin nhắn, lợi ích chỉ xuất hiện khi user hỏi).
- ≤6 dòng → khối `RECALL` vào đúng prompt đang chạy: không thêm call, không thêm
  lượt. Kèm chỉ thị: không có trong các khối trên thì **nói thật là không nhớ
  rõ** — hỏi về quá khứ là chỗ model bịa nhiều nhất.

## 6. Dọn dẹp

- `findLiveForUser`: lấy 30 dòng theo `lastSeen` rồi xếp trong code theo
  **confidence × hệ số tươi** (nửa đời 60 ngày). Xếp 30 dòng trong code rẻ hơn
  dựng aggregate.
- Cap 60 memory sống/user; vượt → dòng điểm thấp nhất chuyển `inactive`, KHÔNG
  xoá ("không được chỉ lưu summary rồi xoá raw").
- `coach_messages` không xoá dòng nào; thêm index `{userId, sessionId,
  createdAt}` cho watermark.

## Cổng kiểm

- Spec thuần: `buildMemoryCard` (200 rows → thẻ ≤700 ký tự, cắt đúng ưu tiên,
  rỗng → `null` chứ không phải chuỗi rỗng); regex tra cứu (không bắt oan "trường
  hợp"/"tập trung").
- Chạy 1–2 file spec đích, KHÔNG chạy cả suite (RAM máy này).
- `npm run build` trước push (tsc lỏng không phải cổng CI).
- Probe api-dev bằng token ẩn danh: 2 phiên liên tiếp, phiên 2 phải nhắc được
  cảnh phiên 1. Đo `/coach-ai-usage/summary` trước/sau để có số thật.

## ĐÃ LÀM — 2026-09-17 (chưa commit, chưa deploy)

hddhistory-api:
- `memory/coach-memory-card.ts` + spec (9 test): `buildMemoryCard` thuần cap 700
  ký tự, 5 khối (NGƯỜI · ĐANG MUỐN · CẢNH GẦN ĐÂY · ĐÃ LÀM ĐƯỢC · CÓ THỂ HAY),
  cắt từ dưới lên theo dòng; `freshnessScore`/`rankByFreshness` (nửa đời 60
  ngày); `splitForCard`.
  - Khối "ĐÃ LÀM ĐƯỢC" thêm vào so với design: `contextFor` cũ có đọc
    `coach_progress`, thẻ 4 khối ban đầu đánh rơi nó.
- `memory/coach-memory-recall.ts` + spec (6 test): regex hai mức (MẠNH tự đủ /
  YẾU cần dấu hỏi), neo `[^\p{L}]` chứ không `\b`; `recallKeywords`.
- `coach_memory_cards` (schema + repo + `ICoachMemoryCard`), vào module memory.
- `CoachMemoryService`: cô đọng TĂNG DẦN (`since`/`final`, trả vạch), `rebuildCard`,
  `cardFor`, `greetingTopicFor`, `markGreetingUsed`, `recallFor`, `retireOverCap`.
  `contextFor` xoá (dead sau khi thẻ thay chỗ).
- Vạch đọc-tới: `coach_sessions.memoryExtractedAt` + `extractMemoryFrom` ở session
  service (đọc lại vạch từ DB, không tin bản `session` trong tay).
- `findForSessionAfter` trả `{lines, alreadyRead}`; prompt cô đọng TÁCH hai đoạn
  ("đã đọc rồi, đừng tính là bằng chứng mới"), và cửa sổ chỉ có dòng cũ thì
  KHÔNG gọi Gemini.
- Prompt: `cardBlock` + `recallBlock`, vào story-talk · reflect · lesson-talk ·
  closing-line. `priorBlock` còn 6 dòng (`PRIOR_TAIL_LINES`) và chỉ query trong
  `runStoryTalk`. Spec `coach-prompt-context.spec.ts` +7 test khoá việc này.
- `greetingTopic` gộp vào `MEMORY_EXTRACTION_RESPONSE_SCHEMA` (0 call thêm),
  cắt ≤80 ký tự ở adapter.
- Câu chào: `COACH_PROMPT_KEY_HUB_BACK`, chỉ cửa HOME + bước HUB + phiên MỚI,
  song song `historyFor` nên không thêm round-trip vào `open`.

hddhistory-flutter:
- `promptHubBack` trong 5 YAML + `dart run slang`; case mới trong
  `coach_prompt_map.dart`.
- `topic` vào `protect:` của `_addressVi` — nó là CONTENT, để nguyên không thì
  một "bạn" trong câu người ta kể bị đổi thành tên người ta.
- Doc của `coachPrompt` sửa lại: "never the model's words" giờ có đúng một
  ngoại lệ, kèm lý do.

Cổng đã qua: `npm run build` sạch; jest 4 file đích (32 test) + adapter
(19 test). KHÔNG chạy cả suite coach — hết RAM máy này.

### THỨ TỰ DEPLOY — Flutter TRƯỚC, api SAU

Ngược quy tắc thường lệ của repo. `coach_prompt_map.dart` là switch tường minh,
key lạ → trả null → sheet in ra RỖNG. Nên nếu api lên trước, người mở Home sẽ
thấy bộ chip hub mà KHÔNG có câu hỏi nào. Không có header build/version nào tới
được api (`minAppBuild` của deeplink nói về link, không dùng được ở đây), nên
không chặn được bằng code — chỉ bằng thứ tự.

### Chưa làm
- `buildSituationPrompt` không nhận thẻ (lý do ở mục 3). Muốn làm thì phải đánh
  dấu row `personal: true` để cảnh không vào pool dùng chung.
- Admin đọc thẻ/memory của một user (plan v3 cũng đã xếp "sau").
- zh/ja/ko chưa có regex tra cứu — rơi về thẻ nhớ, mất chữ nguyên văn.
- Chưa probe trên api-dev, chưa đo `/coach-ai-usage/summary` trước/sau.
