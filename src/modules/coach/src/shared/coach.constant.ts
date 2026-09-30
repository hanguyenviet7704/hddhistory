/**
 * How long a session document survives.
 *
 * The session keeps the full exchange, both sides — it is the ONLY place a
 * Coach line is ever written, and every durable fact the session produces is
 * also written to its own collection the moment it is produced.
 *
 * 30 days rather than the original 48 hours (2026-09-04, product call): admin
 * has to be able to read a conversation back as the conversation it was, and
 * "chỉ bốn thứ user để lại" turned out to be unreadable — a column of answers
 * with the questions missing. The window is still a window: this is people's
 * own words about difficult things, and a transcript that never expires is a
 * different product than the one they agreed to.
 *
 * Changing this only affects sessions created AFTER the deploy — the TTL index
 * reads `expiresAt`, which is stamped onto each document when it is created.
 *
 * (The old 48 was itself already above 24 because the derived day-flags — `has
 * Coach appeared in this lesson today`, `has Home asked today` — read sessions
 * back, and 24 hours starts expiring them mid-day.)
 */
export const COACH_SESSION_TTL_HOURS = 24 * 365 * 10;

/**
 * How much of earlier sessions a reopened sheet shows above the divider:
 * the newest sessions, whole, until the next one would push past the line cap.
 */
export const COACH_HISTORY_SESSIONS = 3;
export const COACH_HISTORY_MAX_LINES = 60;

/**
 * How long an unfinished scene is still worth coming back to.
 *
 * The day close is lifted for a session left mid-scene, so the row survives —
 * but a scene from three months ago is not "the one I was doing", it is an
 * ambush. Three days is the grace the Coach's own "mai kể tiếp cũng được" asks
 * for, plus a weekend.
 *
 * The row is spared by STEP and found by DATE on purpose: sparing without a
 * floor keeps the history intact, and every query that could trip over an old
 * ACTIVE row already bounds itself by id or by date.
 */
export const COACH_SCENE_RESUME_MAX_DAYS = 3;

/**
 * Pending plans that make ① go quiet.
 *
 * Two commitments already waiting is enough; a third asked for at the end of a
 * lesson is how a nudge turns into a backlog.
 */
export const LESSON_DOOR_MAX_PENDING_PLANS = 2;

/**
 * How many pending plans one ③A session will walk through.
 *
 * The prototype exposes this as an editable prop (1-3); 2 is its default and
 * the number the flow was written against.
 */
export const MAX_INTENT_ROUNDS = 2;

/**
 * Consecutive "no occasion came up" answers before a plan goes to sleep.
 *
 * Not a failure count — the plan is not wrong, the context simply never
 * appeared, and continuing to ask turns a reminder into nagging.
 */
export const NO_OCCASION_SLEEP_LIMIT = 3;

/**
 * Skipped ratings before the ask is hidden for good.
 *
 * Someone who has declined three times has answered the question.
 */
export const RATING_SKIP_LIMIT = 3;

/**
 * Add-ons that may ask for a TAP in one sheet-open. TWO.
 *
 * The doc calls this "luật trần — quan trọng hơn từng luật riêng", and spells
 * out the failure it prevents: "hỏi mood đầu → làm task → hỏi mood cuối → chấm
 * điểm Coach → xem card course. Năm lần bị chặn cho một lần kể chuyện." The
 * course card is exempt because it costs no tap.
 */
export const COACH_BOOST_ACTION_CEILING = 2;

/** Consecutive skips before an add-on goes quiet. Shared by all four. */
export const COACH_BOOST_SKIP_LIMIT = 3;

/** How long a muted add-on stays away. The rating alone mutes for good. */
export const COACH_BOOST_MUTE_DAYS = 7;

/**
 * Eligible sessions between two rating asks — "1 lần / 3 phiên đủ điều kiện".
 *
 * Eligible means a session that actually ran the storytelling task; a session
 * that only practised a scene never counts, so the cadence is measured in
 * chances the reader really had.
 */
export const RATING_ELIGIBLE_SESSIONS = 3;

/**
 * Mood is stored 1..3, never 0-based — the same rule `habit_checkins.mood`
 * already follows. `mood: 0` is falsy in both Dart and JS, so every
 * `if (mood)` / `mood ?? fallback` downstream would silently drop the lowest
 * level, which is precisely the answer that matters most here.
 */
export const COACH_MOOD_MIN = 1;
// FIVE levels — "5 mức chữ: Tệ · Hơi mệt · Bình thường · Ổn · Tốt" (BA flow
// 2026-08-26). Words, never numbers: the app teaches being kind to yourself,
// and scoring a mood 3/5 is the first step of scoring yourself.
export const COACH_MOOD_MAX = 5;

/** "Tệ" and "Hơi mệt" — the two answers that count as a low day. */
export const COACH_MOOD_LOW_VALUES = [1, 2] as const;

/**
 * ④ "mời tập lại sau ≥3 tuần" — OFF for this release.
 *
 * `ai-coach-tom-tat_2.md` (2026-08-27) hoãn it with the recap it feeds: "trigger
 * này tồn tại CHỈ để nuôi khối Đổi thay trong recap. Không có recap thì nó tốn
 * một lần gọi AI và chặn user một lần để lấy dữ liệu không ai xem." The
 * machinery stays (the door, the tier, `retryCandidate`) because the same doc
 * insists the DATA keep accruing — `situationId` + `createdAt` on every answer —
 * so the vòng sau has three weeks of pairs waiting instead of starting the clock
 * again. Flip this to true when the recap ships.
 */
export const COACH_RETRY_DOOR_ENABLED = false;

/** Weeks between two answers to the same situation for ⑤ "ĐỔI THAY". */
export const CHANGE_BLOCK_MIN_WEEKS = 3;

/** Cap on one free-text turn. Long enough to tell a story, short enough to bound cost. */
export const COACH_MAX_INPUT_LENGTH = 2000;

/**
 * Turns a Long-script conversation may take before it closes itself.
 *
 * Not a soft nudge — "hết lượt là đóng, không thương lượng". The rule exists
 * because the failure mode of a listening coach is rumination: someone can
 * circle the same evening for forty minutes and leave worse than they arrived.
 * Running out jumps straight to the closing beat rather than cutting mid-word.
 *
 * 12, not the doc-v2 6: under v4 the registry itself bounds the session (3 task
 * runs), and a full T1 + T3 + T2 with the scene's feeling beat is ~10 reader
 * turns. Six was closing the third task mid-scene — one answer into a beat and
 * straight to the commitment. This is the runaway backstop, not the pacing.
 */
export const LONG_SCRIPT_MAX_TURNS = 12;

/**
 * After this local hour, a reader who started the day low does NOT get the
 * follow-up question.
 *
 * Digging into a hard evening at midnight is how a coach becomes the thing
 * keeping somebody awake. The draft still gets built — they are not turned
 * away — but nobody asks them to go deeper first.
 */
export const COACH_LATE_NIGHT_HOUR = 22;

/**
 * Keypoints nhịp 4 points at. ONE.
 *
 * The ⑦ diagram writes "gợi 1 keypoint (tối đa 2)" — one is the suggestion, two
 * is only the ceiling, and shipping the ceiling turned every closing beat into a
 * short reading list. A catalogue at the end of a personal conversation reads as
 * an upsell, which is the exact thing the beat is not.
 *
 * READ from the habit's own keypoints, never generated: a model inventing a
 * "keypoint" sends the reader looking for something nobody wrote.
 */
export const COACH_KEYPOINT_SUGGESTION_LIMIT = 1;

/**
 * Most answers one scene may take before the commitment question.
 *
 * The scene is FLEXIBLE (product call 2026-08-26): after each answer the Coach
 * either closes in one line or — when the answer is thin, or one natural
 * follow-up would sharpen it — asks ONE question and the reader gets another
 * turn. The Coach decides by what it wrote: a reply that ends in a question
 * keeps the scene open. Three is the ceiling; the last reply never asks.
 */
export const SITUATION_PROBE_ROUNDS = 3;

/**
 * Lines the two-column draft proposes. FIVE, generated proactively.
 *
 * Product call (2026-08-25): the left column is the Coach OFFERING five
 * concrete "chuyện đã xảy ra" lines drawn from the telling — rephrased and
 * completed where the reader was terse — for the reader to pick from, edit, or
 * delete. The earlier quote-only rule (every line a literal substring of what
 * they typed) produced two-line drafts from short tellings, which read as the
 * Coach not having listened. The reader still owns the outcome: nothing enters
 * the right column, and no problem sentence is saved, except by their hand.
 */
export const TWO_COLS_DRAFT_LINES = 5;

