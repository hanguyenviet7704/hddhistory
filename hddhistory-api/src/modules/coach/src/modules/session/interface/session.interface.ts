import {
  CoachEntry,
  CoachHomeTier,
  CoachPersona,
  CoachScript,
  CoachStep,
} from '../../../shared/coach.enum';
import { CoachPlanAnswer } from '../../plan/enum/plan.enum';
import { CoachSessionStatus, CoachTurnRole } from '../enum/session.enum';

/**
 * One line of the exchange, kept ONLY for the model's context on the next turn.
 *
 * Coach turns live here and nowhere else, and this document expires — see
 * `COACH_SESSION_TTL_HOURS`. Everything the reader said that matters was
 * already copied into its own typed collection when it was said.
 */
export interface ICoachSessionTurn {
  role: CoachTurnRole;
  text: string;
  step: CoachStep;
  at: Date;
}

/**
 * One exchange exactly as the app drew it — what the reader said or tapped,
 * and the pieces the Coach's side was rendered from. Fixed lines are kept as
 * their KEY, not their text, so a replay re-renders them in whatever language
 * the app is in now. This is the transcript the reader sees when they come
 * back; `turns` stays the model's own plain-text context.
 */
export interface ICoachShownTurn {
  at: Date;
  step: CoachStep;
  userLine?: string | null;
  reply?: string | null;
  speaker?: string | null;
  noteKey?: string | null;
  promptKey?: string | null;
  promptArgs?: Record<string, string> | null;
  situation?: string | null;
  scene?: {
    habit?: string | null;
    setup: string;
    question?: string | null;
    /**
     * The named ways to answer this scene's question.
     *
     * Structured rather than pre-rendered so the client can set the letter and
     * the approach's name in the bubble's bold heading and drop the quote
     * underneath — one `Text` cannot carry two weights, and the letter is what
     * the reader reaches for.
     */
    options?: Array<{ key: string; label: string; text: string }>;
    /** The sentence that introduces them, and says writing your own is allowed. */
    optionsLead?: string | null;
  } | null;
}

/** Luồng 5 — one question of the in-chat quiz, as shown. */
export interface ICoachQuizItem {
  learningItemId: string;
  exerciseId: string;
  question: string;
  options: string[];
  correctIndex: number;
  explanation?: string | null;
}

/** Luồng 5 — one answered question, in the shape `habit_practice_attempts` files. */
export interface ICoachQuizResult {
  exerciseId: string;
  passed: boolean;
  chosenIndex: number;
}

/** Luồng 2 — one question of the keypoint quiz, as the app reported it. */
export interface ICoachTalkQuizResult {
  exerciseId: string;
  passed: boolean;
  question?: string;
  chosen?: string;
  correct?: string;
}

export interface ICoachSession {
  userId: string;
  entry: CoachEntry;
  /** Only set for CoachEntry.HOME. */
  tier?: CoachHomeTier | null;
  step: CoachStep;
  status: CoachSessionStatus;

  habitId?: string | null;
  lessonId?: string | null;
  persona?: CoachPersona | null;
  script?: CoachScript | null;
  /** The situation currently on screen, so its answer can be filed against it. */
  situationId?: string | null;

  /** ① — habits added in today's lesson, frozen at open. ≥2 → PICK_NEW. */
  newHabitIds: string[];

  /**
   * ③A walks pending plans in order, at most `MAX_INTENT_ROUNDS` of them.
   *
   * Frozen at session start rather than re-read each round: a plan created
   * during this very session must not be asked back about in the same session,
   * which is exactly what a live re-read would do.
   */
  planQueue: string[];
  planIndex: number;
  /** The plan this session is asking about or has just created. */
  activePlanId?: string | null;
  lastIntent?: CoachPlanAnswer | null;

  /** Conversational turns spent — the six-turn ceiling reads this. */
  turnCount: number;
  /** Vạch của lần cô đọng memory gần nhất trong phiên này — xem schema. */
  memoryExtractedAt?: Date | null;
  /** ⑧ — the Coach is barred from drafting again in this session. */
  draftRejected: boolean;
  /** The draft as the model first proposed it, for the impose metric. */
  draftProposed: string[];

  /** ⑦ two-column draft, mid-drag. Dies with the session; only the final sentence is kept. */
  draftLeft: string[];
  draftRight: string[];

  /** ⑥ is offered only before the reader has committed to telling something. */
  escapeAvailable: boolean;

  /**
   * Start-of-day mood was low (Tệ · Hơi mệt) — read once at open, or set by
   * the MOOD answer. Drives the third-person scene and the 22h rule.
   */
  moodLow: boolean;
  /** A story was told this sheet-open → the rating may be asked ("chỉ hiện sau phiên CÓ kể chuyện"). */
  storyTold: boolean;

  /** Task runs spent this session — T1–T3 share a ceiling of three. */
  tasksRun?: number;
  t1Done?: boolean;
  t2Done?: boolean;
  t3Done?: boolean;
  /** The session's real occasion, in the reader's words — what makes T4 possible. */
  dip?: string | null;
  /** The commitment has been offered once already. */
  t4Offered?: boolean;
  /** The course card has been shown — one per session. */
  cardShown?: boolean;
  /** The habit the silent match found OUTSIDE the kho — what the card is about. */
  cardHabitId?: string | null;
  /** The closing sequence has started. */
  closing?: boolean;
  /** The reader has confirmed the habit — until then the chip stays hidden. */
  habitConfirmed?: boolean;
  /** Where the habit picker returns to — the chip's "đổi" is a detour. */
  habitReturnStep?: CoachStep | null;

  /** Keypoints the Coach spoke from at nhịp 4 — kept for older sessions. */
  keypointIds?: string[];

