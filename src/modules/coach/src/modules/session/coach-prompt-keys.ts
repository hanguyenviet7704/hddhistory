import { CoachStep } from '../../shared/coach.enum';

/**
 * The Coach's FIXED lines, as slang keys rather than sentences.
 *
 * Every line here is navigation — "how are you today", "when should I remind
 * you" — and navigation is the same words every time. Generating it would cost
 * a model call per turn to produce a sentence we already know, in a language we
 * already ship, and would let it drift: a rule like "the reader's sentence is
 * never touched" is not survivable if the line that follows it is rewritten on
 * every render.
 *
 * The client renders these from `assets/i18n/<locale>/coach.yaml` in all five
 * languages. The free-text steps whose line is GENERATED (nhịp 2's question,
 * the scene, the reply after the scene) are absent on purpose; the ones whose
 * line is fixed by the design (nhịp 3's "Đó là câu của bạn, mình không sửa.")
 * are `noteKey`s below rather than step keys, because they are said BEFORE the
 * next step's own line.
 */
export const COACH_PROMPT_KEY: Partial<Record<CoachStep, string>> = {
  [CoachStep.MOOD]: 'coach.prompt.mood',
  [CoachStep.MOOD_END]: 'coach.prompt.moodEnd',
  [CoachStep.PICK_NEW]: 'coach.prompt.pickNew',
  // ②B — "Hôm nay có chuyện gì mới không?", the door's one opening line. ②A
  // and a new session say "còn" instead — see `COACH_STORY_MORE_KEY`.
  [CoachStep.STORY]: 'coach.prompt.story',
  // ②A opens by quoting the reader's own commitment back at them, so its line
  // is assembled from their words rather than looked up. The client owns the
  // frame; `promptArgs` supplies context and action.
  [CoachStep.INTENT]: 'coach.prompt.intent',
  // ②A "Đã làm được": "Kể mình nghe một câu: lúc đó bạn nói hay làm gì?" —
  // the MISSED branch asks a different sentence (`COACH_INTENT_TELL_MISSED_KEY`).
  [CoachStep.INTENT_TELL]: 'coach.prompt.intentTell',
  [CoachStep.LOOP]: 'coach.prompt.loop',
  // ②A after "có dịp mà chưa làm" — "Muốn thu nhỏ nhắc hẹn này lại không?"
  [CoachStep.SHRINK_ASK]: 'coach.prompt.shrinkAsk',
  // The old wording, pre-filled, for the reader to make smaller.
  [CoachStep.SHRINK]: 'coach.prompt.shrinkEdit',
  // Nhịp 3 — "Mình gom lại thành nháp hai cột — toàn bằng lời bạn…"
  [CoachStep.TWO_COLS]: 'coach.prompt.twoCols',
  // RETIRED with the doc of 2026-08-27 (v3): ② has no scene to invite anybody
  // to, and ① runs the scene without asking. Kept for parked sessions.
  [CoachStep.INVITE]: 'coach.prompt.invite',
  // RETIRED with nhịp 4 (doc v4).
  [CoachStep.SCENE_AGAIN]: 'coach.prompt.sceneAgain',
  // The scene's opening beat — "Lúc đó bạn cảm thấy thế nào?". A low day is
  // asked in the third person instead (`COACH_SCENE_FEELING_THIRD_KEY`).
  [CoachStep.SCENE_FEELING]: 'coach.prompt.sceneFeeling',
  // 6a — "Ngoài đời bạn gặp chuyện kiểu này chưa?" · Rồi / Chưa.
  [CoachStep.SCENE_MET]: 'coach.prompt.sceneMet',
  // RETIRED (nhịp 6 mở rộng) — "Lúc đó là lúc nào?". Parked sessions only.
  [CoachStep.SCENE_WHEN]: 'coach.prompt.sceneWhen',
  // 6b — "Hôm đó bạn làm gì?": việc đã làm thật, không hỏi "có giống không".
  [CoachStep.SCENE_DID]: 'coach.prompt.sceneDid',
  // 6d — "Lần sau gặp lại, bạn muốn làm khác đi không?" — viết sẵn, không gợi
  // sẵn hành động.
  [CoachStep.SCENE_CHANGE]: 'coach.prompt.sceneChange',
  // Bộ điều phối — "Xong rồi. Còn gì bạn muốn nói không?"
  [CoachStep.HUB]: 'coach.prompt.hub',
  // Luồng 4 — "Bạn muốn tập cái nào trong kho của bạn?"
  [CoachStep.SCENE_PICK]: 'coach.prompt.scenePick',
  // Luồng 4 — "Vẫn cảnh đó:" — said before the same scene is shown again.
  [CoachStep.SCENE_RETRY]: 'coach.prompt.sceneRetry',
  // Luồng 5 — "Hôm nay bạn có làm được nó không? Kể mình một câu là đủ."
  [CoachStep.CHECKIN_ASK]: 'coach.prompt.checkinAsk',
  // Luồng 5 — "Kể mình một câu: lúc đó bạn đã nói hay làm gì?"
  [CoachStep.CHECKIN_TELL]: 'coach.prompt.checkinTell',
  // Luồng 2 — "Nói một chút về phần vừa học nhé? Bắt đầu kiểu nào?"
  [CoachStep.TALK_ASK]: 'coach.prompt.talkAsk',
  // Luồng 2 — "Vài câu về phần này nhé."
  [CoachStep.QUIZ_HANDOFF]: 'coach.prompt.quizHandoff',
  // Luồng 2 — "Học tiếp phần sau chứ?"
  [CoachStep.TALK_WHEN]: 'coach.prompt.talkWhen',
  // Luồng 3 — "Bạn vừa xong «{course}». Nhìn lại một chút nhé? Bài nào ở lại với bạn lâu nhất?"
  [CoachStep.RECAP_PICK]: 'coach.prompt.recapPick',
  // Luồng 3 — "Làm vài câu random từ cả khoá xem còn nhớ gì nhé?"
  [CoachStep.RECAP_QUIZ]: 'coach.prompt.recapQuiz',
  // Luồng 1 — Onboarding Coach: the eight questions (the intro's two lines are
  // server text). `{address}` rides in promptArgs once it is known.
  [CoachStep.ONBOARD_ADDRESS]: 'coach.prompt.onboardAddress',
  [CoachStep.ONBOARD_ADDRESS_CONFIRM]: 'coach.prompt.onboardAddressConfirm',
  [CoachStep.ONBOARD_GOAL]: 'coach.prompt.onboardGoal',
  [CoachStep.ONBOARD_BARRIER]: 'coach.prompt.onboardBarrier',
  [CoachStep.ONBOARD_CURRENT]: 'coach.prompt.onboardCurrent',
  [CoachStep.ONBOARD_STYLE]: 'coach.prompt.onboardStyle',
  [CoachStep.ONBOARD_AGE]: 'coach.prompt.onboardAge',
  [CoachStep.ONBOARD_GENDER]: 'coach.prompt.onboardGender',
  [CoachStep.ONBOARD_JOB]: 'coach.prompt.onboardJob',
  // Tầng 4 — "Mình bước ra khỏi tình huống một chút." The card does the rest.
  [CoachStep.SCENE_SCORE]: 'coach.prompt.sceneScore',
  [CoachStep.PLAN_ASK]: 'coach.prompt.planAsk',
  [CoachStep.PLAN]: 'coach.prompt.plan',
  [CoachStep.SCHEDULE]: 'coach.prompt.schedule',
  // "Có một khoá gần với chuyện bạn vừa nói tới."
  [CoachStep.COURSE_CARD]: 'coach.prompt.courseCard',
  // "Mình mở khoá đó cho bạn. Cứ xem một lesson thôi cũng được."
  [CoachStep.LEAVE]: 'coach.prompt.courseLeave',
  // "Cảm ơn bạn." — the toast does the asking.
  [CoachStep.RATING]: 'coach.prompt.rating',
  // ① closes on "Tập vậy là đủ cho hôm nay."; ② on `COACH_END_STOP_KEY`.
  [CoachStep.END]: 'coach.prompt.endLesson',
  [CoachStep.SAFETY]: 'coach.prompt.safety',
  // Retired steps keep their lines so a session parked on one still renders.
  [CoachStep.PICK_HABIT]: 'coach.prompt.pickHabit',
  [CoachStep.PERSONA]: 'coach.prompt.persona',
  [CoachStep.TIME]: 'coach.prompt.time',
  [CoachStep.CHECKIN]: 'coach.prompt.checkin',
  [CoachStep.TELL]: 'coach.prompt.tell',
  [CoachStep.FREE]: 'coach.prompt.free',
  [CoachStep.DEPTH]: 'coach.prompt.depth',
  [CoachStep.BARRIER]: 'coach.prompt.barrier',
  [CoachStep.CONTEXT_ASK]: 'coach.prompt.contextAsk',
  [CoachStep.CONTEXT_EDIT]: 'coach.prompt.contextEdit',
  [CoachStep.JOT]: 'coach.prompt.jot',
  [CoachStep.NEXT_ACTION]: 'coach.prompt.nextAction',
  [CoachStep.REDRAFT]: 'coach.prompt.redraft',
};

