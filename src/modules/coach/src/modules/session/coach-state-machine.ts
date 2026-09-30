import {
  MAX_INTENT_ROUNDS,
  STORY_TALK_ROUNDS,
  STORY_TALK_ROUNDS_LOW,
} from '../../shared/coach.constant';
import {
  CoachEntry,
  CoachHomeTier,
  CoachStep,
  CoachStoryKind,
  CoachUiKind,
} from '../../shared/coach.enum';
import { CoachPlanAnswer } from '../plan/enum/plan.enum';

/**
 * Everything the graph needs to decide the next step — and nothing else.
 *
 * Deliberately plain data with no repositories, no request, no clock. The
 * eight principles of this feature are transition rules, and transition rules
 * that can only be exercised by standing up a database are rules nobody
 * checks. This file is pure so its spec can enumerate the whole graph in
 * milliseconds.
 *
 * The graph is the design of 2026-08-26 (`HDDhistory AI Coach.html`, v2): ONE
 * spine, four doors. ① (end of a lesson, new habit) runs one scene and offers
 * a commitment. ② (Home) asks the day's mood once, checks in on a pending
 * commitment when there is one (②A), asks "hôm nay có chuyện gì mới không?",
 * runs the 5-beat script when a story is told (kể → hỏi lại → tách 2 cột →
 * luyện tập tình huống → nhắc hẹn + câu chốt), and closes on the tail: course
 * card → mood → rating → closing line → stop or start again. ③ (push) lands
 * on ②A. ④ replays a scene answered three weeks ago so the recap has a pair.
 *
 * Added 2026-08-26 (hướng đi): ②A's "có dịp mà chưa làm" is followed by the
 * offer to make the commitment smaller (SHRINK_ASK → SHRINK) — law 5, which
 * v2 had left with no step.
 */
/** What a typed answer at DEPTH means. */
export type CoachDepthGuess = 'deep' | 'shallow' | 'unsure';

/**
 * Words that close a subject rather than open one.
 *
 * The doc's own examples — "thế thôi", "ghi lại giúp mình", "vậy đó" — plus the
 * English equivalents, since the sentence is whatever language the reader
 * writes in and the five locales share one classifier.
 */
