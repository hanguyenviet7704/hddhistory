# AI Coach — sáu luồng (design "AI Coach Flows" v1.0.0, 2026-09-03)

Nguồn: `~/Downloads/AI Coach Flows (1).html` (bundle Claude Design; markup +
logic nằm trong `<script>` ở dòng 392 — decode JSON string) + tài liệu owner dán
2026-09-04. Sáu luồng là "đề xuất của Phần II" phủ lên coach v4; thứ tự LÀM chốt
với owner: **4 → 5 → 6 → 2 → 3 → 1**. Mỗi luồng = API + Flutter deploy cùng.

Bốn chỗ design lật quyết định cũ — theo design, owner đã duyệt 2026-09-04:
1. Nhắc hẹn (T4) và check-in nhắc hẹn (②A/T1) không có mặt ở luồng nào → nghỉ
   hưu ở Home (code/enum giữ cho phiên treo).
2. Check-in qua Coach quay lại ở màn Habit (luồng 5, `method: COACH`).
3. Được chấm ở đúng 3 bước: TALK_REPLY (khuyên nước đi), SCENE_JUDGE, QUIZ_BACK/
   QUIZ_IN_CHAT — prompt riêng, không dưới CORE_RULES.
4. Kho rỗng → bong bóng Home ẩn (thay "card học bài để có habit đầu tiên").

---

## Luồng 4 · Luyện tình huống từ kho habit (Home) — CODE XONG 2026-09-04

Trạng thái: API + Flutter đã code, gate xanh (jest coach 70/70, `npm run build`,
`dart analyze lib/src/coach`, slang 5 locale). CHƯA deploy dev / CHƯA probe sống
(`coach-seed/probe-flow4.sh scene|scene-later|talk`). Còn để lại trong service
các helper đã hết đường vào (`pickCourseFor`, `resolveTier`, `pendingForAsking`,
`retryOfferedToday`, `retryCandidate`, `mostDueHabitId`) — parked cùng ②A/④,
xoá khi luồng 2 thay cửa ①. Flutter chưa dọn widget twoCols (parked).

### Luồng
```
Home bubble (chỉ khi kho ≠ rỗng) → [MOOD 1 lần/ngày] → HUB "Hôm nay bạn muốn làm gì?"
  ├ ⟨Luyện tập tình huống⟩ (T2)  → SCENE_PICK (chip = habit trong kho, gõ tên cũng được)
  │                                → TELL_ONCE (= SCENE_SHOW: 1 cảnh ≤50 từ + câu hỏi)
  │                                → user trả lời → judgeScene
  │                                     ├ đúng hướng: khen ≤25 từ + câu dẫn cố định
  │                                     │             → check-in EXERCISE → COURSE_CARD cùng skill set → END
  │                                     └ chưa đúng:  chấm ≤35 từ (câu mẫu + vì sao) → SCENE_FIX
  │                                          ├ ⟨Luyện lại cảnh này⟩ → SCENE_RETRY (cùng cảnh, "Vẫn cảnh đó:") → judge
  │                                          │        đúng → như trên · sai lần 2 → câu đóng cố định → END
  │                                          └ ⟨Để sau⟩ → câu đóng cố định → END
  └ ⟨Kể chuyện hôm nay⟩ (T3) / gõ thẳng → STORY(opener) / STORY_TALK ngay (KHÔNG DEPTH)
                                   → ≤3 lượt (mood thấp 2) → khoá nối được từ chuyện (đối chiếu ngầm
                                     → khoá chứa habit, chưa học) → câu dẫn cố định + COURSE_CARD → END
                                     · không khoá → câu đóng cố định → END · KHÔNG check-in
```
Một phiên = MỘT task rồi END. Không quay lại hub, không mood cuối, không rating,
không nhắc hẹn (`afterCard` bỏ nhánh PLAN_ASK; `afterCourse` HOME → END).

### Máy trạng thái (`coach-state-machine.ts`)
- Step mới: `SCENE_PICK` (CHIPS), `SCENE_FIX` (CHIPS), `SCENE_RETRY` (TEXT + scene).
  SCENE_SHOW dùng lại `TELL_ONCE`; SCENE_JUDGE = reply của lượt TELL_ONCE/SCENE_RETRY.