  /** DEPTH — the "kể tiếp, hay mình ghi lại?" question has been asked already. */
  depthReasked?: boolean;
  /** STORY_TALK — replies given in the story conversation so far. */
  storyTalkRounds?: number;
  /** STORY_TALK — the recurring subject has been named once this session. */
  patternNamed?: boolean;
  /** Luồng 5 — the in-chat quiz's questions, snapshotted at open. */
  quizItems?: ICoachQuizItem[];
  quizIndex?: number;
  quizResults?: ICoachQuizResult[];
  /** Luồng 5 — the next unwritten habit the offer names. */
  checkinOfferHabitId?: string | null;
  /** The story showed intent to improve — the one thing that lets a story end on a course. */
  improveSignal?: boolean;
  /** Luồng 2/3 — the lesson door redrawn. */
  talkMode?: 'talk' | 'recap' | null;
  keypointId?: string | null;
  courseId?: string | null;
  talkHabitId?: string | null;
  summaryScope?: 'keypoint' | 'lesson' | null;
  talkQuizResults?: ICoachTalkQuizResult[];
  /** Luồng 2 — follow-up questions already answered at TALK_FREE. */
  talkFreeTurns?: number;
  recapLessons?: Array<{ id: string; title: string }>;
  recapLessonId?: string | null;
  /** Luồng 1 — Onboarding Coach. */
  onboarding?: boolean;
  onboardAnswers?: Record<string, string>;
  /** Luồng 1 — the chip picked at each onboarding step, so "← Câu trước" relights it. */
  onboardPicks?: Record<string, string> | null;
  /** How the reader asked to be called, copied from the profile at open. Vietnamese fixed lines follow it. */
  address?: string | null;
  /** How many habits the kho held at open — Home's "Luyện tập tình huống" pill needs one. */
  khoSize?: number;
  onboardName?: string | null;
  /** Asked once per sheet-open, however many sessions run inside it. */
  moodEndAsked: boolean;
  moodEndLow: boolean;
  ratingAsked: boolean;
  /** The course the tail offers, resolved when the tail is reached. */
  courseCardId?: string | null;
  /** Why that course — a `COACH_COURSE_REASON` key, and the habit title it names. */
  courseCardReasonKey?: string | null;
  courseCardReasonArg?: string | null;
  /** The commitment created in THIS session — the closing line quotes it. */
  createdPlanId?: string | null;
  /** The move for next time that pre-fills the commitment's action — see the schema. */
  sceneActionDraft?: string | null;
  /** The scene's moment that pre-fills the commitment's "when". */
  sceneContextDraft?: string | null;
  /**
   * The script of the scene in `situationId`, snapshotted when it was shown so
   * the reply to each answer walks the same beats even if an editor changes the
   * scene mid-session. `sceneBeats` = the ordered probe intents (its length
   * decides how many turns the scene takes); empty means a legacy scene with no
   * script, which runs the old improvised path.
   */
  /**
   * The day's start mood, 1..5, as the reader answered it.
   *
   * `moodLow` was enough while mood only gated the deep-dive; the opening line
   * now picks its wording per level ("câu mở, chọn theo mood"), which needs the
   * value. Null when they were never asked or skipped — "không suy đoán".
   */
  moodStart?: number | null;
  sceneBeats?: string[] | null;
  /** The other person's line per beat, index-aligned — see the situation model. */
  sceneBeatLines?: string[] | null;
  /** Who those lines belong to, read out of the scene's own text once. */
  sceneCounterpart?: string | null;
  /**
   * The ways forward the last reaction named, packed `key|label|text` — so a
   * reader who answers "A" can be scored on the approach, not on the letter.
   */
  sceneOptions?: string[] | null;
  /** How each answer in this scene sat, in order — see `CoachScenePosture`. */
  scenePostures?: string[] | null;
  /** Difficulty asked for the next scene, 1–5. Null = the slot decides. */
  sceneTargetLevel?: number | null;
  /** Nhịp 4 — the scene's written second stage, snapshotted when shown. */
  /** The scene's opening prompt, frozen when it was shown. */
  scenePrompt?: string | null;
  scenePromptStage2?: string | null;

  /** Luồng 4 — the reader's FIRST line in the current scene; the verdict reads both. */
  sceneFirstLine?: string | null;
  /** Luồng 4 — the other person has answered that line, so the next one is scored. */
  sceneReacted?: boolean;
  /**
   * Luồng 4 — scenes this session has already put in front of the reader. The
   * retry must be a DIFFERENT scene about the same habit, and the one they
   * just failed is not marked "answered" anywhere yet.
   */
  sceneShownIds?: string[];

  /** Luồng 4 — the habits SCENE_PICK dealt last, so ⟨Xáo trộn⟩ deals different ones. */
  scenePickShown?: string[];
  sceneTakeaway?: string | null;
  sceneGoodMove?: string | null;
  /** Difficulty of the scene on screen, so the score it earns lands on the ladder. */
  sceneLevel?: number | null;
  /** The rubric card has already replayed this scene once. */
  sceneRetried?: boolean;
  /**
   * The score the finished scene earned, kept on the session so reopening the
   * sheet re-renders the card instead of paying for a second assessment.
   */
  sceneScore?: {
    criteria: Array<{ key: string; label: string; score: number; note?: string | null }>;
    overall: number;
    strength?: string | null;
    improve?: string | null;
    tip?: string | null;
    betterPhrasing?: string | null;
  } | null;

  locale: string;
  tzOffsetMinutes: number;
  turns: ICoachSessionTurn[];
  /** The exchange as shown, for the reader's own replay. Never wiped. */
  shown?: ICoachShownTurn[];
  expiresAt: Date;
  closedAt?: Date | null;
}