const DEPTH_CLOSING =
  /(th[êế]\s*th[ôố]i|v[ậa]y\s*th[ôố]i|v[ậa]y\s*[đd][óo]|th[êế]\s*[đd][óo]|h[êế]t\s*r[ồo]i|xong\s*r[ồo]i|ch[ỉi]\s*(v[ậa]y|nhi[êề]u\s*[đd][óo])|ghi\s*(l[ạa]i|gi[úu]p)|l[ưu]u\s*l[ạa]i|kh[ôo]ng\s*c[óo]\s*g[ìi]|that'?s\s*(it|all)|just\s*(note|log|jot)|nothing\s*(else|more)|note\s*it|log\s*it)/i;

/**
 * "Coach đọc input kế tiếp để đoán ý" — zero model calls.
 *
 * Long enough to be new content is telling; a short line that closes the
 * subject is filing; anything in between is genuinely unclear, and the flow
 * asks once more instead of choosing for them.
 */
export function guessDepth(text: string): CoachDepthGuess {
  const said = (text ?? '').trim();
  if (!said) return 'unsure';

  const words = said.split(/\s+/).length;
  if (DEPTH_CLOSING.test(said)) return 'shallow';
  if (words >= DEPTH_DEEP_WORDS) return 'deep';
  if (words <= DEPTH_SHALLOW_WORDS) return 'shallow';

  return 'unsure';
}

/** A sentence this long is somebody carrying on with their story. */
const DEPTH_DEEP_WORDS = 12;

/** This short, with nothing that reads as a story, is a shrug. */
const DEPTH_SHALLOW_WORDS = 3;

/**
 * Words that ask to STOP — not to file the story (that is `DEPTH_CLOSING`),
 * but to end the conversation: "dừng", "không muốn nói nữa", "enough".
 *
 * Accented "dừng" only, on purpose: typed without accents it is also "dùng"
 * (to use) and "đúng" (right), and a story about using a different approach
 * must not end the session. The length cap does the rest of the work — "xe
 * dừng lại giữa đường" is a story, and stories are long.
 */
const STORY_STOP =
  /(d[ừ]ng|kh[ôo]ng\s*(mu[ốo]n\s*)?(n[óo]i|k[ểe]|chia\s*s[ẻe])\s*(g[ìi]\s*)?(n[ữu]a|th[êe]m)|kh[ôo]ng\s*(mu[ốo]n\s*)?ti[ếe]p(\s*t[ụu]c)?|[đd][ủu]\s*r[ồo]i|\bstop\b|\benough\b|i'?m\s*done|no\s*more|let'?s\s*stop)/i;

/** A stop is a short utterance; anything longer is somebody still talking. */
const STORY_STOP_MAX_WORDS = 8;

/**
 * "User không muốn tiếp tục" — read with no model call, so the reader's
 * "thôi" is never sent anywhere to be replied to. The model may ALSO report
 * `CoachStoryKind.STOP`; this is the cheaper, earlier net.
 */
export function saysStop(text: string): boolean {
  const said = (text ?? '').trim();
  if (!said) return false;
  if (said.split(/\s+/).length > STORY_STOP_MAX_WORDS) return false;

  return STORY_STOP.test(said);
}

export interface CoachMachineContext {
  entry: CoachEntry;
  /** ② only: A with a pending commitment, D with a scene to replay, C otherwise. */
  tier?: CoachHomeTier | null;

  /**
   * ②A — the answer just given was "có dịp mà chưa làm", so the sentence
   * about what stopped them is followed by the offer to shrink the plan.
   */
  intentMissed: boolean;

  /** The start-of-day mood has already been recorded today (② only). */
  moodAlreadyAskedToday: boolean;

  /**
   * Today's start mood is Tệ or Hơi mệt.
   *
   * Two rules hang off it: the scene is told in the third person, and nhịp 2 of
   * the story script is skipped — "không đào sâu khi người ta đang mệt". ① reads
   * it if the day already has one and never asks for it.
   */
  moodLow?: boolean;

  /** ① — how many habits were added by the lesson just finished. */
  newHabitCount?: number;

  // ---- the task registry (doc v4: "bảng đăng ký task") ----------------

  /** Task runs spent this session — T1–T3 share one ceiling of 3. */
  tasksRun?: number;

  /** T1 is eligible: a pending commitment not yet asked about today. */
  hasPlanPending?: boolean;

  /** T2 is eligible: the session has settled on a habit in the reader's kho. */
  hasHabit?: boolean;

  /** Tasks already run this session — each has its own ceiling of one, T1 two. */
  t1Done?: boolean;
  t2Done?: boolean;
  t3Done?: boolean;

  /**
   * T4 is eligible: the session holds a REAL occasion in the reader's words —
   * from the story they told, or from "Gặp rồi" at the end of a scene.
   *
   * "Bối cảnh giả cho được hành động. Chỉ đời thật của user cho được dịp."
   */
  hasDip?: boolean;

  /** The commitment has already been offered once — it is offered once only. */
  t4Offered?: boolean;

  /** The course card has already been shown this session (one per session). */
  cardShown?: boolean;

  /** The scene on screen has a written second stage. */
  hasStage2?: boolean;
  /** Luồng 4 — the other person has spoken and the scene is waiting for the reader's SECOND line. */
  sceneAwaitingSecondLine?: boolean;

  /** What the line typed at the coordinator asked for — see `routeHub`. */
  hubRoute?: CoachTask | null;
  /**
   * The line asked to go back to a scene already practised, AND there is one
   * stored to go back to — see `asksForOldScene`.
   *
   * Both halves matter: the words alone would send a reader with no history
   * into a replay of nothing, and the flow has no way to say "there isn't one"
   * once it is in the step.
   */
  hubReplayScene?: boolean;
  /** The reader asked US something instead of answering — see `HOLDS_ON_QUESTION`. */
  readerAsksBack?: boolean;

  /**
   * Mid-scene, the reader asked for a DIFFERENT scene — see
   * `asksForAnotherScene`. Only that they ASKED; whether they may have one is
   * `sceneOnRequest`, applied here so the ceiling is read in one place.
   */
  sceneSwapAsked?: boolean;

  /**
   * The closing sequence has started — card → the one commitment offer → tail.
   *
   * Set once the reader chooses to stop or the task ceiling is reached, so a
   * commitment made HERE goes on to the tail instead of back to the coordinator.
   */
  closing?: boolean;

  /**
   * ②C — the habit the story matched is already in the reader's kho.
   *
   * Decides the whole shape of the tail: a habit they have can carry a
   * reminder, one they do not can only be pointed at through a course.
   */
  guidedHabitOwned?: boolean;

  /** ②A — pending plans this session will walk, frozen at session start. */
  planQueueLength: number;
  planIndex: number;
  /** ②A "không có tình huống nào": THIS answer is the third in a row — the plan sleeps. */
  planSlept: boolean;

  /** Three skips and the ask is gone for good. */
  ratingHidden: boolean;
  /** A story was told this sheet-open — "chỉ hiện sau phiên CÓ kể chuyện". */
  storyTold: boolean;
  /** Mood-end and rating are asked once per sheet-open, however many sessions run. */
  moodEndAsked: boolean;
  ratingAsked: boolean;
  /** Mood-end came back low: "phiên mới" is hidden, only "Dừng" remains. */
  moodEndLow: boolean;

  /** A published course matches the habit — the tail shows the card. */
  hasCourse: boolean;

  /**
   * The reader started the day low AND it is past 22:00 their time.
   *
   * "Mood thấp và sau 22h → bỏ nhịp 2": the draft is still built, nobody is
   * turned away, but they are not asked to dig deeper first. Digging into a
   * hard evening at midnight is how a coach becomes the thing keeping
   * somebody awake. A safety rule, so it outlives the artboard that omits it.
   */
  lateNightLow: boolean;

  /**
   * A scene can be built — the session knows which habit it is about.
   *
   * Without one, "Tập thử một cảnh" would open an empty Coach turn and a
   * text box; the invitation is skipped and the commitment asked for instead.
   * Only ever false on the edge (a reader with no habit reaching the Home
   * door through something other than the bubble).
   */
  hasScene: boolean;

  /**
   * ⑤ — the whole draft was rejected once already.
   *
   * The reader tells the story again and the Coach drafts again, but the
   * button is not offered a second time: "không tranh luận, không bảo vệ bản
   * nháp" cuts both ways, and a third telling is where a conversation about
   * something hard turns into an argument about a form.
   */
  draftRejected: boolean;

  /**
   * DEPTH — what the reader's typed answer to "Bạn muốn chia sẻ thêm không?"
   * looks like, read by `guessDepth` and never by a model.
   *
   * `unsure` is a real answer, not a failure: the doc asks for one more
   * question rather than a guess, and only then defaults to filing it.
   */
  depthGuess?: CoachDepthGuess;

  /** DEPTH — the "kể tiếp, hay mình ghi lại?" question has been asked already. */
  depthReasked?: boolean;

  /**
   * STORY_TALK — what kind of line the reader just typed, as the model
   * reported it with its reply (or as `saysStop` read it, with no model). The
   * graph routes on this alone; unset means "carry on".
   */
  storyKind?: CoachStoryKind | null;

  /** STORY_TALK — replies already given in this conversation. */
  storyTalkRounds?: number;

  /**
   * Luồng 4 — the judge's verdict on the answer just given to the Home scene:
   * on track, or not. Set by the service from the model's reply on the same
   * turn, so the graph can send an off-track answer to the retry offer at once.
   */
  sceneOnTrack?: boolean | null;

  /** SCENE_PICK — the name typed matched a habit in the reader's kho. */
  pickedHabit?: boolean;

  // ---- luồng 5 (Habit screen) -------------------------------------------
  /** The habit has a quiz to read in the chat (playable single-choice questions). */
  hasQuiz?: boolean;
  /** Today's check-in for THIS habit is already written. */
  checkinDone?: boolean;
  /** The quiz has already run this session. */
  quizDone?: boolean;
  /** Another habit in the kho is still unwritten today — the offer has something to name. */
  hasNextHabit?: boolean;
  /** QUIZ_IN_CHAT — questions still to ask, the current one included. */
  quizRemaining?: number;

  // ---- luồng 2/3 (the lesson door, redrawn) ------------------------------
  /**
   * Which of the lesson door's two new flows this session is: the talk after a
   * keypoint, or the course recap after the last one. Null = the legacy scene
   * door ①, kept for clients that open without a keypoint.
   */
  talkMode?: 'talk' | 'recap' | null;
  /** The chip value of a `pick` event, read by the step it was tapped on. */
  pick?: string | null;
  /**
   * TALK_FREE — this answer spends the last turn of the follow-up budget, so
   * the floor closes after it.
   *
   * Decided by the service, not here: the budget lives on the session and its
   * ceiling comes from admin config, and the machine stays a pure function of
   * (step, event, context).
   */
  talkFreeExhausted?: boolean;

  // ---- luồng 1 (Onboarding Coach) ----------------------------------------
  /** First Home session ever: the eight questions run before the mood. */
  onboarding?: boolean;
  /** Which of the four optional questions the admin left on. */
  onboardAsk?: { style: boolean; age: boolean; gender: boolean; job: boolean };
  /** The address question exists only in Vietnamese. */
  viLocale?: boolean;
  /** ONBOARD_ADDRESS — a NAME was typed rather than a pronoun; confirm it first. */
  onboardNamed?: boolean;

  /**
   * 6b's answer was a dead end — nothing typed worth keeping, or a question
   * back at the Coach. Either way 6d is skipped and NO dip is made: "phiên
   * chưa có dịp thật nên không mời T4" (mẫu #7, #13).
   */
  sceneDidDead?: boolean;

  /** Free-text answers already given to the scene currently on screen. */
  situationRound: number;

  /**
   * The Coach's reply to the last scene answer asked a follow-up question, so
   * the reader gets another turn — bounded by `situationRoundsFor`. Set by the
   * service from the reply itself; false whenever the model closed the scene.
   *
   * Only consulted for LEGACY scenes with no script. A scripted scene walks its
   * authored beats regardless — `sceneScripted` switches which rule applies.
   */
  sceneContinues: boolean;

  /**
   * This scene carries a script (`sceneBeats`), so the number of turns is
   * decided by the script, not by whether the model happened to ask. False for
   * legacy scenes, which keep the improvised "ask → continue" behaviour.
   */
  sceneScripted?: boolean;

  /**
   * How many answers THIS scene takes in total — the script's beat count plus
   * one (the closing turn). Legacy scenes leave it unset and fall back to
   * `SITUATION_PROBE_ROUNDS`.
   */
  sceneRounds?: number;

  /**
   * The skill this scene belongs to defines a rubric, so the finished scene gets
   * the tầng-4 card. False (no rubric authored on the habit) sends the flow
   * straight to the commitment exactly as before — scoring is opt-in per skill,
   * which is what keeps an unscored habit from showing an empty report.
   */
  hasRubric?: boolean;

  /**
   * The reader has already replayed this scene once from the score card.
   *
   * One retry, not many: "thử lại theo cách khác" is a second attempt at a
   * moment, and an unbounded loop would let somebody grind the same scene for a
   * better number — which is the failure mode of putting a score on anything.
   */
  sceneRetried?: boolean;
}

export type CoachEvent =
  | { kind: 'start' }
  | { kind: 'mood' }
  | { kind: 'pickNew' }
  | { kind: 'text' }
  /** STORY — "Không có gì đặc biệt". */
  | { kind: 'skip' }
  | { kind: 'intent'; answer: CoachPlanAnswer }
  /** "Tập thử một cảnh" (true) · "Hôm nay bỏ qua" (false). */
  | { kind: 'invite'; accept: boolean }
  /** "Có, đặt Nhắc hẹn" (true) · "Không, đóng luôn" (false). */
  | { kind: 'planAsk'; accept: boolean }
  | { kind: 'plan' }
  | { kind: 'schedule' }
  | { kind: 'loop'; keepGoing: boolean }
  /**
   * The card's ways out: "Đi tới khoá học" leaves, save and close go on, and
   * "Luyện cảnh khó hơn" turns the tail back into another scene.
   */
  | { kind: 'course'; open: boolean; harder?: boolean }
  | { kind: 'moodEnd' }
  | { kind: 'rating' }
  /** "Bắt đầu phiên mới" (true) · "Dừng ở đây" (false). */
  | { kind: 'nextSession'; again: boolean }
  /** ⑤ — "Không đúng với mình": the draft was not theirs at all. */
  | { kind: 'rejectDraft' }
  /** Bộ điều phối — the reader picked a task by name. */
  | { kind: 'task'; task: CoachTask }
  /** Luồng 5 — CHECKIN_ASK: "Có, mình làm được" (true) · "Chưa, hôm nay không có dịp" (false). */
  | { kind: 'checkin'; done: boolean }
  /** Luồng 5 — QUIZ_IN_CHAT: an option was tapped. */
  | { kind: 'quizAnswer' }
  /** Luồng 2/3 — a generic chip pick; the value rides in `ctx.pick`. */
  | { kind: 'pick' }
  /** Luồng 2 — the keypoint quiz ran on its own screen and reported back. */
  | { kind: 'quizDone' }
  /** Bộ điều phối — "Mình dừng ở đây": start the closing sequence. */
  | { kind: 'stop' }
  /** Nhịp 6 — "Gặp rồi" (true) · "Chưa gặp" (false). */
  | { kind: 'sceneMet'; met: boolean }
  /** RETIRED (doc v4): nhịp 4 does not ask them to say it again. */
  | { kind: 'sceneAgain'; again: boolean }
  /** The rubric card: "Thử lại tình huống này" (true) · "Tiếp tục" (false). */
  | { kind: 'sceneScore'; retry: boolean }
  /** SHRINK_ASK — "Thu nhỏ lại" (true) · "Giữ nguyên, thử lại" (false). */
  | { kind: 'shrink'; accept: boolean }
  // ---- retired events, accepted only from the steps they used to leave ----
  | { kind: 'depth'; deep: boolean }
  | { kind: 'context'; keep: boolean }
  | { kind: 'escape' }
  | { kind: 'ack' };

/**
 * ⑥ is gone from the design (v2 has no "chỉ ghi lại thôi" line). The hook
 * stays so a parked JOT session still renders; nothing offers it any more.
 */
export function isEscapeAvailable(_step: CoachStep): boolean {
  return false;
}

/**
 * Steps whose free-text answer costs a model call.
 *
 * STORY is absent on purpose: its answer is handled by name in the service
 * (the reply IS the model's one question, plus ②B's silent habit match).
 * TELL_2's cost is the draft, not a reply. TWO_COLS is answered with a FIXED
 * line — "Đó là câu của bạn, mình không sửa." — because a model commenting on
 * the one sentence it is forbidden to touch was the bug. INTENT_TELL is fixed
 * too: "Mình lưu nguyên văn câu bạn vừa kể." — the Coach files it and moves on.
 */
/**
 * Steps where a question back HOLDS instead of advancing.
 *
 * Owner 2026-09-05: "trả lời chệch đi 1 cái là AI cứ đi tiếp luôn chả quan tâm
 * user nói gì". Every one of these poses a question and then treats whatever
 * comes back as the answer — a scene scored "sao lại hỏi thế?" as the reader's
 * move. Holding re-asks the step; the turn's reply answers what they actually
 * said.
 *
 * The story steps are deliberately NOT here: a question inside the
 * conversation is content, and `storyKind: "asks_how"` already answers it.
 */
const HOLDS_ON_QUESTION: ReadonlySet<CoachStep> = new Set([
  CoachStep.TELL_ONCE,
  CoachStep.SCENE_RETRY,
  CoachStep.SCENE_STAGE2,
  CoachStep.SCENE_DID,
  CoachStep.SCENE_MET,
  CoachStep.CHECKIN_TELL,
  CoachStep.TALK_ASK,
  CoachStep.TALK_SUMMARY,
]);

/** Does a question back hold this step? See `HOLDS_ON_QUESTION`. */
export function holdsOnQuestion(step: CoachStep): boolean {
  return HOLDS_ON_QUESTION.has(step);
}

const AI_STEPS: ReadonlySet<CoachStep> = new Set([
  // T3's conversation — every line costs the one call that answers it.
  CoachStep.STORY_TALK,
  CoachStep.TELL_2,
  CoachStep.TELL_ONCE,
  // Luồng 4 — the second try at the Home scene is judged like the first.
  CoachStep.SCENE_RETRY,
  // Luồng 5 — the one sentence about the occasion earns one acknowledging line.
  CoachStep.CHECKIN_TELL,
  // Luồng 2 — what they remember (typed at the opener) and their answer to the
  // summary's question both earn the ≤25-word reply, and every follow-up
  // question they ask afterwards earns an answer of its own.
  CoachStep.TALK_ASK,
  CoachStep.TALK_SUMMARY,
  CoachStep.TALK_FREE,
  // Luồng 1 — a question typed at the introduction is answered.
  CoachStep.ONBOARD_INTRO,
  // Nhịp 5 — one specific piece of praise for how they handled both stages.
  CoachStep.SCENE_STAGE2,
  // 6b's answer earns the mirror line (6c) — one call, ≤35 từ. A "Rồi" that
  // arrives WITH the telling (typed at 6a) earns the same line.
  CoachStep.SCENE_DID,
  CoachStep.SCENE_MET,
  // Retired steps keep costing what they cost, for sessions parked on them.
  CoachStep.TELL,
  CoachStep.FREE,
  CoachStep.JOT,
  CoachStep.NEXT_ACTION,
]);

export function requiresAi(step: CoachStep): boolean {
  return AI_STEPS.has(step);
}

/**
 * Steps that belong to the end of a session rather than to any task.
 *
 * The service latches `closing` on these, so a commitment made after the card
 * goes on to the tail instead of back to the coordinator.
 */
const CLOSING_STEPS: ReadonlySet<CoachStep> = new Set([
  CoachStep.COURSE_CARD,
  CoachStep.LEAVE,
  CoachStep.MOOD_END,
  CoachStep.RATING,
  CoachStep.NEXT_SESSION,
  CoachStep.END,
]);

export function isClosingStep(step: CoachStep): boolean {
  return CLOSING_STEPS.has(step);
}

/** Steps that show a scene and file the answer against it. */
const SITUATION_STEPS: ReadonlySet<CoachStep> = new Set([
  // The scene's opening beat — shows the scene, asks the feeling. Its answer
  // is NOT filed as the scene's answer (the action at TELL_ONCE is).
  CoachStep.SCENE_FEELING,
  CoachStep.TELL_ONCE,
  CoachStep.RETRY_SCENE,
  CoachStep.SCENE_RETRY,
  CoachStep.TELL_ONCE_A,
  CoachStep.TELL_ONCE_B,
  CoachStep.PRACTICE_ANSWER,
]);

export function isSituationStep(step: CoachStep): boolean {
  return SITUATION_STEPS.has(step);
}

/**
 * Steps a session is allowed to survive the day boundary on.
 *
 * The day close exists for a good reason — "yesterday's half-told story is
 * closed rather than put back in front of somebody whose mood today nobody has
 * asked" — but it treats every unfinished session the same, and these are not
 * the same. A scene is a question the reader was in the middle of answering,
 * and the Coach's own closing line promises "mai kể tiếp cũng được"; closing it
 * overnight made that promise impossible to keep.
 *
 * Only the scene steps, and only these: a session left sitting at the
 * coordinator has nothing to come back to, and resuming it would put a stale
 * opener in front of somebody who came to start something.
 *
 * Onboarding already survives the boundary the same way, which is the pattern
 * this copies — including the trade-off it accepts: the resumed session does
 * not ask today's mood, because the scene on screen was already written.
 */
/**
 * Steps where a typed line IS the scene's answer.
 *
 * `SITUATION_STEPS` alone is not that set: `SCENE_STAGE2` shows no scene of its
 * own so it is not one, but the other person has just spoken and the reader
 * owes the second line — which the verdict reads. Anything that asks "are we
 * inside a scene" wants THIS list, and a spec caught the difference the hard
 * way: a guard written on `isSituationStep` let a request typed at stage two
 * through to be graded as the answer.
 */
export function isInScene(step: CoachStep): boolean {
  return isSituationStep(step) || step === CoachStep.SCENE_STAGE2;
}

/** The same set as an array — what the resume queries filter on. */
export const SCENE_RESUME_STEPS: readonly CoachStep[] = [
  ...SITUATION_STEPS,
  CoachStep.SCENE_STAGE2,
];

/** Scene steps whose answer the model replies to (④'s is answered with a fixed line). */
const SITUATION_PROBE_STEPS: ReadonlySet<CoachStep> = new Set([
  CoachStep.TELL_ONCE,
  // The retry files as the scene's second answer (round 2).
  CoachStep.SCENE_RETRY,
  CoachStep.SCENE_STAGE2,
  CoachStep.TELL_ONCE_A,
  CoachStep.TELL_ONCE_B,
]);

export function isSituationProbeStep(step: CoachStep): boolean {
  return SITUATION_PROBE_STEPS.has(step);
}

/**
 * Answers one scene takes. ONE — "ba nhịp, 30–45 giây": Coach dựng cảnh, user
 * trả lời, Coach phản hồi một lượt. Kept as a function because the prompt and
 * the service both ask "is this the closing answer", and the answer is always
 * yes; a parked multi-round session still terminates on its next answer.
 */
export function situationRoundsFor(_ctx: CoachMachineContext): number {
  return SCENE_ANSWERS;
}

/**
 * Answers one scene takes. THREE since 2026-09-07 (owner).
 *
 * Two gave exactly one fork: answer, feel the reaction, answer again, verdict.
 * With the named ways forward now offered after each reaction, one fork is not
 * a branching practice — it is a single multiple-choice question, which is what
 * the owner saw on the device ("user chọn theo các tình huống rẽ ra các ngữ
 * cảnh tương ứng chứ tôi chưa thấy chọn gì"). Three answers give two forks, so
 * the second choice is made in a situation the FIRST choice created.
 *
 * FIVE since later the same day, after the owner put the whole reference
 * transcript side by side with ours: theirs forks five times (A → A1/A2 →
 * A2-a/A2-b → A2-a1/A2-a2 → one more), and the practice only becomes a practice
 * once a choice is made in a situation an earlier choice built. Three forked
 * twice and still read as a quiz.
 *
 * The reason two was chosen has NOT gone away and is the thing to watch on the
 * device: "vòng lặp không có đáy, và user bắt đầu đoán Coach muốn nghe gì". The
 * symptom to look for is a reader who stops asking "what would I say" and
 * starts asking "which one does it want" — if that shows up, the fix is not
 * four; it is letting the reaction say the scene has landed and closing there,
 * which is what the reference transcript actually did (it ended when An became
 * co-operative, not on a count).
 *
 * Cost is linear in this number: four reactions plus one verdict per scene,
 * against one plus one before.
 */
const SCENE_ANSWERS = 5;

/**
 * Which shade of scene to show.
 *
 * `default` for every live door. A low day does NOT change the pool any more:
 * the doc of 2026-08-27 makes the two tellings of a scene — second person and
 * third — two FIELDS of one row ("cùng một tình_huống_id, chỉ khác cách kể…
 * đổi biến thể không đổi nội dung cảnh"), and `attachSituation` picks the
 * third-person wording off the same row when the mood is low. Pointing a low
 * day at a different variant key instead only emptied the pool it looked in.
 *
 * ④ replays a stored scene, so its variant is bookkeeping; the rest are steps
 * no live session reaches.
 */
export function situationVariantFor(
  step: CoachStep,
  _moodLow: boolean,
  _entry?: CoachEntry | null,
): string {
  if (step === CoachStep.RETRY_SCENE) return 'retry';
  if (step === CoachStep.TELL_ONCE_B) return 'after_missed';
  if (step === CoachStep.PRACTICE_ANSWER) return 'practice';
  if (step === CoachStep.TELL_ONCE_A) return 'after_none';

  return 'default';
}

/**
 * What a line typed at the coordinator is asking for — keywords, no model.
 *
 * "Classifier chỉ định tuyến, không sinh chữ — không tính vào ngân sách gọi
 * AI." The examples are the doc's own; anything that does not match is left to
 * the caller, which falls back to the story task and lets its own fork ask.
 */
const HUB_ROUTES: ReadonlyArray<[CoachTask, RegExp]> = [
  [
    'T1',
    /(nh[ắa]c\s*h[ẹe]n|c[áa]i\s*h[ẹe]n|h[ôo]m\s*qua|h[ẹe]n\s*h[ôo]m\s*tr[ưu][ớo]c|[đd][ãa]\s*th[ửu]|l[àa]m\s*[đd][ưu][ợo]c\s*r[ồo]i|reminder|the plan)/i,
  ],
  [
    'T4',
    /(l[ầa]n\s*t[ớo]i|nh[ắa]c\s*m[ìi]nh|[đd][ặa]t\s*l[ịi]ch|h[ẹe]n\s*gi[ờo]|remind me|next time)/i,
  ],
  [
    'T2',
    // `tập` carries a lookahead because the bare syllable is a substring of
    // ordinary words: "tôi tập trung hơn" was routed to the practice task and
    // answered with the habit picker. The excluded syllables are the ones that
    // turn it into a different word — `tập luyện` stays, being the real thing.
    /(t[ậa]p(?!\s*(trung|th[ểe]|tin|qu[áa]n|h[ợo]p))\s*(th[ửu]|m[ộo]t|lu[ỵy]?[ệe]n)?|lu[ỵy]?[ệe]n\s*t[ậa]p|t[ìi]nh\s*hu[ốo]ng|b[ốo]i\s*c[ảa]nh|n[óo]i\s*th[ếe]\s*n[àa]o|tr[ưu][ờo]ng\s*h[ợo]p|practi[sc]e|role\s*play)/i,
  ],
];

/**
 * Longest line the keyword router will judge.
 *
 * The routes exist to catch a short ASK — "cho mình tình huống", "nhắc hẹn" —
 * typed instead of tapping the pill. A paragraph is not an ask, it is somebody
 * telling their day, and matching a keyword anywhere inside one hijacks it:
 * "…để xử lý nhanh hơn trong các TRƯỜNG HỢP tương tự về sau" was read as "I
 * want to practise" and answered with the habit picker, while the sentence
 * itself was answering the question the previous session had ended on.
 *
 * A ceiling rather than a smarter pattern because the failure is structural: a
 * long line has room for any keyword by coincidence, so every pattern here
 * would need the same guard.
 */
const HUB_ROUTE_MAX_WORDS = 12;

/**
 * Is the line short enough to be read as an ask?
 *
 * zh and ja write without spaces, so a whole paragraph can be one "word" —
 * when the token count is implausibly low for prose, count characters instead,
 * at roughly two per word. Same fallback `situationTooLong` uses.
 */
function withinRouteLength(said: string): boolean {
  const tokens = said.split(/\s+/).filter(Boolean);
  if (tokens.length > 3) return tokens.length <= HUB_ROUTE_MAX_WORDS;

  return said.replace(/\s+/g, '').length <= HUB_ROUTE_MAX_WORDS * 2;
}

/**
 * Does this line ask for the scene they ALREADY practised, not a new one?
 *
 * Separate from `HUB_ROUTES` because it is not a different task — it is T2
 * pointed at a stored scene by id. Everything else about practice in this
 * product means "a different scene": the pool excludes what they answered,
 * `resolve` writes a fresh one every time, and even SCENE_RETRY is documented
 * as "a DIFFERENT scene about the same habit". So the only way back to a scene
 * is to ask for it in these words.
 */
const HUB_REPLAY_PATTERN =
  /((t[ìi]nh\s*hu[ốo]ng|c[ảa]nh|b[àa]i\s*t[ậa]p)\s*(c[ũu]|tr[ưu][ớo]c|v[ừu]a\s*r[ồo]i|h[ôo]m\s*qua|l[úu]c\s*tr[ưu][ớo]c|d[ởo]|[đd]ang\s*d[ởo])|(quay\s*l[ạa]i|l[àa]m\s*l[ạa]i|t[ậa]p\s*l[ạa]i|ti[ếe]p\s*t[ụu]c)\s*(c[áa]i\s*)?(t[ìi]nh\s*hu[ốo]ng|c[ảa]nh|b[àa]i\s*t[ậa]p)|(the\s*)?(same|old|previous|last)\s*(scene|situation|exercise))/i;

/** Whether a line asks to go back to a scene already practised. */
export function asksForOldScene(text: string): boolean {
  const said = (text ?? '').trim();
  if (!said || !withinRouteLength(said)) return false;

  return HUB_REPLAY_PATTERN.test(said);
}

/**
 * "Cho tôi tình huống khác" — asked from INSIDE a scene.
 *
 * Deliberately its own pattern, not `HUB_ROUTES`. Mid-scene every line is the
 * ANSWER: it is what `sceneFirstLine` files and what the verdict reads, so a
 * request typed there used to be scored as though the reader had said it to the
 * person in the scene (owner, 2026-09-08 — "bắt buộc user hoàn thành tình
 * huống nếu user bảo là cho tôi tình huống khác thì mới sang tình huống khác").
 *
 * The words are the OPPOSITE half of `HUB_REPLAY_PATTERN`: khác · mới · đổi,
 * where that one takes cũ · trước · vừa rồi. Nothing else leaves a scene, which
 * is the rest of what the owner asked for — finish it, unless you say this.
 */
const SCENE_SWAP_PATTERN =
  /((t[ìi]nh\s*hu[ốo]ng|c[ảa]nh|b[àa]i\s*t[ậa]p)\s*(kh[áa]c|m[ớo]i)|([đd][ổo]i|thay)\s*(sang\s*)?(c[áa]i\s*)?(t[ìi]nh\s*hu[ốo]ng|c[ảa]nh|b[àa]i\s*t[ậa]p)|(another|different|new)\s*(scene|situation|exercise))/i;

/** Whether a line asks to swap the scene rather than answer it. */
export function asksForAnotherScene(text: string): boolean {
  const said = (text ?? '').trim();
  if (!said || !withinRouteLength(said)) return false;
  // "tình huống cũ" wins: that is a request for a SPECIFIC scene, and a line
  // carrying both words is asking to go back, not to move on.
  if (HUB_REPLAY_PATTERN.test(said)) return false;

  return SCENE_SWAP_PATTERN.test(said);
}

/**
 * May a scene run because the reader ASKED for one, in words?
 *
 * Looser than `eligibleTasks`, deliberately. That list decides what the Coach
 * OFFERS, and it drops T2 once a scene has run so the coordinator stops
 * pushing the same pill; refusing somebody who typed "cho mình tình huống
 * khác" on the same flag answers a request with silence. The run limit still
 * holds — it is what stops a session becoming an endless scene generator.
 */
export function sceneOnRequest(ctx: CoachMachineContext): boolean {
  if ((ctx.tasksRun ?? 0) >= TASK_RUN_LIMIT) return false;

  return Boolean(ctx.hasHabit);
}

/**
 * Will a line typed inside the story conversation actually LEAVE it?
 *
 * Exported because [CoachSessionService] has to ask the same question: it
 * suppresses the model's reply when the line was a request, on the grounds
 * that the task about to start will do the talking. The two conditions were
 * written separately and disagreed — suppression asked "did they ask for a
 * task?", routing asked "did they ask AND may they have one?" — and the gap
 * between them was a turn with no answer at all: reply thrown away, step
 * unchanged, the reader's explicit "luyện tình huống" met with the step's
 * fallback line (owner on-device 2026-09-08, twice in one screen).
 *
 * One predicate so they cannot drift again.
 */
export function storyTalkLeaves(ctx: CoachMachineContext): boolean {
  if (!ctx.hubReplayScene && ctx.hubRoute !== 'T2') return false;

  return sceneOnRequest(ctx);
}

/** Which task a line typed at the coordinator is asking for, if any. */
export function routeHub(text: string): CoachTask | null {
  const said = (text ?? '').trim();
  if (!said || !withinRouteLength(said)) return null;

  for (const [task, pattern] of HUB_ROUTES) {
    if (pattern.test(said)) return task;
  }

  return null;
}

/**
 * The four tasks, by the names the doc gives them — plus the Habit screen's
 * two (luồng 5), which are never in the Home registry: "mục này không đăng ký
 * task mới" for Home, but the sheet opened from a habit needs its own pills.
 */
export type CoachTask = 'T1' | 'T2' | 'T3' | 'T4' | 'checkin' | 'quiz';

/**
 * Task runs one session may spend — T1, T2 and T3 share it.
 *
 * "Trần 3 lượt task… cũng là mức chi phí AI xấu nhất còn dự đoán được: T1 + T3
 * + T2 = 8 lần gọi." T4 sits outside it: it is the session's RESULT, not a way
 * to spend more of somebody's evening.
 */
export const TASK_RUN_LIMIT = 3;

/**
 * Which tasks could run right now, most important first.
 *
 * The doc's registry, in code: each task declares its own condition and its own
 * ceiling, and nothing anywhere writes down an order of steps. Priority is only
 * consulted "khi nhiều task cùng đủ điều kiện và user không chọn gì" — the
 * coordinator shows the first two, and a reader who asks for something else
 * wins over all of it.
 *
 * T4 is absent on purpose: it is never a coordinator suggestion. It is offered
 * exactly once, in the closing sequence, when the session has a real occasion.
 */
export function eligibleTasks(ctx: CoachMachineContext): CoachTask[] {
  // Luồng 5 — the sheet opened from a habit's own screen offers exactly two
  // things about THAT habit: write today, or take its quiz. Neither once done.
  if (ctx.entry === CoachEntry.HABIT) {
    const tasks: CoachTask[] = [];
    if (!ctx.checkinDone) tasks.push('checkin');
    if (ctx.hasQuiz && !ctx.quizDone) tasks.push('quiz');
    // Today is written and no other habit is waiting: the Home tasks join the
    // list rather than replacing it — "đã điểm danh hết rồi thì có thể đưa ra
    // luyện tập tình huống HOẶC làm quiz cùng mình" (owner, 2026-09-04). The
    // pill limit then keeps the sheet to two: the quiz first when there is one,
    // the scene next. The story needs no pill — the box under them says
    // "Hoặc kể luôn chuyện hôm nay của bạn…".
    if (ctx.checkinDone && !ctx.hasNextHabit) {
      if (!ctx.t2Done) tasks.push('T2');
      if (!ctx.t3Done) tasks.push('T3');
    }

    return tasks;
  }

  // The ceiling gates the EXPENSIVE task, not the conversation.
  //
  // It used to return nothing at all here, which took "kể chuyện" away with the
  // scene and left the coordinator empty — so a reader who reopened from Home
  // after a full evening was put back inside a story they had stopped telling
  // with nothing to choose (owner on-device 2026-09-08: "ở nav home thì lại
  // mất chọn luyện cảnh hoặc trò chuyện").
  //
  // Keeping T3 costs nothing the ceiling was protecting: the Home story
  // conversation is ALREADY endless once entered (`afterStoryLine` returns
  // STORY_TALK for ever) and is one call per line. What the ceiling exists for
  // is T2, which writes a scene — several calls, and the thing "T1 + T3 + T2 =
  // 8 lần gọi" was measuring. Asking for a scene past the ceiling now gets a
  // line saying so rather than silence; see COACH_SCENE_NOT_NOW_ENOUGH.
  const spent = (ctx.tasksRun ?? 0) >= TASK_RUN_LIMIT;

  const tasks: CoachTask[] = [];
  // T1 (the reminder check-in) is RETIRED with luồng 4 — a pending commitment
  // no longer puts a pill on the coordinator. `hasPlanPending` is still read
  // by parked sessions walking the old ②A steps.
  // T2 stands before T3 (bug sheet 2026-08-28 16:18): "sau khi hỏi mood →
  // habit → luyện tập tình huống / kể chuyện". With two pills on screen the
  // order decides what a reader is actually offered, and a habit sitting
  // unpractised in the kho is the more specific thing to offer than "kể
  // chuyện" — which they can always reach by simply typing.
  if (!spent && ctx.hasHabit && !ctx.t2Done) tasks.push('T2');
  if (!ctx.t3Done) tasks.push('T3');

  return tasks;
}

/** Which task a step belongs to — the service counts runs with this. */
export function taskOf(step: CoachStep): CoachTask | null {
  switch (step) {
    case CoachStep.INTENT:
    case CoachStep.INTENT_TELL:
    case CoachStep.SHRINK_ASK:
    case CoachStep.SHRINK:
    case CoachStep.CONTEXT_ASK:
    case CoachStep.CONTEXT_EDIT:
    case CoachStep.LOOP:
      return 'T1';
    case CoachStep.SCENE_PICK:
    case CoachStep.SCENE_FIX:
    case CoachStep.SCENE_RETRY:
    case CoachStep.SCENE_FEELING:
    case CoachStep.TELL_ONCE:
    case CoachStep.SCENE_STAGE2:
    case CoachStep.SCENE_MET:
    case CoachStep.SCENE_WHEN:
    case CoachStep.SCENE_DID:
    case CoachStep.SCENE_CHANGE:
    case CoachStep.RETRY_SCENE:
      return 'T2';
    case CoachStep.STORY:
    case CoachStep.DEPTH:
    case CoachStep.STORY_TALK:
    case CoachStep.TELL_2:
    case CoachStep.TWO_COLS:
    case CoachStep.NEXT_ACTION:
      return 'T3';
    case CoachStep.PLAN_ASK:
    case CoachStep.PLAN:
    case CoachStep.SCHEDULE:
      return 'T4';
    case CoachStep.CHECKIN_ASK:
    case CoachStep.CHECKIN_TELL:
    case CoachStep.CHECKIN_OFFER:
      return 'checkin';
    case CoachStep.QUIZ_IN_CHAT:
      return 'quiz';
    default:
      return null;
  }
}

/** The step a task starts on. */
export function firstStepOf(task: CoachTask, ctx: CoachMachineContext): CoachStep {
  switch (task) {
    case 'T1':
      return CoachStep.INTENT;
    case 'T2':
      // Home asks WHICH habit to practise first (luồng 4: "bước đầu tiên
      // không hỏi habit — hỏi việc", and only then the habit). The lesson
      // door already knows its habit and goes straight to the scene and its
      // own action question — the feeling beat was tried for a day and
      // reversed (owner, 2026-08-28 tối).
      return ctx.entry === CoachEntry.LESSON
        ? CoachStep.TELL_ONCE
        : CoachStep.SCENE_PICK;
    case 'T3':
      return CoachStep.STORY;
    case 'checkin':
      return CoachStep.CHECKIN_ASK;
    case 'quiz':
      return CoachStep.QUIZ_IN_CHAT;
    case 'T4':
    default:
      return ctx.t4Offered ? CoachStep.PLAN : CoachStep.PLAN_ASK;
  }
}

/**
 * A task has just finished. Back to the coordinator, or into the closing
 * sequence when nothing is left to offer.
 */
function taskEnd(ended: CoachTask, ctx: CoachMachineContext): CoachStep {
  const after: CoachMachineContext = {
    ...ctx,
    // "T4 ngoài trần 3 lượt" — the result of a session never costs a run.
    tasksRun: (ctx.tasksRun ?? 0) + (ended === 'T4' ? 0 : 1),
    t1Done: ctx.t1Done || ended === 'T1',
    t2Done: ctx.t2Done || ended === 'T2',
    t3Done: ctx.t3Done || ended === 'T3',
  };

  // Luồng 4: a Home session is ONE task. Whatever it was, it ends through
  // the closing — the card when the session earned one, otherwise a line —
  // never back at the coordinator. The lesson door keeps the coordinator
  // until luồng 2 replaces it.
  // Luồng 7 — the habit just added is practised ONCE and the sheet closes:
  // "chọn một, tập một — habit còn lại không xếp hàng chờ và Coach không mời
  // nó ở cuối phiên", and the reader is on their way back to the finished
  // lesson. The coordinator belongs to the doors that host a conversation.
  return closing(after);
}

/**
 * The end of a session, in the doc's three stages: card course → the one offer
 * of a commitment → the tail.
 *
 * The card stands before the commitment because a reader who has just promised
 * something is already reaching for the close, and would wave it away. The last
 * thing they see is still the closing line, which is theirs.
 */
function closing(ctx: CoachMachineContext): CoachStep {
  // "KHÔNG bật: cửa ①" — a course offered straight after a lesson is auto-next.
  // The course RECAP is the one lesson-door flow that does show a card: the
  // course is finished, and "chỉ bậc 3 được hiện card" (luồng 3).
  const cardAllowed =
    ctx.entry !== CoachEntry.LESSON || ctx.talkMode === 'recap';
  if (cardAllowed && ctx.hasCourse && !ctx.cardShown) {
    return CoachStep.COURSE_CARD;
  }

  return afterCard(ctx);
}

/**
 * Card behind us: the commitment, offered once, and only with a real occasion.
 *
 * Exported for one caller: the empty-kho session CLAIMS a card sight-unseen
 * (`ctx.hasCourse`) and resolves the course only on the turn that enters it —
 * when the library then has nothing to offer, the service continues the
 * closing from exactly here, as if the card had never been claimed.
 */
export function afterCard(ctx: CoachMachineContext): CoachStep {
  // The commitment offer is RETIRED (luồng 4, 2026-09-04): none of the six
  // flows asks for a reminder — "KHÔNG nhắc hẹn" on every closing row. The
  // PLAN_ASK/PLAN/SCHEDULE steps stay parked for sessions standing on them.
  return afterCourse(ctx);
}

/**
 * Luồng 1 — the eight questions, in order.
 *
 * Owner 2026-09-05: the barrier is asked BEFORE the goal, swapping questions 2
 * and 3 from the canvas's numbering. Everything downstream reads this array —
 * `onboardPosition` counts the progress strip out of it — so this is the only
 * place the order lives.
 */
export const ONBOARD_ORDER: CoachStep[] = [
  CoachStep.ONBOARD_ADDRESS,
  CoachStep.ONBOARD_BARRIER,
  CoachStep.ONBOARD_GOAL,
  CoachStep.ONBOARD_CURRENT,
  CoachStep.ONBOARD_STYLE,
  CoachStep.ONBOARD_AGE,
  CoachStep.ONBOARD_GENDER,
  CoachStep.ONBOARD_JOB,
];

export function isOnboardStep(step: CoachStep): boolean {
  return (
    step === CoachStep.ONBOARD_INTRO ||
    step === CoachStep.ONBOARD_ADDRESS_CONFIRM ||
    ONBOARD_ORDER.includes(step)
  );
}

/**
 * Whether one onboarding question is asked at all: the four main ones always,
 * the address only in Vietnamese ("locale khác vi thì bỏ hẳn bước này"), the
 * four optional ones by the admin's toggles.
 */
export function onboardAsks(step: CoachStep, ctx: CoachMachineContext): boolean {
  const ask = ctx.onboardAsk;
  switch (step) {
    case CoachStep.ONBOARD_ADDRESS:
      return ctx.viLocale !== false;
    case CoachStep.ONBOARD_STYLE:
      return ask?.style !== false;
    case CoachStep.ONBOARD_AGE:
      return ask?.age !== false;
    case CoachStep.ONBOARD_GENDER:
      return ask?.gender !== false;
    case CoachStep.ONBOARD_JOB:
      return ask?.job !== false;
    default:
      return true;
  }
}

/** The 1-based number of a question among those actually asked — the progress strip. */
export function onboardPosition(step: CoachStep, ctx: CoachMachineContext): { step: number; total: number } {
  const asked = ONBOARD_ORDER.filter((s) => onboardAsks(s, ctx));

  return { step: Math.max(1, asked.indexOf(step) + 1), total: asked.length };
}

/**
 * Where the onboarding goes when it ends — finished or skipped: the day's mood
 * (once a day), else the coordinator. "Xong bước này … → sang MOOD."
 */
function afterOnboarding(_ctx: CoachMachineContext): CoachStep {
  // Owner 2026-09-05: BỎ HẲN hỏi mood. Onboarding xong đi thẳng vào bộ điều
  // phối. `CoachStep.MOOD` giữ trong enum để phiên đang treo ở đó còn thoát ra
  // được, nhưng không đường nào dẫn vào nữa.
  return CoachStep.HUB;
}

/** The next question still to ask after `step`, or the way out of the onboarding. */
/** "← Câu trước": the question asked before this one — the address at the floor. */
export function onboardStepBefore(step: CoachStep, ctx: CoachMachineContext): CoachStep {
  const index = ONBOARD_ORDER.indexOf(step);
  for (let i = index - 1; i >= 0; i--) {
    if (onboardAsks(ONBOARD_ORDER[i], ctx)) return ONBOARD_ORDER[i];
  }

  return CoachStep.ONBOARD_ADDRESS;
}

export function onboardStepAfter(step: CoachStep, ctx: CoachMachineContext): CoachStep {
  const index = step === CoachStep.ONBOARD_INTRO ? -1 : ONBOARD_ORDER.indexOf(step);
  for (let i = index + 1; i < ONBOARD_ORDER.length; i++) {
    if (onboardAsks(ONBOARD_ORDER[i], ctx)) return ONBOARD_ORDER[i];
  }

  return afterOnboarding(ctx);
}

/**
 * The first step of a session, once the door's guards have already passed.
 *
 * ② asks the day's mood at most once a day; ① never asks it — "Cửa ① bỏ qua
 * bước này".
 */
export function resolveOpeningStep(ctx: CoachMachineContext): CoachStep {
  // Luồng 2/3 — the lesson door redrawn: after a keypoint the talk, after the
  // last keypoint the recap. Neither asks the mood; neither is a task.
  if (ctx.entry === CoachEntry.LESSON && ctx.talkMode === 'talk') {
    return CoachStep.TALK_ASK;
  }
  if (ctx.entry === CoachEntry.LESSON && ctx.talkMode === 'recap') {
    return CoachStep.RECAP_PICK;
  }
  // Luồng 1 — the first Home session ever opens on the onboarding, before
  // the mood: "chạy đúng một lần đời user, trước MOOD của phiên đầu tiên.
  // Không đi qua eligibleTasks(), không tốn lượt".
  if (ctx.entry === CoachEntry.HOME && ctx.onboarding) {
    return CoachStep.ONBOARD_INTRO;
  }
  if (ctx.entry === CoachEntry.LESSON) {
    // "◇ Mấy habit mới? — ⟨Phương án⟩ khi có ≥2 · user chọn 1, không bỏ qua
    // được." One habit needs no question, and the doc says so.
    return (ctx.newHabitCount ?? 0) >= 2 ? CoachStep.PICK_NEW : afterMood(ctx);
  }
  // Luồng 5 — "không hỏi mood ở cửa này": the reader opened the sheet to
  // write one habit, and a feeling step first only slows the thing they came for.
  if (ctx.entry === CoachEntry.HABIT) return afterMood(ctx);

  // Owner 2026-09-05: cửa Home cũng không hỏi mood nữa — mở là vào việc.
  return afterMood(ctx);
}

/**
 * Luồng 5 — after a habit was written (or its quiz finished): the NEXT habit
 * still unwritten today is offered, never jumped to — "user luôn thấy rõ mình
 * đang ghi cho habit nào". Nothing left → the sheet closes on one line.
 */
/**
 * Where a scored scene goes: the card when the move was made, the retry offer
 * the first time it was not, a quiet close the second time. One place, so the
 * first try and the retry cannot drift apart.
 */
function sceneVerdict(ctx: CoachMachineContext): CoachStep {
  if (ctx.sceneOnTrack) return taskEnd('T2', ctx);

  return ctx.sceneRetried ? homeTail(ctx) : CoachStep.SCENE_FIX;
}

function afterCheckinWrite(ctx: CoachMachineContext): CoachStep {
  if (ctx.hasNextHabit) return CoachStep.CHECKIN_OFFER;

  // Nothing left to write: the coordinator offers the story and the scene
  // rather than closing the sheet on the reader.
  return eligibleTasks({ ...ctx, checkinDone: true }).length
    ? CoachStep.HUB
    : CoachStep.END;
}

/**
 * Which task the door opens on — and that is ALL a door decides.
 *
 * "Cổng vào không phải một loại thứ khác. Nó là điều kiện xét lúc mở bong bóng,
 * và hệ quả duy nhất của nó là chọn task đầu tiên — một lối tắt, không phải một
 * luồng riêng." Everything after the first task comes from the registry and the
 * coordinator, identically at every door.
 */
export function afterMood(ctx: CoachMachineContext): CoachStep {
  switch (ctx.entry) {
    case CoachEntry.LESSON:
      // ① — the scene, about the habit just added.
      return firstStepOf('T2', ctx);

    case CoachEntry.HOME:
    case CoachEntry.HABIT:
    default:
      // ②A (the check-in door) and ④ (the old scene) are RETIRED with luồng 4:
      // Home asks "Hôm nay bạn muốn làm gì?" and nothing else picks the first
      // task. `tier` is still stored, so a parked session can be read.

      // ②B and ②C open on the COORDINATOR, not on the story (bug sheet
      // 2026-08-28 16:18): "có nhắc hẹn → nói về nhắc hẹn · kho habit có habit
      // chưa luyện tập → chọn 1 habit để bắt đầu · không có cả 2 → hỏi bạn
      // muốn làm gì, gợi ý Kể chuyện / Luyện tập tình huống". Opening straight
      // into "hôm nay có chuyện gì mới không?" made the story the only door
      // and left the practice to be guessed at. Typing still lands on nhịp 1
      // — `advance(HUB, text)` routes an unrouted line into the story task —
      // so "kể trước, xếp sau" survives for anybody who just starts talking.
      return CoachStep.HUB;
  }
}

/**
 * After one check-in branch has converged: another pending commitment?
 *
 * Bounded by `MAX_INTENT_ROUNDS` as well as by the queue, and the queue was
 * already filtered at open (a plan asked yesterday sits this round out). The
 * LOOP step's two buttons are equal.
 */
function afterCheckin(ctx: CoachMachineContext): CoachStep {
  const limit = Math.min(MAX_INTENT_ROUNDS, ctx.planQueueLength);
  if (ctx.planIndex + 1 < limit) return CoachStep.LOOP;

  return taskEnd('T1', ctx);
}

/**
 * After the commitment was made (or the schedule set): ① closes on its fixed
 * line, ② runs the tail — "Card course … đứng TRƯỚC mood cuối phiên. Sau bài
 * học thì không gợi."
 */
function afterPlanStage(ctx: CoachMachineContext): CoachStep {
  // The commitment is stored. If the reader asked for T4 mid-session there may
  // be more they want to do; in the closing sequence the card is already behind
  // us and the tail is next.
  if (ctx.closing) return afterCourse(ctx);

  return taskEnd('T4', ctx);
}

/**
 * Replies the story conversation may run before T3 closes itself.
 *
 * Three, so the task's worst case is the bill it always was (see
 * `STORY_TALK_ROUNDS`). A low day — and the late-night rule that lives inside
 * it — gets two: "không đào sâu khi người ta đang mệt" outlived nhịp 2.
 */
export function storyTalkCap(ctx: CoachMachineContext): number {
  return ctx.moodLow || ctx.lateNightLow
    ? STORY_TALK_ROUNDS_LOW
    : STORY_TALK_ROUNDS;
}

/**
 * The owner's table of 2026-09-04, as arrows: where one line of the story
 * conversation sends the session, by what KIND of line it was.
 *
 * Three of the nine rows are arrows; the rest keep talking. "Chủ động hỏi cách
 * cải thiện" opens the course card NOW when the session has one to show — the
 * same three guards the closing sequence uses — and otherwise hands over to the
 * coordinator, where a habit already in the kho puts the practice pill first.
 * "Không muốn tiếp tục" goes straight to the tail: no card, no commitment
 * offer, nothing recommended to somebody who just said enough. Mood-end and the
 * rating still run — they are the sheet's, asked once, and not a pitch.
 *
 * Everything else counts a round, and the round that reaches the cap ends the
 * task the way any task ends: through `taskEnd`, so the run is spent and the
 * coordinator (or the closing sequence) decides what is next. The same arrows
 * answer the depth question's own text — "làm sao để cải thiện?" typed there
 * is the same request.
 */
function afterStoryLine(ctx: CoachMachineContext): CoachStep {
  // Owner (2026-09-04, on the simulator): at Home the story conversation has
  // NO end of its own — no round cap, no closing line, no ⟨Đóng · về chỗ vừa
  // rời đi⟩. It goes on until the reader closes the sheet. A stop is answered
  // with one soft line and the box stays open; a request for how to improve
  // opens the course card when there is one and otherwise just keeps talking.
  const home = ctx.entry === CoachEntry.HOME;

  switch (ctx.storyKind) {
    case CoachStoryKind.STOP:
      return home ? CoachStep.STORY_TALK : afterCourse(ctx);

    case CoachStoryKind.WANTS_IMPROVE:
      if (!home) return CoachStep.STORY_TALK;
    // falls through — at Home "nhận ra muốn cải thiện" may open the card too
    case CoachStoryKind.ASKS_HOW:
      if (
        ctx.entry !== CoachEntry.LESSON &&
        ctx.hasCourse &&
        !ctx.cardShown
      ) {
        return CoachStep.COURSE_CARD;
      }

      return home ? CoachStep.STORY_TALK : taskEnd('T3', ctx);

    default: {
      if (home) return CoachStep.STORY_TALK;
      const spent = (ctx.storyTalkRounds ?? 0) + 1;

      return spent >= storyTalkCap(ctx) ? taskEnd('T3', ctx) : CoachStep.STORY_TALK;
    }
  }
}

/**
 * "Chỉ ghi lại thôi" — T4. The sentence they already wrote is filed, the Coach
 * says one fixed line ON THE WAY (a note, not a step: "ra ở đâu — THẲNG tới
 * Muốn đặt Nhắc hẹn không?"), and the scene is skipped on purpose: "người vừa
 * nói hôm nay đừng đào sâu mà bước ngay sau lại mời tập một cảnh là mâu thuẫn".
 */
function jotted(ctx: CoachMachineContext): CoachStep {
  return taskEnd('T3', ctx);
}

/**
 * The tail: mood-end once per sheet-open, then the rating, then the closing
 * line. ① has neither mood nor rating — "cửa ① không hỏi mood, cả đầu ngày lẫn
 * cuối phiên" — so it closes on its own fixed line.
 */
function afterCourse(ctx: CoachMachineContext): CoachStep {
  // Only the course recap (luồng 3) has the full tail — COURSE_CARD → MOOD_END
  // → RATING → END: "chỉ bậc 3 có đuôi phiên đầy đủ". Everywhere else the
  // session simply ends: "xong một keypoint chưa phải mốc để hỏi cảm giác".
  if (ctx.talkMode === 'recap') {
    // Mood cuối phiên bỏ cùng lượt với mood đầu ngày (owner 2026-09-05): đuôi
    // bậc 3 giờ là COURSE_CARD → RATING → END.
    return afterMoodEnd(ctx);
  }

  return homeTail(ctx);
}

/**
 * Where a Home session goes when a task is over: back to the open box. The
 * sheet never closes itself at Home (owner, 2026-09-04) — every other door
 * still ends.
 */
function homeTail(ctx: CoachMachineContext): CoachStep {
  // The Habit door behaves like Home once its own two things are done: the
  // conversation carries on until the reader closes the sheet.
  return ctx.entry === CoachEntry.HOME || ctx.entry === CoachEntry.HABIT
    ? CoachStep.STORY_TALK
    : CoachStep.END;
}

/**
 * Where a session goes once the mood is in.
 *
 * It used to detour through `CoachStep.RATING` — the 👍/👎 toast — which was
 * removed on 2026-09-14: the one question left is asked on the way OUT, by the
 * sheet after ⟨Vẫn đóng⟩, at a frequency admin controls. Nothing routes to
 * RATING any more, and the step survives only so sessions written before that
 * date still replay.
 */
function afterMoodEnd(ctx: CoachMachineContext): CoachStep {
  return ctx.talkMode === 'recap' ? CoachStep.END : CoachStep.NEXT_SESSION;
}

/**
 * The whole graph.
 *
 * Every arrow the design draws, and no others. An event that does not belong
 * to the current step returns `null` rather than guessing, so a client that
 * falls out of sync gets a clean rejection instead of skipping a step.
 */
export function advance(
  step: CoachStep,
  event: CoachEvent,
  ctx: CoachMachineContext,
): CoachStep | null {
  // Before anything reads WHICH step this is: a line that asks us something is
  // not an answer to the question the step asked. Holding here rather than in
  // eight branches is the point — the guard cannot be forgotten when a step is
  // added, and the step re-asks itself while the turn's reply answers them.
  // A scene is finished, not abandoned — EXCEPT when they say so in words.
  // Handled here rather than in each scene step for the same reason as the
  // guard below: a scene step added later must not quietly lose it. TELL_ONCE
  // with the scene state cleared is what writes a fresh one, the same way
  // changing habit mid-practice already restarts it.
  if (event.kind === 'text' && ctx.sceneSwapAsked && isInScene(step)) {
    // Refused by the ceiling: HOLD the step rather than advance. The line was a
    // request, so scoring it as the scene's answer is the exact failure this
    // guard exists to stop — the turn's reply says why instead.
    return sceneOnRequest(ctx) ? CoachStep.TELL_ONCE : step;
  }

  if (
    event.kind === 'text' &&
    ctx.readerAsksBack &&
    HOLDS_ON_QUESTION.has(step)
  ) {
    return step;
  }

  switch (step) {
    case CoachStep.MOOD:
      return event.kind === 'mood' ? afterMood(ctx) : null;

    case CoachStep.PICK_NEW:
      // ① with ≥2 habits just added — the chosen habit's scene, feeling first.
      return event.kind === 'pickNew' ? firstStepOf('T2', ctx) : null;

    // ---------------------------------------------------------- ②A check-in

    case CoachStep.INTENT:
      if (event.kind !== 'intent') return null;
      switch (event.answer) {
        case CoachPlanAnswer.DONE:
        case CoachPlanAnswer.MISSED:
          // Both ask one sentence back — "lúc đó bạn nói hay làm gì?" · "điều
          // gì làm bạn dừng lại?". Only DONE's answer becomes evidence.
          return CoachStep.INTENT_TELL;
        case CoachPlanAnswer.NONE:
        default:
          // "Vậy là bối cảnh chưa xuất hiện, không phải bạn tránh." The Coach
          // does NOT ask why — "hỏi sẽ thành ép" — it asks about the CONTEXT:
          // "bối cảnh 'khi họp nhóm' có hay xảy ra không?" A plan that has just
          // gone to sleep is not asked about at all; its line says so and the
          // session moves on.
          return ctx.planSlept ? afterCheckin(ctx) : CoachStep.CONTEXT_ASK;
      }

    case CoachStep.INTENT_TELL:
      if (event.kind !== 'text') return null;

      // "Có dịp mà chưa làm" → the sentence is filed, and the plan is offered
      // smaller. Law 5: "nhắc hẹn mới luôn nhỏ hơn" — as a question, never
      // done for them.
      return ctx.intentMissed ? CoachStep.SHRINK_ASK : afterCheckin(ctx);

    case CoachStep.SHRINK_ASK:
      if (event.kind !== 'shrink') return null;

      return event.accept ? CoachStep.SHRINK : afterCheckin(ctx);

    case CoachStep.SHRINK:
      // The PLAN form, pre-filled with the old wording; saving REPLACES the
      // old commitment. A parked pre-v2 session still answers with `shrink`.
      return event.kind === 'plan' || event.kind === 'shrink'
        ? afterCheckin(ctx)
        : null;

    case CoachStep.LOOP:
      if (event.kind !== 'loop') return null;

      // "Sau nhắc hẹn thứ nhất, nút đi tiếp phải ngang hàng với nút dừng."
      // Stopping ends T1; where the session goes next is the coordinator's.
      return event.keepGoing ? CoachStep.INTENT : taskEnd('T1', ctx);

    // ------------------------------------------------ the 5-beat script

    case CoachStep.STORY:
      // The pill `Chỉ ghi lại thôi`, pressed on the opener itself — a
      // SUGGESTION, not a branch button. Pressed, it means "file it and move
      // on"; not pressing it leaves the flow running and the depth question
      // below decides.
      if (event.kind === 'ack') return jotted(ctx);

      // ②C — no five beats and no scene. The story is heard, matched against
      // the catalogue, and the session turns on ONE fact: is that habit theirs?
      // "Bỏ qua, không nói gì" — a DECLINE, and "Coach không mời lại": the
      // pill goes away for the session, or tapping Kể chuyện → skipping →
      // being offered Kể chuyện again is a carousel (seen on the simulator,
      // 2026-08-27). But nothing RAN either — "một lượt = một lần user nói +
      // Coach đáp" — so it costs none of the three runs.
      if (event.kind === 'skip') {
        const declined = { ...ctx, t3Done: true };

        return eligibleTasks(declined).length ? CoachStep.HUB : closing(declined);
      }

      if (event.kind !== 'text') return null;

      // Nhịp 1 landed. At Home the conversation answers it directly (luồng 4:
      // "không cảnh, không chấm — chỉ nghe và hỏi lại"). The lesson door still
      // asks the READER's choice of depth first, until luồng 2 replaces it.
      return ctx.entry === CoachEntry.LESSON
        ? CoachStep.DEPTH
        : CoachStep.STORY_TALK;

    // The story conversation (owner, 2026-09-04): one step that repeats, each
    // line routed by its kind. "Chỉ ghi lại thôi" stays reachable inside it —
    // "hai pill ở lại suốt phiên… bấm nút bất cứ lúc nào cũng thắng phán đoán
    // của Coach".
    case CoachStep.STORY_TALK:
      if (event.kind === 'ack') return jotted(ctx);
      // Owner 2026-09-05: they typed "luyện tình huống khác" mid-story and got
      // a story reply, because `routeHub` only ever ran at HUB — so once the
      // conversation had started there was NO way to ask for a scene in words,
      // only by a pill that may not be on screen. An explicit ask is not a
      // story about their day.
      // Same reasoning as the route below, for the scene they already did.
      if (event.kind === 'text' && storyTalkLeaves(ctx)) {
        // The scene they already did wins over a fresh one: asking for "cảnh
        // cũ" is the more specific request of the two.
        return ctx.hubReplayScene
          ? CoachStep.TELL_ONCE
          : firstStepOf('T2', ctx);
      }

      return event.kind === 'text' ? afterStoryLine(ctx) : null;

    // PARKED (2026-09-04, "bỏ 2 cột kéo kéo"): nhịp 2, the two-column draft
    // and "bạn sẽ làm gì" are no longer entered. Sessions standing on them
    // still walk the old arrows out.
    case CoachStep.TELL_2:
      if (event.kind === 'ack') return jotted(ctx);

      return event.kind === 'text' ? CoachStep.TWO_COLS : null;

    case CoachStep.TWO_COLS:
      // ⑤ — the draft was wrong as a whole. Once only.
      if (event.kind === 'rejectDraft') {
        return ctx.draftRejected ? null : CoachStep.TELL_2;
      }

      return event.kind === 'text' ? CoachStep.NEXT_ACTION : null;

    // PARKED with the beats above — "bạn sẽ làm gì?" still ends the task.
    case CoachStep.NEXT_ACTION:
      return event.kind === 'text' ? taskEnd('T3', ctx) : null;

    // ------------------------------------------------------ nhịp 4 · scene

    // RETIRED with the doc of 2026-08-27 (v3): ② has no scene, and ① runs its
    // scene without asking first. Kept so a session parked here walks out.
    case CoachStep.INVITE:
      if (event.kind !== 'invite') return null;
      if (event.accept && ctx.hasScene) return CoachStep.TELL_ONCE;

      return ctx.storyTold ? CoachStep.PLAN_ASK : CoachStep.END;

    // RETIRED the same day it shipped (owner, 2026-08-28 tối): the feeling
    // lead-in is gone — scenes ask their action question directly. A session
    // parked here still walks out into the question.
    case CoachStep.SCENE_FEELING:
      return event.kind === 'text' ? CoachStep.TELL_ONCE : null;

    // The scene, six beats: chặng 1 → answer → a-b-c → chặng 2 (WRITTEN, the
    // other person reacting) → answer → one specific piece of praise → "chuyện
    // giống vậy bạn gặp bao giờ chưa?".
    //
    // Nhịp 4 deliberately does NOT ask them to say it again: part c has just
    // said "không phải tốt hơn, chỉ là khác", and "thử nói lại xem" right after
    // that reads as "now do it properly" — it breaks the one guard the reply is
    // built around. A scene with no second stage jumps to nhịp 6.
    case CoachStep.TELL_ONCE:
      if (event.kind !== 'text') return null;

      // Luồng 4, reactive branching (owner, 2026-09-04): the first line is NOT
      // scored. The other person in the scene answers it — annoyed, half-
      // hearing, asking them to say the thing plainly — and only the reader's
      // SECOND line closes the beat: "user cảm được hậu quả của câu đầu tiên
      // trước khi bị chấm". A provider failure leaves the flag false and
      // the beat scores on one line rather than stranding the scene.
      return ctx.sceneAwaitingSecondLine ? CoachStep.SCENE_STAGE2 : sceneVerdict(ctx);

    // Luồng 4 — "Bạn muốn tập cái nào trong kho của bạn?". A chip, or a name
    // typed and matched by the service; a name that matches nothing asks
    // again rather than guessing.
    case CoachStep.SCENE_PICK:
      if (event.kind === 'pickNew') return CoachStep.TELL_ONCE;
      // Giữ cho app CŨ: bản tới 2026-09-04 có một chip ⟨Xáo trộn⟩ gửi `pick`
      // lên đây. Server không còn phát chip đó nữa (việc đổi ba habit khác đã
      // về client, đổi tại chỗ), nhưng bản đã cài vẫn gửi — nhận và đứng yên
      // ở bước này thì vô hại, còn trả null là 400 trên máy người ta.
      if (event.kind === 'pick') return CoachStep.SCENE_PICK;
      if (event.kind === 'text') {
        return ctx.pickedHabit ? CoachStep.TELL_ONCE : CoachStep.SCENE_PICK;
      }

      return null;

    // Luồng 4 — after an off-track answer: ⟨Luyện lại cảnh này⟩ · ⟨Để sau⟩.
    // The same scene, verbatim, at most twice ("trần hai lần; hết trần Coach
    // đóng bằng một câu ngắn, không đếm số lần sai"). The wrong branch never
    // shows a course — "chưa làm được thì gợi học thêm là đổi chủ đề".
    case CoachStep.SCENE_FIX:
      if (event.kind !== 'sceneAgain') return null;
      if (!event.again || ctx.sceneRetried) return homeTail(ctx);

      return CoachStep.SCENE_RETRY;

    // Luồng 4 — the second and last try, on a DIFFERENT scene about the same
    // habit ("đưa tình huống tương tự, không lặp lại y nguyên" — owner,
    // 2026-09-04). Same two beats as the first try.
    case CoachStep.SCENE_RETRY:
      if (event.kind !== 'text') return null;

      return ctx.sceneAwaitingSecondLine ? CoachStep.SCENE_STAGE2 : sceneVerdict(ctx);

    // The reader's answer to that push-back. The scene is scored HERE, on both
    // of their lines together — never on the last one alone.
    case CoachStep.SCENE_STAGE2:
      if (event.kind !== 'text') return null;

      // Same shape as TELL_ONCE, and for the same reason: the SERVICE decides
      // whether this answer gets another reaction or the verdict (it is the one
      // that knows how many answers the scene has spent), and says so by
      // leaving the flag set. A provider failure clears it and the scene is
      // scored on what it has rather than looping on a reaction that never came.
      return ctx.sceneAwaitingSecondLine
        ? CoachStep.SCENE_STAGE2
        : sceneVerdict(ctx);

    // 6a — the invented scene gave them an ACTION; only their own life can
    // give the occasion a commitment needs. "Ngoài đời bạn gặp chuyện kiểu này
    // chưa?" · Rồi / Chưa.
    case CoachStep.SCENE_MET:
      // Mẫu #10 — "Rồi" typed WITH the telling: 6b is already answered, so the
      // mirror is earned and the flow goes straight to 6d.
      if (event.kind === 'text') return CoachStep.SCENE_CHANGE;
      if (event.kind !== 'sceneMet') return null;
      if (event.met) return CoachStep.SCENE_DID;

      // "Chưa → thẳng sang T3, không chạy 6b–6d, vẫn tính một lượt task" (the
      // service's bookkeeping counts any T2→T3 transition). Nothing is said
      // about having just missed. T3 already run → the coordinator as usual.
      return ctx.t3Done ? taskEnd('T2', ctx) : CoachStep.STORY;

    // 6b — "Hôm đó bạn làm gì?": the real occurrence. A dead answer (nothing
    // worth keeping, or a question back) skips 6d — the reply still answers a
    // question, but no dip is made and T4 is not invited (mẫu #7, #13).
    case CoachStep.SCENE_DID:
      if (event.kind !== 'text') return null;

      return ctx.sceneDidDead ? taskEnd('T2', ctx) : CoachStep.SCENE_CHANGE;

    // 6d — "Lần sau gặp lại, bạn muốn làm khác đi không?". Either answer makes
    // the dip, and the scene hands over STRAIGHT to the commitment.
    //
    // It used to end into the coordinator, which asked "Xong rồi. Còn gì bạn
    // muốn nói không?" and offered pills — and a first-time reader who does not
    // yet know what Nhắc hẹn is simply never pressed it (bug sheet 2026-08-28
    // 16:18: "trực tiếp điều hướng sang T4 luôn"). The occasion was just
    // collected in their own words; the commitment is what it is FOR.
    case CoachStep.SCENE_CHANGE:
      if (event.kind !== 'text') return null;

      return ctx.t4Offered ? taskEnd('T2', ctx) : CoachStep.PLAN_ASK;

    // RETIRED (nhịp 6 mở rộng): "Lúc đó là lúc nào?". Parked sessions walk out.
    case CoachStep.SCENE_WHEN:
      return event.kind === 'text' ? taskEnd('T2', ctx) : null;

    // RETIRED with nhịp 4 (doc v4). A parked session still walks out.
    case CoachStep.SCENE_AGAIN:
      if (event.kind !== 'sceneAgain') return null;

      return event.again ? CoachStep.TELL_ONCE : CoachStep.SCENE_MET;

    // RETIRED with the rubric (same doc: "Cấm chấm điểm, kể cả Chính xác!").
    // The case stays so a session parked on the card can still walk out of it.
    case CoachStep.SCENE_SCORE:
      return event.kind === 'sceneScore' ? CoachStep.PLAN_ASK : null;

    case CoachStep.RETRY_SCENE:
      // ④ — the second answer to the same scene; the recap does the rest.
      return event.kind === 'text' ? CoachStep.PLAN_ASK : null;

    // ------------------------------------------- luồng 5 · the Habit screen

    // "Hôm nay bạn có làm được nó không? Kể mình một câu là đủ." Both answers
    // WRITE a check-in: ⟨Có⟩ after one sentence about the occasion (done:true),
    // ⟨Chưa⟩ at once (done:false — "không bỏ trống ngày").
    case CoachStep.CHECKIN_ASK:
      if (event.kind !== 'checkin') return null;

      return event.done ? CoachStep.CHECKIN_TELL : afterCheckinWrite(ctx);

    // The one sentence, then the write. "Không chấm câu kể, không góp ý —
    // bước này là ghi nhận, không phải luyện tập."
    case CoachStep.CHECKIN_TELL:
      return event.kind === 'text' ? afterCheckinWrite(ctx) : null;

    // "Trong kho còn «Y» chưa ghi hôm nay — làm luôn nhé?" ⟨Ghi nhận habit đó⟩
    // · ⟨Để sau⟩. Yes → the same question, about the next habit; the service
    // has already moved `habitId`. "Không nài habit vừa rồi thêm một câu nào."
    case CoachStep.CHECKIN_OFFER:
      if (event.kind !== 'invite') return null;

      return event.accept ? CoachStep.CHECKIN_ASK : CoachStep.END;

    // The habit's quiz, one question per turn, options as chips. The last
    // answer files the attempt (EXERCISE) and goes on to the offer like a
    // check-in does — "QUIZ_IN_CHAT hết 3 câu → EXERCISE, done: true → cũng
    // vào CHECKIN_OFFER".
    case CoachStep.QUIZ_IN_CHAT:
      if (event.kind !== 'quizAnswer') return null;
      if ((ctx.quizRemaining ?? 0) > 1) return CoachStep.QUIZ_IN_CHAT;

      // Luồng 3 — the recap's random questions are read in the chat too; the
      // last answer hands over to the card and the full tail.
      return ctx.talkMode === 'recap' ? closing(ctx) : afterCheckinWrite(ctx);

    // ------------------------------------------ luồng 1 · Onboarding Coach

    // Two written lines, ⟨Bắt đầu⟩, and "Bỏ qua phần giới thiệu →". Typing
    // here is a question to the Coach — answered, and the questions begin.
    case CoachStep.ONBOARD_INTRO:
      if (event.kind === 'pick' && ctx.pick === 'skip') return afterOnboarding(ctx);
      if (event.kind === 'pick' || event.kind === 'text') {
        return onboardStepAfter(CoachStep.ONBOARD_INTRO, ctx);
      }

      return null;

    // "Mình gọi bạn thế nào cho thuận?" — the one question that cannot be
    // skipped: every fixed line after it has to know. A pronoun chip or a
    // typed pronoun moves on; a typed NAME is confirmed first.
    case CoachStep.ONBOARD_ADDRESS:
      if (event.kind === 'pick') {
        return ctx.pick === 'skip' ? null : onboardStepAfter(step, ctx);
      }
      if (event.kind === 'text') {
        return ctx.onboardNamed ? CoachStep.ONBOARD_ADDRESS_CONFIRM : onboardStepAfter(step, ctx);
      }

      return null;

    case CoachStep.ONBOARD_ADDRESS_CONFIRM:
      if (event.kind !== 'pick') return null;
      if (ctx.pick === 'yes') return onboardStepAfter(CoachStep.ONBOARD_ADDRESS, ctx);
      if (ctx.pick === 'no') return CoachStep.ONBOARD_ADDRESS;

      return null;

    // The seven others: a chip or their own words moves on; "Bỏ qua" ends the
    // onboarding here and now — what was answered is kept.
    case CoachStep.ONBOARD_GOAL:
    case CoachStep.ONBOARD_BARRIER:
    case CoachStep.ONBOARD_CURRENT:
    case CoachStep.ONBOARD_STYLE:
    case CoachStep.ONBOARD_AGE:
    case CoachStep.ONBOARD_GENDER:
    case CoachStep.ONBOARD_JOB:
      if (event.kind === 'pick' && ctx.pick === 'skip') return afterOnboarding(ctx);
      // "Trả lời nhầm thì trả lời lại được" — one question back; the answer
      // already given stays until a new one overwrites it.
      if (event.kind === 'pick' && ctx.pick === 'back') return onboardStepBefore(step, ctx);
      if (event.kind === 'pick' || event.kind === 'text') return onboardStepAfter(step, ctx);

      return null;

    // ------------------------------------- luồng 2 · the talk after a keypoint

    // "Nói một chút về phần vừa học nhé? Bắt đầu kiểu nào?" ⟨Tóm tắt⟩ ⟨Làm
    // quiz⟩ — or they type what they remember, which is its own answer and
    // goes straight to the quiz hand-off with the ≤25-word reply.
    case CoachStep.TALK_ASK:
      if (event.kind === 'pick') {
        if (ctx.pick === 'summary') return CoachStep.TALK_SUMMARY;
        if (ctx.pick === 'talkQuiz') return CoachStep.QUIZ_HANDOFF;

        return null;
      }

      return event.kind === 'text' ? CoachStep.QUIZ_HANDOFF : null;

    // The summary ended in one question; their answer earns the reply that
    // grades what they recalled.
    //
    // Owner 2026-09-04: sau lượt chấm phần nhớ được thì ĐÓNG và sang keypoint
    // kế tiếp, không mời quiz nữa. Owner 2026-09-05 reopened the far end of
    // that: the grading is where questions START, so instead of ending, the
    // talk stays open for a few of them (TALK_FREE). The quiz is untouched —
    // still the second chip at TALK_ASK, a choice of its own.
    case CoachStep.TALK_SUMMARY:
      if (event.kind !== 'text') return null;

      // A budget of 0 closes the floor before it opens — the grading turn is
      // the last thing said, which is the behaviour this branch had before
      // 2026-09-05 and what an admin gets by setting the ceiling to 0.
      return ctx.talkFreeExhausted ? CoachStep.END : CoachStep.TALK_FREE;

    // The floor is open. Each question is answered and costs one turn; the
    // budget is spent in the service (it owns the session), so by the time a
    // transition is asked for, `ctx.talkFreeExhausted` already says whether
    // this was the last one.
    case CoachStep.TALK_FREE:
      if (event.kind !== 'text') return null;

      return ctx.talkFreeExhausted ? CoachStep.END : CoachStep.TALK_FREE;

    // "Vài câu về phần này nhé." ⟨Bắt đầu⟩ → the quiz on its own screen;
    // ⟨Thôi, để sau⟩ → straight to the closing question.
    case CoachStep.QUIZ_HANDOFF:
      if (event.kind !== 'pick') return null;
      if (ctx.pick === 'start') return CoachStep.QUIZ_RUN;
      if (ctx.pick === 'later') return CoachStep.TALK_WHEN;

      return null;

    // The quiz is running elsewhere; it comes back with its results (or
    // without, if they left it) and the Coach speaks about the content.
    case CoachStep.QUIZ_RUN:
      return event.kind === 'quizDone' ? CoachStep.TALK_WHEN : null;

    // "Học tiếp phần sau chứ?" — both answers end the session; the app takes
    // ⟨Học tiếp⟩ to the next keypoint. No card, no mood, no rating, no
    // reminder: "xong một keypoint chưa phải mốc để hỏi cảm giác".
    case CoachStep.TALK_WHEN:
      if (event.kind !== 'pick') return null;

      return ctx.pick === 'continue' || ctx.pick === 'later'
        ? CoachStep.END
        : null;

    // ------------------------------------------- luồng 3 · the course recap

    // "Bài nào ở lại với bạn lâu nhất?" — a lesson picked; the reply is one
    // line about the choice, and the quiz offer follows in the same breath.
    case CoachStep.RECAP_PICK:
      return event.kind === 'pick' && ctx.pick ? CoachStep.RECAP_QUIZ : null;

    // "Làm vài câu random từ cả khoá xem còn nhớ gì nhé?" ⟨Làm thử⟩ → the
    // in-chat quiz over the whole course · ⟨Để sau⟩ → the card and the tail.
    case CoachStep.RECAP_QUIZ:
      if (event.kind !== 'pick') return null;
      if (ctx.pick === 'try') return CoachStep.QUIZ_IN_CHAT;
      if (ctx.pick === 'later') return closing(ctx);

      return null;

    // ------------------------------------------------------ bộ điều phối

    // One Coach line and up to two task suggestions. Typing wins over both:
    // "user gõ tự do → classifier định tuyến", and the service hands the
    // routed task back as a `task` event.
    case CoachStep.HUB:
      if (event.kind === 'stop') return closing(ctx);
      if (event.kind === 'task') {
        // A task the registry no longer allows is refused rather than started —
        // "task đã chạm trần biến mất khỏi gợi ý". T4 is never in the registry
        // now, so an old client's "Đặt Nhắc hẹn" pill is refused too.
        return eligibleTasks(ctx).includes(event.task)
          ? firstStepOf(event.task, ctx)
          : null;
      }

      if (event.kind === 'text') {
        const open = eligibleTasks(ctx);
        // Asking for the scene they were already in is answered with THAT
        // scene, by id — checked before the ordinary practice route, which
        // would hand back a different one and read as the Coach forgetting.
        //
        // TELL_ONCE, not RETRY_SCENE. RETRY_SCENE looks like the right step and
        // is not: it exists for ④, whose only job is to accrue a second answer
        // for the recap, so `advance` sends its answer straight to PLAN_ASK —
        // no reaction, no verdict, no score. A reader who asked to practise
        // this scene again would answer it and be offered a reminder. TELL_ONCE
        // is the ordinary scene beat (`firstStepOf('T2')` at the lesson door),
        // reads the scene by id just the same, and runs the whole loop.
        if (ctx.hubReplayScene && (open.includes('T2') || sceneOnRequest(ctx))) {
          return CoachStep.TELL_ONCE;
        }
        // A line that asks to practise starts the scene. The other routes (the
        // check-in, the reminder) are retired: a line about them is a line.
        if (ctx.hubRoute === 'T2' && (open.includes('T2') || sceneOnRequest(ctx))) {
          return firstStepOf('T2', ctx);
        }

        // Anything else is somebody carrying on with their day, so their line IS
        // the story — "gõ thẳng vào ô chat thì đi luôn nhánh kể chuyện" — and
        // the conversation answers it. Nothing re-asks the opener, and Home
        // asks no depth question (luồng 4); the lesson door keeps the fork.
        if (open.includes('T3')) {
          return ctx.entry === CoachEntry.LESSON
            ? CoachStep.DEPTH
            : CoachStep.STORY_TALK;
        }
        // Luồng 5 — "Hoặc kể luôn chuyện của bạn…": typing at the Habit
        // screen's coordinator is the story too.
        if (ctx.entry === CoachEntry.HABIT) return CoachStep.STORY_TALK;

        return CoachStep.HUB;
      }

      // "Không bấm, không gõ → im lặng rồi đóng → CỔNG RA, không lưu gì": a
      // closed sheet is not an event, so nothing here answers for it.
      return null;

    // -------------------------------------------------- nhịp 5 · commitment

    // T4 "Ghi một câu" — the sentence they already wrote is filed, the Coach
    // says one fixed line, and the flow goes straight to the reminder. Zero
    // model calls: "task này không có câu mở… Không diễn giải, không phản
    // chiếu, không cá nhân hoá."
    case CoachStep.JOT:
      return event.kind === 'ack' || event.kind === 'text'
        ? CoachStep.PLAN_ASK
        : null;

    // T4 — the session's RESULT. Inside the closing sequence a decline goes on
    // to the tail ("từ chối → chặng 3"); asked for mid-session — the hub pill,
    // typing "lần tới mình sẽ…" — a decline hands back to the coordinator
    // instead of slamming the session shut around them.
    case CoachStep.PLAN_ASK:
      if (event.kind !== 'planAsk') return null;
      if (event.accept) return CoachStep.PLAN;

      return ctx.closing ? afterCourse(ctx) : taskEnd('T4', ctx);

    case CoachStep.PLAN:
      return event.kind === 'plan' ? CoachStep.SCHEDULE : null;

    case CoachStep.SCHEDULE:
      return event.kind === 'schedule' ? afterPlanStage(ctx) : null;

    // ---------------------------------------------------------------- tail

    case CoachStep.COURSE_CARD:
      if (event.kind !== 'course') return null;

      // The other way forward: another scene, one rung harder. Checked first
      // because it is the only one that does not end the session — the reader
      // asked to keep practising, and the card was the offer they answered.
      // TELL_ONCE, so the new scene runs the whole loop (see the note on the
      // coordinator's replay route for why RETRY_SCENE is not it).
      if (event.harder && sceneOnRequest(ctx)) return CoachStep.TELL_ONCE;

      // "Học ngay" goes STRAIGHT to the course and the session ends on the
      // spot — owner's call (2026-08-27): no LEAVE beat in between, tapping
      // the course IS the goodbye. Save and close go on to the commitment
      // offer, then the tail.
      return event.open ? CoachStep.END : afterCard(ctx);

    case CoachStep.MOOD_END:
      return event.kind === 'moodEnd' ? afterMoodEnd(ctx) : null;

    case CoachStep.RATING:
      if (event.kind !== 'rating') return null;

      // Luồng 3's tail ends here — no "phiên mới" after a course recap.
      return ctx.talkMode === 'recap' ? CoachStep.END : CoachStep.NEXT_SESSION;

    case CoachStep.NEXT_SESSION:
      if (event.kind !== 'nextSession') return null;
      // "Phiên mới" is hidden on a low mood-end; a client that sends it anyway
      // is refused rather than obeyed.
      if (event.again && ctx.moodEndLow) return null;

      return event.again ? afterMood(ctx) : CoachStep.END;

    // ------------------------------------------- retired steps, parked only

    // "Bạn muốn chia sẻ thêm không?" — the depth question, asked OUT LOUD with
    // two pills under the box. Typing on instead of tapping is the main road,
    // so the next input is read for its intent; one that says neither is asked
    // about exactly once and then filed ("không chắc thì hỏi, không đoán bừa").
    case CoachStep.DEPTH:
      if (event.kind === 'ack') return jotted(ctx);
      if (event.kind === 'depth') return event.deep ? afterStoryLine(ctx) : jotted(ctx);
      if (event.kind !== 'text') return null;
      if (ctx.depthGuess === 'deep') return afterStoryLine(ctx);
      if (ctx.depthGuess === 'shallow') return jotted(ctx);

      return ctx.depthReasked ? jotted(ctx) : CoachStep.DEPTH;

    case CoachStep.BARRIER:
    case CoachStep.CONTEXT_EDIT:
      return event.kind === 'text' ? afterCheckin(ctx) : null;

    // ③ "chưa gặp dịp" — `Giữ nguyên` · `Đổi bối cảnh`. Revived 2026-08-27:
    // changing it opens a box where the reader retypes the context in their own
    // words, which is the whole point of asking.
    case CoachStep.CONTEXT_ASK:
      if (event.kind !== 'context') return null;

      return event.keep ? afterCheckin(ctx) : CoachStep.CONTEXT_EDIT;

    case CoachStep.TELL:
      return event.kind === 'text' ? CoachStep.TELL_2 : null;

    case CoachStep.REDRAFT:
      return event.kind === 'text' ? CoachStep.NEXT_ACTION : null;

    case CoachStep.CLOSING:
      return event.kind === 'ack' ? CoachStep.INVITE : null;

    case CoachStep.FREE:
    case CoachStep.PRACTICE_ANSWER:
    case CoachStep.TELL_ONCE_A:
    case CoachStep.TELL_ONCE_B:
      return event.kind === 'text' ? CoachStep.PLAN_ASK : null;

    case CoachStep.PICK_HABIT:
    case CoachStep.PERSONA:
    case CoachStep.TIME:
    case CoachStep.CHECKIN:
      // No arrow leaves these any more; the client re-opens a fresh session.
      return null;

    case CoachStep.LEAVE:
    case CoachStep.END:
    case CoachStep.SAFETY:
    default:
      return null;
  }
}

/** What the composer renders for a step. The client switches on this alone. */
export function uiFor(step: CoachStep): CoachUiKind {
  switch (step) {
    case CoachStep.MOOD:
    case CoachStep.MOOD_END:
    case CoachStep.PICK_NEW:
    case CoachStep.PICK_HABIT:
    case CoachStep.PERSONA:
    case CoachStep.TIME:
    case CoachStep.INTENT:
    case CoachStep.CHECKIN:
    case CoachStep.SHRINK_ASK:
    case CoachStep.LOOP:
    case CoachStep.CONTEXT_ASK:
    case CoachStep.INVITE:
    case CoachStep.SCENE_AGAIN:
    case CoachStep.SCENE_MET:
    case CoachStep.PLAN_ASK:
    // Luồng 4 — the habits in the kho, then the retry offer.
    case CoachStep.SCENE_PICK:
    case CoachStep.SCENE_FIX:
    // Luồng 5 — did you / the next habit / the quiz's options.
    case CoachStep.CHECKIN_ASK:
    case CoachStep.CHECKIN_OFFER:
    case CoachStep.QUIZ_IN_CHAT:
    // Luồng 2/3 — the hand-offs and the closing question; QUIZ_RUN shows no
    // chips at all (the quiz is on its own screen).
    case CoachStep.QUIZ_HANDOFF:
    case CoachStep.QUIZ_RUN:
    case CoachStep.TALK_WHEN:
    case CoachStep.RECAP_PICK:
    case CoachStep.RECAP_QUIZ:
      return CoachUiKind.CHIPS;

    // Luồng 2 — two pills AND the box ("Hoặc kể luôn điều bạn nhớ nhất…").
    case CoachStep.TALK_ASK:
      return CoachUiKind.HUB;

    // Luồng 1 — every question: chips as shortcuts, the box always open.
    case CoachStep.ONBOARD_INTRO:
    case CoachStep.ONBOARD_ADDRESS:
    case CoachStep.ONBOARD_GOAL:
    case CoachStep.ONBOARD_BARRIER:
    case CoachStep.ONBOARD_CURRENT:
    case CoachStep.ONBOARD_STYLE:
    case CoachStep.ONBOARD_AGE:
    case CoachStep.ONBOARD_GENDER:
    case CoachStep.ONBOARD_JOB:
      return CoachUiKind.HUB;
    case CoachStep.ONBOARD_ADDRESS_CONFIRM:
      return CoachUiKind.CHIPS;

    case CoachStep.STORY:
      return CoachUiKind.TEXT_SKIPPABLE;

    // Text box PLUS the two pills: they are shortcuts, and "đường chính là
    // user cứ gõ tiếp".
    case CoachStep.DEPTH:
      return CoachUiKind.DEPTH;

    // The coordinator: one line, up to two task pills, and the way to stop.
    case CoachStep.HUB:
      return CoachUiKind.HUB;

    case CoachStep.TWO_COLS:
      return CoachUiKind.TWO_COLS;

    case CoachStep.NEXT_ACTION:
      return CoachUiKind.NEXT_ACTION;

    case CoachStep.CLOSING:
      return CoachUiKind.CLOSING;

    // The shrink is the commitment form again, pre-filled — one composer for
    // one shape of answer, and nothing new for the client to learn.
    case CoachStep.SHRINK:
    case CoachStep.PLAN:
      return CoachUiKind.PLAN;

    case CoachStep.SCHEDULE:
      return CoachUiKind.SCHEDULE;

    case CoachStep.SCENE_SCORE:
      return CoachUiKind.SCENE_SCORE;

    // T4 says one line and offers one way on.
    case CoachStep.JOT:
      return CoachUiKind.CLOSING;

    // The card sits in the thread; the composer shows its three chips.
    case CoachStep.COURSE_CARD:
      return CoachUiKind.COURSE_CARD;

    case CoachStep.RATING:
      return CoachUiKind.RATING;

    case CoachStep.NEXT_SESSION:
      return CoachUiKind.NEXT_SESSION;

    // LEAVE is END with a different button: "Sang Roadmap khoá học".
    case CoachStep.END:
    case CoachStep.LEAVE:
      return CoachUiKind.END;

    case CoachStep.SAFETY:
      return CoachUiKind.SAFETY;

    default:
      return CoachUiKind.TEXT;
  }
}