- ctx mới: `sceneOnTrack?: boolean | null` (kết quả judge lượt này), `pickedHabit?: boolean`
  (SCENE_PICK gõ tên khớp). `hasHabit` = kho ≠ rỗng.
- HUB: text → hubRoute T2 → SCENE_PICK, còn lại → STORY_TALK (không DEPTH); task T2 →
  SCENE_PICK; task T3 → STORY. `eligibleTasks` bỏ T1; `taskEnd` ở HOME → closing (không HUB).
- TELL_ONCE ở HOME: text → onTrack ? sceneDone(ctx) : SCENE_FIX. Ở LESSON giữ 6 nhịp cũ
  cho tới luồng 2. `sceneDone` = hasCourse && !cardShown ? COURSE_CARD : END.
- SCENE_FIX: sceneAgain(true) → SCENE_RETRY · (false) → END. SCENE_RETRY: text → onTrack ?
  sceneDone : END. Trần 2 lần (sceneRetried).
- STORY ở HOME: text → STORY_TALK. DEPTH park.
- `firstStepOf('T2')` HOME → SCENE_PICK (LESSON giữ TELL_ONCE).

### Service (`coach-session.service.ts`)
- `open(HOME)`: bỏ tier (null), `hasHabit` = countActiveForUser > 0, `habitId` = null (chọn ở
  SCENE_PICK). `getBubble(HOME)`: visible = kho ≠ rỗng, dot = false.
- `runAi`: TELL_ONCE/SCENE_RETRY ở HOME → `ai.judgeScene` → `{onTrack, reply}` → `ctx.sceneOnTrack`;
  đúng hướng + có khoá → nối thêm `COACH_SCENE_CARD_LEAD_LINE`. SCENE_PICK text → khớp tên habit
  trong kho (fold) → `patch.habitId`; không khớp → ở lại SCENE_PICK.
- Ghi check-in đúng hướng: `userHabitService.checkIn(userHabitId, {done:true, method:EXERCISE})`.
- Khoá: `pickCourseInSkillsetOf(habitId)` — `coursesWithHabit` → skillsetIds →
  `findRandomPublishedCourseIdInSkillset` trừ khoá đã học; reason `SKILLSET` (T2) /
  `STORY` (T3, "Từ chuyện bạn vừa kể"). T3 chỉ khi đối chiếu ngầm có habit.
- Câu đóng cố định 5 locale qua `reply` + `COACH_NO_PROMPT_KEY` để END không nói thêm.
- Bỏ khỏi Home: pendingForAsking/T1, PLAN_ASK ở đuôi, MOOD_END/RATING (steps giữ, park).

### AI (`coach-prompt.ts`, `gemini-coach.service.ts`)
- `buildSceneJudgePrompt` + `SCENE_JUDGE_RESPONSE_SCHEMA {onTrack, reply}`; `judgeScene()`;
  `CoachAiCallKind.JUDGE_SCENE`. Prompt RIÊNG (không CORE_RULES) như scoreScene: được nói
  đúng hướng/chưa; đúng → khen MỘT điều cụ thể trong câu user (≤25 từ, không "giỏi quá");
  chưa → câu mẫu + một dòng vì sao (≤35 từ), chấm NƯỚC ĐI không chấm NGƯỜI.

### Flutter (`lib/src/coach`)
- l10n ×5: hubTaskT2 "Luyện tập tình huống", hubTaskT3 "Kể chuyện hôm nay", promptScenePick,
  promptSceneRetry ("Vẫn cảnh đó:"), sceneFixRetry/sceneFixLater (+echo), stepScenePick,
  courseReasonStory. Hub: bỏ pill "Mình dừng ở đây" (đóng bằng ⟨Đóng⟩, luồng 6 sẽ níu).
- composer: chips 'scenePick' → pickNewHabit; 'sceneFix' → answerSceneAgain; prompt map,
  slime, step label cho 3 step mới. Dọn widget twoCols.

### Gate
jest coach + `npm run build`; probe `coach-seed/probe-flow4.sh [scene-ok|scene-fix|talk]`;
sim: bubble ẩn khi kho rỗng, hub 2 pill, cảnh → khen → card → END.

## Luồng 5 · Màn Habit — hàng 3 bộ chọn — CODE XONG 2026-09-04

