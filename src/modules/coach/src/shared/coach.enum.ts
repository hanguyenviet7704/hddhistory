/**
 * Which touchpoint opened the sheet. Stored on the session and on every plan
 * created in it, so "where do commitments actually come from" is answerable
 * without reconstructing anything.
 */
export enum CoachEntry {
  /** ① end of a lesson, only right after a new habit was added. */
  LESSON = 'lesson',
  /**
   * ⑤ the Habit screen's own door — LIVE, whatever this comment used to say.
   *
   * It was marked RETIRED by the BA flow of 2026-08-26 ("Nav Habit đã bị bỏ
   * khỏi thiết kế") and then came back as luồng 5, but the note stayed: it
   * still claimed `open()` maps this to HOME, which it has not done for a
   * while. `eligibleTasks` has a branch of its own for this door and the
   * service reads `entry === HABIT` in a dozen places.
   *
   * The door has its OWN session, deliberately: it is about ONE habit and
   * offers only that habit's two things (điểm danh, quiz), which is why
   * opening a different habit's screen closes it rather than resuming a
   * conversation about the wrong one. Home's session is the evening's general
   * conversation and stays separate — a reader who has both open sees two
   * threads, and merging them is a design change, not a bug fix.
   */
  HABIT = 'habit',
  /** ② Home — ②A with a pending commitment, ②B without one. ③ push lands here. */
  HOME = 'home',
}

/**
 * Every step the sheet can be parked at, waiting for the reader.
 *
 * The prototype's transient `wait` (typing indicator) is deliberately absent:
 * it is a client-side render state during an in-flight request, never a step
 * the server hands back.
 */
export enum CoachStep {
  MOOD = 'mood',
  PICK_NEW = 'pickNew',
  /** RETIRED with the Nav Habit door. Enum kept so parked sessions still render. */
  PICK_HABIT = 'pickHabit',
  /** RETIRED: the voice is a header control now, not a step. */
  PERSONA = 'persona',
  /** RETIRED: "không còn hỏi bạn có mấy phút" — depth is chosen AFTER the first line. */
  TIME = 'time',
  /** RETIRED: nhịp 1 is the STORY step now; the question it earned is asked at DEPTH. */
  TELL = 'tell',
  TELL_2 = 'tell2',
  TWO_COLS = 'twoCols',
  /**
   * ⑤ — the reader rejected the whole draft. They write both columns
   * themselves and the Coach is forbidden from drafting a second time.
   */
  REDRAFT = 'redraft',
  /** RETIRED (design v2): nhịp 4 is the scene now, nhịp 5 the commitment. */
  NEXT_ACTION = 'nextAction',
  /** RETIRED. */
  CLOSING = 'closing',
  /** ★ the one short situation — scene, one answer, one reply. */
  TELL_ONCE = 'tellOnce',
  /**
   * The scene's opening beat: the scene is shown and the FEELING is asked
   * first — "lúc đó bạn cảm thấy thế nào?" — before the scene's own "bạn nói
   * gì?" question at `TELL_ONCE`. Leading someone into a moment through what
   * it felt like is what makes the action answer theirs instead of a quiz
   * response. Fixed line, no model call; the feeling is kept only in the
   * transcript so the reply to the action can hear it.
   */
  SCENE_FEELING = 'sceneFeeling',
  /**
   * RETIRED with the doc of 2026-08-27 (v4): "nhịp 4 — KHÔNG mời nói lại".
   * Part c has just said "không phải tốt hơn, chỉ là khác"; asking them to say
   * it again reads as "now do it properly". The scene's second stage replaced
   * it — see `SCENE_STAGE2`.
   */
  SCENE_AGAIN = 'sceneAgain',

  /**
   * Nhịp 4 of the scene — the SECOND stage of the same written scene.
   *
   * The other person reacts and the situation turns one notch harder ("cùng
   * người, cùng chỗ, đẩy tình huống khó lên một nấc — không phải một bối cảnh
   * mới"). Written, not generated, and not a test of whether the reader took
   * the Coach's suggestion.
   */
  SCENE_STAGE2 = 'sceneStage2',

