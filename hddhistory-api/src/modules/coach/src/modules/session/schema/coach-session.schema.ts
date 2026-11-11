import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  CoachEntry,
  CoachHomeTier,
  CoachPersona,
  CoachScript,
  CoachStep,
} from '../../../shared/coach.enum';
import { CoachPlanAnswer } from '../../plan/enum/plan.enum';
import { CoachSessionStatus } from '../enum/session.enum';
import {
  ICoachQuizItem,
  ICoachQuizResult,
  ICoachSession,
  ICoachSessionTurn,
  ICoachShownTurn,
  ICoachTalkQuizResult,
} from '../interface/session.interface';

@Schema({ collection: 'coach_sessions' })
export class CoachSession extends AbstractDocument implements ICoachSession {
  @Prop({ required: true })
  userId: string;

  @Prop({ type: String, enum: CoachEntry, required: true })
  entry: CoachEntry;

  /**
   * `null` is spelled into every nullable enum below on purpose.
   *
   * Mongoose's enum validator REJECTS an explicit null unless null is in the
   * list — and each of these defaults to null and is written back as null when
   * a session resets. Without it `POST /coach/sessions` 500s on the very first
   * call with "`null` is not a valid enum value", which is exactly how it
   * reached dev: no session could open at all.
   */
  @Prop({ type: String, enum: [...Object.values(CoachHomeTier), null], default: null })
  tier?: CoachHomeTier | null;

  @Prop({ type: String, enum: CoachStep, required: true })
  step: CoachStep;

  @Prop({
    type: String,
    enum: CoachSessionStatus,
    default: CoachSessionStatus.ACTIVE,
  })
  status: CoachSessionStatus;

  @Prop({ type: String, default: null })
  habitId?: string | null;

  @Prop({ type: String, default: null })
  lessonId?: string | null;

  @Prop({ type: String, enum: [...Object.values(CoachPersona), null], default: null })
  persona?: CoachPersona | null;

  @Prop({ type: String, enum: [...Object.values(CoachScript), null], default: null })
  script?: CoachScript | null;

  @Prop({ type: String, default: null })
  situationId?: string | null;

  /**
   * Answers already given to the scene in `situationId`.
   *
   * Drives three things at once: when the step stops looping, whether the
   * scene is re-attached on the next render, and which of the three probe
   * instructions the model is given. Reset to 0 whenever a new scene is put up.
   */
  @Prop({ type: Number, default: 0, min: 0 })
  situationRound: number;

  /**
   * ① — the habits added in today's lesson, frozen at open.
   *
   * Two or more is what makes PICK_NEW appear, and the picker's chips render
   * from THIS list rather than from a re-query: a habit added after the sheet
   * opened must not appear in a question about "the ones you just added".
   */
  @Prop({ type: [String], default: [] })
  newHabitIds: string[];

  @Prop({ type: [String], default: [] })
  planQueue: string[];

  @Prop({ type: Number, default: 0, min: 0 })
  planIndex: number;

  @Prop({ type: String, default: null })
  activePlanId?: string | null;

  @Prop({ type: String, enum: [...Object.values(CoachPlanAnswer), null], default: null })
  lastIntent?: CoachPlanAnswer | null;

  /**
   * Conversational turns spent in this session.
   *
   * Counted, not derived from `turns.length`: chip taps and form saves are not
   * turns of a conversation, and the six-turn ceiling is about how long
   * somebody has been TALKING about the same evening.
   */
  @Prop({ type: Number, default: 0, min: 0 })
  turnCount: number;

  /** ⑧ — once true, the Coach may never build another draft in this session. */
  @Prop({ type: Boolean, default: false })
  draftRejected: boolean;

  /**
   * The draft exactly as the model proposed it.
   *
   * Kept beside the reader's edited version so "how many lines did they have
   * to move" is answerable — a draft nobody touches is the model imposing, not
   * the model being right.
   */
  @Prop({ type: [String], default: [] })
  draftProposed: string[];

  @Prop({ type: [String], default: [] })
  draftLeft: string[];

  @Prop({ type: [String], default: [] })
  draftRight: string[];

  @Prop({ type: Boolean, default: false })
  escapeAvailable: boolean;

  @Prop({ type: Boolean, default: false })
  moodLow: boolean;

  /** The day's start mood 1..5 — see the interface. Null = never answered. */
  @Prop({ type: Number, default: null, min: 1, max: 5 })
  moodStart?: number | null;

  /** A story was told this sheet-open → the rating may be asked. */
  @Prop({ type: Boolean, default: false })
  storyTold: boolean;