- Cửa: `PracticePickSheet` hàng 3 `PracticeChoice.coach` → `showCoachSheet(entry: habit,
  habitId)`. API giữ `CoachEntry.HABIT` là cửa riêng (trước map về HOME): không MOOD,
  `habitConfirmed` từ frame đầu (thanh "Đang nói về"), ⟨Đổi habit⟩ ẩn (`canChange:false`).
- HUB pill = `eligibleTasks(HABIT)` = `checkin` (chưa ghi hôm nay) + `quiz` (có
  `quizItems`). Gõ chữ → STORY_TALK. Không card ở cửa này.
- CHECKIN_ASK (chips client) → ⟨Có⟩ → CHECKIN_TELL (AI ack theo instruction intentTell,
  fallback cố định) → `checkIn{done:true, method:COACH, note}` · ⟨Chưa⟩ → `checkIn{done:false,
  COACH}` + dòng "không bỏ trống ngày". Sau ghi → `afterCheckinWrite`: có habit khác chưa ghi
  → CHECKIN_OFFER (dòng «done»/«next» server, chips client → event `invite`) → accept đổi
  `habitId` → CHECKIN_ASK lại · không → END + dòng "Hôm nay ghi đủ rồi".
- QUIZ_IN_CHAT: snapshot `quizItems` lúc open từ `HabitPracticeService.findForHabit` (chỉ
  single_choice có đúng 1 đáp án, text = documents), `QUIZ_IN_CHAT_COUNT`=3, options =
  `ui.choices` (client default chips → event `quizAnswer`). Đúng → "Đúng rồi." · sai →
  `ai.quizFeedback(wrong)` (fallback «đáp án»). Hết → `quizFeedback(summary)` +
  `submitAttempt(EXERCISE)` → offer/END. `HabitCheckinMethod.COACH` thêm lại.
- Gate: jest coach 73/73, build sạch, slang + analyze sạch. CHƯA deploy/probe
  (`coach-seed/probe-flow5.sh yes|no|quiz`; quiz cần user đã học keypoint có exercise).

## Memory layer cho T3 (owner gửi 2026-09-04 chiều: "Context & User Memory
Architecture" — "ở luồng T3 cần như này") — CODE XONG 2026-09-04 (MVP)

Đã có: `coach/src/modules/memory/` — 5 collection (`coach_messages` raw không TTL,
`coach_memories`, `coach_goals`, `coach_episodes`, `coach_progress`), `mergeMemory`
thuần (spec 6 test: mới ≤0.7 & pattern=possible, lặp → evidence+1/confidence+0.1,
possible→active ở 2, trần 0.95, extraction được đổi improving/inactive),
`ai.extractMemory` (1 call sau END hoặc close, bất đồng bộ), `contextFor` → khối
`readerMemory` trong `buildStoryTalkPrompt` ("để nối, không đọc lại, không phán").
Card cuối T3 chỉ khi `improveSignal` (wants_improve/asks_how trong phiên).
CHƯA: admin đọc memories; vector search; dùng memory pattern thay bộ đếm habitId.
- RAW = source of truth: mọi lượt user/coach ghi vào `coach_messages`
  (userId, sessionId, role, content, step, createdAt) — KHÔNG TTL. Session
  48h TTL giữ nguyên cho state; transcript sống ở collection mới.
- `coach_memories` (userId, type ∈ profile/preference/goal/habit/pattern/
  context, content, confidence, evidenceCount, firstSeen, lastSeen, status ∈
  active/improving/inactive, sourceSessionIds) + `coach_goals`, `coach_episodes`,
  `coach_progress`. Extraction = 1 call Gemini SAU khi phiên END (bất đồng bộ,
  không chặn reply), đầu vào = messages của phiên + memories đang active → trả
  danh sách upsert: khớp memory cũ (theo id) → evidenceCount+1, confidence lên;
  mới → confidence khởi điểm thấp (≤0.7), type `pattern` chỉ được lưu như
  possible_pattern cho tới khi evidence ≥2. Không kết luận lâu dài từ 1 câu.
- Retrieval MVP: Mongo query `memories.find({userId, status:{$ne:'inactive'}})`
  sort confidence/lastSeen, top ~8 + goals active + 3 episodes gần + progress
  gần → khối "what you know about this reader" vào `buildStoryTalkPrompt`
  (và về sau vào judge/scene). Vector search để sau (Atlas) — không dựng thêm DB.