/**
 * The coordinator's line when it is the session's OPENING rather than the seam
 * between two tasks.
 *
 * ②B and ②C open on the coordinator now (bug sheet 2026-08-28 16:18), and its
 * usual line — "Xong rồi. Còn gì bạn muốn nói không?" — reads as a goodbye when
 * nothing has happened yet. Same step, same pills, one honest sentence.
 */
export const COACH_HUB_OPEN_KEY = 'coach.prompt.hubOpen';

/**
 * "Say nothing of your own" — a key no client maps, so the step's fixed line
 * is suppressed. Used when the server has already said the closing sentence
 * through `reply` and END must not add "Vậy mình dừng ở đây nhé." under it.
 */
export const COACH_NO_PROMPT_KEY = 'coach.prompt.none';

/** STORY on ②A, ④ and every new session: "Hôm nay CÒN chuyện gì mới không?" */
export const COACH_STORY_MORE_KEY = 'coach.prompt.storyMore';

/**
 * ②B's opening line, chosen by the day's mood — "câu mở, chọn theo mood, không
 * cố định".
 *
 * Five moods × three variants, all written and all shipped as slang keys: the
 * doc is explicit that they are "viết sẵn, không gọi AI. Mỗi mức có 2–3 biến
 * thể, chọn xoay vòng để không lặp y hệt hằng ngày."
 *
 * Two rules live in the wording rather than in code, so they are worth naming
 * here: mood only widens or narrows the DOOR, and the line must never mention
 * the mood itself — "Thấy bạn đang mệt, có muốn nói gì không?" is a statement
 * about the person, which is the one thing this feature forbids.
 */