/**
 * Word ceiling on one situation scene — scene plus its closing question.
 *
 * 40, chốt 2026-08-27 evening, from `ai-coach-tom-tat_2.md`: "cảnh viết sẵn
 * 2–3 câu … kết bằng đúng một câu hỏi", and its own example runs 28 words. This
 * replaced the 70 of that same afternoon — which had replaced the 30 of
 * 2026-08-25. The swing is real and worth recording: a scene long enough to
 * draw a lesson from was the ask when the practice took 3–5 turns; with the
 * practice back to ONE exchange the scene is a doorway again.
 *
 * Historic note kept because the reasoning still applies if turns ever return: Thirty words bought
 * brevity at the cost of the exercise: the reader met a caption, not a moment,
 * and there was nothing in it to draw a lesson from ("chưa được dài để user rút
 * ra được bài học nào đó đáng"). Fifty to seventy words fits a setting, ONE
 * detail that makes the choice cost something, and the question — about fifteen
 * seconds of reading, which the reader spends stepping INTO the scene rather
 * than studying it. Still enforced server-side (one retry, then trust) because
 * scenes are CACHED: an overlong one would be every reader's turn until an
 * editor noticed.
 */
// 42: readers found 50-word scenes hard to follow (bug sheet 2026-08-28 16:18 —
// "tình huống khó hiểu… nếu mô tả trong 2 câu ngắn được thì tốt nhất"), and the
// twenty reference dialogues run 30–45 words, so this asks for the short end of
// the shape they prescribe rather than a different shape. The generator's own
// gate keeps its +8 tolerance, so a 45-word scene that earns its length still
// passes instead of costing a second call.
export const SITUATION_MAX_WORDS = 42;

/**
 * Floor on a scene, in words.
 *
 * Paired with the ceiling on purpose: the failure this replaces was scenes
 * coming in SHORT, and a ceiling alone never fixed that. Under this the scene
 * has a setting but no tension, which is the caption problem again.
 */
export const SITUATION_MIN_WORDS = 20;

/**
 * Register EXAMPLES for a scene's setting — the ten from the owner's reference
 * doc (2026-08-28), which were written for a student reader.
 *
 * Examples, not a menu — the owner's correction the same day: "bối cảnh vẫn
 * gắn chặt chẽ theo habit, nhưng mỗi habit sẽ phụ thuộc vào độ tuổi, tính cách
 * của từng user mà sẽ có 20 bối cảnh khác nhau." The setting is INVENTED per
 * scene from habit × reader (age band, goal, the corner of life their own
 * words point at); this list only shows the model what an "ordinary moment
 * with a small cost" looks like. Vietnamese on purpose: the model transposes
 * the register into the reader's language and world.
 */
export const COACH_SCENE_SETTING_EXAMPLES: readonly string[] = [
  'Lớp học buổi tối, 15 phút cuối',
  'Bàn làm việc chiều thứ sáu',
  'Bữa cơm gia đình',
  'Nhóm chat bạn bè',
  'Họp nhóm dự án',
  'Phòng ngủ, 11 giờ đêm',
  'Quán cà phê học nhóm',
  'Buổi review với người hướng dẫn',
  'Sáng thứ hai, danh sách việc dài',
  'Ba ngày trước kỳ thi',
];

/**
 * The action question a scene falls back to when its own cannot be found.
 *
 * A generated scene is REQUIRED to end in a question (one retry enforces it),
 * but a model that still ends on a statement — "điện thoại chờ bạn phản hồi."
 * — used to leave the feeling beat with nothing to ask next: the reader typed
 * "sao nữa?" at a silent Coach (seen on the simulator, 2026-08-28). The chain
 * "cảm xúc → hành động" must never dead-end, so the server owns a plain
 * fallback in every shipped language.
 */
export const COACH_SCENE_DEFAULT_QUESTION: Record<string, string> = {
  vi: 'Bạn sẽ làm gì?',
  en: 'What do you do?',
  zh: '你会怎么做？',
  ja: 'あなたならどうしますか？',
  ko: '당신이라면 어떻게 하겠어요?',
};

/**
 * The line said when a scene cannot be built AT RENDER — the peek let the step
 * through (a habit existed) but generation failed on the turn itself: provider
 * down, no API key on the deployment, an empty fallback pool. The design's rule
 * is "a missing scene is a shorter conversation, not a broken one", so the flow
 * jumps to the commitment — but jumping silently is what "AI coach im luôn"
 * looked like on-device (owner, 2026-08-29). Server-owned text, not a promptKey:
 * clients already in the field cannot learn a new key.
 */
/**
 * Spoken with the first-habit card ("phải điều hướng user học bài và thêm thói
 * quen… add habit mình sẽ dựng tình huống cho bạn" — owner, 2026-08-29): the
 * card alone reads as an ad, the line makes it a direction — learn the lesson,
 * add the habit, and the practice scenes unlock. Server-owned text, not a
 * promptKey: clients already in the field cannot learn a new key.
 */
export const COACH_FIRST_HABIT_INVITE_LINE: Record<string, string> = {
  vi: 'Bạn chưa có thói quen nào trong kho. Học thử bài dưới đây để thêm thói quen nhé — có habit rồi, mình sẽ dựng tình huống cho bạn tập.',
  en: "You don't have any habits yet. Try the lesson below to add one — once you have a habit, I'll build practice scenes for you.",
  zh: '你还没有任何习惯。试试下面这节课来添加一个吧 — 有了习惯，我就能为你搭建练习情境。',
  ja: 'まだ習慣がありません。下のレッスンで習慣を追加してみてください。習慣ができたら、練習シーンを用意します。',
  ko: '아직 습관이 없어요. 아래 강의로 습관을 추가해 보세요. 습관이 생기면 연습 상황을 만들어 드릴게요.',
};

/**
 * Lines the story conversation (STORY_TALK) may run before T3 closes itself.
 *
 * THREE, so T3's worst case stays what it was: the silent match plus three
 * replies = four calls, the same bill as match + nhịp 2 + the draft + nhịp 4.
 * The last reply is told to ask nothing — a question with no box under it is
 * the bug every closing beat in this feature has had once. A low day gets two:
 * "không đào sâu khi người ta đang mệt" still holds even without nhịp 2.
 */
export const STORY_TALK_ROUNDS = 3;
export const STORY_TALK_ROUNDS_LOW = 2;

/**
 * "Có vấn đề lặp lại → xác định pattern" — but the PATTERN is counted, never
 * guessed. A subject is recurring when at least this many EARLIER sessions,
 * inside the window, filed a line about the same habit. Two earlier sessions
 * make today the third time; naming it once a session is enough.
 */
export const STORY_PATTERN_MIN_SESSIONS = 2;
export const STORY_PATTERN_WINDOW_DAYS = 30;

/** Word ceiling on one story reply — two short sentences, said out loud. */
export const STORY_TALK_MAX_WORDS = 40;

/**
 * "User không muốn tiếp tục → dừng, không recommend." Fixed, in five
 * languages, because the one thing a model must not do to somebody who just
 * said "enough" is keep talking. Server-owned text, not a promptKey: clients
 * already in the field cannot learn a new key.
 */
/**
 * Owner (2026-09-04, on the simulator): "Kể chuyện hôm nay" at Home opens with
 * ONE open question and no chips — no "Không có gì đặc biệt", no habit picker.
 * The app renders the key; the reader just talks.
 */
export const COACH_STORY_OPEN_KEY = 'coach.prompt.storyOpen';

export const COACH_STORY_STOP_LINE: Record<string, string> = {
  vi: 'Ừ, mình nghe rồi. Khi nào muốn kể tiếp thì mình ở đây.',
  en: "Okay, I hear you. Whenever you want to pick it up again, I'm here.",
  zh: '好，我听到了。想继续的时候，我就在这里。',
  ja: 'うん、聞いたよ。また話したくなったら、ここにいるから。',
  ko: '응, 들었어. 다시 이야기하고 싶을 때 여기 있을게.',
};

/**
 * Home never closes on its own (owner, 2026-09-04): after the card is put
 * away or a scene is left for later, the box stays open under this one line.
 */
export const COACH_STORY_CONTINUE_LINE: Record<string, string> = {
  vi: 'Ừ. Còn chuyện gì khác không, kể mình nghe.',
  en: "Okay. Anything else on your mind? I'm listening.",
  zh: '好。还有别的事吗？说给我听。',
  ja: 'うん。ほかに何かある？聞かせて。',
  ko: '응. 다른 이야기 있어? 들려줘.',
};

/**
 * Luồng 4 (design "AI Coach Flows", 2026-09-03) — the Home scene is JUDGED.
 * On track: one specific piece of praise. Off track: a sample line and one
 * line of why. Both short; the judge speaks about the MOVE, never the person.
 */
