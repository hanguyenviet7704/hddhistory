# AI Coach v2

Ngày: 2026-08-24 · Stack: `hddhistory-api` + `hddhistory-admin` + `hddhistory-flutter`
Nguồn design: `HDDhistory - AI Coach v2.html` (Claude Design), artboard `AI Coach v2`,
kế thừa `13 · AI Coach Flow` (bản v1).

Coach không phải một tab, không phải một màn hình, không phải một mục trong menu.
Nó là **một bong bóng phủ lên đúng những màn app đang có**, mở ra một sheet hội
thoại ngắn, rồi đóng lại. Không thêm nav, không đổi layout, không thêm mục vào
Habit detail.

Việc nó làm, gói trong một câu: giúp người học biến điều vừa học thành **một
nhắc hẹn nhỏ ngoài đời** ("khi họp nhóm — nói ra ý mình"), rồi vài hôm sau hỏi
lại xem có dịp nào chưa. Thứ duy nhất được tính là "đã làm thật" là **câu chính
người đó kể lại**.

## Quyết định sản phẩm (chốt 2026-08-24)

| Câu hỏi | Chốt |
|---|---|
| Coach là LLM hay cây kịch bản | **Cây bước cố định ở server, LLM chỉ điền lời.** NestJS giữ state machine và mọi lệnh ghi DB. LLM không bao giờ tự tạo `NhacHen`, `CauKe`, hay chọn một habit không có thật. |
| Gọi LLM thế nào | **Gemini gọi thẳng từ NestJS**, đúng khuôn `LessonGenerator` của `learning-import` — raw `fetch`, structured output, abstract class che provider. **Không** dựng service Python riêng. |
| Vì sao không tách service riêng | Coach đọc/ghi liên tục vào chính bảng của hddhistory-api (`coach_plans`, `user_habits`, `habits`, `courses`). Tách ra thì service đó phải gọi ngược API hoặc share DB. Và ba luật xương sống đều là **luật dữ liệu**, phải nằm cạnh repository chứ không sau một network hop. |
| Transport | **REST turn-by-turn, không socket.** Lời Coach dài 1–2 câu; stream 15 chữ là vô nghĩa. State machine ở server nên mỗi lượt phải round-trip sẵn rồi. |
| `TinhHuongNgan` từ đâu ra | **Sinh lúc chạy + cache** theo `(habitId, locale, variant)`. Không authoring tay, không hàng đợi duyệt. Admin chỉ cần sửa/xoá cái cache dở. |
| Phạm vi lát đầu | **Đủ cả 8 kịch bản.** |
| Mood lưu ở đâu | Bảng riêng `user_day_logs` ở hạt **user + ngày**. Không merge vào `habit_checkins.mood` (khác hạt: cái kia gắn với một practice JOURNAL của một habit cụ thể). |
| ⑥ lối thoát 20 giây có lưu dòng ghi không | **Có lưu.** Prototype để Coach nói "Đã ghi." mà không ghi bảng nào — mâu thuẫn, đã giải theo hướng lưu. |
| ③C chuyện kể tự do có lưu không | **Không.** Phiên đóng là mất. Đúng như prototype. |
| Lời Coach có lưu không | **Không** — và được thực thi bằng TTL index chứ không bằng kỷ luật code. |
| ④ push đặt giờ | User tự chọn, dùng lại hạ tầng `notification` đang có. **Không** dựng lại local schedule đã gỡ. |
| Safety ⑧ | Fast-path keyword 5 locale (local, luôn chạy) + classifier LLM **chạy song song** call chính. Không hardcode 115 — hotline theo locale/country, cấu hình admin. |

## Trục xoay của thiết kế: server cầm vô lăng, LLM chỉ nói

Thiết kế gốc có bảy luật, và cả bảy đều là luật **dữ liệu**, không phải luật hội
thoại:

1. Bong bóng chỉ có chấm ở Home khi có Nhắc hẹn đang chờ. Không tự bung.
2. Mood hỏi bằng 3 mức chữ, một chạm, đầu và cuối phiên.
3. Lời Coach không lưu. Chỉ chữ của user mới vào bảng.
4. `CauKe` là thứ duy nhất tính là đã làm thật ngoài đời.
5. "Có dịp mà chưa làm" không phải thất bại — nhắc hẹn mới luôn nhỏ hơn.
6. Đánh giá Coach chỉ hỏi sau kịch bản Long, bỏ qua 3 lần thì ẩn hẳn.
7. Ba lựa chọn kết thúc luôn ngang hàng nhau.

Một LLM không giữ được luật nào trong bảy luật đó. Nó sẽ giữ được sáu luật trong
mười lượt, và lượt thứ mười một nó sẽ đề xuất course trước hai lựa chọn kia vì
câu chuyện nghe hợp. **Chỉ repository mới giữ được luật.**

Nên kiến trúc là: NestJS chạy state machine, quyết mọi chuyển bước, ghi mọi bảng.
LLM được gọi ở đúng những chỗ cần đọc hiểu lời người ta vừa kể, trả về structured
output, và **server kiểm tra lại trước khi tin**.

Hệ quả rẻ tiền và dễ chịu: hơn nửa số bước là chip/form, **không tốn một token
nào**.

## Tám kịch bản

| # | Tên | Cửa vào |
|---|---|---|
| ① | Cuối mỗi Lesson | chỉ khi vừa add habit mới · 1 tình huống, không mở trò chuyện |
| ② | Chủ động vào Nav Habit | chọn nhân cách + thời lượng → Short / Medium / Long / chỉ tập |
| ③ | Mở màn Home | cây ba tầng: **A** nhắc hẹn · **B** check-in · **C** trò chuyện tự do |
| ④ | Push nhắc hẹn | user tự đặt giờ, max 1/ngày, trùng giờ thì gộp |
| ⑤ | Bản ghi cải thiện | khối nối thêm vào weekly recap thứ 2 |
| ⑥ | Lối thoát 20 giây | "Hôm nay chỉ ghi lại thôi" |
| ⑦ | Kịch bản Long | tách 2 cột: Chuyện đã xảy ra / Vấn đề thật của tôi |
| ⑧ | Đường thoát an toàn | cắt ngang mọi kịch bản, dừng hoàn toàn |

### Cây quyết định cửa vào

Server quyết ngay ở `POST /coach/sessions`:

| Cửa | Guard | Kết quả |
|---|---|---|
| ① lesson | ≥2 nhắc hẹn `pending` → **im lặng**; đã có phiên `entry=lesson` cùng `lessonId` hôm nay → **im lặng** | `mood` → `pickNew` (nếu ≥2 habit mới) → `tellOnce` |
| ② habit | vào từ Habit detail đã neo → bỏ `pickHabit` | `mood` → `pickHabit` → `persona` → `time` |
| ③ home | có plan `pending` → **A**; không, có habit đến hạn → **B**; không → **C** | A: `intent` · B: `checkin` · C: `free` |

Chấm đỏ chỉ bật khi tầng = **A**. Đúng một điều kiện, đúng một nơi.

Ba tầng của ③ là **một khối không tách được**: người chưa có nhắc hẹn nào sẽ rơi
xuống B, chưa có habit đến hạn thì rơi xuống C. Làm nửa cây thì bấm bong bóng
không ra gì.

### Bảng bước

| Loại | Bước | LLM | Ghi bảng |
|---|---|---|---|
| Chip / form | `mood` `pickNew` `pickHabit` `persona` `time` `intent` `checkin` `loop` `plan` `schedule` `moodEnd` `rating` `end` | không | `user_day_logs`, `coach_plans`, `coach_ratings`, `coach_profiles` |
| Text tự do | `tell` `tell2` `twoCols` `tellOnce` `tellOnceA` `tellOnceB` `practiceAnswer` `intentTell` `free` `jot` | **có** | `coach_situation_answers`, `coach_evidence`, `coach_problem_statements`, `user_day_logs` |

⑦ tách-2-cột chỉ tới được qua ② (chọn thời lượng Long). ⑥ và ⑧ cắt ngang mọi bước.

### Một tình huống = ba câu trả lời

`tellOnce` / `tellOnceA` / `tellOnceB` **tự lặp lại chính nó** cho tới khi nhận
đủ `SITUATION_PROBE_ROUNDS = 3` lượt text, rồi mới sang `plan`:

| Lượt | Coach nói gì | Ghi bảng |
|---|---|---|
| 1 | cảnh đã cache (`coach_situations`) | `coach_situation_answers` |
| 2 | công nhận + **một** câu hỏi vào phần cụ thể của câu trả lời | không |
| 3 | công nhận + **một** câu hỏi về cái khó ngoài đời thật | không |
| — | (sau lượt 3) không hỏi gì nữa → `plan` | |