const STORY_OPEN_KEYS: Record<number, readonly string[]> = {
  1: [
    'coach.prompt.storyOpenBad1',
    'coach.prompt.storyOpenBad2',
    'coach.prompt.storyOpenBad3',
  ],
  2: [
    'coach.prompt.storyOpenTired1',
    'coach.prompt.storyOpenTired2',
    'coach.prompt.storyOpenTired3',
  ],
  3: [
    'coach.prompt.storyOpenOk1',
    'coach.prompt.storyOpenOk2',
    'coach.prompt.storyOpenOk3',
  ],
  4: [
    'coach.prompt.storyOpenGood1',
    'coach.prompt.storyOpenGood2',
    'coach.prompt.storyOpenGood3',
  ],
  5: [
    'coach.prompt.storyOpenGreat1',
    'coach.prompt.storyOpenGreat2',
    'coach.prompt.storyOpenGreat3',
  ],
};

/**
 * Which opener to use today.
 *
 * `mood` null (never asked, or the mood question was skipped) falls back to the
 * default line — "không suy đoán". The variant rotates on the local day so the
 * same reader does not meet the same sentence two mornings running, and it is
 * derived rather than stored: a counter in the database would be one more thing
 * to migrate for a line nobody remembers.
 */
export function coachStoryOpenKey(
  mood: number | null | undefined,
  localDay: number,
): string | null {
  const variants = mood ? STORY_OPEN_KEYS[mood] : null;
  if (!variants?.length) return null;

  return variants[Math.abs(localDay) % variants.length];
}

/** INTENT_TELL after "Có dịp nhưng chưa làm": "…Lúc đó điều gì làm bạn dừng lại?" */
export const COACH_INTENT_TELL_MISSED_KEY = 'coach.prompt.barrier';

/** ② END: "Vậy mình dừng ở đây nhé." */
export const COACH_END_STOP_KEY = 'coach.prompt.endStop';

/** TELL_2 entered through ⑤: "Mình hiểu sai rồi. Vậy bạn kể lại giúp mình: chuyện gì đã xảy ra?" */
export const COACH_REDRAFT_KEY = 'coach.prompt.redraft';

/** NEXT_SESSION when the model could not write the closing line, or there is no commitment to quote. */
export const COACH_CLOSING_WITH_PLAN_KEY = 'coach.prompt.closingWithPlan';
export const COACH_CLOSING_NO_PLAN_KEY = 'coach.prompt.closingNoPlan';

// ---- notes: fixed lines said BEFORE the next step's own line ---------------

