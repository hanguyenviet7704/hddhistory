# AI Coach — hướng đi cho người dùng

Ngày: 2026-08-26 · Stack: `hddhistory-api` + `hddhistory-flutter` (+ 1 dòng `hddhistory-admin`)
Kế thừa: `plans/260824-ai-coach-v2/README.md` (xương sống v2, design
`HDDhistory AI Coach.html`). Tài liệu này **không đổi xương sống** — nó bổ vào những
chỗ xương sống đang để trống.

## 1. Vì sao có tài liệu này

Câu hỏi đặt ra 26/08: *"luồng AI Coach có cần đổi gì để có ích hơn với người
dùng không — user rút được gì sau tình huống, và ai định hướng cho họ?"*

Khảo sát code cho ra ba kết luận:

**Coach là một tấm gương tốt, nhưng gương không chỉ đường.** Sau mỗi nhịp,
user nhận lại gần như chỉ chữ của chính họ:

| Nhịp | Coach trả lại | User rút được |
|---|---|---|
| Trả lời cảnh | gọi tên lựa chọn, không chấm, không gợi | — |
| Hai cột → câu "vấn đề thật" | "Đó là câu của bạn, mình không sửa." | — |
| Check-in "đã làm" | trích 1 cụm, nêu 1 điểm khó đã vượt | một lời công nhận |
| Check-in "có dịp mà chưa làm" | "Lần tới nên nhỏ hơn một chút." | — (hẹn giữ nguyên) |
| Câu chốt | lặp lại cam kết + giờ nhắc | — |
| Card course | một khoá chọn theo habit | link, không có "vì sao" |
| Recap thứ 2 | 4 khối chữ của họ, "im lặng — không bình luận" | nhìn lại, không có hướng |

Đây là hệ quả của thiết kế cố ý (bảy luật đều là luật "không": không khuyên,
không chấm, không chẩn đoán) **cộng** với việc v2 cắt đúng hai chỗ định hướng
từng có: nhịp 4 gợi keypoint (`NEXT_ACTION`) và `SHRINK`. Bằng chứng còn trong
code: `COACH_KEYPOINT_SUGGESTION_LIMIT` khai báo mà không ai tham chiếu; các
dòng `BARRIER` ("điều gì làm bạn dừng lại" — code tự gọi là *the most valuable
row in the feature*) được ghi ở `coach-session.service.ts` và **không ai đọc**
(recap chỉ lọc `PROBLEM_STATEMENT`).

**Card course hiện chỉ đường về chỗ user vừa đứng.** `courseForHabit` →
keypoint của habit → lesson → course, xếp theo số keypoint trùng, **không có
`userId`**. Habit của user đến từ một khoá (`user_habits.sourceCourseId`), nên
khoá trùng nhiều keypoint nhất chính là khoá họ vừa học. Card không biết khoá
nào đã học xong / đang học / đã "Lưu để sau".

**Cả sản phẩm chỉ định hướng đúng một lần** — lúc onboarding: lọc khoá theo
triệu chứng rồi chọn ngẫu nhiên (`OnboardV2RandomCoursePicker`). Triệu chứng
không được gửi lên server (server chỉ giữ `learningGoal`, `skillsetWantToMaster`,
`learningStruggles`). Sau onboarding không còn ai chỉ đường nữa. Coach là chỗ
tự nhiên nhất để làm việc đó.

**Kịch bản "3 thói quen chưa check-in hôm nay, mở Coach từ Home".** Không có
nhắc hẹn → không có cảnh cũ → ②B: Coach lấy `active[0]` **theo `createdAt`**
(habit cũ nhất, không phải habit đang bị bỏ) rồi hỏi "Hôm nay có chuyện gì mới
không?". Không nhắc tới thói quen nào, không ghi check-in. Tầng ③B cũ đã bị cắt.
`user_habits.lastCheckInDate / currentStreak / packLength` có sẵn mà Coach không
đọc dòng nào — Coach và tab Habit là hai thế giới song song.

Ngoài ra bốn lỗi luồng nhỏ hơn nhưng nhìn thấy được:

1. **Hỏi lại ngay cùng ngày với câu "Hôm qua bạn nói…"** — hẹn vừa tạo có
   `lastAskedAt = null` → `getBubble` bật chấm + teaser ngay khi đóng sheet;
   `open()` không xét `createdAt`; câu cố định hardcode "Hôm qua".