Ba điều bị ràng bởi `coach_sessions.situationRound`: khi nào thôi lặp, có gắn
lại cảnh vào `ui.situation` không, và model nhận chỉ dẫn nào trong ba.

- **Chỉ lượt 1 được ghi** vào `coach_situation_answers`. ĐỔI THAY so hai câu trả
  lời cho *cùng một câu hỏi*; hai lượt đào sâu là về những gì người đọc vừa nói
  nên ghi vào sẽ làm phép so vô nghĩa. Chúng là hội thoại, như `tell`/`tell2`.
- **Cảnh được đẩy vào `session.turns`** như một lượt của Coach — nếu không, hai
  lượt đào sâu đang bảo model khoét vào một câu trả lời cho câu hỏi mà nó không
  nhìn thấy; và mở lại sheet sẽ thấy câu trả lời trôi lơ lửng không có đề bài.
- **Lượt cuối cấm hỏi.** Ngay dòng sau là app hỏi nhắc hẹn, nên câu hỏi ở đây
  chắc chắn không ai trả lời được — đúng lỗi mà thay đổi này sửa.
- `practiceAnswer` **không** nằm trong vòng lặp: người đó bấm "chỉ muốn luyện
  tập", nghĩa của lựa chọn đó là không ai hỏi gì thêm.
- Bước text nào không có câu cố định mà model lại hỏng thì trả
  `coach.fallback.reply` — trước đây là màn hình câm.

### Bước nào cũng phải có câu mở

`COACH_PROMPT_KEY` giờ có thêm `tell`, `free`, `intentTell`. Ba bước này đều được
bước vào **từ một chip** — chip không tốn model call nên không có `reply`, và
chúng cũng không có cảnh để hiện. Thiếu câu cố định thì client không render gì:
người đọc chọn "Dài · thoải mái" xong nhìn một ô nhập trống, nên kịch bản họ vừa
chọn không bao giờ tự giới thiệu. Cùng lỗi ở ③A khi tap "mình làm rồi".

`tell` cũng đổi chỉ dẫn: nhịp 2 của thiết kế là "hỏi lại 1–2 câu", nhưng chỉ dẫn
cũ ghi *"the app asks the next question itself"* — mà app không hỏi. Giờ `tell`
công nhận rồi hỏi lại một câu, **trừ** khi nhánh kế tiếp không cho trả lời (Short
đi thẳng sang nhắc hẹn, đêm khuya + mood thấp nhảy sang hai cột). Nhánh đó dùng
`tellNoFollowUp` và `followUpFollows` được lấy thẳng từ `advance()` chứ không suy
lại luật.

### Habit là ống kính, không phải chữ cấm

Khối habit trong prompt trước đây chỉ có đúng một câu: *"Do not name it unless
the reader does"*. Model đọc ra thành **"chủ đề này cấm động vào"** — nên một
người chọn habit *"Nhìn một việc từ nhiều góc khác nhau"* rồi kể chuyện đi du
lịch thì bị hỏi *"Bạn đã chuẩn bị những gì trước chuyến đi rồi?"*. Mọi câu hỏi
đều về giai thoại, không câu nào về cái habit họ cố ý mở sheet ra để tập.

Giờ khối đó nói thẳng: habit **là mục đích của cuộc nói chuyện**; người ta kể gì
thì việc của Coach là tìm xem habit đó *có hay không xuất hiện* trong đó và hỏi
về chính chỗ ấy. Luật kiểm: **câu hỏi nào đặt với habit khác cũng vẫn hợp thì đó
là câu hỏi sai.** "Không nhắc tên" được giữ lại — nhưng đó là luật văn phong
(không ai muốn một coach cứ đọc tên bài tập), chưa bao giờ là lệnh cấm chủ đề.

Kèm theo, một luật lõi mới: **người đọc hỏi thì phải trả lời**. Họ hỏi "đi du
lịch thì tập habit này thế nào" và nhận lại một câu hỏi ngược — lờ đi một câu
hỏi thẳng là thứ thô lỗ nhất ở đây.

### Nhịp 3: kéo, SỬA, và XOÁ

Sơ đồ ⑨ ghi ba việc trên mỗi dòng: *"tự kéo từng dòng · sửa chữ · xoá dòng
sai"*. Chỉ có việc đầu được làm. Người đọc nhìn một dòng model ghi sai mà không
có cách nào chữa — trong đúng bài tập mà tiền đề là **chữ đó phải là của họ**.

Giờ mỗi dòng có ba cửa: chạm vào chữ để kéo sang cột kia, bút chì để sửa tại
chỗ, dấu × để xoá. Sửa xong mà để trống thì coi như xoá — bắt người ta xoá chữ
rồi còn bấm thêm dấu × là một bước chỉ tồn tại vì code.

Không cần đổi API: `leftLines`/`rightLines` trong DTO vốn nhận mảng tuỳ ý.

Ba thao tác đánh **theo chỉ số**, không theo nội dung: model dựng được hai dòng
chữ giống hệt nhau, và so theo chuỗi thì thao tác lên cả hai.

**Và metric chống áp đặt đang đọc số cũ.** `draftKeptCount` lấy từ
`session.draftLeft` — nhưng thao tác của người đọc tới *trong chính lượt này* và
chỉ được ghi vào session *sau* đó. Nên `proposed === kept` mọi lần, và
`draft_untouched` được đếm cho **mọi cuộc trò chuyện từng diễn ra**: đúng con số
lẽ ra phải kêu lên thì lại luôn kêu. Giờ đọc `dto.leftLines` trước.

### Nhãn trên chip phải đúng với thứ nó giao

| Chip | Hứa | Trước | Giờ |
|---|---|---|---|
| Ngắn | dưới 1 phút | 1 lượt | 1 lượt |
| **Vừa** | **khoảng 3 phút** | **2 lượt (~40 giây)** | **3 lượt** |
| Dài | thoải mái | 5 lượt | 5 lượt |

Medium chạy cùng vòng hỏi lại như Long rồi mới sang nhắc hẹn — không sang hai
cột, đó vẫn là đặc quyền của Long. Đây không phải lấy lại lựa chọn của người
đọc: họ bấm vào một con số và app phải giao đúng con số đã in trên nút. Một lượt
kể rồi một cái form không phải thứ ai hiểu là "khoảng ba phút".

`LONG_BEAT2_MAX_QUESTIONS` đổi tên thành `BEAT2_MAX_QUESTIONS` cho đúng.

### ⑦ nhịp 2 hỏi một HOẶC hai câu — và trần 6 lượt mới chạm tới được

Sơ đồ ghi "hỏi lại **1–2 câu**". Ship con số nhỏ làm kịch bản Long chỉ dài bốn
lượt text — `tell`, `tell2`, `twoCols`, `nextAction` — mà trần là `turnCount >= 6`.
Tại bước `TELL_2`, `session.turnCount` luôn bằng 1, nên `turnsExhausted` **luôn
false**: chốt 4 ("hết lượt là đóng, không thương lượng") đang canh một trần không
gì với tới. Nhịp 2 giờ tự lặp một lần (`LONG_BEAT2_MAX_QUESTIONS = 2`), thành
năm lượt, sáu nếu có `redraft` — trần mới có đường chạm.

Thứ tự kiểm quan trọng: **trần được xét TRƯỚC câu hỏi thứ hai**, để giới hạn
thắng nhịp chứ không phải ngược lại.

`beat2Answers` suy ra từ `turnCount - 1` chứ không thêm cột: chỉ có `tell` đứng
trước `tell2`, nên mọi lượt text sau lượt đầu đều là câu trả lời nhịp 2 nhận.

Short và Medium **không đổi**. Độ dài là thứ duy nhất người đọc tự chọn, nên nó
là thứ duy nhất hệ thống không được lặng lẽ lấy lại.

### Bản nháp hai cột: dựng đúng lượt, và lọc được tiếng Việt

Hai lỗi nằm chồng lên nhau ở nhịp 3.

**Dựng sai lượt.** `runAi` bám vào `step === TELL_2`, nên khi nhịp 2 được cho
hỏi hai câu thì nó dựng nháp ngay ở câu đầu: người đọc bị bảo "kéo dòng nào là
vấn đề thật sang phải" trong khi vẫn đang bị hỏi, không có cột nào trên màn, và
bản nháp bị vứt đi khi bước lặp lại. Nó cũng **chưa bao giờ chạy** ở nhánh đêm
khuya — nhánh đó nhảy thẳng từ `tell` sang hai cột. Giờ điều kiện là *"lượt này
có thật sự tới hai cột không"*, hỏi thẳng `advance()`.