/**
 * Luồng 4 — the other person's push-back between the two turns of a scene.
 * Long enough to react and ask one thing back, short enough that the scene
 * still reads as chat rather than a script.
 */
export const SCENE_REACT_MAX_WORDS = 40;

/**
 * How many ways forward the reaction names for the reader's next line.
 *
 * TWO OR THREE since 2026-09-08 (owner: "không cần thiết phải luôn cố định là
 * 3 option… mà có thể là 2"). Three was fixed on the reasoning that "two reads
 * as right-and-wrong, four stops being a choice and becomes a list to skim" —
 * and the first half of that only holds when one of the two is a bad option.
 * A third invented to reach the count IS that bad option, so forcing three was
 * producing the very thing it was written to avoid. The rule that replaces it
 * is about quality, not count: three when the moment genuinely offers three
 * approaches, two when it offers two, and never pad. Four is still too many.
 *
 * They are deliberately NOT
 * sent as pills — see `ui.samples = []` at the scene: a button to tap is a
 * button to copy, and the exercise is the sentence the reader writes. Naming
 * the approaches in the reaction's own text teaches the contrast without
 * handing over an answer to paste.
 */
export const SCENE_OPTION_MAX = 3;

/** Below this the trio is dropped: one "choice" is not a choice. */
export const SCENE_OPTION_MIN = 2;

/** Two to four words: the NAME of an approach ("Phản ánh cảm xúc"), never a sentence. */
export const SCENE_OPTION_LABEL_MAX_WORDS = 4;

/**
 * The sample line under each label.
 *
 * Short on purpose. It exists to make the approach concrete enough to choose
 * between, not to be a finished answer — a reader who can copy a whole reply
 * has practised nothing.
 */
export const SCENE_OPTION_MAX_WORDS = 12;

/**
 * Hard safety bounds on an option, in CHARACTERS — not the style rule.
 *
 * Style is the prompt's job ("2–4 words", `SCENE_OPTION_MAX_WORDS`). These
 * exist only to stop a runaway generation reaching the screen, so they are
 * deliberately loose: an entry over them is garbage, not merely wordy.
 *
 * They used to be 40 and 120 and were doing the prompt's job badly. The unit is
 * the trap: the prompt counts WORDS, the filter counts CHARACTERS, and four
 * Vietnamese words carry accents — "Tách sự thật khỏi cách mình diễn giải" is
 * 37 characters, three under the old cap, and it is a habit's own NAME, which
 * is exactly what a label echoes. A habit named slightly longer pushed its
 * labels over, they were dropped one by one in silence, and when fewer than
 * two survived the whole set went with them: the reader got a scene with no
 * answers to choose from (owner on-device 2026-09-09).
 */
export const SCENE_OPTION_LABEL_MAX_CHARS = 80;
export const SCENE_OPTION_TEXT_MAX_CHARS = 220;

/**
 * 25 was one sentence of praise. Since 2026-09-05 the on-track branch may also
 * offer the lesson's move as an extra tool when it genuinely differs from what
 * the reader did — the alternative belongs HERE, beside an answer that worked,
 * not in the miss branch where it read as "here is the right answer instead".
 * That needs a second sentence to fit.
 *
 * 60 since 2026-09-08. The closing reply was one flat sentence and the owner
 * called it thin next to what they had written by hand: it named what the
 * reader's line achieved and stopped there. Two things were missing and both
 * need room — the ARC (how the other person moved from the top of the scene to
 * the end of it) and the scene's own lesson, which was authored, stored, passed
 * into the prompt's context and then read by nobody.
 */
export const SCENE_JUDGE_ON_TRACK_MAX_WORDS = 60;
export const SCENE_JUDGE_OFF_TRACK_MAX_WORDS = 35;

/**
 * Fixed lines of luồng 4, five languages each. Server-owned text sent as
 * `reply` (never a promptKey): clients already in the field cannot learn a
 * new key, and every one of these closes or bridges a beat where a generated
 * sentence was the bug last time.
 */
/** Said after the on-track praise, only when a course card follows it. */
export const COACH_SCENE_CARD_LEAD_LINE: Record<string, string> = {
  vi: 'Đúng ý mình đang nghĩ luôn. Bạn tới được chỗ này rồi thì khoá dưới đây là bước hợp lý tiếp theo.',
  en: "That's exactly it. Now that you're here, the course below is the natural next step.",
  zh: '正是我想的那样。走到这一步了，下面这门课是很自然的下一步。',
  ja: 'まさにそのとおり。ここまで来たなら、下のコースが自然な次の一歩です。',
  ko: '바로 그거예요. 여기까지 왔으니 아래 강의가 자연스러운 다음 단계예요.',
};
/** ⟨Để sau⟩ at the retry offer. */
export const COACH_SCENE_LATER_LINE: Record<string, string> = {
  vi: 'Được, để lúc khác. Cảnh này vẫn ở đó.',
  en: "Okay, another time. The scene will still be here.",
  zh: '好，下次再说。这个情境还在这里。',
  ja: 'わかりました、また今度。このシーンはここにあります。',
  ko: '좋아요, 다음에 해요. 이 상황은 그대로 있을 거예요.',
};
/** The second try was off track too — close in one line, count nothing. */
export const COACH_SCENE_GIVE_UP_LINE: Record<string, string> = {
  vi: 'Cảnh này để đó nhé — lúc khác mình tập lại.',
  en: "Let's leave this scene here — we'll try it again another time.",
  zh: '这个情境先放着吧 — 下次我们再练。',
  ja: 'このシーンはここまでにしましょう。また別の時に練習しましょう。',
  ko: '이 상황은 여기까지 해요. 다음에 다시 연습해요.',
};
/** FREE_TALK reached its cap and the story connects to a course. */
export const COACH_STORY_CARD_LEAD_LINE: Record<string, string> = {
  vi: 'Nếu bạn muốn đi sâu hơn chuyện này, có một khoá nói đúng về nó.',
  en: "If you want to go deeper into this, there's a course that speaks to exactly it.",
  zh: '如果你想更深入地聊这件事，有一门课正好讲到它。',
  ja: 'この話をもっと深めたいなら、ちょうどそれについてのコースがあります。',
  ko: '이 이야기를 더 깊이 다뤄 보고 싶다면, 딱 그 얘기를 하는 강의가 있어요.',
};
/**
 * The card is the course they are partway through, not one the story matched.
 *
 * Owner 2026-09-05: the lead line above the card cannot claim "có một khoá nói
 * đúng về nó" here — nothing matched, and saying it did is the "gợi bừa một
 * khoá cho có" the doc forbids. This says plainly what the card is.
 */
export const COACH_STORY_RESUME_LEAD_LINE: Record<string, string> = {
  vi: 'Mình nghe rồi. Bạn đang học dở một khoá — quay lại chỗ đó luôn nhé?',
  en: "I heard you. You have a course you're partway through — want to pick it back up?",
  zh: '我听到了。你有一门课还没学完 — 要接着学吗？',
  ja: '聞きました。途中のコースがありますね — その続きから始めますか。',
  ko: '잘 들었어요. 아직 듣다 만 강의가 있어요. 이어서 해 볼까요?',
};
/** FREE_TALK reached its cap and nothing connects — "đóng bằng một câu". */
export const COACH_STORY_NO_COURSE_LINE: Record<string, string> = {
  vi: 'Mình nghe rồi. Cảm ơn bạn đã kể — mai kể tiếp cũng được.',
  en: "I heard you. Thanks for telling me — we can pick this up tomorrow.",
  zh: '我听到了。谢谢你愿意说 — 明天接着聊也可以。',
  ja: '聞きました。話してくれてありがとう。明日また続けてもいいですよ。',
  ko: '잘 들었어요. 이야기해 줘서 고마워요. 내일 이어서 해도 좋아요.',
};
/**
 * They ASKED to be pointed at something to learn and the library has nothing
 * that fits. Saying so is the answer; "tuyệt đối không gợi bừa một khoá cho
 * có" — and silence to a direct request reads as being ignored.
 */
export const COACH_STORY_NO_MATCH_LINE: Record<string, string> = {
  vi: 'Mình chưa thấy khoá nào khớp hẳn với chuyện này. Kể thêm một chút để mình tìm cho đúng nhé?',
  en: "I can't see a course that really fits this yet. Tell me a bit more so I can find the right one?",
  zh: '我还没看到真正合适的课程。再多说一点，我好帮你找准？',
  ja: 'これにぴったり合うコースはまだ見当たりません。もう少し聞かせてもらえますか？',
  ko: '아직 딱 맞는 코스가 안 보여요. 조금만 더 이야기해 주면 제대로 찾아볼게요.',
};