  // ---- the task registry (doc v4) -------------------------------------

  /** Task runs spent — T1–T3 share a ceiling of three. */
  @Prop({ type: Number, default: 0 })
  tasksRun?: number;

  /** Which tasks have already run in this session. */
  @Prop({ type: Boolean, default: false })
  t1Done?: boolean;

  @Prop({ type: Boolean, default: false })
  t2Done?: boolean;

  @Prop({ type: Boolean, default: false })
  t3Done?: boolean;

  /**
   * The session's real occasion, in the reader's own words.
   *
   * From the story they told, or from "Gặp rồi · lúc đó là lúc nào?" after a
   * scene. It is what makes T4 possible at all, and it is never taken from
   * anything they said INSIDE an invented scene.
   */
  @Prop({ type: String, default: null })
  dip?: string | null;

  /** The commitment has been offered — once per session, however it went. */
  @Prop({ type: Boolean, default: false })
  t4Offered?: boolean;

  /** The course card has been shown — one per session. */
  @Prop({ type: Boolean, default: false })
  cardShown?: boolean;

  /**
   * The habit the silent match found OUTSIDE the reader's kho.
   *
   * A session can point at two habits: `habitId` is the one in their kho, to
   * practise and to hang a commitment on; this one is the road not taken yet,
   * and the only thing the course card is allowed to be about.
   */
  @Prop({ type: String, default: null })
  cardHabitId?: string | null;

  /** The closing sequence has started: card → commitment → tail. */
  @Prop({ type: Boolean, default: false })
  closing?: boolean;

  /**
   * The reader has confirmed which habit this session is about.
   *
   * ② resolves the most-due habit at OPEN so a scene can be built the moment
   * one is asked for — that is a resolution, not a decision, and the habit chip
   * must not announce it ("không hiện pill Habit khi user chưa xác nhận bắt đầu
   * task với Habit nào", 2026-08-28). Set when a habit-bound task actually
   * starts, or when the reader picks a habit themselves; never cleared.
   */
  @Prop({ type: Boolean, default: false })
  habitConfirmed?: boolean;

  /**
   * Where the habit picker returns to.
   *
   * The chip's "đổi" is a detour, not a branch: nothing about where they are in
   * the conversation moves, so the step they were on is kept and restored.
   */
  @Prop({ type: String, default: null })
  habitReturnStep?: CoachStep | null;

  /**
   * Keypoints the Coach has spoken from at nhịp 4, in the order used.
   *
   * "Ghi nhớ keypoint_id đã dùng — cuối phiên sẽ gợi đúng khoá chứa nó": this
   * is what makes the course card ưu tiên 1 possible at all.
   */
  @Prop({ type: [String], default: [] })
  keypointIds?: string[];

  /**
   * The depth question has been asked a second time already.
   *
   * "Không chắc thì hỏi, không đoán bừa. Sau lần đó thì mặc định là ghi lại."
   */
  @Prop({ type: Boolean, default: false })
  depthReasked?: boolean;

  /**
   * STORY_TALK — replies the story conversation has given so far. The cap
   * (`STORY_TALK_ROUNDS`) is read against this; "phiên mới" resets it.
   */
  @Prop({ type: Number, default: 0 })
  storyTalkRounds?: number;

  /**
   * STORY_TALK — the recurring subject has been named this session. Once: a
   * Coach that says "lần thứ ba rồi" twice in one evening is nagging.
   */
  @Prop({ type: Boolean, default: false })
  patternNamed?: boolean;

  /**
   * Luồng 5 — the in-chat quiz, snapshotted at open: the questions this run
   * asks, with their options and which is right, so an answer is judged
   * against what was shown even if the content changes mid-session.
   */
  @Prop({ type: [SchemaTypes.Mixed], default: [] })
  quizItems?: ICoachQuizItem[];

  @Prop({ type: Number, default: 0 })
  quizIndex?: number;

  @Prop({ type: [SchemaTypes.Mixed], default: [] })
  quizResults?: ICoachQuizResult[];

  /** Luồng 5 — the next habit the offer names ("Trong kho còn «Y»…"). */
  @Prop({ type: String, default: null })
  checkinOfferHabitId?: string | null;

  /**
   * The story showed INTENT — the reader said they want to get better at
   * this, or asked how. The course card at the end of a story waits for this:
   * "Không recommend Course chỉ vì conversation có keyword liên quan."
   */
  @Prop({ type: Boolean, default: false })
  improveSignal?: boolean;