  /**
   * Nhịp 6 — "Chuyện giống vậy bạn gặp bao giờ chưa?".
   *
   * The scene is invented; a commitment needs a real occasion. This is where
   * the two are joined, and it is the only place a `dip` can come from besides
   * a story the reader told.
   */
  SCENE_MET = 'sceneMet',

  /**
   * RETIRED by nhịp 6 mở rộng (doc 20 mẫu v2, 2026-08-28): the follow-up to
   * "Rồi" asks what they DID (`SCENE_DID`), not when it was. Kept for parked
   * sessions.
   */
  SCENE_WHEN = 'sceneWhen',

  /**
   * 6b — "Hôm đó bạn làm gì?": the real occurrence, in their words. Its answer
   * is filed as CauVanDe(lan_da_qua) — a thing that already happened, never a
   * câu kể — and earns the mirror line (6c) on the way to 6d.
   */
  SCENE_DID = 'sceneDid',

  /**
   * 6d — "Lần sau gặp lại, bạn muốn làm khác đi không?". Either answer makes
   * the session's dip: "muốn khác" carries their words into the reminder,
   * "không đổi" carries the very thing they did at 6b. Both roads lead to T4.
   */
  SCENE_CHANGE = 'sceneChange',

  /**
   * Bộ điều phối — one Coach line and up to two task suggestions.
   *
   * Not a screen: the step between two tasks. It is what replaced the fixed
   * per-door spine, so "mọi task đều gọi được từ mọi cửa, miễn đủ điều kiện".
   */
  HUB = 'hub',
  /** ④ — the scene answered three weeks ago, shown again for the recap's pair. */
  RETRY_SCENE = 'retryScene',
  /** "Đi tới khoá học" — one short line, then the app leaves for the Roadmap. */
  LEAVE = 'leave',
  /** RETIRED with the "chỉ tập" script. */
  PRACTICE_ANSWER = 'practiceAnswer',
  /** ②A check-in: three equal buttons. */
  INTENT = 'intent',
  /** ②A "Đã làm được" → one sentence about what they actually did. */
  INTENT_TELL = 'intentTell',
  /** RETIRED. */
  TELL_ONCE_A = 'tellOnceA',
  /** RETIRED with the due-habit tier. */
  CHECKIN = 'checkin',
  /** RETIRED. */
  TELL_ONCE_B = 'tellOnceB',
  /** RETIRED: ③C's free talk is the STORY step now. */
  FREE = 'free',
  /** RETIRED (design v2): MISSED asks its sentence at INTENT_TELL now. */
  BARRIER = 'barrier',
  /**
   * ②A after "có dịp mà chưa làm": "Muốn thu nhỏ nhắc hẹn này lại không?".
   * Law 5 ("nhắc hẹn mới luôn nhỏ hơn") had no step left to live in.
   */
  SHRINK_ASK = 'shrinkAsk',
  /**
   * The commitment form pre-filled with the OLD wording, for the reader to
   * make smaller. Renders as PLAN; the save replaces the old plan instead of
   * creating a second one.
   */
  SHRINK = 'shrink',
  /** RETIRED (design v2): "không có tình huống" moves on with one fixed line. */
  CONTEXT_ASK = 'contextAsk',
  /** RETIRED. */
  CONTEXT_EDIT = 'contextEdit',
  /** ② "Hôm nay có chuyện gì mới không?" — tell, or skip. */
  STORY = 'story',
  /**
   * "Bạn muốn chia sẻ thêm không?" — the depth question, asked once the reader
   * has written their first sentence and never before it.
   *
   * `Kể sâu hơn` runs the 5-beat script, `Chỉ ghi lại thôi` files the sentence
   * and skips straight to the commitment (T4).
   */
  DEPTH = 'depth',
  /**
   * T3 after the depth question — the conversation itself, one step that
   * repeats (owner, 2026-09-04: "bỏ 2 cột kéo kéo").
   *
   * Every line the reader types here earns ONE model call that returns both
   * the reply and what KIND of line it was (`CoachStoryKind`); the machine
   * routes on the kind, never on the words. It replaced nhịp 2 → the
   * two-column draft → "bạn sẽ làm gì" (TELL_2 → TWO_COLS → NEXT_ACTION), all
   * three of which stay in this enum for sessions still standing on them.
   */
  STORY_TALK = 'storyTalk',