/** SCENE_PICK — the name typed matches nothing in the kho. */
export const COACH_SCENE_PICK_MISS_LINE: Record<string, string> = {
  vi: 'Mình chưa thấy habit đó trong kho của bạn. Bạn chọn một cái ở dưới nhé.',
  en: "I can't find that habit in your collection. Pick one below.",
  zh: '你的习惯库里没有这个。从下面选一个吧。',
  ja: 'その習慣はあなたのリストに見つかりません。下から一つ選んでください。',
  ko: '그 습관은 목록에서 찾을 수 없어요. 아래에서 하나 골라 주세요.',
};

/**
 * Luồng 5 — questions the in-chat quiz asks per run. Three, as the design's
 * screen counts them ("Ba câu, mình hỏi trong chat luôn").
 */
export const QUIZ_IN_CHAT_COUNT = 3;
/** Word ceiling on the quiz's feedback lines — "câu đó chưa đúng" and the closing summary. */
export const QUIZ_FEEDBACK_MAX_WORDS = 35;

/** Luồng 5 fixed lines — server text, five languages, sent as `reply`. */
/** `{done}` = the habit just written, `{next}` = the next one still unwritten today. */
export const COACH_CHECKIN_OFFER_LINE: Record<string, string> = {
  vi: 'Ghi xong «{done}». Trong kho còn «{next}» chưa ghi hôm nay — làm luôn nhé?',
  en: '«{done}» is written down. «{next}» is still unwritten today — do it now?',
  zh: '«{done}» 已经记好了。今天还有 «{next}» 没记 — 现在一起记？',
  ja: '«{done}» を記録しました。今日はまだ «{next}» が残っています — 今やりますか？',
  ko: '«{done}» 기록했어요. 오늘 아직 «{next}» 가 남았어요 — 지금 할까요?',
};
export const COACH_CHECKIN_ALL_DONE_LINE: Record<string, string> = {
  vi: 'Hôm nay ghi đủ rồi. Mai mình lại hỏi nhé.',
  en: "That's everything written for today. I'll ask again tomorrow.",
  zh: '今天都记好了。明天我再问你。',
  ja: '今日の記録はこれで全部です。明日また聞きます。',
  ko: '오늘 기록은 다 됐어요. 내일 다시 물어볼게요.',
};
export const COACH_CHECKIN_LATER_LINE: Record<string, string> = {
  vi: 'Được. Mai ghi tiếp nhé.',
  en: 'Okay. We can write the rest tomorrow.',
  zh: '好。剩下的明天再记。',
  ja: 'わかりました。残りは明日にしましょう。',
  ko: '좋아요. 나머지는 내일 기록해요.',
};
export const COACH_CHECKIN_MISSED_LINE: Record<string, string> = {
  vi: 'Mình ghi hôm nay là chưa có dịp — không bỏ trống ngày.',
  en: "Noted as no occasion today — the day isn't left blank.",
  zh: '记下今天没有机会 — 这一天不留空。',
  ja: '今日は機会がなかったと記録しました。空白の日にはしません。',
  ko: '오늘은 기회가 없었다고 기록했어요. 빈 날로 남기지 않아요.',
};
/** `{n}` = number of questions. */
export const COACH_QUIZ_INTRO_LINE: Record<string, string> = {
  vi: '{n} câu, mình hỏi trong chat luôn.',
  en: "{n} questions — I'll ask them right here.",
  zh: '{n} 道题，我就在这里问你。',
  ja: '{n} 問、ここで直接聞きます。',
  ko: '{n} 문제, 여기서 바로 물어볼게요.',
};
/** `{i}` = question number, `{q}` = the question. */
export const COACH_QUIZ_QUESTION_LINE: Record<string, string> = {
  vi: 'Câu {i}: {q}',
  en: 'Question {i}: {q}',
  zh: '第 {i} 题：{q}',
  ja: '問 {i}：{q}',
  ko: '{i}번: {q}',
};
/** Stands in when the model could not explain a wrong answer. `{a}` = the right option. */
export const COACH_QUIZ_WRONG_FALLBACK_LINE: Record<string, string> = {
  vi: 'Câu đó chưa đúng. Đáp án là «{a}».',
  en: "Not that one. The answer is «{a}».",
  zh: '这题不对。答案是 «{a}»。',
  ja: 'それは違います。答えは «{a}» です。',
  ko: '그건 아니에요. 정답은 «{a}» 예요.',
};
export const COACH_QUIZ_RIGHT_LINE: Record<string, string> = {
  vi: 'Đúng rồi.',
  en: 'Right.',
  zh: '对。',
  ja: '正解です。',
  ko: '맞아요.',
};
/** Stands in when the model could not write the closing summary. `{n}` = questions. */
export const COACH_QUIZ_DONE_LINE: Record<string, string> = {
  vi: 'Hết {n} câu. Mình ghi hôm nay cho habit này.',
  en: "That's all {n}. I've written today down for this habit.",
  zh: '{n} 道题做完了。这个习惯今天记好了。',
  ja: '{n} 問おわり。この習慣の今日を記録しました。',
  ko: '{n} 문제 끝. 이 습관의 오늘을 기록했어요.',
};
export const COACH_CHECKIN_DONE_FALLBACK_LINE: Record<string, string> = {
  vi: 'Vậy là làm được rồi. Mình ghi hôm nay cho habit này.',
  en: "So you did it. I've written today down for this habit.",
  zh: '这么说你做到了。这个习惯今天记好了。',
  ja: 'できたんですね。この習慣の今日を記録しました。',
  ko: '해냈네요. 이 습관의 오늘을 기록했어요.',
};

/**
 * The memory layer's arithmetic of doubt (owner's doc 2026-09-04, §5).
 *
 * A memory heard once starts between the floor and the cap, never higher —
 * "AI không được kết luận một pattern lâu dài chỉ từ một câu nói". Each time it
 * is heard again it gains one step; a `possible` pattern turns `active` at the
 * evidence count below; nothing ever reaches certainty.
 */
export const MEMORY_NEW_MIN_CONFIDENCE = 0.3;
export const MEMORY_NEW_MAX_CONFIDENCE = 0.7;
export const MEMORY_REINFORCE_STEP = 0.1;
export const MEMORY_MAX_CONFIDENCE = 0.95;
export const MEMORY_ACTIVE_EVIDENCE = 2;
/** How many memories / goals / episodes / progress rows the prompt is handed. */
export const MEMORY_CONTEXT_LIMIT = 8;
export const MEMORY_GOALS_LIMIT = 3;
export const MEMORY_EPISODES_LIMIT = 3;
export const MEMORY_PROGRESS_LIMIT = 3;
/** The most memories one session may add or reinforce — a conversation is not a census. */
export const MEMORY_EXTRACT_MAX = 6;
/** A session with fewer reader lines than this is not extracted from. */
export const MEMORY_EXTRACT_MIN_USER_LINES = 1;

/**
 * THẺ NHỚ — ngân sách cứng cho mọi thứ Coach nhớ về một người (2026-09-17).
 *
 * Trước bản này khối nhớ được dựng lại mỗi lượt từ 4 query và chỉ vào đúng một
 * prompt, còn phần "nhớ nguyên văn" là 30 dòng raw. Cả hai đều lớn dần theo
 * lịch sử, nên câu hỏi của owner ("rút gọn raw không thì tràn context") là câu
 * hỏi đúng: chỗ chặn phải là một CAP CỨNG, không phải một giới hạn số dòng.
 *
 * 700 ký tự ≈ 200 token, và nó không đổi dù người ta dùng ba năm. Thẻ được cắt
 * theo thứ tự ưu tiên của `buildMemoryCard`, nên khi tràn thì thứ mất đi là
 * pattern (đoán) chứ không phải nghề nghiệp (dữ kiện).
 */
export const MEMORY_CARD_MAX_CHARS = 700;
/** Mỗi dòng của thẻ. Dài hơn thì cắt ở ranh giới từ và thêm "…". */
export const MEMORY_CARD_LINE_MAX_CHARS = 120;
export const MEMORY_CARD_PEOPLE_LIMIT = 3;
export const MEMORY_CARD_GOALS_LIMIT = 2;
export const MEMORY_CARD_EPISODES_LIMIT = 3;
export const MEMORY_CARD_PATTERNS_LIMIT = 2;
export const MEMORY_CARD_PROGRESS_LIMIT = 2;

/**
 * Thứ "đã biết" gửi kèm khi cô đọng: thẻ nhớ + danh sách rút gọn này.
 *
 * Trước đây là 40 memory thô, gửi lại nguyên bộ MỖI lần cô đọng (mà một phiên
 * dài cô đọng nhiều lần). Model chỉ cần đủ để KHỚP một dòng cũ theo id, không
 * cần đọc cả hồ sơ.
 */
export const MEMORY_EXTRACT_KNOWN_LIMIT = 25;