**Lọc xoá sạch tiếng Việt.** `keepOnlyReaderLines` giữ token dài **hơn 4 ký tự**
— một con số tiếng Anh. Tiếng Việt viết mỗi âm tiết một khoảng trắng, nên "ông",
"bán", "xôi", "chè", "béo" đều rớt; hết token thì hàm trả `false` cho mọi dòng.
**Mọi người đọc tiếng Việt đều nhận một bài tập rỗng.** Sàn hạ xuống 2 ký tự, hai
vế được **bỏ dấu** trước khi so (người ta gõ "ong ban xoi che", model viết "ông
bán xôi chè" — cùng một câu), `đ` xử tay vì NFD không tách nó. CJK không có
khoảng trắng nên rơi xuống so theo ký tự.

**Nháp rỗng không còn là ngõ cụt.** Không dòng nào sống sót thì đi thẳng sang
`redraft` — đúng nhánh ⑧ đã có: người đọc tự viết cả hai cột. Một bài tập kéo-thả
không có dòng nào để kéo thì tệ hơn hẳn.

**Bỏ lời dẫn trùng.** `draftTwoCols` không trả `reply` nữa: `coach.prompt.twoCols`
đã nói đúng câu đó bằng 5 ngôn ngữ, gửi cả hai thì người đọc nhận hai câu hướng
dẫn gần như y hệt dán liền nhau.

### ⑦ nhịp 2 — cấm hỏi ý nghĩa, chặn bằng classifier

Sơ đồ ⑦ ghi in hoa cạnh nhịp 2: **"ENFORCE BẰNG CLASSIFIER, không chỉ dặn
prompt"**. Đúng, vì luật đó đã nằm trong prompt sẵn rồi mà vẫn thua.

Sau khi `reflect` sinh lời nhịp 2, một call thứ hai (`classifyQuestion`, model
lite `gemini-flash-lite-latest`, timeout 6s như risk) đọc lại **chính câu vừa
viết** và trả `ok | banned`:

| Cấm | Cho phép |
|---|---|
| điều đó có ý nghĩa gì với bạn | chuyện gì xảy ra, họ nói gì, bạn làm gì |
| bạn học/nhận ra được gì | ai có mặt, bạn sẽ nói gì, bạn sẽ làm gì |
| tại sao bạn nghĩ/phản ứng vậy | câu không hỏi gì cả |
| bạn cảm thấy thế nào | |
| điều đó nói lên gì về con người bạn | |

`banned` → sinh lại **một lần** với chỉ dẫn sửa lỗi. Vẫn `banned` → **bỏ hẳn lời
model** và dùng câu cố định `coach.prompt.tellFollowUp` ("Rồi sau đó thì sao?").
Giữ lại phần công nhận đồng nghĩa với giữ luôn câu hỏi cấm dính vào nó.

Gate **fail open**: classifier lỗi hoặc timeout thì lời đi qua. Một hội thoại
đứng lại tệ hơn một câu hỏi chưa chuẩn — cùng đánh đổi đã ghi ở lớp safety.

Hai counter mới, theo tuần, không gắn user: `banned_question` (bắt được, sinh
lại) và `banned_question_fallback` (sai hai lần, phải dùng câu cố định). Tỉ lệ
tăng nghĩa là chỉ dẫn của nhịp 2 đang thua, cần sửa prompt chứ không phải lo cho
người dùng.

### Nhịp 4 gợi MỘT keypoint

Sơ đồ ghi "gợi **1** keypoint (tối đa 2)". Một là con số gợi, hai chỉ là trần —
mà ship cái trần thì nhịp kết nào cũng thành một danh sách đọc thêm. Một danh
mục đặt ở cuối một cuộc nói chuyện riêng tư đọc như quảng cáo, đúng thứ nhịp đó
không được là. `COACH_KEYPOINT_SUGGESTION_LIMIT = 1`.

### Trần chữ trên nhịp 2 và nhịp 5

Sơ đồ viết thẳng lên nhịp: nhịp 2 **≤30 từ**, nhịp 5 **≤25 từ**. Luật cũ
`SCRIPT_RULES[LONG]` chỉ ghi "at most three sentences" — không chặn gì cả, ba câu
của một model đang ấm áp là tám mươi chữ.

Nhịp 5 còn hai ràng buộc nữa từ sơ đồ: **cấm khen chung chung** ("giỏi lắm",
"làm tốt lắm" và mọi bản dịch — không chỉ được ra một nước đi cụ thể thì thôi
không khen), và góp ý phải là **bước nhỏ cho ngày mai**, không phải một nguyên
lý.

### ③C nghe đủ rồi mới chỉ đường

Sơ đồ vẽ một lượt kể rồi ra course. Một lượt hoá ra là không có gì: *"hôm nay
chị tôi không uống trà sữa"* không phải một con người mà mình hiểu, và mời khoá
học sau câu đó đọc như quảng cáo bắn theo phím gõ.

`free` giờ tự lặp, và **thẻ course chỉ gắn vào lượt đóng lại**:

| Chốt | Ý nghĩa |
|---|---|
| `FREE_TALK_MIN_TURNS = 2` | sớm nhất được đóng, kể cả khi Coach nói đã đủ |
| `FREE_TALK_MAX_TURNS = 3` | trần, không thương lượng — giống trần 6 lượt của Long |
| `enough` | model tự nói đã nghe đủ chưa |

Hai chốt cùng lúc vì mỗi cái một mình đều hỏng: chỉ có `enough` thì model hỏi
một câu xong bảo đủ ngay; chỉ có số lượt cố định thì người mở đầu bằng cả đoạn
văn vẫn bị phỏng vấn thêm hai lần để tới cùng một chỗ.

`enough=false` thì reply phải kết bằng **một câu hỏi** giúp hiểu thêm;
`enough=true` thì cấm hỏi. Ở lượt cuối cùng, `freeTalkLastTurn` được truyền vào
prompt để model biết không còn ô nào phía sau — nếu không lại thêm một câu hỏi
không ai trả lời được nữa.

### ③C: "dù kể chuyện gì, output LUÔN là một link tới một habit"

Đó là phụ đề của chính sơ đồ ③C, và tôi làm ngược: đặt ngưỡng
`confidence >= 0.6` cộng với một prompt nói "null đúng nhiều hơn sai" — nên
output thường xuyên là **không có gì cả**. Người ta kể một chuyện và không nhận
được cánh cửa nào.

Bỏ ngưỡng. `confidence` vẫn được model trả về và vẫn ghi lại, nhưng **không còn
là cửa gác** — id chỉ cần có thật và nằm trong danh sách đã đưa (id bịa thì chỉ
người đọc lãnh, nên vẫn chặn và ghi log). Prompt đổi từ "quyết định xem có khớp
không" thành **"chọn một cái gần nhất"**, kèm nhắc rằng 24 habit này nói về để ý
cảm xúc trước khi phản ứng, tử tế với chính mình, dừng một nhịp, lắng nghe, nhìn
từ góc khác — hầu như chuyện người nào cũng chạm vào một trong số đó.

"Gần nhất, không phải hoàn hảo. Hoàn hảo không có trên bàn, và người đọc không
bị chẩn đoán."

### Bong bóng ③ đọc cả UserHabit

Ô ② ghi **ĐỌC NhacHen + UserHabit**. Code chỉ đọc `NhacHen`. Nên người không có
nhắc hẹn nào nhưng có habit tới hạn check-in lại thấy bong bóng **không chấm** —
tức "chẳng có gì đợi bạn" — rồi mở ra thì rơi vào ③B, đúng là có một check-in
đang đợi.

### Chặn câu chép lại bằng phép đếm, không bằng lời dặn

Luật "đừng đọc ngược lại câu của người ta" nằm ở **hai** chỗ — `CORE_RULES` và
prompt ③C — và cả hai đều thua. Model có ít thứ để nói thì với lấy đúng những
chữ đang trước mặt:

| Người đọc | Coach đáp |
|---|---|
| hôm nay chị tôi không uống trà sữa | **chị tôi không uống trà sữa.** Việc này… |
| Tôi cố làm xong việc rồi mới ngủ. | **Bạn chọn cố làm xong việc rồi mới ngủ.** |
| hôm nay người yêu cũ tôi đi lấy chồng | **Người yêu cũ đi lấy chồng.** |

`looksLikeEcho` trong `coach-text.ts` bỏ dấu cả hai vế rồi đếm: **câu mở đầu** có
≥70% từ (≥2 ký tự) nằm trong lời người đọc thì viết lại một lần với chỉ dẫn sửa
lỗi. Chỉ xét câu mở — trích lại lời họ ở giữa là hợp lệ, mở đầu bằng câu của họ
mới là vẹt. Dưới 4 từ thì không xét: "Nghe nặng." không sao chép của ai cả.

Khác classifier ở nhịp 2: **cái này đếm được** nên không đáng một call và sáu
giây. Đặt trong module thuần để có spec thật — cả ba câu trên đều là test case.

Counter `echoed_reader` theo tuần: tăng nghĩa là prompt đang không gánh nổi luật.

### ③C trả lời như máy đánh chữ, và từ chối khớp quá tay

Kể *"hôm nay người yêu cũ tôi đi lấy chồng"* thì Coach đáp *"Người yêu cũ đi lấy
chồng."* — chép lại nguyên câu. Vì luật trong `buildHabitMatchPrompt` viết đúng
như thế: *"reflecting their situation back in their own terms"*. Model làm đúng
lời dặn; lời dặn sai. Đó là câu tệ nhất có thể nhận sau khi vừa kể một chuyện đau.

Luật viết lại: nói **một điều cho thấy đã nghe được cái giá của nó, bằng chữ của
mình**; cấm chép lại câu của người đọc; cấm khuyên, cấm an ủi kiểu "ít ra thì",
cấm hỏi ngược.

Và bộ đối chiếu bị đè quá nặng về phía `null`: *"Answering null is the correct
answer more often than not, and there is no cost to it."* Có cái giá chứ — nhịp
⑨ không bao giờ chạy. Ngưỡng `confidence ≥ 0.6` giữ nguyên, nhưng bỏ ngón tay
đè lên cân, kèm hai ví dụ về thứ **là khớp chứ không phải cố nhét**: habit về
gọi tên cảm xúc trước khi phản ứng hợp với một buổi tối làm người ta chao đảo;
habit về đối xử tử tế với chính mình hợp với ngày người ta đang tự dằn vặt.

`STEP_INSTRUCTION.free` bị gỡ: ③C không bao giờ tới `reflect`, nên dòng đó chưa
từng chạy và chỉ dụ người sau sửa nhầm chỗ.

### ③C không hỏi nhắc hẹn

Sơ đồ ③C chạy: kể tự do → đối chiếu ngầm → phản chiếu (kèm **tối đa một** course)
→ mood cuối phiên → ba lựa chọn → kết thúc. **Không có nút nhắc hẹn nào trên
đó.** Tôi từng cho nhánh "khớp habit mình đang tập" đi sang `plan` — biến "kể gì
cũng được" thành thêm một thứ phải cam kết, đúng ngược với việc cửa này tồn tại.

Quyết định có mời course hay không nằm ở service, nơi phép đối chiếu thật sự
diễn ra; graph không cần biết vì hai nhánh kết thúc như nhau. "Có rồi → chỉ phản
chiếu": mời course cho đúng thứ người ta đang tập đọc như app không nghe gì cả.

### Cảnh bám vào habit nào

Cache key `(habitId, locale, variant)` — nên cảnh **luôn thuộc về một habit cụ
thể**, và habit đó là của chính người đọc ở mọi cửa:

| Cửa | `habitId` lấy từ |
|---|---|
| ① lesson | habit vừa add trong bài (hoặc `pickNew` nếu có ≥2) |
| ② habit | habit đang mở, hoặc `pickHabit` trong danh sách habit **đang theo** |
| ③A | `habitId` của nhắc hẹn đang `pending` |
| ③B | habit tới hạn check-in |
| ③C | habit khớp được với câu chuyện, trong số habit người đọc đang theo |

`generate_situation` nhận **title + tối đa 3 keypoint (title: description)** của
habit đó (`HABIT_MATERIAL_LIMIT`). Trước đây chỉ có title — mà title là một cái
nhãn: "nói ra ý mình" đặt được vào phòng họp, bữa cơm hay ngã tư đèn đỏ, và model
chọn cái nào tuỳ nó. Keypoint là giáo trình thật của habit nên cảnh mới nằm trong
đúng thế giới người đọc đang học.

Câu hỏi khép cảnh **cấm dùng khuôn**: "bạn sẽ làm gì trong tình huống này" và mọi
bản dịch của nó bị chặn thẳng — nếu câu hỏi vẫn đúng với một cảnh khác thì nó sai.
`CORE_RULES` cấm lặp lại từ ngữ của chính Coach trong cùng phiên, và hai lượt đào
sâu bị ép nhắm hai đích khác nhau (lời cụ thể ↔ cái khó ngoài đời).

Nhân cách **Người bạn** trước đây ghi *"Name what the moment sounded like before
anything else"* — model hiểu đúng nghĩa đen: ba reply liên tiếp mở bằng một âm
thanh bịa ra ("im lặng bao trùm phòng họp", "tiếng thở dài nhẹ", "tiếng thở
phào"), không câu nào người đọc từng nhắc. Vừa phạm luật cấm bịa chi tiết, vừa
làm mọi reply mở giống hệt nhau. Giờ nó mở bằng **chính thứ người đọc đã gọi
tên**, và luật cấm bịa được viết cụ thể: không âm thanh, không khoảng lặng,
không tiếng thở, không nét mặt, không thời tiết, không ngôn ngữ cơ thể.

**Cache không tự làm mới.** Cảnh đã sinh trước thay đổi này vẫn giữ câu hỏi kiểu
cũ; xoá row trong admin `coach-situations` thì người kế tiếp sinh lại.

## API

```
POST /api/v1/coach/sessions            → { sessionId, step, ui }
POST /api/v1/coach/sessions/:id/turns  → { reply, step, ui }
POST /api/v1/coach/sessions/:id/close
GET  /api/v1/coach/bubble              → { visible, dot, teaser }
```

`ui` quyết định composer hiện gì: chips / text+samples / form nhắc hẹn / chọn giờ
/ rating / ba nút kết thúc. **Client không tự suy ra bước tiếp** — server nói.
Đó là cái làm luật 7 ("ba lựa chọn ngang hàng") bất khả xâm phạm: không có bản
sao logic nào ở client để trôi lệch theo thời gian.

## Module

`hddhistory-api/src/modules/coach/`, ngang hàng `habit`, theo lối lồng đệ quy repo đang
dùng:

```
modules/coach/
  coach.module.ts
  src/modules/
    session/     state machine + bước hiện tại (lời Coach KHÔNG lưu)
    plan/        coach_plans (NhacHen + LichNhac nhúng)
    reflection/  coach_evidence, coach_problem_statements, coach_situation_answers
    day-log/     user_day_logs
    situation/   cache coach_situations + generator
    rating/      coach_ratings
    config/      coach_configs (singleton)
    ai/          CoachAi (abstract) + GeminiCoachService
    safety/      fast-path keyword + classifier
```

`ai/` dựng theo đúng khuôn `LessonGenerator`
(`courses/src/modules/learning-import/ai/gemini-lesson-generator.service.ts`):
abstract class che provider, raw `fetch` tới
`https://generativelanguage.googleapis.com/v1beta/models`, structured output qua
JSON response schema. Ngoài thư mục đó không file nào biết tên Gemini. Dùng lại
env đã có: `GEMINI_API_KEY`, `GEMINI_MODEL`, `GEMINI_TIMEOUT_MS`.

## Data model

Chín collection Mongo mới, cộng một config singleton. Theo convention của `habit`
module: `userId` là `string`, kế thừa `AbstractDocument` (`_id`, `createdAt`,
`updatedAt`, `createdBy`, `updatedBy`).

| Collection | Prototype | Nội dung chính | Index |
|---|---|---|---|
| `coach_sessions` | — | `entry`, `step`, `habitId?`, `lessonId?`, `persona?`, `script?`, `planId?`, `pendingIdx`, `turns[]`, `locale`, `tzOffset`, `expiresAt` | `(userId, createdAt)`, **TTL** trên `expiresAt` |
| `coach_profiles` | — | 1 doc/user: `lastPersona`, `ratingSkipCount`, `ratingHidden` | `userId` unique |
| `user_day_logs` | `Mood` + ⑥ | `date` (UTC midnight), `moment: start\|end`, `mood?: 1..3`, `note?`, `sessionId?` | `(userId, date, moment)` |
| `coach_plans` | `NhacHen` + `LichNhac` | `context`, `action` (chữ user), `status: pending\|done\|replaced\|sleeping`, `source`, `habitId`, `lastAskedAt`, `lastAnswer`, `consecutiveNoOccasion`, `reminder: { enabled, hour, days }` | `(userId, status, lastAskedAt)`, `reminder.hour` |
| `coach_evidence` | `CauKe` | `planId`, `content` — **thứ duy nhất tính là đã làm thật** | `(userId, createdAt)`, `planId` |
| `coach_problem_statements` | `CauVanDe` | `sessionId`, `habitId`, `content` | `(userId, createdAt)` |
| `coach_situation_answers` | `TraLoiTinhHuong` | `situationId`, `variant`, `content` | `(userId, situationId, createdAt)` |
| `coach_situations` | `TinhHuongNgan` | cache: `habitId`, `locale`, `variant`, `prompt`, `source: generated\|edited` | `(habitId, locale, variant)` unique |
| `coach_ratings` | `DanhGiaCoach` | `sessionId`, `thumb`, `chips[]`, `needsReview` | `(userId, createdAt)`, `needsReview` |
| `coach_configs` | — | singleton: `enabled`, `hotlines` theo locale/country | — |

### Ba quyết định trong data model

**TTL index là cách thực thi luật "lời Coach không lưu".**
LLM cần ngữ cảnh các lượt trước, nhưng luật cấm lưu lời Coach. Giải bằng hạ tầng
chứ không bằng kỷ luật code: session doc giữ đủ `turns[]` (cả lời Coach) để LLM
có ngữ cảnh, mang `expiresAt` TTL 48h, và **mọi sự thật cần sống lâu đã được ghi
sang bảng riêng ngay lúc phát sinh**. Session bốc hơi thì không mất gì đáng lẽ
phải còn. "Phiên đóng là mất" trở thành thuộc tính của database.

**Không cần bảng cờ.**
`da_hoi_hom_nay` và `coach_da_hien_phien_hoc` đều suy ra được từ `coach_sessions`
("hôm nay đã có phiên `entry=home` chưa", "đã có phiên `entry=lesson` với
`lessonId` này chưa"). TTL 48h thừa cho câu hỏi "hôm nay". Bớt một bảng và một
nguồn sai lệch.

**`LichNhac` nhúng vào `coach_plans`** thay vì tách bảng: 1:1 với nhắc hẹn, luôn
đọc cùng nhau, cron ④ chỉ cần index trên `reminder.hour`. Bớt một join và một
bảng mồ côi khi nhắc hẹn bị đóng.

**`NhanCach` không thành bảng.** Ba persona là enum + slang keys; "giọng dùng lần
trước" là `coach_profiles.lastPersona`.

### Hai bộ đếm thiết kế yêu cầu nhưng prototype không có chỗ chứa

- `coach_plans.consecutiveNoOccasion` — ba lần liên tiếp `lastAnswer = none` thì
  `status → sleeping`, ngừng nhắc. Reset về 0 khi trả lời `done` hoặc `missed`.
- `coach_profiles.ratingSkipCount` — bỏ qua 3 lần thì `ratingHidden = true`.

## Năm LLM task

Mỗi task một structured output riêng, và **mỗi task đều bị server kiểm tra lại**:

| Task | Gọi ở | Output | Server chặn gì |
|---|---|---|---|
| `reflect` | mọi bước kể | `{ reply }` | — chỉ hiện rồi vứt |
| `draft_two_cols` | ⑦ sau `tell2` | `{ reply, lines[] }` | mỗi dòng phải khớp lời user đã nói trong phiên; model bịa thêm → loại dòng đó |
| `match_habit` | ③C `free` | `{ reply, habitId, confidence }` | `habitId` phải nằm trong habit của chính user; ngoài danh sách → coi như không khớp, rơi về nhánh mời course |
| `generate_situation` | cache miss | `{ prompt }` | ghi vào `coach_situations`, lần sau không gọi nữa |
| `classify_risk` | mọi lượt text | `{ risk, level }` | chạy **song song** call chính |

`generate_situation` bám vào dữ liệu thật: `habits.title` (`ITranslation`, 5
locale) + nội dung keypoint qua `habits.keypointIds`. Không bịa từ hư không.

## ⑧ Đường thoát an toàn

Hai lớp, chạy **song song** với call chính chứ không nối tiếp — nối tiếp sẽ cộng
~800ms vào mọi lượt bình thường:

1. **Fast-path keyword**, 5 locale, hoàn toàn local, 0ms. Khớp thì cắt luôn.
2. **Classifier** `gemini-flash-lite` bắn cùng lúc với call chính. Báo nguy cơ thì
   vứt reply chính, trả nhánh ⑧.

Khi vào ⑧: luồng **dừng hoàn toàn**. Không tình huống, không tách 2 cột, không
chốt nhắc hẹn, không đề xuất course, **không ghi bảng nào**.

Số hotline lấy từ `coach_configs.hotlines` theo locale + country. Không hardcode
115 — đó chỉ đúng ở Việt Nam.

## ④ Push nhắc hẹn

Không nhét vào vòng lặp template (vì `NotificationTemplate.localHour` cố định
theo type, còn đây user tự chọn giờ). Thay vào đó `CoachPlanReminderDispatcher`
chạy trong cùng nhịp `@Cron('* * * * *')` của `NotificationScheduler`:

1. `NotificationDispatchService.zonesDueAt(h, m)` → các timezone đang ở giờ đó
2. Query `coach_plans`: `reminder.enabled`, `reminder.hour = h`, `status = pending`,
   weekday khớp `reminder.days`, user thuộc zone due
3. **Gộp**: nhiều plan cùng giờ cùng user → một push duy nhất. Max 1/ngày; phần
   còn lại ghi `NotificationLogStatus.SKIPPED` kèm lý do
4. Nội dung: khung câu per-locale từ `NotificationTemplate` với biến `{{context}}`
   `{{action}}` — chữ user điền vào chỗ trống
5. Deeplink mới `NotificationDeeplink.COACH`, payload `planId`

Thêm `NotificationType.COACH_PLAN_REMINDER` để có template đa locale và có dòng
log — chỉ là **bị loại khỏi vòng lặp template**, `localHour` không dùng tới.

Bỏ qua thì không cộng dồn: mai nhắc lại như mới.

> **Chú ý khi làm**: `NotificationDispatchService.render(template, variables)`
> hiện là `private`. Cần expose hoặc tách ra helper dùng chung — đừng copy.

## ⑤ Khối recap

`WeekRecapDto` thêm một field, `coach: {...} | null`. `null` khi chưa có gì →
Flutter không render slot, **không hiện khối rỗng**. Đây là trạng thái mặc định
trong vài tuần đầu.

| Khối | Nguồn |
|---|---|
| ĐỜI THẬT | `coach_evidence` trong tuần |
| ĐÃ TẬP | phân bố `coach_plans.lastAnswer` (đã làm / lỡ dịp / chưa có dịp) — chỉ tăng, không mũi tên xuống |
| ĐỔI THAY | hai `coach_situation_answers` **cùng `situationId`** cách nhau ≥3 tuần |
| CHỮ CỦA CHÍNH BẠN | `coach_problem_statements` |

ĐỔI THAY chỉ chạy được **vì tình huống có cache** — cùng một `situationId` mới so
sánh được hai câu trả lời cách nhau ba tuần. Nếu chọn "sinh mới mỗi lượt" thì khối
này chết. Hai quyết định ăn khớp vào nhau.

Recap không phải màn mới: nó là slot nối thêm vào poster đã có
(`260820-week-recap`).

## Flutter

`ScaffoldLayout` (`lib/core/utils/layouts/scaffod_layout.dart`) đang có sẵn hai
thứ cần dùng:

1. Chuỗi popup-host (`WeekRecapPopupHost > ImportDonePopupHost > WinBackHost >
   GiftPopupHost > StreakPopupHost`) — **Coach không tham gia chuỗi này**.
2. `ImportProgressToast`: một `Positioned` trong Stack, gate bằng
   `BlocSelector<PageCubit, PageState>`, tránh nav bằng `floatingNavBarHeight(context)`.

Bong bóng Coach là **anh em của `ImportProgressToast`**, không phải host mới.

Đây là chỗ luật "không tự bung" trả cổ tức kỹ thuật chứ không chỉ sản phẩm: vì
bong bóng không tự mở, Coach **không phải tranh `AppOpenModalGate`** với
WeekRecap / Gift / Streak / Home promo lúc cold-start. Một luật sản phẩm vừa xoá
luôn một class bug.

| Cửa | Đặt ở đâu |
|---|---|
| ③ Home | shell Stack, gate `isPrimaryRoute && currentRouteName == home` |
| ② Habit | cùng widget, gate tab Habit — **không** thêm mục vào Habit detail |
| ① Lesson | `lib/src/lesson/presentation/pages/keypoint_complete_page.dart` — sub-route, nav đã ẩn, nên bubble là widget cục bộ trong page đó |

Sheet Coach mở bằng `showModalBottomSheet` full-height. Feature mới
`lib/src/coach/` theo Clean Architecture (`data`/`domain`/`presentation`).
`CoachCubit` **chỉ render `step` + `ui` server trả về** — không có bản sao state
machine nào ở client.

Trạng thái bong bóng lấy từ `GET /coach/bubble`, gọi song song với bootstrap của
Home, cache trong cubit, invalidate khi đóng phiên. Endpoint riêng và cố ý nhỏ —
Home đã từng dính lỗi perf vì gọi lặp.

## Ba nguồn chữ, đừng lẫn

| Nguồn | Chứa gì | Ở đâu |
|---|---|---|
| slang `assets/i18n/<locale>/coach.yaml` × 5 | câu điều hướng cố định, label chip, nút | client |
| LLM | lời Coach sinh theo ngữ cảnh | server, prompt ép đúng `locale` |
| `NotificationTemplate` | copy push ④ với `{{context}}` `{{action}}` | server |

Năm locale đủ: `en`, `vi`, `zh`, `ja`, `ko`. Sau khi sửa YAML chạy `dart run slang`.

## Xử lý lỗi — hai chỗ phải dứt khoát

**LLM chết giữa cuộc trò chuyện.** Coach tuyệt đối không được hiện màn lỗi khi
người ta đang kể chuyện khó nói. Timeout hoặc lỗi → dùng câu trung tính từ slang
("Mình nghe rồi.") và **vẫn chuyển bước bình thường**. Người dùng không biết có
gì hỏng.

**Classifier an toàn chết.** Fail-closed thì mỗi lần Gemini hắt hơi lại quăng
người đang kể chuyện bình thường vào màn hotline — phản tác dụng, và người ta bỏ
Coach. Fail-open thì bỏ lọt.

Chọn **fail-open, nhưng có lưới**: fast-path keyword chạy hoàn toàn local, không
phụ thuộc LLM, nên luôn hoạt động kể cả khi classifier chết. Classifier lỗi thì
ghi log và đếm để cảnh báo. Lưới tối thiểu không bao giờ rơi.

Còn lại:
- Session hết TTL giữa chừng → `410`, app mở phiên mới.
- Mất mạng giữa lượt → giữ input chưa gửi ở client, user gửi lại.

## Admin

| Trang | Việc |
|---|---|
| `coach-situations` (mới) | list theo habit × locale × variant, xem/sửa/xoá cache dở. **Không** có luồng duyệt |
| `coach-ratings` (mới, nhỏ) | hàng đợi `needsReview = true` từ thumb-down |
| `notifications` (có sẵn) | thêm template `COACH_PLAN_REMINDER` |
| `coach-config` (mới, singleton) | bật/tắt Coach, hotline theo locale/country |

`coach_configs` đi đúng pattern `streak-config` / `paywall-config` đã có.

## Chạm vào code có sẵn

Chỉ ba chỗ, đều nhỏ:

1. `courses/.../week-recap/week-recap.service.ts` — `days[].mood` ưu tiên
   `user_day_logs`, rơi về `habit_checkins` khi thiếu (tuần cũ không có
   `user_day_logs` nên tự động giữ nguyên hành vi); thêm `coach` vào `WeekRecapDto`.
2. `notification/notification.enum.ts` — thêm `NotificationDeeplink.COACH` và
   `NotificationType.COACH_PLAN_REMINDER`.
3. `notification/notification-dispatch.service.ts` — expose `render()`.

Phía Flutter: một `Positioned` thêm vào `ScaffoldLayout`, một widget trong
`keypoint_complete_page.dart`, một slot trong poster recap.

## Đã build — khác biệt so với thiết kế trên

Ghi lại ba chỗ hiện thực đi lệch khỏi bản thiết kế, và vì sao.

**`sendDirect` thay vì chỉ expose `render()`.** Thiết kế nói mở `render()` ra dùng
chung. Khi làm mới thấy ④ còn cần cả daily-cap, `claimSlot` nguyên tử (thứ khiến
double-send là bất khả), gọi Firebase, prune dead token và ghi dòng log — tức là
toàn bộ `dispatchToUser` trừ phần "ai, lúc nào". Nên `NotificationDispatchService`
mở ra **một** method `sendDirect` gói trọn phần đó, và `CoachPlanReminderDispatcher`
chỉ quyết định ai và lúc nào. Ít bề mặt hơn, và không có nhánh nào để trôi.

**Prompt key giải bằng switch tường minh, không bật slang `flat_map`.** Tra key
động sẽ làm mọi câu điều hướng chỉ phân giải được lúc chạy: một key server bắt đầu
gửi mà app chưa thêm sẽ thành **dòng trắng** trước mặt người đang kể chuyện. Với
`coachPrompt()` nó là một lỗ hổng nhìn thấy được trong một file.

**Admin có thêm hai endpoint.** `coach-situations` (list/sửa/xoá) và `coach-ratings`
(hàng đợi + đánh dấu đã đọc) — thiết kế có nhắc tới trang admin nhưng chưa liệt kê
route, giờ có.

## Kiểm chứng & rollout

**Không chạy full test suite trên máy dev** (jest và `flutter test` ăn hết RAM).

- **API**: spec cho chuyển bước state machine — 28 test, phủ cả bảy luật. Rồi
  `npx tsc --noEmit` **và** `npm run build` (`tsconfig.build.json` bật `strict`,
  `tsc` thường không bắt — nó đã bắt đúng một lỗi `TS7018` mà `tsc` bỏ qua).
- **DI**: `@nestjs/testing` KHÔNG có trong deps nên không boot được graph thật, và
  thêm dependency là quyết định riêng. Thay bằng kiểm tra tĩnh 88 module: mọi module
  có controller gắn `AuthGuard` đều import `AuthModule`, và không vòng import nào
  thiếu `forwardRef`. Script ở `scratchpad/check-di.js`; đáng chuyển vào repo nếu
  muốn giữ.
- **Flutter**: `flutter analyze` + sim-test cho sheet.

Thứ tự: **API → admin → Flutter**. Admin trước Flutter để có chỗ sửa tình huống
dở trước khi người dùng thật gặp.

`coach_configs.enabled` cho phép tắt không cần deploy.

## Cố ý KHÔNG làm

- Không bảng `NhanCach` — enum + slang là đủ.
- Không bảng cờ — suy ra từ `coach_sessions`.
- Không tách `LichNhac` — nhúng vào `coach_plans`.
- Không WebSocket — lời Coach quá ngắn để stream có nghĩa.
- Không service Python — Coach sống cạnh dữ liệu của nó.
- Không luồng duyệt tình huống — cache write-through, admin sửa khi gặp cái dở.
- Không thêm nav, không thêm mục vào Habit detail, không đổi layout màn nào.

## Mâu thuẫn trong thiết kế gốc, đã giải

| Chỗ | Vấn đề | Giải |
|---|---|---|
| ⑥ lối thoát | Coach nói "Đã ghi." nhưng cột Dữ liệu không ghi bảng nào | **Lưu** vào `user_day_logs.note`. Luật của chính thiết kế là "chỉ chữ user mới vào bảng" |
| ④ push | Đi ngược quyết định đã gỡ habit reminders local | Dùng lại hạ tầng `notification` server-side, không dựng local schedule mới |
| Mood | `habit_checkins.mood` đã tồn tại 1..3, và `WeekRecapDto.days[].mood` đã đọc nó | Khác hạt → bảng riêng ở hạt user+ngày, recap ưu tiên nguồn mới, rơi về nguồn cũ |
| Hotline | `RISK` hardcoded 6 từ tiếng Việt, số 115 | Classifier LLM 5 locale + hotline cấu hình theo country |

---

# Chỉnh lại theo luồng chốt — `AI Coach.html` (2026-08-25)

Người dùng đưa bản design hợp nhất (`AI Coach.html`, export 2026-08-25) và chốt:
**luồng trong file này là chuẩn**. Bản này quay về kịch bản v1 ở những chỗ v2 đã
tự nới rộng, và thêm nhân vật "Cục slime". Các mở rộng v2 dưới đây bị **thu hồi**
— lý do cũ vẫn đọc được ở git history, nhưng luồng phải theo bản vẽ:

| Chỗ | v2 (thu hồi) | Theo design |
|---|---|---|
| Tình huống ngắn (①/③A/③B) | 3 lượt (1 trả lời + 2 đào sâu) | **1 câu trả lời → nhắc hẹn** (`SITUATION_PROBE_ROUNDS = 1`; máy móc vòng lặp giữ nguyên sau hằng số) |
| Nhịp 2 (`tell2`) | hỏi 2 câu | **hỏi đúng 1 câu** (`BEAT2_MAX_QUESTIONS = 1`) |
| Long sau 2 cột | nextAction → closing → plan | **2 cột → plan** — câu "vấn đề thật của tôi là…" là lời cuối trước nhắc hẹn. `NEXT_ACTION`/`CLOSING` không còn mũi tên nào tới (enum + UI giữ cho session cũ còn render được) |
| ③C trò chuyện tự do | 2–3 lượt, luôn về moodEnd | **1 câu chuyện** → trùng habit ĐANG TẬP → `plan` gắn habit đó; không thì mời course → moodEnd. `matchedOwnedHabitId` đi từ match về máy trạng thái, session nhận habit |
| Mood | 5 mức | **3 mức chữ, 1 chạm** (`COACH_MOOD_MAX = 3`, low = [1]); dòng cũ 4/5 vẫn đọc được |
| Chấm đỏ bong bóng | sáng cả khi có habit đến hạn (mọi user có habit → chấm vĩnh viễn) | **chỉ khi có Nhắc hẹn chờ** — luật số 1 |

Sửa thêm hai chỗ ① chưa từng chạy đúng:
- **Cửa ① giờ có guard "vừa thêm habit"**: không có habit thêm hôm nay →
  im lặng (`coach.silent.noNewHabit`). Trước đó bong bóng hiện ở mọi cuối lesson
  và phiên chạy với `habitId = null` (không có cảnh nào sinh được).
- **`PICK_NEW` lần đầu với tới được**: `hasMultipleNewHabits` trước đây hardcode
  `false` ở cả open lẫn turn. Giờ đọc `user_habits` thêm từ 0h (giờ máy người
  dùng), đóng băng vào `session.newHabitIds`; 1 habit → gán thẳng, ≥2 → hỏi
  "nói về cái nào trước?" với chip từ danh sách đóng băng đó.

Nhân vật: `CoachSlime` (hddhistory-flutter) — 7 trạng thái buộc theo bước, một Ticker
+ CustomPainter; thay mặt tròn tĩnh ở bong bóng nổi và header sheet.

Chưa verify trên máy: cần deploy api-dev + build lại app. Spec máy trạng thái đã
cập nhật theo đồ thị mới (49 test pass).

## Cảnh theo người đọc (2026-08-25, sau chỉnh luồng)

Yêu cầu: câu hỏi tình huống phải dựa vào độ tuổi và những gì user chọn ở
onboarding. Ràng buộc cứng: ⑤ ĐỔI THAY so hai câu trả lời cho CÙNG một cảnh
cách nhau nhiều tuần, nên cá nhân hoá phải nằm trong KHOÁ CACHE chứ không
được sinh per-user — hai tín hiệu được chọn vì chúng vừa đổi được bối cảnh
cảnh vừa ổn định theo người:

- `audience` — băng tuổi parse từ `user.age` (label admin viết, "Dưới 18" /
  "25-34 tuổi"…): teen · young_adult · adult · midlife · unknown. Parse số
  trong chuỗi + từ "dưới/under/未満/미만…", không match danh sách đóng vì
  config đổi label là gãy.
- `goalKey` — `onboarding.learningGoal` (id option) resolve qua config lấy
  trackingLabel ổn định; label theo locale chỉ đưa vào PROMPT.

Khoá cache `coach_situations` thành (habit, locale, variant, audience,
goalKey); index unique cũ 3 trường phải bị DROP không thì mọi dòng
per-audience bị chặn duplicate — Mongo không có migration nên repository
`syncIndexes()` lúc boot (log-not-throw). Dòng cũ thiếu 2 trường được đọc
như (unknown, unknown) qua `$in: ['unknown', null]`.

Prompt sinh cảnh thêm khối Reader: hint theo băng tuổi (teen thì lớp học/
câu lạc bộ/gia đình, cấm phòng họp) + goal được phép nhuộm bối cảnh nhưng
CẤM gọi tên. Thiếu gì rơi về 'unknown' — người bỏ qua onboarding nhận cảnh
chung, không bao giờ mất cảnh.

## Xương sống mới theo BA flow 2026-08-26 (pha 1 — API)

Nguồn: `aicoachbaflow.html` + `aicoachtomtat.md` (2026-08-26). Một xương sống,
hai cửa; sơ đồ ⓪–⑤. Những gì implementation cũ có mà BA mới không có đã bị
gỡ khỏi đồ thị (enum giữ giá trị để phiên đang đỗ còn render tới hết TTL):

| Bỏ | Thay bằng |
|---|---|
| Cửa Nav Habit (`entry=habit`, bubble tab Habit, `PICK_HABIT`) | `open()` map HABIT → HOME; bubble Habit trả hidden |
| Bước TIME + `CoachScript` Short/Medium/Long/Practice | `DEPTH` sau câu đầu: *Chỉ ghi lại thôi* / *Kể sâu hơn* |
| Bước PERSONA đầu phiên | `PATCH /coach/sessions/:id/persona` — nút đổi giọng trong header, sáng sẵn `lastPersona` |
| Home 3 tầng ③A/③B/③C (`CHECKIN`, `FREE`, `TELL_ONCE_A/B`, `PRACTICE_ANSWER`) | ②A (`tier=A`, có nhắc hẹn) / ②B (`tier=C`, không); habit ②B do match ngầm trên kho của user hoặc habit đến hạn nhất |
| END 3 nút chữ + `courseInvite` | `COURSE_CARD` (tap / **Lưu → Để dành** qua `SavedCourseRepository` / Đóng) |
| Mood 3 mức | 5 mức (`COACH_MOOD_MAX=5`, thấp = 1,2) |
| Chip đánh giá cũ | `imposed_thinking · missed_the_point · too_generic · too_long · voice_mismatch` |

Đồ thị (`coach-state-machine.ts`, spec 30 test):

```
①  [PICK_NEW] → TELL_ONCE → PLAN_ASK → (PLAN → SCHEDULE) → END("Tập vậy là đủ cho hôm nay")
②  MOOD(1 lần/ngày) → ②A INTENT | ②B STORY
   INTENT: done → INTENT_TELL → DEPTH
           missed → BARRIER → SHRINK(accept|keep) → afterCheckin
           none → CONTEXT_ASK(keep|edit→CONTEXT_EDIT) → afterCheckin   (lần 3 → ngủ, bỏ hỏi bối cảnh)
   afterCheckin: còn nhắc hẹn (≤MAX_INTENT_ROUNDS, bỏ cái hỏi hôm qua) → LOOP → INTENT | STORY
   STORY: text → DEPTH | skip → INVITE
   DEPTH: shallow → (origin checkin: afterCheckin | story: INVITE)
          deep → TELL_2 (lateNightLow: thẳng TWO_COLS/REDRAFT)
   TELL_2 → TWO_COLS|REDRAFT → NEXT_ACTION → CLOSING → ack → afterDepth      (hết 6 lượt → CLOSING)
   INVITE: tập → TELL_ONCE → PLAN_ASK | bỏ → PLAN_ASK
   PLAN_ASK: có → PLAN → SCHEDULE → tail | không → tail
   tail: [COURSE_CARD] → MOOD_END(1 lần/lần mở sheet) → [RATING: deepRan && !hidden && chưa hỏi] → NEXT_SESSION
   NEXT_SESSION: câu chốt (AI ≤20 từ, không hỏi; fallback key) + Dừng | Phiên mới→STORY (moodEndLow → chỉ Dừng)
```

Ba chỗ doc tự mâu thuẫn, đã chốt mặc định: (1) "không đặt nhắc hẹn" ở ② vẫn
chạy đuôi; (2) đánh giá chỉ hỏi sau phiên có 5 nhịp (`deepRan`); (3) câu
chốt: có nhắc hẹn → GỌI AI (từ chối nếu là câu hỏi) fallback
`coach.prompt.closingWithPlan`, không → `coach.prompt.closingNoPlan`.

Dữ liệu mới: `coach_problem_statements.kind=barrier` (+`planId`);
`coach_plans.source=check_in_shrink`, `reminder.days=custom` + `customDays[]`
(dispatcher đọc); session thêm `moodLow · pendingStory · depthOrigin · deepRan ·
moodEndAsked · moodEndLow · ratingAsked · shrinkContext/Action · courseCardId ·
createdPlanId`. Response thêm `promptArgs` (chữ user cho INTENT/CONTEXT_ASK/câu
chốt), `noteKey` (dòng "cất hẹn đi"), `ui.shrink`, `ui.course`,
`ui.allowNewSession`; `uiKind` mới `text_skippable · shrink · course_card ·
next_session`.

**Chưa làm (pha 2/3):** Flutter composer cho các bước mới + bỏ chip thời
lượng + bỏ bubble tab Habit + nút đổi giọng + card course có Lưu; recap mời tập
lại sau 3 tuần; phát hiện vấn đề lặp 3 phiên; `CourseDaLuu.nguon`.
**Deploy API phải đi cùng app pha 2** — app hiện tại không biết các uiKind mới.

### Pha 2 (hddhistory-flutter) — đã code, chưa commit (2026-08-26)

`CoachUiKind` thêm `textSkippable · shrink · courseCard · nextSession`; entity/model
thêm `promptArgs · noteKey · persona · ui.shrink · ui.course · ui.allowNewSession`.
Cubit: sự kiện `skip · depth · shrink · context · invite · planAsk · course ·
nextSession` + `setPersona` (PATCH, không phải turn); bỏ `pickHabit/pickScript/
answerCheckin`. Composer: mood 5 chip; chip depth/contextAsk/invite/planAsk;
`_story` (ô gõ + Bỏ qua), `_shrink` (2 ô sửa được + 2 nút ngang hàng),
`_courseCard` (ảnh + tên + "khớp habit" · tap → pop openCourse · Lưu · Đóng),
`_nextSession` (Dừng · Phiên mới, ẩn khi mood cuối thấp), lịch nhắc thêm "tự
chọn" 7 thứ, đánh giá 👎 mở 5 chip đa chọn + Gửi; `_end` chỉ còn một nút Đóng
(① — Home END tự đóng sheet trong listener). Header: pill đổi giọng
(PopupMenu 3 nhân cách). Bubble host chỉ còn Home. Prompt map nhận `args`
(`promptIntent`, `promptContextAsk`, `closingWithPlan`). l10n 5 locale: +54 key,
mood1..5 đổi chữ.

Chưa: ① đóng về Roadmap từ bubble lesson (giữ như cũ — người dùng còn đứng ở màn
hoàn thành keypoint, màn đó tự dẫn về roadmap).

---

## 2026-08-26 (chiều) — Design v2 `HDDhistory AI Coach.html`: một xương sống, bốn cửa

Nguồn: `~/Downloads/HDDhistory AI Coach.html` (Claude Design bundle; markup thật ở
dòng 384 dạng JSON string, logic ở `class Component extends DCLogic`). Bản này
thay cho `aicoachbaflow.html` + `aicoachtomtat.md` ở những chỗ hai bên khác nhau.

### Xương sống (server = `coach-state-machine.ts`, spec 27 test)

```
① lesson   : [pickNew] → tellOnce ("Bạn vừa thêm “X”. Một cảnh ngắn:" + cảnh)
             → planAsk → (plan → schedule) → END "Tập vậy là đủ cho hôm nay."
②A home    : mood (1 lần/ngày) → intent {done|missed → intentTell → ; none →}
             → [loop] → story …
②B home    : mood → story ("Hôm nay có chuyện gì mới không?")
③ push     : = ②A
④ retry    : mood → retryScene (cảnh ĐÃ trả lời ≥3 tuần, cùng situationId) → planAsk …
story      : text → tell2 (AI hỏi lại 1 câu về điều đã xảy ra) → twoCols (AI dựng nháp)
             → text "Vấn đề thật của tôi là …" → note "Đó là câu của bạn, mình không sửa."
             → invite {tập thử → tellOnce → ; bỏ qua →} → planAsk
             skip ("Không có gì đặc biệt") → invite
⑤ reject   : twoCols → tell2 (note "Mình hiểu sai rồi…"), chỉ MỘT lần (ui.rejectAvailable)
planAsk no : → END "Vậy mình dừng ở đây nhé." (không tail)
schedule   : ① → END · ② → courseCard? → moodEnd → [rating nếu storyTold] → nextSession
courseCard : open → LEAVE ("Mình mở khoá đó cho bạn…", nút "Sang Roadmap khoá học")
             save/close → moodEnd
nextSession: câu chốt AI ≤20 từ (fallback key) → "Bắt đầu phiên mới" | "Dừng ở đây"
```

Bỏ khỏi luồng (enum giữ cho session đang đỗ): DEPTH, BARRIER, SHRINK,
CONTEXT_ASK/EDIT, NEXT_ACTION, CLOSING, REDRAFT, ⑥ escape, persona pill.
`proposeShrink` gỡ khỏi lớp AI. INTENT_TELL và TWO_COLS không còn gọi model —
Coach đáp bằng câu cố định (`noteKey`).

### Dòng cố định mới (slang key → 5 locale)

`storyMore`, `intentNone`, `intentTellDone`, `intentTellMissed`, `barrier` (câu
hỏi nhánh missed), `redraft` (sau ⑤), `problemAck`, `sceneAck` (fallback),
`lessonIntro{habit}`, `retryScene`, `retryAck`, `courseCard`, `courseLeave`,
`endStop`, teaser `coach.teaser.retry`.

### Rating

Toast trồi lên từ vùng nhập: 👍 · 👎 · ✕. Sau 👎: chip đa chọn
`imposed_thinking · too_many_questions · missed_the_point · too_generic ·
voice_mismatch · other` (+ `ratingNote` khi chọn Khác). Không echo vào chat.

### Cửa ④ (mới)

`CoachHomeTier.RETRY = 'D'`. `findRetryCandidate(userId, before)` = situationId
có câu trả lời MỚI NHẤT ≥ `CHANGE_BLOCK_MIN_WEEKS` tuần. Bubble: chấm + teaser
cố định. Session mở với `situationId` cố định; `attachSituation` lấy theo id
(không resolve lại) để recap có đúng một cặp. Plan tạo ở đây `source = retry`.

### Phía app

Composer vẽ lại theo artboard: chip full-width `#F7F6FE/#D9D4F3` (mood = grid
3+2 kèm emoji), gợi ý tròn có fade mép phải, card course trong thread (ảnh 76,
tác giả + lượt xem), toast đánh giá, header chỉ còn tên + nhãn bước + "Đóng".
Deploy API và app CÙNG NHAU: app cũ không biết `leave`/`retryScene`; app mới
không còn chip cho depth/shrink/context.

### Chỉnh sau khi thử trên api-dev + simulator (26/08 chiều)

- ① vào thẳng cảnh, **không** có bước `pickNew` (design không có); nhiều habit
  thêm trong ngày → lấy habit vừa thêm gần nhất. Lời mở + cảnh là **một** bong bóng.
- INVITE "Tập thử một cảnh" khi session không có habit (không dựng được cảnh) →
  đi thẳng `planAsk` (`ctx.hasScene`), tránh lượt Coach trống.
- ④ chỉ mời **một lần mỗi ngày** (`existsSince(tier: D, since: đầu ngày)`); đóng
  không trả lời thì hôm sau mới mời lại, còn hôm nay về ②B.
- Cảnh tình huống: **kho tối đa 4 cảnh** mỗi (habit × locale × biến thể × nhóm
  tuổi × mục tiêu), khoá unique thêm `slot`. Chọn cảnh user CHƯA trả lời
  (`findAnsweredSituationIds`); hết thì sinh thêm một cảnh khác hẳn (prompt nhận
  danh sách cảnh đã có); đủ 4 thì xoay cảnh trả lời lâu nhất. Trước đó 1 cảnh/khoá
  → lần nào cũng gặp lại đúng cảnh cũ.
- Habit có `description` + `contexts` (đa ngôn ngữ; contexts mỗi dòng một bối cảnh,
  admin form + sheet import/export, cột trống không xoá). Prompt sinh cảnh nhận
  cả hai; slot i của kho đứng trong bối cảnh i. `DELETE /coach-situations/habit/:id`
  dựng lại kho sau khi đổi. Nội dung 24 habit (vi+en) seed lên dev từ
  `scratchpad/habit-descriptions.json` qua PUT /habits/:id; zh/ja/ko fallback en.
- ③ tap push nhắc hẹn → app mở THẲNG sheet Coach (chiếm Home bên dưới, entry home
  → server vào ②A). Quyết định của user 26/08; bỏ luật "về Home có chấm".
- Kho cảnh KHÔNG còn trần 4: hết cảnh chưa trả lời là sinh mới (quyết định user
  26/08 "sinh rất nhiều cũng được"); `SITUATION_POOL_SIZE=200` chỉ là chốt chặn
  vòng lặp, prompt chỉ nhận 12 cảnh gần nhất để tránh lặp.
- Luyện tập tình huống LINH HOẠT (user 26/08, thay luật "một lượt"): sau mỗi câu
  trả lời, Coach hoặc chốt một câu, hoặc hỏi thêm MỘT câu và user trả lời tiếp;
  mở lượt = câu trả lời của Coach kết thúc bằng dấu hỏi (`ctx.sceneContinues`);
  tối đa `SITUATION_PROBE_ROUNDS=3` lượt, lượt cuối không hỏi. Câu trả lời đầu
  vẫn là câu lưu `TraLoiTinhHuong`.

---

## 2026-08-26 (tối) — Hướng đi cho người dùng

Tiếp theo ở `plans/260826-ai-coach-huong-di/README.md`: card course chọn theo
vấn đề của user kèm lý do, thu nhỏ nhắc hẹn sau "có dịp mà chưa làm" (luật 5
sống lại), câu trả lời sau cảnh đặt "cách khác" của bài học cạnh lựa chọn + điền
sẵn Nhắc hẹn bằng cách đó, hẹn tạo hôm nay không bị hỏi lại hôm nay, resume chỉ
trong ngày, deeplink `coach`, funnel metric. (②C điểm danh check-in đã thử rồi
bỏ theo quyết định user.)