/** ②A "Không có tình huống nào": "Vậy là bối cảnh chưa xuất hiện, không phải bạn tránh. Mình giữ nhắc hẹn này lại." */
export const COACH_INTENT_NONE_KEY = 'coach.prompt.intentNone';

/** ②A — the third "không có tình huống" in a row put the commitment to sleep. */
export const COACH_PLAN_SLEPT_KEY = 'coach.prompt.planSlept';

/** ②A after the câu kể: "Mình lưu nguyên văn câu bạn vừa kể." */
export const COACH_INTENT_TELL_DONE_ACK_KEY = 'coach.prompt.intentTellDone';

/** ②A after "what stopped you": "Mình ghi nhận." — the shrink question follows. */
export const COACH_INTENT_TELL_MISSED_ACK_KEY = 'coach.prompt.intentTellMissed';

/** ②A — the smaller commitment replaced the old one: "Mình đổi sang bản nhỏ hơn. Giờ nhắc giữ nguyên." */
export const COACH_SHRINK_DONE_KEY = 'coach.prompt.shrinkDone';

/**
 * Why THIS course is on the card — a fact about the reader, never a model's
 * opinion. Each is a slang key the client fills with `reasonArgs`.
 */
export const COACH_COURSE_REASON = {
  /**
   * The one reason the card has (doc v4): the story touched a habit the reader
   * does not have, and this course opens with it.
   */
  OUTSIDE: 'coach.course.reasonOutside',
  /** RETIRED (doc v4): the keypoint at nhịp 4 no longer chooses a course. */
  KEYPOINT: 'coach.course.reasonKeypoint',
  /** The habit the reader keeps stopping at; this course teaches it. */
  BARRIER: 'coach.course.reasonBarrier',
  /** The habit this session was about; a course they have not taken teaches it. */
  HABIT: 'coach.course.reasonHabit',
  /** Same skillset as a habit they practise; not started. */
  SKILLSET: 'coach.course.reasonSkillset',
  /** Luồng 4 FREE_TALK — the story itself connected to this course: "Từ chuyện bạn vừa kể". */
  STORY: 'coach.course.reasonStory',
  /** Luồng 3 — same skill set as the course just finished. */
  RECAP: 'coach.course.reasonRecap',
  /** They saved it from an earlier card and never opened it. */
  SAVED: 'coach.course.reasonSaved',
  /**
   * The last resort, and the only reason that needs nothing to match: the
   * course they are already in the middle of.
   *
   * Owner 2026-09-05 — "luôn luôn khi có cơ hội thì điều hướng đề xuất cho user
   * học một bài nào đó". Every other reason here needs a habit to connect
   * through, so a story that touched no habit ended on a closing sentence and a
   * Đóng button. Their own unfinished course is never a course suggested "cho
   * có": it is the next thing they were going to do anyway.
   */
  RESUME: 'coach.course.reasonResume',
} as const;

/**
 * ②C's closing line — "Mình nghe rồi. Khi nào muốn nói tiếp thì mình ở đây."
 *
 * The no-commitment line elsewhere says "Ghi lại rồi nhé", and in ②C nothing IS
 * written down: that branch keeps no story ("câu chuyện không được lưu — phiên
 * đóng là mất"). A closing line that claims otherwise is the app lying about
 * itself in the last sentence the reader sees.
 */
export const COACH_CLOSING_HEARD_KEY = 'coach.prompt.closingHeard';

/**
 * SCENE_FEELING on a low day — the scene is told about somebody else, so the
 * feeling is asked the same way: "Nếu là người đó, lúc đó bạn cảm thấy thế nào?"
 */
export const COACH_SCENE_FEELING_THIRD_KEY = 'coach.prompt.sceneFeelingThird';

/**
 * After the feeling is answered, before the scene's own question — "Cảm giác
 * đó dễ hiểu." Fixed on purpose: a model empathising costs a call and drifts
 * into commenting on the feeling, which is the one thing this beat must not do.
 */
export const COACH_SCENE_FEELING_ACK_KEY = 'coach.prompt.sceneFeelingAck';

/**
 * The scene's closing line when nhịp 5 is skipped — "Đủ rồi", or a second
 * answer too short to compare. Said instead of a model line, because there is
 * nothing to compare and nothing to add: "nhịp 5 KHÔNG đưa thêm cách nói khác".
 */
export const COACH_SCENE_DONE_KEY = 'coach.prompt.sceneDone';

/** Nhịp 3 → 4: "Đó là câu của bạn, mình không sửa." */
export const COACH_PROBLEM_ACK_KEY = 'coach.prompt.problemAck';