  // ---- luồng 2/3 — the lesson door redrawn ----------------------------------
  /** `talk` after a keypoint, `recap` after the last one; null = the legacy scene door. */
  @Prop({ type: String, default: null })
  talkMode?: 'talk' | 'recap' | null;

  @Prop({ type: String, default: null })
  keypointId?: string | null;

  @Prop({ type: String, default: null })
  courseId?: string | null;

  /** The reader's habit this keypoint teaches, if they have one — the check-in goes there. */
  @Prop({ type: String, default: null })
  talkHabitId?: string | null;

  /** `lesson` at the lesson's last keypoint (summarise the whole lesson), else `keypoint`. */
  @Prop({ type: String, default: null })
  summaryScope?: 'keypoint' | 'lesson' | null;

  /** Luồng 2 — the keypoint quiz's results, as the app reported them. */
  @Prop({ type: [SchemaTypes.Mixed], default: [] })
  talkQuizResults?: ICoachTalkQuizResult[];

  /**
   * Luồng 2 — how many follow-up questions the reader has already spent at
   * TALK_FREE. Counted server-side so a client cannot ask for more.
   */
  @Prop({ type: Number, default: 0 })
  talkFreeTurns?: number;

  /** Luồng 3 — the lessons offered as chips, snapshotted at open. */
  @Prop({ type: [SchemaTypes.Mixed], default: [] })
  recapLessons?: Array<{ id: string; title: string }>;

  @Prop({ type: String, default: null })
  recapLessonId?: string | null;

  // ---- luồng 1 — Onboarding Coach ------------------------------------------
  /** This session opened on the onboarding (first Home session ever). */
  @Prop({ type: Boolean, default: false })
  onboarding?: boolean;

  /** The answers so far, by field — written to the profile when it ends. */
  @Prop({ type: SchemaTypes.Mixed, default: {} })
  onboardAnswers?: Record<string, string>;

  /** A name typed at the address question, awaiting "Mình gọi bạn là «…» nhé?". */
  @Prop({ type: String, default: null })
  onboardName?: string | null;

  @Prop({ type: Boolean, default: false })
  moodEndAsked: boolean;

  @Prop({ type: Boolean, default: false })
  moodEndLow: boolean;

  @Prop({ type: Boolean, default: false })
  ratingAsked: boolean;

  @Prop({ type: String, default: null })
  courseCardId?: string | null;

  /**
   * Why the card shows THAT course, kept beside the id so a resumed card says
   * the same thing it said the first time — the selector reads live data and
   * a re-run mid-session could pick a different course for a different reason.
   */
  @Prop({ type: String, default: null })
  courseCardReasonKey?: string | null;

  @Prop({ type: String, default: null })
  courseCardReasonArg?: string | null;

  @Prop({ type: String, default: null })
  createdPlanId?: string | null;

  /**
   * The action the reader chose in the scene they just practised, kept so the
   * commitment form can pre-fill "sẽ làm gì" with it — the practice becomes
   * the plan. Their words, always editable; cleared on a new session.
   */
  @Prop({ type: String, default: null })
  sceneActionDraft?: string | null;

  /** The scene's "when", for the form's "khi nào" — see `sceneActionDraft`. */
  @Prop({ type: String, default: null })
  sceneContextDraft?: string | null;

  /**
   * 6b — what they actually DID the time this really happened, kept so 6d's
   * "không đổi" can hand that very thing to the reminder.
   */
  @Prop({ type: String, default: null })
  sceneDidAnswer?: string | null;

  // The current scene's script, snapshotted when shown. `sceneBeats` length
  // decides the number of probe turns; empty = a legacy scene, old path.
  @Prop({ type: [String], default: [] })
  sceneBeats?: string[] | null;

  @Prop({ type: [String], default: [] })
  sceneBeatLines?: string[] | null;

  @Prop({ type: String, default: null })
  sceneCounterpart?: string | null;

  /**
   * The named ways forward the last reaction offered, as `key|label|text`.
   *
   * Stored because the reader may answer with the letter alone. Resolving "A"
   * back to its line needs the offer that was on screen, and the offer is
   * written by a model call that is over by the time the answer arrives.
   *
   * One string per option rather than a sub-document: the whole value is
   * rewritten every turn and never queried into, so a schema for it would buy
   * nothing and cost a migration.
   */
  @Prop({ type: [String], default: [] })
  sceneOptions?: string[] | null;

