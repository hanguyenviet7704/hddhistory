# Community bot — persona đóng vai user thật — 2026-09-21

Bot sinh hội thoại trong Community dưới danh nghĩa **tài khoản người dùng bình
thường**, không phải "Đội ngũ HDDhistory". Mục tiêu: phòng chat và feed không trống,
và bài của người thật không rơi vào im lặng.

Đường ghi của admin hiện nay (`sendOfficial`, `createOfficial`) đóng dấu
`authorType: OFFICIAL` → app vẽ badge team. Thiết kế này thêm một đường ghi song
song, `authorType: USER`, tác giả là một tài khoản thật có cờ `isBot`.

## Quyết định đã chốt

| Chủ đề | Quyết định |
|--------|-----------|
| Danh tính | Persona = document trong `users` + cờ mới `isBot: true`. `authorType` ghi là `USER` → `CommunityAuthorService.pick` tra tên/avatar như mọi người khác |
| Flutter | **Không sửa một dòng nào.** Đó là lý do chọn hướng trên |
| Nội dung | Gemini sinh, theo mô tả tính cách persona + ngữ cảnh phòng/bài |
| Nhịp | Theo **khung giờ cố định trong ngày**, tính theo **múi giờ của từng phòng** |
| Phạm vi | Cả ba: tin nhắn phòng chat · bài đăng mới · bình luận vào bài của người thật. Không có thả tim |
| Đăng | Sinh xong **vào hàng đợi** với `dueAt` rải ngẫu nhiên, cron mỗi phút mới đẩy ra. Admin sửa/xoá được dòng chưa đăng |
| Cấu hình | Một document singleton + trang admin `/community/bot` |
| Môi trường | Lên dev trước, đọc thử câu Gemini sinh; prod sau, cờ tổng mặc định OFF |
| Gỡ | Mọi row bot mang `botRunId` (không trả ra DTO) → xoá sạch một đợt bằng một lệnh |

Cố ý **không** làm: bot thả tim/like (số đếm giả không mua được gì); bot trả lời
tức thời qua socket (đã chốt nhịp theo khung giờ); persona học từ hội thoại cũ;
bot viết ngoài locale của phòng.

## Rủi ro phải ghi vào spec

Bot đội lốt người thật, nếu lộ, mất niềm tin nặng hơn phần lợi nó mang lại —
nặng nhất ở nhánh **bình luận vào bài cá nhân**, vì nó bắn notification
"có người trả lời bạn" cho một người đang chờ người thật. Vì vậy:

- `botRunId` là bắt buộc trên mọi row, để gỡ sạch bất cứ lúc nào.
- Persona bị cấm tuyệt đối (ở prompt **và** ở tầng ghi): tự nhận là nhân viên
  HDDhistory, hứa hẹn, hỏi thông tin cá nhân, khuyên về y tế / thuốc / tài chính.
- Ngữ cảnh chạm chủ đề nhạy cảm → bỏ cả cụm, ghi log cho admin, bot im lặng.

## Data model (MongoDB, prefix `community_`)

### `community_bot_configs` — singleton, giống `community_official_profiles`

```
enabled: boolean                      // cờ tổng, mặc định false
geminiModel?: string                  // rỗng = lấy GEMINI_MODEL của env
personas: [{
  userId: string                      // trỏ vào users._id (isBot = true)
  persona: string                     // mô tả tính cách, ~2-4 câu, vào thẳng prompt
  locales: string[]                   // rỗng = mọi locale
  enabled: boolean
}]
chat: {
  enabled: boolean
  roomIds: string[]                   // rỗng = mọi phòng đang VISIBLE
  slots: [{ hour, minute, turnsMin, turnsMax }]
}
post: {
  enabled: boolean
  topicIds: string[]
  slots: [{ hour, minute, turnsMin, turnsMax }]   // turns = số bài
  maxPerDay: number
}
comment: {
  enabled: boolean
  slots: [{ hour, minute, turnsMin, turnsMax }]
  lookbackHours: number               // chỉ ngó bài đăng trong X giờ qua
  onlyWhenNoComment: boolean          // mặc định true
  maxPerDay: number
}
safety: {
  maxChars: number                    // mặc định 300
  blockedKeywords: string[]           // seed sẵn danh sách tiếng Việt + Anh
}
```

### `community_bot_queue` — dòng đã sinh, chờ đăng