- Card ở FREE_TALK: chỉ khi có INTENT — `storyKind` ∈ {wants_improve, asks_how}
  trong phiên (`session.improveSignal`) — không còn chỉ vì đối chiếu ngầm khớp
  keyword. Thay bộ đếm "lặp lại theo habitId" bằng memory pattern evidence.
- Admin: đọc memories/goals của một user (trang Coach) — sau.

## Luồng 6 · Níu khi rời đi — CODE XONG 2026-09-04

- App: ⟨Đóng⟩ giữa phiên → `CoachExitPleaSheet` (sheet nhỏ, 1 câu, 2 nút, không ô chat)
  khi `state.exitPlea && !ended && status ready && user đã nói ≥1 câu && step có câu níu`.
  Câu theo bước: story/storyTalk/depth/checkinTell → "Bạn kể chưa hết mà…"; tellOnce/
  sceneRetry/sceneFix/… → "Cảnh này còn một câu nữa…"; quizInChat → "Còn {n} câu thôi…"
  (`ui.quizRemaining`). Chưa nói gì → đóng thẳng, KHÔNG níu (design có câu "Không sao…"
  nhưng không có nơi hiện sau khi đóng — bỏ). Tap nền = không quyết định, sheet ở lại.
- ⟨Vẫn đóng⟩ → `POST /coach/sessions/:id/exit {stayed:false}` → `profile.exitDeclinedStreak+1`;
  ⟨Ở lại một câu⟩ → streak=0; phiên chạy tới END → streak=0. `EXIT_PLEA_OFF_AFTER`=2 →
  `exitPlea:false` trong mọi response → app không níu nữa.
- Nháp đang gõ giữ trong `CoachCubit` (lazySingleton) theo sessionId, nạp lại vào ô khi
  cùng phiên mở lại (resume cùng ngày).
- Gate: tsc/build sạch; Flutter build_runner + slang + analyze. CHƯA deploy.
## Luồng 2 · Thảo luận sau keypoint — API CODE XONG 2026-09-04
- `POST /coach/sessions {entry: lesson, lessonId, keypointId}` → `talkMode='talk'`, không
  MOOD, không habit bar (habit dạy keypoint nằm ở `talkHabitId`). `summaryScope` = lesson
  khi là keypoint cuối của bài. Cửa ① cũ (không keypointId) giữ cho client cũ; `getBubble
  (lesson)` không còn silence — mời sau mọi keypoint.
- TALK_ASK (HUB kind: pill `summary`/`talkQuiz` + ô chat) → ⟨Tóm tắt⟩ → TALK_SUMMARY
  (`ai.lessonTalk(summary)` ≤60 từ từ theory của keypoint/bài, kết 1 câu hỏi) → user trả
  lời → reply ≤25 từ (được khuyên NƯỚC ĐI) → QUIZ_HANDOFF ⟨Bắt đầu⟩/⟨Thôi, để sau⟩ →
  QUIZ_RUN (`ui.action='runQuiz'`, app đẩy KeypointQuizPage) → `quizDone {quizResults}` →
  reply quizBack ≤35 từ + khen ≤25 → TALK_WHEN ⟨Học tiếp⟩/⟨Để sau⟩ → END (dòng cố định,
  `ui.action='nextKeypoint'` khi Học tiếp). Ghi check-in cho `talkHabitId` nếu user có:
  EXERCISE (submitAttempt) khi có quiz, COACH khi chỉ nghe. Không card/mood/rating/nhắc hẹn.
- Event mới: `pick {value}` (chip chung), `quizDone {quizResults[]}`.

## Luồng 3 · Nhìn lại cả khoá — API CODE XONG 2026-09-04
- `POST /coach/sessions {entry: lesson, courseId, recap: true}` → RECAP_PICK (chips = lesson
  của khoá, ≤5, mới nhất trước; promptArgs {course}) → pick → `lessonTalk(recapWhy)` ≤25 từ
  → RECAP_QUIZ ⟨Làm thử⟩/⟨Để sau⟩. Quiz: **đọc trong chat** (tái dùng QUIZ_IN_CHAT, ≤5 câu
  random từ mọi keypoint của khoá) — lệch design (design dùng KeypointQuizPage) vì client
  không có sẵn câu hỏi cả khoá. Xong → COURSE_CARD (random cùng skill set, trừ khoá vừa xong,
  reason `reasonRecap`) → MOOD_END → RATING → END (đuôi đầy đủ chỉ ở đây).