/**
 * Bao nhiêu dòng trước watermark được gửi kèm làm ngữ cảnh khi cô đọng tăng dần.
 *
 * Không có nó thì đoạn mới mở đầu bằng một câu trả lời không có câu hỏi, và
 * model cô đọng sai chủ thể.
 */
export const MEMORY_EXTRACT_LOOKBACK_LINES = 2;

/**
 * Mỗi user giữ tối đa bao nhiêu memory còn sống, và độ tươi nửa đời (ngày).
 *
 * `findLiveForUser` cũ sort `confidence:-1`: một dòng đã leo lên 0.95 từ tháng
 * trước chiếm chỗ vĩnh viễn, còn thứ vừa nghe tuần này không bao giờ vào được
 * prompt. Điểm hiệu dụng = confidence × 0.5^(tuổi/nửa đời) trả lại chỗ cho cái
 * mới mà không xoá cái cũ — vượt cap thì dòng điểm thấp nhất chuyển `inactive`,
 * KHÔNG xoá: raw vẫn là nguồn sự thật.
 */
export const MEMORY_LIVE_CAP = 60;
export const MEMORY_FRESHNESS_HALF_LIFE_DAYS = 60;
/** Bao nhiêu dòng được đọc lên để xếp lại trong code. Xếp 30 dòng rẻ hơn dựng aggregate. */
export const MEMORY_RANK_SCAN_LIMIT = 30;

/**
 * Câu chào mở phiên nhắc lại chuyện hôm trước — mảnh chủ đề, ≤80 ký tự.
 *
 * Chỉ MẢNH này là chữ sinh ra; khung câu là `coach.prompt.hubBack` trong slang,
 * vì `reply` và `promptKey` không bao giờ cùng có giá trị (hợp đồng i18n của
 * Coach). Model không thể làm mất câu hỏi mở phiên, vì câu hỏi không do nó viết.
 */
export const MEMORY_GREETING_TOPIC_MAX_CHARS = 80;

/**
 * TRA CỨU — khi user hỏi thẳng về quá khứ ("còn nhớ mình từng kể…").
 *
 * Thẻ nhớ trả lời được phần lớn, nhưng nó là bản cô đọng: một câu hỏi cụ thể
 * cần đúng chữ họ đã nói. Cửa sổ 200 dòng gần nhất quét bằng regex trên index
 * `{userId, createdAt:-1}` đã có — KHÔNG dựng text index, vì text index bắt
 * Mongo trả giá ghi trên mỗi tin nhắn còn lợi ích chỉ xuất hiện lúc user hỏi.
 */
export const MEMORY_RECALL_SCAN_LINES = 200;
export const MEMORY_RECALL_MAX_LINES = 6;
export const MEMORY_RECALL_MIN_KEYWORD_CHARS = 3;

/**
 * Luồng 6 — "níu lại khi user rời đi" has the tightest ceiling in the product:
 * one plea per close, and after this many consecutive sessions closed against
 * the plea it stops appearing at all. A completed session (END) or a "stay"
 * resets the run.
 */
export const EXIT_PLEA_OFF_AFTER = 2;

/**
 * Skipped exit-feedback asks before that question retires too.
 *
 * ⟨Đóng⟩ asks ONE thing, and which one depends on whether the reader has ever
 * told us why they left: no answer on file → "chỗ nào chưa ổn?"; an answer on
 * file → the plea instead. Somebody who has closed the question twice without
 * answering has answered it, so the plea takes over for them as well.
 */
export const EXIT_FEEDBACK_OFF_AFTER = 2;

/**
 * Luồng 6 — defaults for the rating ask shown after ⟨Vẫn đóng⟩.
 *
 * Every one of these is an admin knob (see `RatingAskConfig`); the values here
 * are only what an environment that has never been configured gets. They are
 * deliberately conservative: a question on the way out is the most intrusive
 * place to ask anything, so the untouched default asks a reader at most once a
 * week and leaves somebody who deferred alone for three days.
 */
export const RATING_ASK_ENABLED_DEFAULT = true;
export const RATING_ASK_MIN_DAYS_DEFAULT = 7;
export const RATING_ASK_SNOOZE_DAYS_DEFAULT = 3;
export const RATING_ASK_EVERY_NTH_EXIT_DEFAULT = 1;
export const RATING_ASK_PROBABILITY_DEFAULT = 100;
export const RATING_ASK_MAX_PER_USER_DEFAULT = 0;

/**
 * Luồng 2/3 — the talk after a keypoint and the course recap.
 * Word ceilings from the design's screens; the recap quiz deals this many
 * questions from the whole course.
 */
export const TALK_SUMMARY_MAX_WORDS = 60;
export const TALK_REPLY_MAX_WORDS = 25;
export const QUIZ_BACK_MAX_WORDS = 35;
export const TALK_PRAISE_MAX_WORDS = 25;
/**
 * The open follow-up after the grading turn: how long one answer may run, and
 * how many the reader gets.
 *
 * The budget is a FALLBACK — `CoachConfig.talkFreeMaxTurns` is the live value,
 * so the cost of this can be pulled down from the admin page without a deploy.
 * Every turn is one Gemini call on top of the two the branch already spends.
 */
export const TALK_FREE_MAX_WORDS = 60;
export const TALK_FREE_MAX_TURNS_DEFAULT = 4;
export const RECAP_WHY_MAX_WORDS = 25;
export const RECAP_LESSON_CHIPS = 5;
export const RECAP_QUIZ_COUNT = 5;
/** How much of a lesson's theory the summary prompt may see, in characters. */
export const TALK_BODY_MAX_CHARS = 6000;

/** Luồng 2 — TALK_WHEN's two closing lines, five languages, sent as `reply`. */
/**
 * Luồng 2 — what the Coach says after the grading turn, to open the floor.
 *
 * This replaced a line that pushed to the next keypoint ("Phần này xong rồi.
 * Học tiếp phần tiếp theo nhé."), which ended the talk at the exact moment a
 * reader has just been told what they missed and is most likely to want to ask
 * about it (owner, 2026-09-05).
 */
export const COACH_TALK_FREE_INVITE_LINE: Record<string, string> = {
  vi: 'Còn gì bạn muốn hỏi thêm về bài này không?',
  en: 'Anything else you want to ask about this part?',
  zh: '关于这一部分，你还想问什么吗？',
  ja: 'このパートについて、ほかに聞きたいことはありますか？',
  ko: '이 파트에 대해 더 묻고 싶은 게 있나요?',
};

/**
 * Luồng 2 — the turn budget is spent. Closes the floor without pointing
 * anywhere: the reader leaves by the sheet's own Đóng, and the next keypoint
 * is theirs to start from the Roadmap.
 */
export const COACH_TALK_FREE_DONE_LINE: Record<string, string> = {
  vi: 'Mình dừng phần hỏi đáp ở đây nhé. Bài này bạn nắm được rồi.',
  en: "Let's stop the questions here. You have this part.",
  zh: '问答就到这里吧。这一部分你已经掌握了。',
  ja: '質問はここまでにしましょう。このパートはもう大丈夫です。',
  ko: '질문은 여기까지 할게요. 이 파트는 이제 괜찮아요.',
};

/**
 * Luồng 2 — the answer could not be written. The turn is still SPENT: a failing
 * model must not become an unlimited supply of free turns.
 */
export const COACH_TALK_FREE_FALLBACK_LINE: Record<string, string> = {
  vi: 'Câu này mình chưa trả lời được. Bạn hỏi lại theo cách khác xem sao.',
  en: "I couldn't answer that one. Try asking it a different way.",
  zh: '这个问题我暂时答不上来。换个说法再问问看。',
  ja: 'その質問には答えられませんでした。言い方を変えて聞いてみてください。',
  ko: '그 질문에는 답하지 못했어요. 다르게 물어봐 주세요.',
};

export const COACH_TALK_CONTINUE_LINE: Record<string, string> = {
  vi: 'Được. Mình đóng ở đây — phần sau đang chờ bạn.',
  en: "Okay. I'll close here — the next part is waiting for you.",
  zh: '好。我先到这里 — 下一部分在等你。',
  ja: 'わかりました。ここで閉じます。次のパートが待っています。',
  ko: '좋아요. 여기서 닫을게요. 다음 파트가 기다리고 있어요.',
};
export const COACH_TALK_LATER_LINE: Record<string, string> = {
  vi: 'Không sao. Học được đến đây là đủ cho hôm nay.',
  en: "That's fine. Getting this far is enough for today.",
  zh: '没关系。今天学到这里就够了。',
  ja: '大丈夫です。今日はここまでで十分です。',
  ko: '괜찮아요. 오늘은 여기까지면 충분해요.',
};
/** Stands in when the summary could not be written: hand over to the quiz. */
export const COACH_TALK_SUMMARY_FALLBACK_LINE: Record<string, string> = {
  vi: 'Phần vừa rồi mình chưa gói lại được. Chỗ nào bạn thấy khó làm nhất?',
  en: "I couldn't wrap that part up just now. Which bit feels hardest to actually do?",
  zh: '刚才那部分我没能总结好。哪一点你觉得最难做到？',
  ja: 'いまの部分をうまくまとめられませんでした。実際にやるのが一番難しいのはどこですか？',
  ko: '방금 부분을 잘 정리하지 못했어요. 실제로 하기 가장 어려운 데는 어디예요?',
};