```
runId: string                         // một lần sinh = một runId
slotKey: string                       // unique, xem "Chống sinh trùng"
kind: 'CHAT' | 'POST' | 'COMMENT'
personaUserId: string
roomId?: string                       // CHAT
postId?: string                       // COMMENT
topicId?: string                      // POST
subject?: string                      // POST
body: string
replyToId?: string                    // CHAT: id tin nhắn trong cùng phòng
locale: string
dueAt: Date
status: 'PENDING' | 'SENT' | 'CANCELLED' | 'FAILED'
error?: string
resultId?: string                     // id của message/post/comment đã ghi
```

Index: `{ status: 1, dueAt: 1 }` (cron đọc), `{ slotKey: 1 }` unique,
`{ runId: 1 }` (xem một đợt), `{ createdAt: -1 }` (trang admin).

### Sửa schema có sẵn

| Schema | Thêm | Lý do |
|--------|------|------|
| `users` | `isBot: boolean` (default false) | phân biệt persona với người thật ở mọi truy vấn thống kê |
| `community_chat_rooms` | `timezone: string` (default `Asia/Ho_Chi_Minh`) | khung giờ tính theo phòng |
| `community_chat_messages` | `botRunId?: string` | gỡ sạch một đợt |
| `community_posts` | `botRunId?: string` | nt |
| `community_comments` | `botRunId?: string` | nt |

Mongo không có migration — mọi field trên đều additive, row cũ đọc ra `undefined`
và được coi là "không phải bot". `botRunId` **không** xuất hiện trong bất kỳ DTO
trả về app nào.

### Phải loại `isBot` ra khỏi 4 chỗ

Rà và loại trong lúc làm, mỗi chỗ một dòng filter:

1. Dashboard admin — số user, user mới theo ngày.
2. `segment` — mọi tiêu chí đếm user.
3. `NotificationDispatchService` — vòng quét user để bắn push (persona không có
   device token nên không gửi nhầm, nhưng đang tốn một vòng lặp và làm sai số
   "đã gửi").
4. `analytics` / `user_events` — persona không phát event, nhưng mẫu số
   "số user hoạt động" đọc từ `users` thì phải trừ.

## Ba đường ghi

Mỗi đường nằm **cạnh** đường của người thật trong chính service đó, không nhân
bản logic fan-out:

### `CommunityChatService.sendAsPersona(roomId, personaUserId, dto, runId)`

Sao nhịp của [`send()`](../../src/modules/community/src/modules/chat/community-chat.service.ts):
`messageRepository.create` với `authorType: USER` + `botRunId`, rồi
`roomRepository.bumpMessageCount` + `membershipRepository.touch`.

Bỏ hai gate: `sanctionService.assertCanWrite` (persona không phải thành viên bị
kiểm duyệt) và `assertWithinRate` (trần chống spam dành cho người thật; nhịp của
bot do scheduler quyết, và hàng đợi đã rải thưa hơn trần đó).

Giữ nguyên kiểm tra `replyToId` phải thuộc cùng phòng.

### `CommunityPostService.createAsPersona(...)`

`authorType: USER`, `locale` lấy từ persona/topic, `images: []`,
không `attachedCourseId`/`attachedCard`. Bỏ `assertCanWrite`.

### `CommunityCommentService.createAsPersona(...)`

`authorType: USER`, đi qua `notifyForNewComment` **có sẵn** → chủ bài nhận
notification thật. Đây là nhánh rủi ro nhất, nên thêm hai chặn ở tầng gọi:
không comment vào bài `ANONYMOUS`, và không comment vào bài của một persona khác.

## Sinh nội dung (Gemini)

`CommunityBotAiService` riêng trong module bot — **không** dùng lại
`GeminiCoachService` (prompt của nó là prompt coach, và số đo của nó đổ vào
`coach-ai-usage`). Copy hình dạng lời gọi: `API_BASE` v1beta, header
`x-goog-api-key`, `responseMimeType: application/json`,
`thinkingConfig.thinkingLevel: 'low'`, timeout, 503 → thử model dự phòng.

Model mặc định: `config.geminiModel` → `GEMINI_MODEL` của env →
`gemini-flash-lite-latest`. Hội thoại mồi không cần model lớn.

**Một lần gọi cho cả cụm**, không phải mỗi câu một lần. Input:

- tên + mô tả phòng (hoặc chủ đề, với nhánh post)
- `community_chat_guides` theo locale: `intro`, `dos`, `donts`, `starters`
- 15 tin nhắn gần nhất, kèm tên tác giả và **đánh dấu ai là người thật**
- mô tả tính cách của các persona tham gia
- số lượt cần sinh

**Chọn persona cho một cụm:** lấy các persona đang bật có `locales` rỗng hoặc
chứa locale của phòng/bài, xáo ngẫu nhiên, lấy 2–3 cái. Cụm nào cũng phải có ít
nhất 2 persona thì hội thoại mới ra hội thoại; chỉ còn 1 persona hợp lệ thì nhánh
CHAT bỏ slot đó (POST và COMMENT vẫn chạy với 1).

Output JSON: `[{ personaIndex, body, replyToIndex? }]`. Vì tin của người thật nằm
sẵn trong ngữ cảnh nên **"mồi chuyện" và "đáp lời người thật" là cùng một cơ
chế** — đúng với nhịp theo khung giờ.

Nhánh COMMENT: input là bài viết (subject + body + locale) + 5 comment hiện có;
output 1–2 comment.

## Hàng đợi và scheduler

`CommunityBotScheduler`, `@Cron('* * * * *')`, copy pattern của
[`notification.scheduler.ts`](../../src/modules/notification/notification.scheduler.ts):
cờ `isRunning` chặn tick chồng, đếm tick, giữ `lastError`/`lastTickAt` trong bộ
nhớ, phơi qua `GET /community/admin/bot/status`.

Mỗi tick làm hai việc, hai `try` riêng (một cái hỏng không kéo cái kia):

1. **Lập kế hoạch** — với mỗi phòng/nhánh đang bật, đổi giờ UTC hiện tại sang giờ
   địa phương của phòng (`Intl`, như `NotificationDispatchService.zoneClocks`);
   trùng một slot → gọi Gemini, ghi N dòng vào hàng đợi với
   `dueAt = now + rand(1..6 phút)` cộng dồn.
2. **Đẩy dòng tới hạn** — `status: PENDING` và `dueAt <= now`, mỗi dòng gọi đúng
   một `*AsPersona` tương ứng, đặt `status: SENT` + `resultId`. Lỗi → `FAILED` +
   `error`, không thử lại (câu đã lỡ nhịp thì không còn hợp ngữ cảnh).

**Chống sinh trùng:** `slotKey = <kind>:<roomId|postId|topicId>:<ngày địa
phương>:<hh:mm>:<seq>` với unique index, `seq` là thứ tự dòng trong cụm (0..N-1). Một tick chạy hai lần, hoặc hai container
cùng chạy cron, thì lần thứ hai đụng duplicate key và bỏ qua — không cần khoá
phân tán.

**Dòng chờ gặp tình huống mới:** người thật nói xen vào lúc đang chờ → dòng vẫn
đăng (nó chỉ là một câu trong phòng). Nhưng dòng `replyToId` trỏ vào tin đã bị
ẩn/xoá, hoặc `postId` của bài đã bị ẩn → `CANCELLED`.

## Chốt chặn ở tầng ghi

Không tin prompt. Trước khi ghi, mỗi dòng phải qua `sanitize()` (helper thuần,
có spec riêng):

- cắt/loại nếu dài hơn `safety.maxChars`
- bỏ URL, bỏ `@mention`, bỏ số điện thoại/email
- trùng (chuẩn hoá hoa thường + bỏ dấu câu) với 50 dòng gần nhất của phòng → bỏ
- chạm `safety.blockedKeywords` → bỏ **cả cụm**, ghi log, không đăng dòng nào

Ngữ cảnh đầu vào cũng bị soi: nếu 15 tin gần nhất chạm từ khoá cấm thì không gọi
Gemini cho slot đó. Luật từ khoá đơn giản, **không** gọi thêm một model phân loại
— coach có bộ phân loại rủi ro riêng nhưng nó thuộc ngữ cảnh 1-1, không bê sang.

## API (module `community/src/modules/bot/`)