- Flutter cho 2/3: ĐANG LÀM.
## Luồng 1 · Onboarding Coach — CODE XONG 2026-09-04 (api 9fbe4a0 + 7b84ade, admin 56cd4d8, flutter ea1c98c9)

**Gate:** phiên `HOME` khi `coach_profiles.onboardedAt` rỗng → `resolveOpeningStep`
trả `ONBOARD_INTRO` thay MOOD. Một lần duy nhất mỗi người; bỏ qua giữa chừng
vẫn đóng `onboardedAt` (không hỏi lại lần sau — đúng design "không bắt làm lại").

**Chuỗi bước:** `ONBOARD_INTRO` (2 câu server qua reply, chip `start`, gõ tay →
AI `reflect` với STEP_INSTRUCTION `onboardIntro`) → `ONBOARD_ADDRESS` (chip
bạn/anh/chị/em; gõ đại từ = chip; gõ khác = TÊN → `ONBOARD_ADDRESS_CONFIRM` chips
yes/no; `no` quay lại ADDRESS) → `GOAL` → `BARRIER` → `CURRENT` → [`STYLE`] →
[`AGE`] → [`GENDER`] → [`JOB`] → `afterOnboarding` = MOOD (hoặc HUB nếu hôm nay
đã hỏi mood). Bốn bước ngoặc bật/tắt trên admin (`onboardAskStyle/Age/Gender/Job`,
mặc định bật) → `onboardAsks(ctx)`, `onboardPosition()` đếm "Câu n/N" theo đúng
số câu đang bật. `pick:'skip'` ở mọi bước trừ ADDRESS/CONFIRM.

**Chip = gợi ý, không phải danh sách đóng:** ui.kind HUB cho mọi câu (ô gõ luôn
mở), `ui.choices[].label` do server gán theo locale (`COACH_ONBOARD_OPTIONS`),
`selected:true` khi app đã biết (GOAL fuzzy với goalLabel onboarding app; AGE từ
`coachAudienceFromAge(user.age)`; GENDER từ `user.gender`). `ui.onboard =
{step,total,skippable}` → app vẽ dải tiến độ + Bỏ qua (ẩn ở INTRO).

**Ghi:** mỗi câu → `session.onboardAnswers[field]` (chip → label locale cho các
trường text, value cho style/gender/occupation; JOB gõ tay → `occupationRaw` +
`occupation` qua `ONBOARD_JOB_KEYWORDS` 5 nhóm/other). Rời onboarding →
`profileService.completeOnboarding()` (address, goalText, barrierText,
currentPractice, learningStyle, occupation/Raw, onboardedAt, onboardVersion=1)
+ `userRepository.updateOne` age/gender (bỏ khi gender=private). Các lượt
onboarding KHÔNG cộng `turnCount`.

**Xưng hô:** `CoachTurnContext.address` + `readerStyle` → `voiceBlock` của mọi
prompt AI ("dùng đúng chữ này thay bạn"; practice → trả lời ngắn). Câu cố định:
app dịch — promptKey `coach.prompt.onboard*` + `promptArgs.address` (nguyên
chữ; ngoài vi "bạn" gửi rỗng → app dùng bản trung tính) + `name`. App có 7 cặp
key `promptOnboardX` / `promptOnboardXTo(address)`, hoa/thường quyết định ở
`_addressFor` theo vị trí trong câu vi.

**Lệch design / còn nợ:** câu cố định ngoài onboarding vẫn nói "bạn" (chỉ AI
line có xưng hô); occupation chưa nối vào scene generator (audience vẫn theo
age); CONFIRM `no` quay lại ADDRESS chứ không hỏi "gọi sao"; chưa có màn admin
xem câu trả lời onboarding (nằm trong coach_profiles). Chưa deploy, chưa probe.

## Lưu hội thoại · mở lại thấy chuyện cũ · onboarding dở hỏi tiếp · câu trước — CODE XONG 2026-09-04 tối (api 1f61870, flutter ccfb2cb3)

Owner: "luôn lưu trữ câu chuyện giữa AI coach và user; nỡ đóng thì vẫn cần
đoạn hội thoại cũ; onboarding chưa chạy hết thì quay lại hỏi tiếp; trả lời
nhầm thì trả lời lại được".