/**
 * Luồng 1 — Onboarding Coach. Eight questions, four of them optional
 * (admin toggles); the chips are SUGGESTIONS, typing anything else is kept
 * verbatim. Labels are server text in five languages because which chip is
 * pre-lit is decided here, from what the app already knows.
 */
export const ONBOARD_VERSION = 1;
export const ONBOARD_TOTAL_STEPS = 8;

export type CoachOnboardOption = { value: string; label: Record<string, string> };
export const COACH_ONBOARD_OPTIONS: Record<string, CoachOnboardOption[]> = {
  intro: [{ value: 'start', label: { vi: 'Bắt đầu', en: 'Start', zh: '开始', ja: '始める', ko: '시작' } }],
  // "Trả lời nhầm thì trả lời lại được": one step back, the old answer lit.
  nav: [{ value: 'back', label: { vi: '← Câu trước', en: '← Previous', zh: '← 上一题', ja: '← 前の質問', ko: '← 이전 질문' } }],
  address: [
    { value: 'bạn', label: { vi: 'Bạn', en: 'Bạn', zh: 'Bạn', ja: 'Bạn', ko: 'Bạn' } },
    { value: 'anh', label: { vi: 'Anh', en: 'Anh', zh: 'Anh', ja: 'Anh', ko: 'Anh' } },
    { value: 'chị', label: { vi: 'Chị', en: 'Chị', zh: 'Chị', ja: 'Chị', ko: 'Chị' } },
    { value: 'em', label: { vi: 'Em', en: 'Em', zh: 'Em', ja: 'Em', ko: 'Em' } },
  ],
  goal: [
    { value: 'confident', label: { vi: 'Giao tiếp tự tin', en: 'Speak with confidence', zh: '自信沟通', ja: '自信を持って話す', ko: '자신 있게 소통하기' } },
    { value: 'listen', label: { vi: 'Lắng nghe', en: 'Listen better', zh: '倾听', ja: 'よく聞く', ko: '경청하기' } },
    { value: 'public', label: { vi: 'Nói trước đám đông', en: 'Speak in front of people', zh: '公开演讲', ja: '人前で話す', ko: '사람들 앞에서 말하기' } },
    { value: 'emotion', label: { vi: 'Quản lý cảm xúc', en: 'Manage emotions', zh: '管理情绪', ja: '感情をコントロールする', ko: '감정 다루기' } },
    { value: 'boundary', label: { vi: 'Đặt ranh giới', en: 'Set boundaries', zh: '设定界限', ja: '境界線を引く', ko: '경계 정하기' } },
  ],
  barrier: [
    { value: 'strangers', label: { vi: 'Ngại người lạ', en: 'Shy with strangers', zh: '怕生', ja: '知らない人が苦手', ko: '낯선 사람이 어려움' } },
    { value: 'wrong', label: { vi: 'Sợ nói sai', en: 'Afraid of saying it wrong', zh: '怕说错', ja: '間違うのが怖い', ko: '틀리게 말할까 두려움' } },
    { value: 'time', label: { vi: 'Không có thời gian', en: 'No time', zh: '没时间', ja: '時間がない', ko: '시간이 없음' } },
  ],
  current: [
    { value: 'nothing', label: { vi: 'Chưa làm gì', en: 'Nothing yet', zh: '还没做什么', ja: 'まだ何も', ko: '아직 아무것도' } },
    { value: 'selfstudy', label: { vi: 'Tự đọc, tự xem', en: 'Reading and watching on my own', zh: '自己看、自己读', ja: '自分で読む・見る', ko: '혼자 읽고 보기' } },
    { value: 'practising', label: { vi: 'Đang tập rồi', en: 'Already practising', zh: '已经在练', ja: 'もう練習している', ko: '이미 연습 중' } },
  ],
  style: [
    { value: 'read', label: { vi: 'Đọc chữ', en: 'Reading', zh: '读文字', ja: '文章を読む', ko: '글 읽기' } },
    { value: 'example', label: { vi: 'Xem ví dụ', en: 'Seeing examples', zh: '看例子', ja: '例を見る', ko: '예시 보기' } },
    { value: 'practice', label: { vi: 'Làm thử', en: 'Trying it out', zh: '动手试', ja: 'やってみる', ko: '직접 해보기' } },
  ],
  age: [
    { value: 'under18', label: { vi: 'Dưới 18', en: 'Under 18', zh: '18岁以下', ja: '18歳未満', ko: '18세 미만' } },
    { value: '18_24', label: { vi: '18–24', en: '18–24', zh: '18–24', ja: '18–24', ko: '18–24' } },
    { value: '25_44', label: { vi: '25–44', en: '25–44', zh: '25–44', ja: '25–44', ko: '25–44' } },
    { value: '45plus', label: { vi: '45+', en: '45+', zh: '45+', ja: '45+', ko: '45+' } },
  ],
  gender: [
    { value: 'female', label: { vi: 'Nữ', en: 'Female', zh: '女', ja: '女性', ko: '여성' } },
    { value: 'male', label: { vi: 'Nam', en: 'Male', zh: '男', ja: '男性', ko: '남성' } },
    { value: 'private', label: { vi: 'Không muốn nói', en: 'Rather not say', zh: '不想说', ja: '答えたくない', ko: '말하고 싶지 않음' } },
  ],
  job: [
    { value: 'student', label: { vi: 'Học sinh–sinh viên', en: 'Student', zh: '学生', ja: '学生', ko: '학생' } },
    { value: 'office', label: { vi: 'Văn phòng', en: 'Office', zh: '办公室', ja: 'オフィス', ko: '사무직' } },
    { value: 'sales', label: { vi: 'Kinh doanh–bán hàng', en: 'Sales / business', zh: '商务–销售', ja: '営業・販売', ko: '영업/사업' } },
    { value: 'care', label: { vi: 'Chăm sóc–dịch vụ', en: 'Care / service', zh: '照护–服务', ja: 'ケア・サービス', ko: '돌봄/서비스' } },
    { value: 'tech', label: { vi: 'Kỹ thuật', en: 'Technical', zh: '技术', ja: '技術', ko: '기술' } },
    { value: 'other', label: { vi: 'Khác', en: 'Other', zh: '其他', ja: 'その他', ko: '기타' } },
  ],
};

/** The user table's age labels, mapped onto the onboarding chip that pre-lights. */
export const ONBOARD_AGE_BY_AUDIENCE: Record<string, string> = {
  teen: 'under18',
  young_adult: '18_24',
  adult: '25_44',
  midlife: '45plus',
};

/** Keyword nets for the six occupation groups — no model call for a job title. */
export const ONBOARD_JOB_KEYWORDS: Array<[string, RegExp]> = [
  ['student', /(h[ọo]c\s*sinh|sinh\s*vi[êe]n|student|university|college|school|学生|生徒|学生|학생|대학)/i],
  ['tech', /(k[ỹy]\s*thu[ậa]t|l[ậa]p\s*tr[ìi]nh|dev|engineer|it\b|software|data|技术|工程|エンジニア|開発|기술|개발)/i],
  ['sales', /(kinh\s*doanh|b[áa]n\s*h[àa]ng|sale|marketing|business|销售|营业|営業|販売|영업|판매|사업)/i],
  ['care', /(y\s*t[áa]|[đd]i[ềe]u\s*d[ưu][ỡo]ng|b[áa]c\s*s[ĩi]|gi[áa]o\s*vi[êe]n|nurse|doctor|teacher|care|service|d[ịi]ch\s*v[ụu]|护士|医生|老师|服务|看護|医師|教師|간호|의사|교사|서비스)/i],
  ['office', /(v[ăa]n\s*ph[òo]ng|nh[âa]n\s*vi[êe]n|k[ếe]\s*to[áa]n|h[àa]nh\s*ch[íi]nh|office|admin|account|hr\b|办公|会计|事務|経理|사무|회계)/i],
];