  /**
   * How each of this scene's answers sat — `direct` · `hesitant` · `avoid` ·
   * `escalate`, in the order they were given.
   *
   * The model has always judged this and it was thrown away. Kept now so the
   * closing reply can name a PATTERN rather than only the last line: "hai lượt
   * vừa rồi bạn đều lùi khỏi câu khó" is a different, truer thing to hear than
   * a verdict on one sentence.
   */
  @Prop({ type: [String], default: [] })
  scenePostures?: string[] | null;

  /**
   * Difficulty to write the NEXT scene at, when the reader asked for a harder
   * one ("Luyện cảnh khó hơn" on the card).
   *
   * Null on every ordinary scene, which then takes the level its slot gives it.
   * Kept on the session rather than passed along because the ask and the
   * generation are two different turns.
   */
  @Prop({ type: Number, default: null, min: 1, max: 5 })
  sceneTargetLevel?: number | null;

  /**
   * The scene's opening prompt, snapshotted when the scene was shown.
   *
   * Kept beside its second stage so an answer can be filed against the exact
   * question it answered: an AI-generated scene is deleted outright whenever an
   * editor rebuilds its habit's pool, and joining the catalogue back afterwards
   * returns nothing.
   */
  @Prop({ type: String, default: null })
  scenePrompt?: string | null;

  /**
   * Nhịp 4 — the scene's SECOND stage, snapshotted when the scene was shown.
   *
   * Written by an editor like the first: the other person reacts and the
   * situation turns one notch harder. Null on a scene that has only one stage,
   * and then the flow skips nhịp 4 and 5 rather than inventing them.
   */
  @Prop({ type: String, default: null })
  scenePromptStage2?: string | null;

  @Prop({ type: String, default: null })
  sceneFirstLine?: string | null;

  @Prop({ type: Boolean, default: false })
  sceneReacted?: boolean;

  @Prop({ type: [String], default: [] })
  sceneShownIds?: string[];

  @Prop({ type: [String], default: [] })
  scenePickShown?: string[];

  @Prop({ type: String, default: null })
  sceneTakeaway?: string | null;

  @Prop({ type: String, default: null })
  sceneGoodMove?: string | null;

  @Prop({ type: Number, default: null, min: 1, max: 5 })
  sceneLevel?: number | null;

  @Prop({ type: Boolean, default: false })
  sceneRetried?: boolean;

  // Mixed: the criteria are authored per habit, so this is a snapshot of what
  // was shown, not a shape this file owns. Dies with the session (48h) — the
  // durable copy is one row in `coach_scene_scores`.
  @Prop({ type: SchemaTypes.Mixed, default: null })
  sceneScore?: ICoachSession['sceneScore'];

  @Prop({ type: String, required: true })
  locale: string;

  @Prop({ type: Number, default: 0 })
  tzOffsetMinutes: number;

  @Prop({ type: SchemaTypes.Mixed, default: [] })
  turns: ICoachSessionTurn[];

  @Prop({ type: SchemaTypes.Mixed, default: [] })
  shown: ICoachShownTurn[];

  @Prop({ type: SchemaTypes.Mixed, default: null })
  onboardPicks?: Record<string, string> | null;

  @Prop({ type: String, default: null })
  address?: string | null;

  @Prop({ type: Number, default: 0 })
  khoSize?: number;

  @Prop({ type: Date, required: true })
  expiresAt: Date;

  @Prop({ type: Date, default: null })
  closedAt?: Date | null;

  /**
   * Vạch của lần cô đọng memory gần nhất TRONG phiên này.
   *
   * Phiên giữ vạch, không phải module memory: nó là trạng thái của một cuộc nói
   * chuyện, và module memory không được ghi vào doc của module khác. Null =
   * chưa cô đọng lần nào, và lần đầu sẽ đọc từ đầu phiên.
   */
  @Prop({ type: Date, default: null })
  memoryExtractedAt?: Date | null;
}

export const CoachSessionSchema = SchemaFactory.createForClass(CoachSession);

// No TTL any more (owner, 2026-09-04): "luôn lưu trữ câu chuyện giữa AI coach
// và user" — the exchange is the reader's own record and comes back when they
// reopen the sheet. The old `expiresAt` TTL index is dropped by
// `CoachSessionRepository.onModuleInit` (syncIndexes); the field stays as a
// validity stamp for `findActiveForEntry`.


// "Has this reader already had a Coach session today, and at which door?" —
// the read behind both derived day-flags, which is why there is no flag table.
CoachSessionSchema.index({ userId: 1, entry: 1, createdAt: -1 });