**Phát hiện khi soi:** server chỉ lưu câu user gõ + câu AI sinh (`turns`,
`coach_messages`); câu cố định (promptKey) và chip user bấm không lưu → resume
cùng ngày vốn đã mất nửa hội thoại, riêng onboarding gần như trống. Và ở
Flutter `CoachTurnModel.toEntity()` chưa từng map `replay` → resume luôn trống.

**Cách làm:**
- `coach_sessions.shown[]` (ICoachShownTurn): mỗi `respond()` không-replay
  append một exchange `{at, step, userLine, reply, speaker, noteKey, promptKey,
  promptArgs, situation, scene}`. Câu cố định lưu bằng KEY → app render lại theo
  locale hiện tại. Chip: app gửi `dto.label` (chữ trên chip) → `userLine` + một
  dòng user trong `coach_messages`.
- Bỏ TTL: schema không khai báo index `expiresAt` nữa,
  `CoachSessionRepository.onModuleInit` chạy `syncIndexes()` để drop index cũ
  trên dev/prod lúc boot; `closeActiveBefore`/`close()` không xoá `turns` nữa;
  `COACH_SESSION_TTL_HOURS` = 10 năm (chỉ còn là dấu hiệu lực cho
  `findActiveForEntry`).
- `open()`: resume → `replay = history + divider + shownOf(session)` và
  `resumed: true`, đồng thời giữ lại promptKey/noteKey của bước hiện tại (đã nằm
  trong replay) — trừ phiên cũ chưa có `shown` (fallback từ `turns`). Phiên mới
  → `replay = history + divider(hôm nay)`. `historyFor`: 3 phiên gần nhất có
  dòng, nguyên phiên, trần 60 dòng (`COACH_HISTORY_*`), cũ → mới, mọi cửa.
- Onboarding: `closeActiveBefore(..., keepSteps=onboardSteps)` cho HOME,
  `findOnboardingInProgress` không giới hạn ngày → mở Home hôm sau resume đúng
  câu đang dở.
- "← Câu trước": `COACH_ONBOARD_OPTIONS.nav`, machine `pick:'back'` →
  `onboardStepBefore` (bỏ qua câu admin tắt, sàn = ADDRESS); `session.onboardPicks[step]`
  ghi chip đã chọn để sáng lại; trả lời mới ghi đè; back không ghi vào answers.
- Flutter: `CoachReplayEntity` (+legacy isCoach/text), `CoachMessage.divider`,
  cubit tách `_linesFor()` dùng chung cho lượt thật và replay, `_replayMessages`,
  `_send` gửi `label` cho event không phải text, vạch "Hôm qua · Trang chủ" qua
  promptResolver key `coach.divider` (l10n dividerToday/Yesterday, door*).

**Còn nợ:** sửa câu trả lời onboarding SAU khi đã xong (cần màn riêng); lịch sử
chưa phân trang (chỉ 3 phiên); `coach_messages` không có chip label cho các
phiên trước deploy.

## Sau khi lên api-dev 2026-09-04 chiều tối — probe + chỉnh theo owner thử trên sim

Probe `coach-seed/probe-onboarding.sh` (user anonymous mới) trên api-dev: ĐẠT —
bubble hiện dù kho rỗng (0930455), INTRO → ADDRESS → gõ tên → CONFIRM → GOAL
(có "← Câu trước", args.address=tên) → BARRIER → back → GOAL, mở lại giữa
onboarding resume đúng bước + replay 6 dòng (promptKey của bước hiện tại bị giữ
lại), skip → xong, mở lại → replay 7 dòng, bubble sau onboarding về luật kho.

Chỉnh thêm cùng tối:
- `0930455` bubble Home hiện khi `coach_profiles.onboardedAt` rỗng (người mới kho
  luôn rỗng → trước đó luồng 1 không bao giờ mở được).