/** Luồng 1 — the intro's two written lines, five languages, one bubble each. */
export const COACH_ONBOARD_INTRO_LINES: Record<string, string[]> = {
  vi: [
    'Mình là Coach. Mình không dạy, không chấm điểm — mình hỏi lại vài câu để bạn nghe rõ chuyện của chính mình.',
    'Mình là AI, không thay thế được chuyên gia tâm lý.',
  ],
  en: [
    "I'm the Coach. I don't teach or grade — I ask a few questions back so you can hear your own story more clearly.",
    "I'm an AI. I can't replace a mental-health professional.",
  ],
  zh: ['我是 Coach。我不教课、不打分 — 我只是多问几句，让你把自己的事听得更清楚。', '我是 AI，无法替代心理专业人士。'],
  ja: ['私はコーチです。教えることも採点することもしません。少し質問を返して、あなた自身の話をはっきり聞けるようにします。', '私はAIです。心理の専門家の代わりにはなれません。'],
  ko: ['저는 코치예요. 가르치거나 점수를 매기지 않아요. 몇 가지를 되물어서 당신 이야기를 더 또렷하게 들을 수 있게 할 뿐이에요.', '저는 AI라서 심리 전문가를 대신할 수는 없어요.'],
};
export const COACH_SCENE_UNAVAILABLE_LINE: Record<string, string> = {
  vi: 'Giờ mình chưa dựng được tình huống để tập. Mình làm bước khác nhé.',
  en: "I can't set up a practice scene right now. Let's do something else.",
  zh: '现在暂时无法准备练习情境，我们先做点别的吧。',
  ja: '今は練習シーンを用意できません。別のことをしましょう。',
  ko: '지금은 연습 상황을 준비할 수 없어요. 다른 걸 해볼까요?',
};

/**
 * The line that introduces the ways forward, above the named approaches.
 *
 * Fixed rather than generated: it is the same sentence every time, and a model
 * asked to write it drifts into coaching ("hãy chọn cách khiến bạn thoải mái
 * nhất") — which pushes a choice that is supposed to be the reader's. It also
 * says out loud that writing their own is allowed, because the letters on
 * screen otherwise read as the only three doors.
 */
export const COACH_SCENE_OPTIONS_LEAD: Record<string, string> = {
  vi: 'Bạn sẽ đáp lại thế nào? Chọn một hướng, hoặc tự viết câu của bạn:',
  en: 'How will you answer? Take one of these, or write your own:',
  zh: '你会怎么回应？可以选一个方向，也可以自己写：',
  ja: 'どう答えますか？どれかを選んでも、自分の言葉で書いてもいいです：',
  ko: '어떻게 답할래요? 방향을 하나 골라도 되고, 직접 써도 돼요:',
};

/**
 * They asked for a scene and cannot have one — the kho is empty.
 *
 * Said instead of nothing. The request used to be answered with the step's
 * fallback line, which read as the Coach not listening; a reader who types
 * "luyện tình huống" three times and gets a story question back each time is
 * being ignored by a machine, whatever the reason.
 */
export const COACH_SCENE_NOT_NOW_NO_HABIT: Record<string, string> = {
  vi: 'Mình muốn dựng một tình huống, mà kho thói quen của bạn chưa có gì. Thêm một thói quen rồi mình luyện ngay.',
  en: "I'd set up a scene, but there's nothing in your habit list yet. Add one and we'll practise straight away.",
  zh: '我想给你出个情境，但你的习惯清单还是空的。先加一个，我们马上练。',
  ja: '場面を用意したいのですが、習慣リストがまだ空です。ひとつ追加したらすぐ練習しましょう。',
  ko: '상황을 만들어 주고 싶은데 습관 목록이 아직 비어 있어요. 하나 추가하면 바로 연습해요.',
};

/**
 * They asked for a scene and cannot have one — the evening's task budget is
 * spent (`TASK_RUN_LIMIT`).
 *
 * The ceiling is a cost decision and stays; what was wrong is that hitting it
 * was invisible. Says so, and says when they can come back.
 */
export const COACH_SCENE_NOT_NOW_ENOUGH: Record<string, string> = {
  vi: 'Hôm nay mình luyện đủ rồi. Mai mở lại, mình dựng tình huống mới cho bạn — giờ còn chuyện gì thì kể mình nghe.',
  en: "We've practised enough for today. Open this again tomorrow and I'll set up a new scene — for now, tell me what's on your mind.",
  zh: '今天练得够了。明天再打开，我给你出个新情境 — 现在有什么想说的，跟我说说。',
  ja: '今日はもう十分練習しました。明日また開いてくれたら新しい場面を用意します — 今は話したいことを聞かせてください。',
  ko: '오늘은 충분히 연습했어요. 내일 다시 열면 새 상황을 준비할게요 — 지금은 하고 싶은 이야기를 들려주세요.',
};

/**
 * The same line, for the scene's OPENING — the question half removed.
 *
 * At a reaction the lead asks "Bạn sẽ đáp lại thế nào?" and that is the right
 * question: somebody just spoke and the reader answers them. At the opening the
 * scene has ALREADY asked its own question one bubble above, so asking again is
 * a repeat — and "đáp lại" is wrong on top of it, because nothing has been said
 * to reply to yet (owner on-device 2026-09-08: "có nhiều đoạn text bị thừa").
 *
 * Dropping the question also fixes a second thing: `addressVi` rewrites EVERY
 * "bạn" in a fixed line, so the two-clause version printed the reader's name
 * twice in one sentence — "Hà sẽ đáp lại thế nào? … tự viết câu của Hà:".
 *
 * What it must KEEP is the second clause. Without "hoặc tự viết câu của bạn",
 * the three lettered approaches read as the only three doors — which is the
 * whole reason this sentence exists.
 */
export const COACH_SCENE_OPENING_LEAD: Record<string, string> = {
  vi: 'Chọn một hướng, hoặc tự viết câu của bạn:',
  en: 'Take one of these, or write your own:',
  zh: '可以选一个方向，也可以自己写：',
  ja: 'どれかを選んでも、自分の言葉で書いてもいいです：',
  ko: '방향을 하나 골라도 되고, 직접 써도 돼요:',
};

/**
 * Word ceiling for a scene's `goodMove` — the one concrete move it teaches,
 * which pre-fills the reminder's "sẽ làm gì". Short because it is a commitment
 * the reader reads at a glance and edits, not a sentence to study.
 */
export const SITUATION_GOOD_MOVE_MAX_WORDS = 10;

/**
 * The most probe intents a scene's script may carry.
 *
 * FOUR, chốt 2026-08-27 — the reader asked for "3–5 lượt thoại" so the scene is
 * something they inhabit and think inside, not a form field. Beats + the first
 * answer is the turn count, so 2–4 beats means 3–5 exchanges. The earlier ceiling of
 * two came from protecting the "10 minutes" promise; at 3–5 short turns the
 * practice is still minutes, and the extra turns are what let a lesson land
 * instead of being announced.
 */
export const SITUATION_MAX_BEATS = 4;

/**
 * The fewest probe intents a scripted scene may carry — 3 exchanges in total.
 *
 * A floor rather than a default: one-beat scenes were the old behaviour and they
 * closed before the reader had committed to anything.
 */
export const SITUATION_MIN_BEATS = 2;

/**
 * Difficulty band of a scene — the design's "Level 1 … Level 5".
 *
 * The ladder is about PRESSURE, not about the reader: 1 is an easy refusal, 3
 * is the other person insisting, 5 stacks several things at once (more people,
 * time running out, guilt). It is a property of the written scene, so the
 * generator and the editor set it and the reader is never told a number they
 * have to live up to.
 */
export const SITUATION_MIN_LEVEL = 1;
export const SITUATION_MAX_LEVEL = 5;

/** Where a reader with no history starts. */
export const SITUATION_START_LEVEL = 1;

/**
 * Rubric scores at or above this promote the reader to the next level, and
 * below the floor they drop one.
 *
 * Two thresholds rather than one so the middle band is "stay here and do it
 * again" — a skill that moves up on every single good answer is a skill nobody
 * ever practises twice.
 */
export const SCENE_SCORE_PROMOTE_AT = 8;
export const SCENE_SCORE_DEMOTE_UNDER = 5;

/** Scores are on 0–10 per criterion; the card shows the mean to one decimal. */
export const SCENE_SCORE_MAX = 10;

/**
 * Criteria per skill rubric.
 *
 * Four to five, from the design. Fewer reads as a grade with no explanation;
 * more turns the card into a report the reader scrolls past.
 */
export const RUBRIC_MIN_CRITERIA = 4;
export const RUBRIC_MAX_CRITERIA = 5;

/**
 * How many recent scored scenes make up the skill score shown on the habit.
 *
 * A window, not a lifetime average: the number is meant to answer "am I better
 * at this than I was", and a lifetime mean stops moving after a month of use.
 */
export const SKILL_SCORE_WINDOW = 10;