/** After the scene, when the model could not reply: "Mình nghe rồi — không chấm đúng sai…" */
export const COACH_SCENE_ACK_KEY = 'coach.prompt.sceneAck';

/**
 * T4's acknowledgement — "Mình ghi lại rồi nhé."
 *
 * A note rather than a step: the task has no question of its own, so the line
 * is said on the way to "Muốn đặt Nhắc hẹn không?". ≤15 words, fixed, and
 * deliberately flat — "không diễn giải, không phản chiếu, không cá nhân hoá".
 */
export const COACH_JOT_ACK_KEY = 'coach.prompt.jotAck';

/** ① before its scene: "Bạn vừa thêm “{habit}”. Một cảnh ngắn:" */
export const COACH_LESSON_INTRO_KEY = 'coach.prompt.lessonIntro';

/** ④ before the old scene: "Tình huống này bạn từng gặp ba tuần trước. Thử lại xem sao?" */
export const COACH_RETRY_INTRO_KEY = 'coach.prompt.retryScene';

/** ④ after the answer: "Ghi rồi. Recap thứ 2 sẽ đặt hai câu cạnh nhau và im lặng — không bình luận." */
export const COACH_RETRY_ACK_KEY = 'coach.prompt.retryAck';

/** ④'s bubble teaser: "Tình huống ba tuần trước…" */
export const COACH_TEASER_RETRY_KEY = 'coach.teaser.retry';

/**
 * Luồng 5 — the Habit screen with an empty kho: the bubble says why it is
 * there ("Chưa có thói quen nào trong kho. Học một bài để thêm nhé?"), which
 * is the one teaser in the app that carries no words of the reader's own.
 */
export const COACH_TEASER_FIRST_HABIT_KEY = 'coach.teaser.firstHabit';

/**
 * The bubble's own line, one per screen and fixed — the design draws each
 * screen with its own sentence ("Vào trò chuyện một chút nhé?" at Home, "Kể
 * mình nghe một lần thật, hay làm quiz cùng mình?" on the Habit screen with a
 * kho). Never a quote of anything the reader said: this sits on a screen
 * anyone walking past can read.
 */
/**
 * Câu mở phiên Home NHẮC LẠI chuyện hôm trước — "Hôm trước bạn kể chuyện
 * {topic}. Hôm nay thế nào?"
 *
 * Thay `coach.prompt.hub` khi thẻ nhớ có một mảnh chủ đề chưa dùng, cùng ngôn
 * ngữ. Chỉ MẢNH `topic` là chữ model viết; khung câu là chữ cố định bên client,
 * vì `reply` và `promptKey` không bao giờ cùng có giá trị (hợp đồng i18n của
 * Coach) — và vì một câu chào do model viết sẽ có lần quên mất câu hỏi, để lại
 * người đọc trước một lời chào không có chỗ trả lời.
 */
export const COACH_PROMPT_KEY_HUB_BACK = 'coach.prompt.hubBack';

export const COACH_TEASER_HOME_KEY = 'coach.teaser.home';
/** Before luồng 1 has ever run: "Mình làm quen với bạn một chút nhé?" */
export const COACH_TEASER_ONBOARD_KEY = 'coach.teaser.onboard';
export const COACH_TEASER_HABIT_KEY = 'coach.teaser.habit';

/**
 * What the Coach says when the model could not answer.
 *
 * A reader mid-sentence about something difficult must never meet an error.
 * These are deliberately empty of content — an acknowledgement that claims to
 * have understood something it did not read would be worse than a plain one.
 */
export const COACH_FALLBACK_REPLY_KEY = 'coach.fallback.reply';

/**
 * Nhịp 2's question when the model failed, or twice reached for a forbidden
 * one: "Mình hỏi lại đúng điều đã xảy ra: lúc đó ai nói gì, ai làm gì?"
 */
export const COACH_TELL_FOLLOW_UP_KEY = 'coach.prompt.tellFollowUp';

/** Why a door stayed shut. Rendered by the client, never shown as an error. */
export const COACH_SILENT_REASON = {
  TOO_MANY_PENDING: 'coach.silent.tooManyPending',
  ALREADY_SHOWN_THIS_LESSON: 'coach.silent.alreadyShownThisLesson',
  // ① only opens when a habit was just added — "chỉ khi vừa add habit mới".
  NO_NEW_HABIT: 'coach.silent.noNewHabit',
  DISABLED: 'coach.silent.disabled',
} as const;
