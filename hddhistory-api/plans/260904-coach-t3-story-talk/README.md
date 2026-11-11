# AI Coach — T3 kể chuyện: bỏ bảng hai cột, Coach đáp theo điều user kể

Ngày: 2026-09-04 · Stack: `hddhistory-api` (Flutter KHÔNG cần sửa để deploy lần 1)
Kế thừa: `plans/260824-ai-coach-v2/README.md` (xương sống v4 — task + bộ điều
phối), `coach-seed/DOC-V4-DELTA.md`. Tài liệu này chỉ đổi **bên trong task T3**.

## 1. Yêu cầu (owner, 2026-09-04 sáng)

> "ở luồng kể chuyện bình thường có thể bỏ 2 cột kéo kéo … làm như này"

| User kể | AI nên làm |
|---|---|
| Chuyện bình thường | Tiếp tục trò chuyện |
| Chuyện vui / thành công | Ghi nhận tiến bộ |
| Có cảm xúc nhưng chưa có vấn đề | Khám phá nhẹ |
| Có vấn đề lặp lại | Xác định pattern |
| User nhận ra mình muốn cải thiện | Có thể recommend Course |
| User chủ động hỏi cách cải thiện | Recommend Course |
| User không muốn tiếp tục | Dừng, không recommend |
| Vấn đề phù hợp Habit | ReAnchor / Habit |
| Vấn đề phù hợp một kỹ năng | Course |

"2 cột kéo kéo" = nhịp 3 hiện tại (`TWO_COLS`: AI soạn 5 dòng, user KÉO dòng
"vấn đề thật" sang cột phải rồi gõ "Vấn đề thật của tôi là…"). Bỏ nó thì
`TELL_2` (bậc dẫn vào), `REDRAFT` (⑤ làm lại) và `NEXT_ACTION` (nhịp 4/5 đi ra
từ câu vấn đề) mất lý do tồn tại — thay cả bốn bằng một bước.

## 2. Luồng

```
trước:  STORY → DEPTH ─deep→ TELL_2 → TWO_COLS → [REDRAFT] → NEXT_ACTION → HUB
sau:    STORY → DEPTH ─deep→ STORY_TALK ⟲ (≤3 lượt, mood thấp ≤2) → HUB / đuôi
                      └shallow→ ghi lại, 0 AI (không đổi)
```

`STORY_TALK` là MỘT bước lặp, ui kind `text` (client đã có). Mỗi câu user →
**một** call Gemini (`talkStory`) trả `{kind, reply}` theo schema; `kind` là
đúng các hàng của bảng; server dựa vào `kind` để quyết định bước kế.

## 3. Bảng → máy

| `kind` | reply (model, dưới CORE_RULES) | server | đi đâu |
|---|---|---|---|
| `normal` | 1–2 câu tiếp chuyện, ≤1 câu hỏi về sự việc | — | lặp |
| `success` | ghi nhận 1 điều CỤ THỂ (luật intentTell), không hỏi | — | lặp |
| `feeling` | đúng 1 câu hỏi mở về điều đã xảy ra; cấm "cảm thấy thế nào" | — | lặp |
| `problem` | phản chiếu 1 câu + ≤1 câu hỏi | ghi `PROBLEM_STATEMENT`; câu đầu → `dip`/`sceneContextDraft` (dịp cho T4), action = TÊN HABIT | lặp |
| *(lặp lại)* | gọi tên pattern 1 câu, hỏi họ có thấy vậy không | **0 AI**: ≥2 phiên trước trong 30 ngày có câu ghi cùng `habitId` → nhét vào prompt; 1 lần/phiên (`patternNamed`) | lặp |
| `wants_improve` | phản chiếu | không làm gì thêm — `hasCourse` sẵn → card ở đuôi như hôm nay | lặp |
| `asks_how` | 1 câu dẫn, trả lời thẳng câu hỏi | ngoài kho + có khoá → **COURSE_CARD ngay**; trong kho → HUB (pill T2 đứng đầu) | card / HUB |
| `stop` | câu CỐ ĐỊNH `COACH_STORY_STOP_LINE` | model HOẶC regex `saysStop` (0 AI); bỏ card, bỏ mời T4 | đuôi (`afterCourse`) |
| khớp Habit / kỹ năng | — | đã có: đối chiếu ngầm ở STORY → `habitId` (T2, T4 = ReAnchor) / `cardHabitId` (card) | không đổi |