/**
 * Word ceilings the ⑦ diagram writes on the beats themselves.
 *
 * Not style advice — they are on the flow chart next to the beat, which is what
 * makes them part of the contract. A three-sentence "at most" rule does not
 * bound anything: three sentences of a model being warm is eighty words, and
 * nhịp 2's whole job is to ask one short thing and get out of the way.
 */
export const LONG_BEAT2_MAX_WORDS = 30;
export const LONG_BEAT5_MAX_WORDS = 25;

/**
 * Nhịp 4 + nhịp 5 together — the idea from a keypoint, then the one specific
 * piece of praise and the small step for tomorrow.
 *
 * Two paragraphs in one turn, so the ceiling is the sum of two beats rather
 * than one. Still a ceiling: at 25 words the idea came out as a fragment, and
 * past ~70 the praise turns into a summary of the session, which nhịp 5 bans.
 */
export const BEAT45_MAX_WORDS = 70;

/**
 * Nhịp 5 — the one difference between the two answers to a scene.
 *
 * "Coach chỉ ra một điểm khác giữa hai lần, ≤30 từ."
 */
export const SCENE_CHANGE_MAX_WORDS = 30;

/**
 * 6c — the mirror line: the practice answer set beside the real one.
 *
 * "≤35 từ · hai việc đặt cạnh nhau · kể lại chứ không nhận xét."
 */
export const SCENE_MIRROR_MAX_WORDS = 35;

/**
 * Words 6b's answer needs to count as a telling at all.
 *
 * Under this, nothing was said — 6c and 6d are skipped and no dip is made:
 * "user không gõ gì → bỏ 6c, KHÔNG mời T4" (mẫu #7).
 */
export const SCENE_DID_MIN_WORDS = 3;

/**
 * Words the second answer needs before nhịp 5 is worth a model call.
 *
 * The doc's own shortcut: "lần 2 gõ quá ngắn để so sánh → bỏ hẳn nhịp 5, nhảy
 * thẳng nhịp 6, không gọi AI lần hai". Three words cannot be compared with
 * anything, and a model asked to compare them invents the difference.
 */
export const SCENE_COMPARE_MIN_WORDS = 4;

/**
 * How long the scene answer may be and still pre-fill the commitment.
 *
 * The doc wants the suggestion taken from what they said in the scene, and
 * their own sentence is the best possible pre-fill — but a paragraph pasted
 * into a one-line field is not a commitment, so past this the authored move
 * stands in and the field stays editable either way.
 */
export const SCENE_DRAFT_MAX_WORDS = 25;

/**
 * Task suggestions the coordinator may show at once.
 *
 * "Tối đa 2 pill · dù ba task cùng đủ điều kiện — lấy hai cái ưu tiên cao
 * nhất." Three suggestions is a menu, and a menu is what this feature is not.
 */
export const COACH_HUB_PILL_LIMIT = 2;


/**
 * ⑧ NT9 — the safety escape: the keyword net, the risk classifier, and the
 * crisis screen they route to.
 *
 * Was OFF for a day of dev testing (owner's call, 2026-08-27 — it kept firing
 * on test input). RE-ENABLED 2026-08-28 for the first production release: the
 * doc lists this among the "mười nguyên tắc bất biến", and no build that
 * reaches real readers ships without it.
 */
export const COACH_SAFETY_ESCAPE_ENABLED = true;

/**
 * How old a commitment must be before the Coach asks how it went.
 *
 * The registry's condition is "chưa hỏi hôm nay" — the day is the grain, not
 * the calendar day it was CREATED on. This guard only keeps out the absurd
 * case: a reader who sets a reminder, closes the sheet and opens it again two
 * minutes later being asked "có dịp nào chưa?" about something that has not
 * had a chance to happen. Ten minutes is enough for that and short enough that
 * the check-in can be tested on the day it was set up.
 */
export const COACH_PLAN_ASK_DELAY_MINUTES = 10;

/**
 * The closing line — "câu chốt" — of a Home session.
 *
 * ≤20 words, never a question (a question reopens the session), never generic
 * praise, and it reuses the reader's own words for the commitment they just
 * made. The last thing they see has to be theirs.
 */
export const CLOSING_LINE_MAX_WORDS = 20;

/**
 * Scenes kept per (habit, locale, variant, audience, goal).
 *
 * Product call (2026-08-26): a reader who has answered every cached scene of a
 * habit gets a NEW one, not a repeat — "sinh thêm, rất nhiều cũng được". The
 * pool is still drawn from first (a scene the reader has not answered costs
 * nothing), so generation happens once per new scene per key and is shared by
 * every reader in that key. This number is not a design target, it is a
 * runaway guard: nobody answers two hundred scenes of one habit unless
 * something is looping.
 */
export const SITUATION_POOL_SIZE = 200;

/**
 * How many of the key's existing scenes the generator is shown to avoid.
 *
 * The most recent ones — enough to stop paraphrases of what the reader just
 * saw, small enough that a big pool does not turn every generation into a
 * long prompt. Contexts rotate by slot regardless, so variety of SETTING does
 * not depend on this list.
 */
export const SITUATION_AVOID_PROMPTS = 12;

/**
 * One slot in every N invents its own moment instead of taking an authored one.
 *
 * Owner 2026-09-05 — "các tình huống hiện tại đang hơi cứng chỉ loanh quanh 1
 * vài tình huống". Binding every scene to `habit.contexts` capped a habit's
 * whole life at however many moments an editor happened to write down, so the
 * pool circled the same three or four settings forever.
 *
 * A fraction rather than all of them: the authored moments are what guarantee
 * the pool covers the habit's REAL situations, and letting the model choose
 * freely every time is what produced four scenes about one unread message back
 * in August. Two grounded, one free.
 */
export const SITUATION_FREE_CONTEXT_EVERY = 3;

/** "Khác" on the rating toast opens a box; this bounds what it takes. */
export const RATING_NOTE_MAX_LENGTH = 300;

/**
 * Questions nhịp 2 may ask before the script moves on.
 *
 * ONE, per the flow (AI Coach.html, 2026-08-25): `tell2` asks back a single
 * question — "hỏi lại đúng điều đã xảy ra" — and then Medium closes with the
 * commitment while Long moves to the two columns. The two-question loop an
 * earlier pass added is retired with it; the loop mechanism stays behind this
 * constant.
 */
export const BEAT2_MAX_QUESTIONS = 1;

/**
 * Barrier rows ("điều gì làm bạn dừng lại") on one habit before the course
 * card treats that habit as the place the reader is stuck — and offers the
 * course that teaches it ahead of anything else.
 */
export const COURSE_STRUGGLE_MIN_BARRIERS = 2;

// ③C takes exactly ONE telling (AI Coach.html, 2026-08-25): the story lands,
// the silent match runs, and the session either closes on the commitment (the
// story matched a habit the reader already practises) or on the course
// invitation. The earlier hold-the-conversation-open loop and its two
// constants are gone with it.

/**
 * Dòng hội thoại của các phiên TRƯỚC được đưa vào prompt trả lời.
 *
 * Bug 2026-09-04: client replay 3 phiên nên user thấy một dải liền, còn prompt
 * chỉ nhận `session.turns` của phiên hiện tại — user nói "vừa nói ở trên mà nó
 * quên luôn". Log thô `coach_messages` không TTL nên dữ liệu vẫn còn, chỉ là
 * chưa ai đọc vào prompt.
 *
 * 30 dòng là chỗ dừng giữa "đủ để nối được mạch" và "mỗi lượt tốn thêm một
 * đoạn prompt dài" — nó xấp xỉ 3 phiên ngắn, đúng bằng số phiên client replay.
 */
export const PRIOR_TRANSCRIPT_MAX_LINES = 30;

/**
 * 2026-09-17 — chỉ còn ĐUÔI của phiên liền trước đi vào prompt.
 *
 * 30 dòng raw ở trên là cách đắt nhất để nhớ: nó lớn theo lịch sử và trả cho
 * model phần lớn là chữ đã được cô đọng vào thẻ nhớ rồi. Thứ thẻ nhớ KHÔNG thay
 * được là mấy câu cuối cùng — "vừa nói ở trên" của một mạch chưa xong. Sáu dòng
 * là đúng phần đó.
 */
export const PRIOR_TAIL_LINES = 6;

/**
 * Cứ bao nhiêu lượt user thì cô đọng memory lại một lần, NGAY TRONG phiên.
 *
 * Trước đây `extractFromSession` chỉ chạy ở END và `close()`, nên một phiên
 * Home không có hồi kết (`storyRoundsLeft = null`) có thể chạy rất dài mà
 * không đóng góp gì vào memory. 6 lượt là mức đủ để một chuyện đã kể xong
 * được ghi lại, mà không biến mỗi lượt thành một call Gemini nền.
 */
export const MEMORY_MIDSESSION_EVERY_LINES = 6;
