import { CoachPersona, CoachStep, CoachUiKind } from '../../../shared/coach.enum';
import { ICoachHotline } from '../../config/interface/coach-config.interface';
import { CoachSessionKind } from '../../rating/enum/rating.enum';

/**
 * One selectable option.
 *
 * `value` is what comes back on the next turn. `label` is present ONLY for
 * options built from data (a habit title); fixed options carry no label at all,
 * because their words live in the client's slang files in five languages and
 * shipping them from the server would put the same sentence in two places.
 */
export interface CoachChoice {
  value: string;
  label?: string | null;
  /** Luồng 1 — the app already holds this answer; the chip is lit and the reader confirms or changes it. */
  selected?: boolean;
}

export interface CoachUiPayload {
  kind: CoachUiKind;
  choices?: CoachChoice[];
  /** Nhịp 3 — the draft, mid-drag. */
  columns?: { left: string[]; right: string[] };
  /**
   * Nhịp 3 — whether ⑤ "Không đúng với mình" is still offered. Once the
   * draft has been rejected once, the second telling is drafted without the
   * button: the Coach does not argue, and the reader is not asked a third time.
   */
  rejectAvailable?: boolean;
  /**
   * Thanh habit — the habit this session is about, and the reader's right to
   * change it.
   *
   * Not an interaction of the flow: a status bar at the top of the sheet, shown
   * from the moment the habit is CERTAIN and never earlier. Present on every
   * turn once it is settled, so the chip does not blink in and out.
   */
  habit?: { id: string; title: string } | null;
  /**
   * Thanh phạm vi cho luồng 2/3 — cùng chỗ, cùng khung với thanh habit, nhưng
   * cái đang bàn không phải một habit.
   *
   * Luồng 2 bàn về một KEYPOINT, luồng 3 về cả KHOÁ, và không cửa nào trong hai
   * cửa đó có `habitId` — nên `habit` ở trên luôn null và thanh không hiện, dù
   * design có nó (owner bắt trên sim 2026-09-04). `kind` để app tự dịch chữ dẫn
   * ("Keypoint ·" / "Khoá ·") chứ không nhận chữ đã ghép sẵn từ server.
   *
   * KHÔNG có nút đổi: keypoint vừa học xong không phải thứ chọn lại được.
   */
  scope?: { kind: 'keypoint' | 'course'; title: string } | null;
  /** The generated scene, when this step shows one. */
  situation?: string | null;
  /**
   * The same scene, broken into the parts the app shows as SEPARATE bubbles:
   * which habit is being practised, the setup, and the question that closes it.
   *
   * One 60-word block read as a wall of text ("chat 1 cục lớn"), so the split
   * happens here rather than in the app: the app has no habit title of its own
   * at this step, and a client-side sentence splitter would drift between
   * platforms. `situation` stays for older builds, which show the whole block.
   */
  scene?: {
    /** The habit's title in the reader's language. Null at ①, which names it already. */
    habit?: string | null;
    /** The scene itself — everything before the closing question. */
    setup: string;
    /** The closing question, shown last and on its own. Null if the scene had none. */
    question?: string | null;
    /**
     * The named ways to answer, structured so the app can put the letter and
     * the approach's name in the bubble's bold heading and the quote
     * underneath. One `Text` cannot carry two weights.
     *
     * Both moments of a scene use this — the opening question and the other
     * person's reaction — so they read as one feature. TEXT, never pills: a
     * tapped-and-copied answer is the one thing that empties the exercise.
     */
    options?: Array<{ key: string; label: string; text: string }>;
    /** The sentence introducing them, which also says writing your own is allowed. */
    optionsLead?: string | null;
  } | null;
  /**
   * Two answers the reader can tap instead of typing.
   *
   * Written by the same call that wrote the reply (or cached with the scene),
   * so they fit what is actually being discussed. Empty is normal and the row
   * simply does not render.
   */
  samples?: string[];
  /** ⑧ only. Empty is a valid answer — see `CoachConfigService.hotlinesFor`. */
  hotlines?: ICoachHotline[];
  /**
   * Nhịp 4 — at most two keypoints, READ from the habit, never generated and
   * never a list. Each can be asked to be re-explained, which counts against
   * the content rather than the reader.
   *
   * `courseId`/`courseTitle` name the published course a tap opens — the head
   * of the same ranking ③C's invite uses. Null when no published course
   * teaches the habit's keypoints; the row then reads without linking.
   */
  keypoints?: Array<{
    id: string;
    title: string;
    courseId?: string | null;
    courseTitle?: string | null;
    courseImage?: string | null;
  }>;
  /** ⑥ — whether the way out is offered at this step. */
  escapeAvailable: boolean;
  /** Luồng 5/6 — QUIZ_IN_CHAT: questions still to ask, the current one included. */
  quizRemaining?: number;
  /** Luồng 2 — something the app does on this step: `runQuiz` (push the keypoint quiz) · `keypointDone` (the talk is over; the sheet STAYS open and its close button goes to the Roadmap). */
  action?: string | null;
  /** Luồng 1 — the onboarding's progress strip: which of the eight questions, and whether "Bỏ qua" is offered. */
  onboard?: { step: number; total: number; skippable: boolean } | null;
  /** RETIRED (design v2). Kept for a client build that still reads it. */
  shrink?: { context: string; action: string } | null;
  /**
   * COURSE_CARD / LEAVE — the one course that matches the habit, read from
   * the library, never generated. Drawn in the thread with its author and
   * reach, as the course rail draws it; `habitTitle` says WHY it is here.
   */
  course?: {
    courseId: string;
    title: string;
    image: string | null;
    habitTitle: string | null;
    author: string | null;
    viewCount: number | null;
    /**
     * Why this course: a `COACH_COURSE_REASON` key the client renders from
     * slang, with the habit title it quotes in `reasonArgs`. A fact about the
     * reader ("you keep stopping at X", "you saved this"), never a model's
     * opinion — the card has to read as the app having listened.
     */
    reasonKey: string | null;
    reasonArgs: Record<string, string> | null;
  } | null;
  /** NEXT_SESSION — false on a low mood-end: only "Dừng" remains. */
  allowNewSession?: boolean;
  /**
   * PLAN — a pre-fill for the commitment form, carried over from a scene the
   * reader just practised: `action` is what they chose to do, `context` a
   * likely "when" from the habit. Both editable; absent when no scene led here.
   */
  suggested?: { context: string; action: string } | null;