2. **"Lần tới nên nhỏ hơn" mà không làm gì** — luật số 5 ("nhắc hẹn mới luôn
   nhỏ hơn") không còn được thực thi; `planService.shrink()` có sẵn, không ai gọi.
3. **Phiên bỏ dở resume sau tới 48h và nhảy qua mood** — `open()` resume mọi
   session ACTIVE trước khi xét mood hôm nay.
4. **Không đo được Coach có ích không** — 7 metric hiện có toàn đo chất lượng
   lời model (draft bị từ chối, câu hỏi cấm, echo); không có funnel nào.

## 2. Quyết định sản phẩm (chốt 2026-08-26, chiều)

| Câu hỏi | Chốt |
|---|---|
| Định hướng đến từ đâu | **Từ khoá học thật và hành vi thật của user, do server tra ra. LLM chỉ viết câu nối.** Không nới luật "không khuyên" cho model — đó là đường quay lại đúng những bug cũ. |
| Đơn vị gợi ý | **Khoá học, không phải keypoint.** (user 26/08: "không phải gợi ý keypoint mà là gợi ý khoá học") |
| 3 habit chưa check-in | Đã thử ②C "điểm danh" (code + chạy trên api-dev 26/08 22h), rồi **bỏ theo quyết định user cùng tối: "không cần"**. Coach không đụng check-in; việc đó là của tab Habit. Xem §3.1. |
| Card course khi không còn khoá mới | **Không hiện card.** Không gợi lại khoá cũ. |
| Resume phiên bỏ dở | **Chỉ trong cùng ngày local.** Cũ hơn thì đóng và mở mới — mọi thứ đáng giữ đã được ghi bảng riêng lúc phát sinh. |

## 3. Thay đổi

### 3.1 (ĐÃ BỎ) ②C — Điểm danh thói quen

Đã code và chạy trên api-dev (26/08 22h): tầng `CHECKIN` với `HABIT_PICK →
CHECKIN → CHECKIN_TELL`, "Có" ghi check-in thật `method: coach`, câu kể thành
note nhật ký, teaser bong bóng "N thói quen chưa ghi". **Gỡ cùng tối theo quyết
định user ("bỏ phần checkin habit đi tôi thấy k cần").** Code, enum
`HabitCheckinMethod.COACH`, metric `checkin_*`, l10n và `teaserArgs` đã được
gỡ hết ở cả ba repo; `CoachStep.CHECKIN` / `CoachHomeTier.CHECKIN` trở lại
trạng thái RETIRED như trước. Với 3 habit chưa check-in, Home vẫn vào ②B "Hôm
nay có chuyện gì mới không?" với habit `active[0]`. Lịch sử ở git
(`fd82742` thêm, commit gỡ ngay sau).

### 3.2 Card course chọn theo *vấn đề của user*

`courseForHabit(habitId)` → `pickCourseFor(session)` có `userId`. Server quyết
theo thứ tự, dừng ở bậc đầu tiên có kết quả:

| # | Bậc | Nguồn dữ liệu | Lý do hiện trên card (`reasonKey`) |
|---|---|---|---|
| 0 | **Loại** khoá đã có progress (đang học hoặc xong) và khoá `sourceCourseId` của mọi habit user đang theo | `user_progress` (distinct `courseId`), `user_habits.sourceCourseId` | — |
| 1 | Khoá dạy keypoint của habit **đang vướng** — có ≥2 dòng `BARRIER` hoặc ≥2 lần `missed` | `coach_problem_statements(kind=barrier)`, `coach_plans.lastAnswer` | `coach.course.reasonBarrier` {habit}: "Vì bạn còn vướng ở «{habit}»" |
| 2 | Khoá dạy keypoint của habit phiên này | `habit.keypointIds` → lesson → course (như cũ), trừ bậc 0 | `coach.course.reasonHabit` {habit}: "Nối tiếp «{habit}» bạn đang tập" |
| 3 | Khoá cùng skillset với habit user đang theo, chưa bắt đầu | `habits.skillsetId` → `courses.skillsetId`, market visibility của request | `coach.course.reasonSkillset`: "Cùng hướng với thói quen bạn đang tập" |
| 4 | Khoá đã "Lưu để sau" mà chưa bắt đầu | `saved_courses` − bậc 0 | `coach.course.reasonSaved`: "Bạn đã lưu khoá này" |
| 5 | Không còn gì → **không hiện card** | | |

Lý do là **dữ liệu**, không phải lời model. `ui.course` thêm `reasonKey` +
`reasonArgs`; session lưu `courseCardReasonKey` / `courseCardReasonArg` cạnh
`courseCardId` để card resume vẫn nói đúng lý do. Bậc 3 chọn deterministic
(mới nhất trước), không `$sample` — card resume phải giống card lúc hiện.

Việc phụ, **chưa làm đợt này**: lưu triệu chứng onboarding lên server để bộ
chọn có thêm tín hiệu.

### 3.3 Thu nhỏ nhắc hẹn sau "có dịp mà chưa làm" (luật số 5 sống lại)

```
INTENT(missed) → INTENT_TELL (điều gì làm bạn dừng lại) → note "Mình ghi nhận."
 → SHRINK_ASK "Muốn thu nhỏ nhắc hẹn này lại không?"  [Thu nhỏ lại] [Giữ nguyên, thử lại]
       Thu nhỏ → SHRINK: form Nhắc hẹn (ui PLAN) điền sẵn context/action CŨ, user sửa
                 → planService.shrink(old, new): hẹn cũ REPLACED, hẹn mới kế thừa giờ nhắc
                 → note "Mình đổi sang bản nhỏ hơn. Giờ nhắc giữ nguyên." → afterCheckin
       Giữ nguyên → afterCheckin (LOOP | STORY) như cũ
```

- `CoachStep.SHRINK_ASK = 'shrinkAsk'` (CHIPS), `CoachStep.SHRINK` sống lại với
  `uiFor(SHRINK) = PLAN` (form có sẵn, `ui.suggested` = hẹn cũ). Event
  `shrink { accept }` (có sẵn), rồi `plan` ở bước SHRINK → server gọi `shrink()`
  thay `create()`.
- Câu "Lần tới nên nhỏ hơn một chút." bỏ khỏi note của INTENT_TELL(missed) —
  giờ có bước hỏi thật, nói trước là thừa.

### 3.4 Bốn sửa nhỏ

1. **Hẹn vừa tạo hôm nay không bị hỏi lại hôm nay.** `open()` và `getBubble`
   bỏ qua plan có `createdAt >= đầu ngày (giờ user)`. Câu `promptIntent` đổi
   "Hôm qua bạn nói" → "Hôm trước bạn nói" (5 locale) — đúng với mọi độ tuổi
   của hẹn.
2. **Resume chỉ trong ngày.** `findActiveForEntry(userId, entry, since)`; session
   ACTIVE cũ hơn được đóng (`status: CLOSED`) ngay lúc `open()`.
3. **Funnel metric** (theo tuần, không gắn user, cùng khuôn `CoachMetricService`):
   `session_opened` (refId `entry:tier`), `plan_ask_yes/no`,
   `intent_done/missed/none`, `scene_answered`,
   `course_shown/opened/saved/skipped`, `shrink_accepted/kept`. Trả lời được
   "có ích hơn không" sau khi đổi.
4. **Chấm đỏ** giữ đúng luật số 1: chỉ khi có nhắc hẹn chờ (và giờ: đủ tuổi một
   ngày).

### 3.5 Phía app (hddhistory-flutter)

- Entity/model: `ui.course.reasonKey / reasonArgs`. Chạy lại `build_runner`.
- Cubit: `answerShrinkAsk(accept, label)`. Form PLAN ở bước SHRINK dùng
  `savePlan` như cũ (server phân biệt theo step).
- Composer `_chips`: case `shrinkAsk`. Prefill form Nhắc hẹn chạy cả ở
  `initState` (mở lại sheet giữa phiên vẫn điền sẵn).
- Prompt map: key mới + step label.
- Card course: thêm dòng lý do dưới tên khoá.
- Deeplink `coach` (`hddhistory://open/coach`): `DeeplinkDestination.coach` → Home +
  `_openCoachFromPush`. Mirror ở `deeplink.catalog.ts` (`minAppBuild 145`).
- l10n 5 locale (`coach.yaml`): key mới liệt kê ở §5.

### 3.7 Nhịp sau cảnh phải cho user mang về một thứ (thêm 26/08 tối, từ screenshot)

Screenshot thật trên sim: cảnh "màn hình vừa phát xong mẹo thuyết trình, ngón
tay chạm dấu nhân…" → user "Tôi tắt luôn cho nhẹ." → Coach "Bạn bấm tắt cửa sổ
ngay lập tức **để khỏi phải giữ lại gì cả**." → form Nhắc hẹn điền sẵn action =
"Tôi tắt luôn cho nhẹ." Hai lỗi chồng nhau, không phải lỗi của cảnh:

1. **Prompt trả lời cảnh không nhận tài liệu** (`habitContext: null`), nên câu
   "may mention the material offers another way" không có gì để nói → model chỉ
   nhại lại, và còn gán động cơ ("để khỏi phải…") — vi phạm "không giải thích
   người đọc cho chính họ".
2. **`sceneActionDraft = text`**: câu trả lời nguyên văn thành cam kết, kể cả khi
   nó là câu né tránh.

Sửa (API, không đổi máy trạng thái):
- `CoachTurnContext.habitMaterial` (description + keypoints của habit, qua
  `CoachSituationService.materialFor`) chỉ gắn ở bước cảnh; prompt có
  `materialBlock`. `CORE_RULES` thêm luật **cấm gán động cơ**.
- Lượt đóng cảnh: tối đa 2 câu — (1) gọi tên lựa chọn của họ, không phán, không
  động cơ; (2) **nếu** tài liệu có một cách khác cho đúng khoảnh khắc đó thì đặt
  cạnh, một câu, ≤10 từ, "Bài này có một cách khác: …", không "nên", không lý do;
  nếu lựa chọn của họ đã là cách đó, hoặc tài liệu không có gì → bỏ câu 2.
- Schema reflect thêm `nextMove` / `nextMoment` (nullable): cách làm cho lần tới
  (cách của bài học, hoặc chính hành động của họ nếu đó đã là hành động thật) và
  khoảnh khắc nó xảy ra. **Rỗng khi câu trả lời là né tránh và không có gì để
  gợi** — né tránh không bao giờ thành plan. Form Nhắc hẹn điền sẵn từ hai giá
  trị này (`sceneActionDraft` / `sceneContextDraft`), vẫn sửa được.
- Metric không đổi; Flutter không đổi (form đã đọc `ui.suggested`).

### 3.6 Không làm đợt này (đã bàn, để sau)

- **Vẽ khối recap ⑤** trong poster (API có sẵn `coach` block; app chưa render).
  Là việc design — designer còn nợ artwork recap.
- **"Vậy tuần tới"** trên từng khối recap (missed > done → thu nhỏ; ĐỔI THAY →
  hỏi "bạn thấy mình khác gì?" và lưu làm chữ của họ).
- **Mức theo habit** (Đang tập → Đã hẹn → Đã làm thật → Vững → gợi habit/lesson
  kế tiếp trong course) — chạm Roadmap, cần design.
- **Giờ nhắc tự chọn** (time picker) và mặc định theo `habit.contexts`.
- **Lưu triệu chứng onboarding** lên server.
- Danh sách "Nhắc hẹn của mình" read-only ngoài sheet.

## 4. Đồ thị mới (`coach-state-machine.ts`)

```
①  lesson : tellOnce → planAsk → (plan → schedule) → END
②  home   : mood(1/ngày) → tier
   A plan    : INTENT {done|missed → INTENT_TELL ; none → afterCheckin}
               INTENT_TELL: done → afterCheckin
                            missed → SHRINK_ASK {yes → SHRINK →(plan)→ afterCheckin ; no → afterCheckin}
   D retry   : RETRY_SCENE → PLAN_ASK
   C free    : STORY
   afterCheckin: còn hẹn → LOOP → INTENT | STORY
   STORY → TELL_2 → TWO_COLS → INVITE → [TELL_ONCE…] → PLAN_ASK → PLAN → SCHEDULE
   → [COURSE_CARD] → MOOD_END → [RATING] → NEXT_SESSION → STORY | END
```

Mũi tên mới trong spec: `SHRINK_ASK`, `SHRINK(plan)`. Mọi bước cũ giữ nguyên
hành vi. (②C đã gỡ — §3.1.)

## 5. Slang key mới (`assets/i18n/<locale>/coach.yaml` × 5)

| Key | vi |
|---|---|
| `promptShrinkAsk` | Muốn thu nhỏ nhắc hẹn này lại không? |
| `shrinkAskYes` / `shrinkAskNo` | Thu nhỏ lại / Giữ nguyên, thử lại |
| `shrinkAskYesEcho` / `shrinkAskNoEcho` | Thu nhỏ lại. / Giữ nguyên. |
| `promptShrinkEdit` | "Sửa lại cho nhỏ hơn — vẫn là chữ của bạn." |
| `shrinkDoneNote` | Mình đổi sang bản nhỏ hơn. Giờ nhắc giữ nguyên. |
| `courseReasonBarrier` | "Vì bạn còn vướng ở «${habit}»" |
| `courseReasonHabit` | "Nối tiếp «${habit}» bạn đang tập" |
| `courseReasonSkillset` | Cùng hướng với thói quen bạn đang tập |
| `courseReasonSaved` | Bạn đã lưu khoá này |
| `stepShrinkAsk` | thu nhỏ nhắc hẹn |
| `promptIntent` (sửa) | "Hôm trước bạn nói: ${context} sẽ ${action}. Có dịp nào chưa?" |
| `intentTellMissed` (sửa) | Mình ghi nhận. |

## 6. Kiểm chứng & rollout

- **API**: `npx jest src/modules/coach/src/modules/session/coach-state-machine.spec.ts`
  (spec bổ thêm cho 5 mũi tên mới) · `npx tsc --noEmit` · **`npm run build`**
  (`tsconfig.build.json` bật `strict`, Jenkins fail cái `tsc` bỏ qua).
- **DI**: CoachSessionModule import thêm `UserProgressModule` + `CourseModule`
  (không module nào trong hai cái đó import ngược về coach; `week-recap` mới
  import coach nhưng nằm ngoài đường này). Kiểm bằng `coach-di.check.ts`.
- **Flutter**: `dart run build_runner build --delete-conflicting-outputs` →
  `dart run slang` → `flutter analyze lib/src/coach`.
- **Deploy API và app CÙNG NHAU**: app cũ không có case chip cho `habitPick` /
  `checkin` / `shrinkAsk` (bấm không đi đâu); API cũ không hiểu event
  `pickHabit` dạng mới. `coach_configs.enabled` vẫn là công tắc tắt không cần
  deploy.
- Không chạy full test suite trên máy dev.

### Đã deploy dev + kiểm trên api-dev (2026-08-26, 22h)

`develop` `fd82742` (feature) + `1b1f909` (catalog deeplink `coach`) → Jenkins →
api-dev. Kiểm bằng tài khoản anon (`POST /users/anonymous`) + một habit vừa adopt
(*bốn dòng đầu là ②C, đã gỡ ngay sau đó — giữ lại làm bằng chứng nó từng chạy*):

| Bước | Kết quả thật trên api-dev |
|---|---|
| open → mood → | `checkin`, `promptArgs.habit = "Lắng nghe hết rồi mới đáp"`, ui chips |
| checkin used=true | `checkinTell`, promptKey `intentTell` |
| text một câu | `invite` + noteKey `checkinTellAck` |
| habit sau đó | `todayDone: true`, `totalCheckIns: 1`, `currentStreak: 1`; dòng check-in `method: coach`, `note` = câu kể |
| bubble sau đó | `visible: true, dot: false`, không teaser ②C |
| cảnh (3 lượt, trả lời né tránh) | câu đóng: *"Bạn chọn nói luôn ý mình. Bài này có một cách khác: để họ nói hết câu rồi mới đáp."* — không gán động cơ |
| planAsk → PLAN | `ui.suggested = { action: "để họ nói hết câu rồi mới đáp", context: "lúc họp nhóm" }` — cách của bài học, không phải câu né tránh |
| schedule → | `courseCard` với `reasonKey: coach.course.reasonHabit`, `reasonArgs.habit` |

Thêm ngoài kế hoạch: đích deeplink **`coach`** (`hddhistory://open/coach`) ở cả
`DeeplinkDestination` (Flutter) và `deeplink.catalog.ts` (API, `minAppBuild 145`)
— dùng để mở sheet không cần bấm bong bóng (test sim, campaign, admin). Sửa
prefill form Nhắc hẹn không chạy khi mở lại sheet giữa phiên (`initState`).
Catalog vẫn thiếu `community`/`community-post` so với Flutter — tồn tại từ trước.

Sim: app dev chạy bản mới trên iPhone 17; deeplink vào đúng `_openCoachFromPush`;
tài khoản trên sim đang có phiên hôm nay chưa đóng nên sheet resume ở bước Nhắc
hẹn (đúng luật); prefill-on-resume đã sửa và nhìn thấy trên ảnh.

**22h40: gỡ ②C theo quyết định user** — API tsc strict/spec 32/32/eslint sạch,
Flutter build_runner + slang + analyze sạch, admin tsc sạch. Commit gỡ đẩy
`develop` ngay sau `1b1f909`.

### Trạng thái 2026-08-26 (tối)

Đã code §3.2–3.5 và §3.7 ở cả `hddhistory-api`, `hddhistory-flutter` (§3.1 đã gỡ). Kiểm chứng trên máy dev: spec state machine **36/36**, `tsc`
strict (`tsconfig.build.json`) sạch, `npm run build` sạch, ESLint sạch trên các
file đã sửa, `build_runner` + `slang` chạy lại, `flutter analyze lib/src/coach`
không lỗi, `tsc` admin sạch. **Chưa** chạy trên simulator/api-dev; chưa commit.
`coach-di.check.ts` hiện không chạy được qua `ts-node` trên máy này (đổ ở
`mongodb/src/bson.ts` — lỗi môi trường, không liên quan thay đổi); kiểm tĩnh:
`CourseModule` và `UserProgressModule` (cùng cây import của chúng) không import
gì dưới `modules/coach`, nên không có vòng mới.