  // ---- luồng 4 (design "AI Coach Flows" 2026-09-03): the Home scene --------
  /** "Bạn muốn tập cái nào trong kho của bạn?" — chips are the reader's own habits. */
  SCENE_PICK = 'scenePick',
  /**
   * The answer was off the mark: the Coach said why and offered a sample line;
   * now ⟨Luyện lại cảnh này⟩ · ⟨Để sau⟩. The scene is judged HERE and nowhere
   * else in the product — one of the design's three named exceptions to
   * "không chấm".
   */
  SCENE_FIX = 'sceneFix',
  /** "Vẫn cảnh đó: … Bạn nói gì?" — the same scene verbatim, second and last try. */
  SCENE_RETRY = 'sceneRetry',

  // ---- luồng 5 (design 2026-09-03): the Habit screen's third row -----------
  /** "Hôm nay bạn có làm được nó không?" · ⟨Có⟩ ⟨Chưa, không có dịp⟩ — both write a check-in. */
  CHECKIN_ASK = 'checkinAsk',
  /** ⟨Có⟩ → "Kể mình một câu: lúc đó bạn đã nói hay làm gì?" — one real occurrence, then the write. */
  CHECKIN_TELL = 'checkinTell',
  /** "Ghi xong «X». Trong kho còn «Y» chưa ghi hôm nay — làm luôn nhé?" — the next habit, offered, never jumped to. */
  CHECKIN_OFFER = 'checkinOffer',
  /** The habit's own quiz, read one question at a time IN the chat; options are the chips. */
  QUIZ_IN_CHAT = 'quizInChat',

  // ---- luồng 2 (design 2026-09-03): the talk after a keypoint --------------
  /** "Nói một chút về phần vừa học nhé? Bắt đầu kiểu nào?" ⟨Tóm tắt⟩ ⟨Làm quiz⟩ + free text. */
  TALK_ASK = 'talkAsk',
  /** The summary was given and ended in one question; the reader answers it. */
  TALK_SUMMARY = 'talkSummary',
  /** "Vài câu về phần này nhé." ⟨Bắt đầu⟩ ⟨Thôi, để sau⟩. */
  QUIZ_HANDOFF = 'quizHandoff',
  /** The quiz is running on its own screen; the server waits for `quizDone`. */
  QUIZ_RUN = 'quizRun',
  /**
   * The talk stays open after the grading turn: the reader may ask about what
   * they just learned, and the Coach answers until the turn budget runs out.
   *
   * Owner 2026-09-05: the branch used to END the moment the grading landed,
   * with a line pushing to the next keypoint. That closed the door exactly
   * where readers start having questions — "mở thêm để user có thể hỏi thêm
   * sâu thêm về bài vừa học".
   */
  TALK_FREE = 'talkFree',
  /** "Học tiếp phần sau chứ?" ⟨Học tiếp⟩ ⟨Để sau⟩ — every branch ends here. */
  TALK_WHEN = 'talkWhen',

  // ---- luồng 3 (design 2026-09-03): the course recap -------------------------
  /** "Bài nào ở lại với bạn lâu nhất?" — chips are the course's lessons. */
  RECAP_PICK = 'recapPick',
  /** "Làm vài câu random từ cả khoá xem còn nhớ gì nhé?" ⟨Làm thử⟩ ⟨Để sau⟩. */
  RECAP_QUIZ = 'recapQuiz',