- `b33f293` + flutter `cb24900b`: owner thử sim — bấm "Kể chuyện hôm nay" không
  cần chip "Không có gì đặc biệt"/chọn habit, chỉ một câu hỏi mở rồi trò chuyện
  tự nhiên → STORY ở cửa HOME: ui TEXT, samples rỗng, promptKey
  `coach.prompt.storyOpen` ("Ừ, kể mình nghe đi. Dạo này thế nào rồi — có gì vui
  hay đang nghĩ về chuyện gì không?"). Cửa LESSON giữ nguyên.
- `497b9a9` sau onboarding rơi thẳng HUB vì `buildContext` gán cứng
  `moodAlreadyAskedToday=true`; phiên onboarding giờ đọc `moodStart`.

Ghi chú: STORY_TALK vẫn trần 3 lượt (2 khi mood thấp) rồi card/kết — owner mẫu
"ảnh bên phải" trò chuyện dài hơn; chưa đổi, hỏi lại nếu muốn nới.

Xác nhận trên api-dev (14:45): bỏ qua onboarding → `mood` → hub [T3] → T3 →
step `story`, ui `text`, promptKey `coach.prompt.storyOpen`, samples/choices
rỗng — cả 4 fix đã sống.

Màn mời sau keypoint (flutter `21248789` + `a77e6a1f`): owner soi sim thấy sai
design — dialog trắng có tiêu đề "Thực hành với Coach?" + đoạn mô tả. Dựng lại
đúng "khung màn mời của cửa ①": full-screen nền `sheetBackground`, câu mời trong
bong bóng có đuôi trên slime (84, shadow), "HDDhistory Coach · BETA", nút chính
stadium, ⟨Lúc khác⟩ dạng chữ; bản hoàn thành khoá thêm nhãn "Hoàn thành khoá
học" + tên khoá lấy từ `HomeCubit.state.currentCourse.title` (chỉ khi đúng
course của lesson; thiếu → bản không tên). Bỏ 4 key inviteTitle/Subtitle/
RecapTitle/RecapSubtitle, thêm inviteBubble/inviteRecapBubble(course)/
inviteRecapBubbleNoName ×5.

## Home không có hồi kết + xưng hô (owner thử sim 2026-09-04 ~15:10) — api ccc7a6f, flutter 983da886

Owner: "bỏ luồng đóng - về chỗ vừa rời đi", "tại sao coach lúc thì anh lúc thì
mình", "nó bị khựng luôn khi đang vào câu chuyện", "thiếu coach ở màn habit".

- **Home = trò chuyện không hồi kết.** `afterStoryLine` ở entry HOME luôn trả
  `STORY_TALK` (kể cả kind STOP / ASKS_HOW sau khi card đã hiện);
  `afterCourse` → `homeTail()` = STORY_TALK ở Home, END ở cửa khác; SCENE_FIX
  ⟨Để sau⟩/hết trần cũng về `homeTail`. `runStoryTalk` truyền
  `storyRoundsLeft = null` ở Home → prompt nhánh mới "no end of its own, never
  wrap up". Trần 3 lượt CHỈ còn cho cửa bài học (DEPTH parked).
  `COACH_STORY_STOP_LINE` viết lại thành câu mềm giữ ô gõ; thêm
  `COACH_STORY_CONTINUE_LINE` cho lúc rời card/cảnh về ô gõ.
  Spec: 20 assertion END ở Home đổi thành STORY_TALK (96 test xanh).
- **Xưng hô.** `coach_sessions.address` copy từ profile lúc open (và cập nhật
  khi onboarding xong). Server: `addressVi()` trong coach-text (+7 test) đổi
  "bạn" → chữ đã chọn, chừa danh từ "bạn bè/người bạn/…", chạy qua
  `fixedLine()/fixedLines()` cho MỌI câu cố định. App: `promptArgs.address` đi
  kèm mọi lượt (vi, khác 'bạn'), `coachPrompt` đổi bằng `_addressVi` cùng luật.
  `voiceBlock` nói rõ: đổi ĐẠI TỪ thôi, giữ giọng thân mật, cấm «ạ/dạ/thưa»,
  vẫn tự xưng «mình».
- **Đổi cách gọi giữa chừng.** `STORY_TALK_RESPONSE_SCHEMA` thêm `newAddress`;
  `talkStory` trả về, service `normalizeAddress` (đại từ về dạng chuẩn, tên giữ
  nguyên, ≤30 ký tự) rồi ghi `coach_profiles` + session ngay trong lượt đó.
- **Bubble ở tab Thói quen**: `_entryFor` nhận thêm `RouteNamed.habit` → mở
  phiên HOME. Cửa HABIT (luồng 5) vẫn chỉ vào từ bộ chọn luyện tập của một
  habit cụ thể.