Hết trần lượt → reply cuối KHÔNG hỏi (`storyRoundsLeft = 0` trong prompt) →
`taskEnd('T3')`.

## 4. Quyết định đã chốt (owner: "theo ý bạn")

- Trần 3 lượt → AI xấu nhất của T3 = match + 3 = 4 call, bằng hôm nay.
- Card "chủ động hỏi" hiện ngay, không đợi đuôi. COURSE_CARD → afterCard như cũ
  (Học ngay = kết phiên; Lưu/đóng → T4 → đuôi).
- "Dừng" từ trong câu chuyện = thẳng đuôi phiên: không card, không mời T4;
  mood cuối/rating/câu chốt vẫn chạy (một lần mỗi lần mở sheet).
- DEPTH giữ nguyên. Mood thấp: trần 2, prompt bảo không dò.
- `TELL_2`/`TWO_COLS`/`REDRAFT`/`NEXT_ACTION` PARK (như `SCENE_FEELING`): enum
  giữ, `advance()` vẫn thoát được, `rejectDraft` chỉ còn nhận ở TWO_COLS.
- Flutter: deploy lần 1 KHÔNG cần — mọi copy mới đi qua `reply` (nguyên tắc
  client cũ không học được promptKey mới). Việc dọn widget twoCols + nhãn header
  `storyTalk` là commit Flutter riêng, không chặn.

## 5. Phạm vi file

- `shared/coach.enum.ts` — `CoachStep.STORY_TALK`, `enum CoachStoryKind`.
- `shared/coach.constant.ts` — `STORY_TALK_ROUNDS=3`, `STORY_TALK_ROUNDS_LOW=2`,
  `STORY_PATTERN_MIN_SESSIONS=2`, `STORY_PATTERN_WINDOW_DAYS=30`,
  `STORY_TALK_MAX_WORDS`, `COACH_STORY_STOP_LINE` (5 locale).
- `session/coach-state-machine.ts` — ctx `storyKind/storyTalkRounds`,
  `afterStoryLine(ctx)`, `saysStop(text)`, `storyTalkCap(ctx)`, case
  STORY_TALK, `deeper()` → STORY_TALK, `taskOf`, AI_STEPS.
- `session/coach-session.service.ts` — CONVERSATION_STEPS, `isShallowJot`, ctx
  fill, nhánh runAi STORY_TALK (+ goingDeep dùng talkStory), stop cố định, ghi
  reflection theo kind, patch rounds/patternNamed/dip, promptOverride fallback.
- `session/schema + interface` — `storyTalkRounds`, `patternNamed`.
- `ai/coach-ai.types.ts` — `CoachTurnContext.storyRoundsLeft/storyRecurringSessions`,
  `CoachStoryTalkResult`, `CoachAi.talkStory`.
- `ai/coach-prompt.ts` — `buildStoryTalkPrompt`, `STORY_TALK_RESPONSE_SCHEMA`.
- `ai/gemini-coach.service.ts` — `talkStory`; `ai-usage` enum `TALK_STORY`.
- `reflection/*` — `countSessionsAboutHabit(userId, habitId, since, exceptSessionId)`.
- Spec: `coach-state-machine.spec.ts` nhóm T3 viết lại (54 test máy, gồm
  `saysStop` + `storyTalkCap` + 4 nhánh của bảng + park). Bộ đếm lặp là một
  aggregate mỏng — không spec riêng, kiểm bằng probe.
- `guardQuestion` (net câu hỏi cấm của nhịp 2) xoá — `runStoryTalk` tự chạy
  net đó bằng `talkStory` retry, không qua `reflect`.

## 6. Gate

Đã chạy 2026-09-04: `npx jest src/modules/coach` 69/69 · `npm run build` sạch ·
eslint trên 13 file đã đụng: 0 error. Sau deploy dev chạy
`coach-seed/probe-story-talk.sh [normal|stop|how]` (anon token): story → depth
→ 3 lượt → hub; "thôi mình dừng ở đây" → moodEnd, reply = dòng dừng cố định,
không card; "làm sao để cải thiện" → courseCard (habit ngoài kho) hoặc hub.