| Route | Việc |
|-------|------|
| `GET /community/admin/bot/config` | đọc cấu hình |
| `PUT /community/admin/bot/config` | ghi cấu hình (allow-list field, như `CoachConfigService.update`) |
| `GET /community/admin/bot/personas` | danh sách persona kèm tên/avatar tra từ `users` |
| `POST /community/admin/bot/personas` | tạo tài khoản persona mới (name, avatar, locale) — ghi `users` với `isBot: true`, password ngẫu nhiên, `status: ACTIVE` |
| `POST /community/admin/bot/personas/link` | gắn một tài khoản có sẵn (tìm theo email) làm persona |
| `GET /community/admin/bot/queue` | hàng đợi, lọc theo status/kind/runId |
| `PATCH /community/admin/bot/queue/:id` | sửa `body` hoặc `dueAt` của dòng PENDING |
| `DELETE /community/admin/bot/queue/:id` | huỷ một dòng PENDING |
| `POST /community/admin/bot/run` | **chạy thử ngay**: sinh một cụm cho phòng/bài chỉ định, `dueAt = now` |
| `DELETE /community/admin/bot/runs/:runId` | gỡ sạch một đợt: ẩn mọi message/post/comment mang `botRunId` đó |
| `GET /community/admin/bot/status` | tình trạng cron trong process này |

Không có route nào cho app — app không biết bot tồn tại.

Layering: controller chỉ định tuyến; `CommunityBotService` điều phối và gọi
`CommunityChatService` / `CommunityPostService` / `CommunityCommentService`;
chỉ repository chạm database.

## Admin (`hddhistory-admin`)

Trang mới `src/pages/community/CommunityBotPage.tsx`, service
`src/services/communityBotService.ts`, đăng ký route trong `src/routes/index.tsx`
dưới `ProtectedRoute` + thêm mục menu trong nhóm Community.

Bốn tab:

1. **Persona** — bảng persona (avatar, tên, mô tả tính cách, locale, bật/tắt),
   nút tạo tài khoản mới (upload avatar qua R2 như các trang khác) và nút gắn tài
   khoản có sẵn.
2. **Lịch & phạm vi** — cờ tổng, model, ba khối chat/post/comment với khung giờ
   (giờ:phút, số lượt min–max), chọn phòng/chủ đề, hạn mức ngày.
3. **Hàng đợi** — dòng chờ (sửa chữ, dời giờ, huỷ), dòng đã đăng kèm link, dòng
   lỗi kèm nguyên nhân; nút "chạy thử ngay"; nút "gỡ đợt này".
4. **Chốt chặn** — `maxChars`, danh sách từ khoá cấm.

Deploy **api trước admin**: `whitelist: true` không kèm `forbidNonWhitelisted`
nên field cấu hình mới gửi lên API chưa deploy sẽ bị xoá âm thầm mà vẫn báo lưu
thành công.

## Test

Repo chạy jest với ~32 spec cho helper thuần và service mock repository. Thêm:

- `community-bot-sanitize.helper.spec.ts` — độ dài, URL, mention, trùng lặp, từ
  khoá cấm (bỏ cả cụm chứ không bỏ một dòng).
- `community-bot-slot.helper.spec.ts` — đổi giờ UTC sang giờ phòng, khớp slot,
  sinh `slotKey`, các múi giờ lẻ `:30`/`:45`.
- `community-bot.service.spec.ts` — mock AI + repository: cụm sinh ra đủ N dòng,
  `dueAt` tăng dần, dòng chạm từ khoá cấm không ghi gì.

Không chạy cả suite trên máy này (hết RAM) — chạy đúng file:
`npm test -- src/modules/community/src/modules/bot/<file>.spec.ts`.
Cổng thật trước khi push vẫn là `npm run build`.

## Thứ tự làm

1. **api nền** — `isBot`, `timezone`, `botRunId`, config + queue schema/repository,
   `sanitize`/`slot` helper + spec.
2. **api sinh + đẩy** — `CommunityBotAiService`, `CommunityBotService`,
   scheduler, ba đường `*AsPersona`, controller admin.
3. **api dọn số liệu** — loại `isBot` khỏi 4 chỗ đã liệt kê.
4. **admin** — service + trang 4 tab + route + menu.
5. **dev** — tạo 3–5 persona, bật một phòng, bấm "chạy thử ngay", đọc câu Gemini
   sinh ra rồi mới chỉnh prompt.
6. **prod** — deploy với `enabled: false`, bật tay khi đã ưng chất lượng câu.

Flutter: không có việc.