Còn nợ: câu cố định các ngôn ngữ khác không có khái niệm xưng hô nên bỏ qua;
`storyTalkRounds` vẫn được đếm ở Home (không dùng nữa, để nguyên cho dữ liệu cũ).

## Bong bóng: mỗi màn một câu cố định (owner 2026-09-04 ~15:45) — api 7d0b80d, flutter 2be0aab8

Owner gửi 3 ảnh design ("MÀN NGOÀI · lời mời làm quen", "CỬA VÀO · bong bóng mời
tập", "MÀN ĐANG CHẠY / CÓ HABIT"): bong bóng KHÔNG trích lời người dùng, mỗi màn
có một câu cố định theo ngữ cảnh.

| ngữ cảnh | teaserKey | câu (vi) |
| --- | --- | --- |
| Home, chưa onboarding | `coach.teaser.onboard` | Mình làm quen với bạn một chút nhé? |
| Home, đã onboarding | `coach.teaser.home` | Vào trò chuyện một chút nhé? |
| Habit, kho rỗng | `coach.teaser.firstHabit` | Chưa có thói quen nào trong kho. Học một bài để thêm nhé? |
| Habit, có kho | `coach.teaser.habit` | Kể mình nghe một lần thật, hay làm quiz cùng mình? |

Ghi chú design giữ nguyên: không modal, không chặn màn, KHÔNG chấm đỏ, không
push; bấm mới mở phiên. Bản ba câu theo trạng thái phiên (intro/resume/today) đã
thử rồi BỎ theo owner — đừng đề xuất lại.

Sửa kèm cùng lúc:
- `084fcce9` sheet mở từ tab Thói quen bị đè lên đồng hồ: trang đó bọc SafeArea
  nên `MediaQuery.viewPaddingOf(context)` ở chỗ gọi = 0; đọc lề thật từ
  `View.of(context).viewPadding` rồi lấy max.
- `d554c68` lịch sử replay bỏ qua phiên không có lượt nào của user (mở rồi đóng
  ngay cũng tạo phiên → 4 câu "Hôm nay bạn muốn làm gì?" xếp chồng).
- `3cdd73e` phiên mở từ tab gắn `habitId` (thiếu thì thanh "Đang nói về · X"
  không hiện); `f28dd9b` bốc NGẪU NHIÊN habit trong kho, ưu tiên chưa ghi hôm nay
  (probe api-dev: 6 user → 3 habit khác nhau).

## Hai pill ở Home + cửa Habit không cụt (owner 2026-09-04 ~16:00) — api 54c30a8

- **Home thiếu ⟨Luyện tập tình huống⟩.** `buildContext` đọc
  `hasHabit: Boolean(session.habitId)`, mà phiên Home KHÔNG chọn habit lúc mở
  (luồng 4 dời việc chọn xuống SCENE_PICK) → từ lượt thứ hai trở đi
  `eligibleTasks` chỉ còn T3. Sửa: `coach_sessions.khoSize` ghi số habit trong
  kho lúc open, Home đọc theo đó. (open() vốn đã đúng — chỉ mỗi lượt sau sai,
  nên lỗi chỉ lộ ra sau bước MOOD.)
- **Cửa Habit ghi xong thì cụt.** `afterCheckinWrite` trả END khi hết habit
  chưa ghi. Giờ: `eligibleTasks` ở cửa HABIT, khi checkin+quiz đã xong và không
  còn habit nào chưa ghi, trả `['T2','T3']`; `afterCheckinWrite` → HUB nếu còn
  task. `homeTail` nhận thêm entry HABIT nên kể chuyện ở cửa này cũng không tự
  kết thúc. Spec: 3 kỳ vọng END cũ đổi sang HUB/danh sách task (96 test xanh).
- Điểm danh qua Coach: server vốn ghi ĐÚNG (probe: totalCheckIns 0→1,
  currentStreak 0→1, lastCheckInDate hôm nay). Lỗi ở app — tab Thói quen không
  reload sau khi đóng sheet → flutter `52121547` gọi `HabitCubit.load()`.
- Pill ⟨Làm quiz với mình⟩ vắng KHÔNG phải bug: `habit-practices` derive từ
  keypoint mà user ĐÃ HỌC (`findPassedKeypointIds`), user probe mới nên rỗng.