  /**
   * Tầng 4 — the rubric card for the scene just finished.
   *
   * Present only at `SCENE_SCORE`. `criteria` carries the label as well as the
   * key so the client renders the reader's own language without knowing what
   * rubric this skill uses; `skill` is the running 0–100 for the habit, absent
   * on a reader's very first scored scene (a 0/100 on day one is a verdict, not
   * a measurement).
   */
  score?: {
    criteria: Array<{
      key: string;
      label: string;
      score: number;
      note?: string | null;
    }>;
    /** Mean of the criteria, 0–10, one decimal. */
    overall: number;
    strength?: string | null;
    improve?: string | null;
    tip?: string | null;
    /** Their own answer, rewritten to do the job better. Null when it needed none. */
    betterPhrasing?: string | null;
    /** Difficulty of the scene that was scored, 1–5. */
    level: number;
    /** Whether "Thử lại tình huống này" is still on offer. */
    retryAvailable: boolean;
    skill?: {
      /** 0–100 over the last few scenes, null with no history. */
      score: number | null;
      scenes: number;
      /** Next scene's difficulty, after this score moved the ladder. */
      level: number;
      /** Newer half minus older half, in points of 10. Null until there is enough. */
      trend: number | null;
    } | null;
  } | null;
}

/**
 * What one turn returns.
 *
 * `reply` and `promptKey` are mutually exclusive and that split is the i18n
 * contract: a generated line arrives already written in the reader's language
 * and the client shows it as-is; a fixed line arrives as a key and the client
 * renders it from slang. Neither ever travels the other's road.
 */