  // ---- luồng 1 (design 2026-09-03): Onboarding Coach — once per reader ----
  /** Two written lines: who the Coach is, and that it is an AI, not a therapist. */
  ONBOARD_INTRO = 'onboardIntro',
  /** "Mình gọi bạn thế nào cho thuận?" Bạn · Anh · Chị · Em — vi only; the one step that cannot be skipped. */
  ONBOARD_ADDRESS = 'onboardAddress',
  /** A name was typed instead: "Mình gọi bạn là «Mai» nhé?" ⟨Đúng⟩ ⟨Đổi⟩. */
  ONBOARD_ADDRESS_CONFIRM = 'onboardAddressConfirm',
  ONBOARD_GOAL = 'onboardGoal',
  ONBOARD_BARRIER = 'onboardBarrier',
  ONBOARD_CURRENT = 'onboardCurrent',
  ONBOARD_STYLE = 'onboardStyle',
  ONBOARD_AGE = 'onboardAge',
  ONBOARD_GENDER = 'onboardGender',
  ONBOARD_JOB = 'onboardJob',
  /** ★ invitation to practise one situation — never required. */
  INVITE = 'invite',
  /**
   * Tầng 4 "Reflect" — the coach steps OUT of the scene and scores the answers
   * against the skill's rubric, then offers the same scene again.
   *
   * Its own step rather than a field on the closing reply because it is a
   * different act: everything before it happens INSIDE the situation, and this
   * is the one beat where the Coach speaks as an assessor. That also makes the
   * card skippable — a scene with no rubric goes straight to the commitment.
   */
  SCENE_SCORE = 'sceneScore',
  /** "Muốn đặt Nhắc hẹn không?" — the commitment is optional at every door. */
  PLAN_ASK = 'planAsk',
  PLAN = 'plan',
  SCHEDULE = 'schedule',
  LOOP = 'loop',
  /** The course card in the thread: Đi tới khoá học · Lưu để sau · Bỏ qua. */
  COURSE_CARD = 'courseCard',
  MOOD_END = 'moodEnd',
  RATING = 'rating',
  /** The closing line, then "Dừng phiên hay bắt đầu phiên mới?". */
  NEXT_SESSION = 'nextSession',
  END = 'end',
  /** ⑥ the 20-second way out. */
  JOT = 'jot',
  /** NT9 terminal. Nothing is written from here. */
  SAFETY = 'safety',
}

/**
 * What a line typed inside the story conversation WAS — the owner's table of
 * 2026-09-04 ("User kể → AI nên làm"), as the model reports it alongside its
 * reply.
 *
 * Only these values route. "Vấn đề lặp lại" is deliberately NOT one of them:
 * whether a subject keeps coming back is a fact in the reader's own filed rows,
 * counted by the server and handed INTO the prompt — a model deciding "you do
 * this a lot" from one message would be the diagnosis the rules forbid. The
 * last two rows of the table (a habit in the kho, a skill outside it) are the
 * silent match's answer at STORY and need no kind either.
 */
/**
 * Luồng 4 — how the reader's line SITS in the scene, judged so the other
 * person can push back in the right tone. Not a verdict: the scene is scored
 * once, at the end, on BOTH turns (owner, 2026-09-04 — "reactive branching",
 * a diamond rather than a tree: four reactions, one outcome).
 */
export enum CoachScenePosture {
  /** Makes the move, plainly and without hedging. */
  DIRECT = 'direct',
  /** Makes the move, but wrapped in apology, hedging or a half-step. */
  HESITANT = 'hesitant',
  /** Sidesteps: postpones it, hands it to someone else, says nothing of substance. */
  AVOID = 'avoid',
  /** Pushes too hard: blames, corrects publicly, talks over the other person. */
  ESCALATE = 'escalate',
}

export enum CoachStoryKind {
  /** Chuyện bình thường — keep the conversation going. */
  NORMAL = 'normal',
  /** Chuyện vui / thành công — name one specific thing they did. */
  SUCCESS = 'success',
  /** Có cảm xúc nhưng chưa có vấn đề — one gentle question about the event. */
  FEELING = 'feeling',
  /** Có vấn đề — filed as their problem statement; the session's dip. */
  PROBLEM = 'problem',
  /** Nhận ra mình muốn cải thiện — the card MAY follow at the tail. */
  WANTS_IMPROVE = 'wants_improve',
  /** Chủ động hỏi cách cải thiện — the course card, now. */
  ASKS_HOW = 'asks_how',
  /** Không muốn tiếp tục — stop, offer nothing. */
  STOP = 'stop',
}

/**
 * What the composer renders. The client owns no step logic — it switches on
 * this value alone, which is what keeps rules like "the three closing choices
 * rank equally" from drifting client-side.
 */
export enum CoachUiKind {
  CHIPS = 'chips',
  TEXT = 'text',
  /** Free text the reader may also SKIP — the STORY step. */
  TEXT_SKIPPABLE = 'text_skippable',
  /**
   * The coordinator: free text, up to two task pills, and the way to stop.
   */
  HUB = 'hub',
  /**
   * Free text plus the two depth pills — the DEPTH step.
   *
   * Both, because the pills are shortcuts and the main road is the reader
   * simply typing on: "hai pill ở lại suốt phiên… đường chính là user cứ gõ
   * tiếp".
   */
  DEPTH = 'depth',
  TWO_COLS = 'two_cols',
  /** Text, plus the keypoints the closing beat offers to explain. */
  NEXT_ACTION = 'next_action',
  /** Read-only: the closing words, and one button onward. */
  CLOSING = 'closing',
  /** The shrunk commitment as an editable draft, with accept / keep buttons. */
  SHRINK = 'shrink',
  PLAN = 'plan',
  SCHEDULE = 'schedule',
  /** One course, with its three ways out drawn on the card. */
  COURSE_CARD = 'course_card',
  /**
   * The rubric card: per-criterion bars, the one strength, the one thing to
   * sharpen, a better phrasing to borrow, and "thử lại tình huống này".
   */
  SCENE_SCORE = 'scene_score',
  RATING = 'rating',
  /** The closing line, then two equal buttons: stop · new session. */
  NEXT_SESSION = 'next_session',
  END = 'end',
  SAFETY = 'safety',
}

/** The three voices. Picked by the reader, never inferred from the habit. */
export enum CoachPersona {
  FRIEND = 'friend',
  DIRECT = 'direct',
  GUIDE = 'guide',
}

/**
 * RETIRED (BA flow 2026-08-26): sessions no longer ask for a length. Kept so
 * parked sessions and stored rows keep their value; new sessions carry null.
 */
export enum CoachScript {
  SHORT = 'short',
  MEDIUM = 'medium',
  LONG = 'long',
  PRACTICE = 'practice',
}

/** Which branch of the ② Home door a session landed on. */
export enum CoachHomeTier {
  /** ②A — a pending commitment to ask back about. */
  PLAN = 'A',
  /** RETIRED: the due-habit tier folded into ②B. */
  CHECKIN = 'B',
  /** ②B — no commitment pending; the story picks the habit. */
  FREE = 'C',
  /** ④ — a scene answered three weeks ago or more, to answer again. */
  RETRY = 'D',
  /**
   * ②C — "trò chuyện có định hướng": the kho is empty, or they already
   * practised a habit today.
   *
   * A shorter path on purpose. It listens, matches what they said against the
   * WHOLE HDDhistory catalogue rather than their own shelf, and then either reminds
   * them of a habit they already have (and offers a reminder) or shows the
   * course that opens with the habit they do not. It never invites a scene —
   * they have practised already, or have nothing to practise — and when the
   * habit is not theirs it never asks for a reminder either, because a reminder
   * has to hang on a habit in the kho. That makes ②C the one path that may end
   * with no reminder at all, and the doc says so explicitly.
   */
  GUIDED = 'E',
}