export interface CoachTurnResponse {
  sessionId: string;
  step: CoachStep;
  reply: string | null;
  promptKey: string | null;
  /**
   * Values the client interpolates into the fixed line — the commitment being
   * asked about at INTENT ("Hôm qua bạn nói: lần tới khi {context} sẽ
   * {action}…"), the context at CONTEXT_ASK, the reminder time at the
   * closing line. Always the reader's own words, never the model's.
   */
  promptArgs?: Record<string, string> | null;
  /**
   * A fixed line shown BEFORE the step's own line — ②A's "cái hẹn này mình tạm
   * cất đi nhé" when the third "chưa gặp dịp" put a commitment to sleep.
   */
  noteKey?: string | null;
  /**
   * Who just spoke, when it was not the Coach.
   *
   * Set on a roleplay turn (tầng 3): the reply is the scene's other person
   * talking, so the app labels the bubble with their name instead of the
   * Coach's. Null on every ordinary turn — the Coach needs no label.
   */
  speaker?: string | null;
  /** The voice in force — pre-lit from last time, changeable from the header. */
  persona?: CoachPersona | null;
  ui: CoachUiPayload;
  /** ③C — the one course offered when a story matched no habit the reader has. */
  courseInvite?: { courseId: string; title: string } | null;
  /**
   * The exchange so far, sent ONLY when an existing session is being resumed.
   *
   * Not history across sessions — the design is firm that a finished
   * conversation is gone. This is the same conversation, picked back up after
   * the sheet was swiped away or the app was backgrounded.
   */
  /**
   * The thread to draw before this response's own lines: earlier sessions
   * (each behind a `divider`), then — on resume — this session so far.
   */
  replay?: CoachReplayItem[];
  /** This session was picked back up: its current lines are already in `replay`. */
  resumed?: boolean;
  ended: boolean;
  /** Luồng 6 — whether ⟨Đóng⟩ may plead once for this reader (off after two declines). */
  exitPlea?: boolean;
  /**
   * Luồng 6 — whether the rating sheet follows ⟨Vẫn đóng⟩ for this reader.
   *
   * AFTER the plea, never instead of it: the design's order is EXIT_PLEA →
   * RATE_COACH, so ⟨Đóng⟩ asks them to stay and only a reader who says no is
   * asked how it went. Resolved by the admin's frequency knobs — see
   * `rating-ask-gate.ts` — so the client only reads it.
   */
  exitFeedback?: boolean;
  /**
   * What the reader is doing right now — which chip set the rating sheet draws.
   *
   * The sheet asks a different question per kind, and somebody sitting at the
   * hub is asked why they never started rather than how the Coach did.
   */
  sessionKind?: CoachSessionKind;
}

/** ①②③ — whether the bubble renders at all, and whether it carries the dot. */
export interface CoachBubbleResponse {
  visible: boolean;
  /**
   * The red dot, which appears in exactly one situation across the whole app:
   * Home, with a pending commitment waiting to be asked about.
   */
  dot: boolean;
  /** A one-line preview of that commitment, in the reader's own words. */
  teaser: string | null;
  /**
   * ④ — a FIXED teaser ("Tình huống ba tuần trước…") as a slang key, since
   * there are no reader's words to quote. The client renders whichever of the
   * two is set.
   */
  teaserKey?: string | null;
}

/** Returned instead of a session when a door's guards say to stay quiet. */
export interface CoachSilentResponse {
  silent: true;
  reasonKey: string;
}

/**
 * One drawn exchange, or a divider between sessions. The Coach's fixed lines
 * travel as keys and are rendered by the app in its current language; `isCoach`
 * / `text` keep the shape older app builds read.
 */
export interface CoachReplayItem {
  at: string;
  step?: string | null;
  userLine?: string | null;
  reply?: string | null;
  speaker?: string | null;
  noteKey?: string | null;
  promptKey?: string | null;
  promptArgs?: Record<string, string> | null;
  situation?: string | null;
  // Carries `options` too: a replayed turn is redrawn through the same path a
  // live one takes, so the approaches have to survive the round trip or the
  // thread loses them the moment the sheet is reopened.
  scene?: {
    habit?: string | null;
    setup: string;
    question?: string | null;
    options?: Array<{ key: string; label: string; text: string }>;
    optionsLead?: string | null;
  } | null;
  divider?: { at: string; entry: string } | null;
  isCoach: boolean;
  text: string;
}
