import {
  CoachPersona,
  CoachScript,
  CoachStep,
  CoachScenePosture,
  CoachStoryKind,
} from '../../shared/coach.enum';

/**
 * What the model is allowed to know about the reader when it writes a reply.
 *
 * Deliberately narrow. It gets the habit being worked on, the voice the reader
 * chose, how long they said they had, and what has been said in THIS session —
 * nothing else. No history from previous sessions, no profile, no progress
 * data. A coach that opens with knowledge the reader did not just give it reads
 * as surveillance, and the design's whole posture is the opposite of that.
 */
export interface CoachTurnContext {
  locale: string;
  step: CoachStep;
  persona?: CoachPersona | null;
  script?: CoachScript | null;
  habitTitle?: string | null;
  habitContext?: string | null;
  /**
   * What the lesson teaches for this habit — description and keypoints.
   *
   * Set only on the scene steps. It is what lets the reply after a scene put
   * the lesson's ONE move beside the reader's choice; without it the model can
   * only mirror the answer back, which is the reply nobody learns from.
   */
  habitMaterial?: string | null;
  /**
   * Nhịp 4's ONE keypoint, retrieved from the library — title and body.
   *
   * The Coach speaks it in its OWN words ("không đọc nguyên xi kèm tên bài —
   * trích dẫn nguyên xi biến Coach thành máy tra cứu"), which is why the body
   * reaches the prompt and the id never does: choosing the keypoint is the
   * app's job, saying it well is the model's.
   */
  keypointTitle?: string | null;
  keypointBody?: string | null;
  /** This session only. Coach lines included, because the model needs its own thread. */
  transcript: Array<{ role: 'user' | 'coach'; text: string }>;
  /** The line the reader just sent. */
  input: string;
  /**
   * Which beat of a three-answer scene this reply closes — 0, 1 or 2.
   *
   * Null everywhere else. It is what decides whether this reply ends with a
   * question or deliberately does not, so it has to reach the prompt rather
   * than being inferred from the step (the step is the SAME for all three).
   */
  situationRound?: number | null;
  /** How many answers this scene takes in total — decides when to stop asking. */
  situationRoundsTotal?: number | null;
  /**
   * The scene's authored SECOND stage — shown to the reader right after the
   * a-b-c reply. Part b must lead into exactly this development: b written
   * blind promises one reaction and the very next message shows another,
   * which reads as the Coach not knowing its own scene.
   */
  sceneStage2?: string | null;
  /**
   * The authored intent of THIS probe — what the scene's script says to draw
   * out on this non-final turn. When set, the reply asks about exactly this
   * rather than improvising a generic follow-up. Null on the closing turn, on
   * legacy scenes with no script, and off the scene steps.
   */
  sceneBeatIntent?: string | null;
  /**
   * The line the OTHER person in the scene says on this turn, when the scene's
   * script supplies one — the design's "AI đóng vai A". With it the Coach speaks
   * IN CHARACTER and the reader answers the person, not a question about them.
   * Null on probe-only beats, on the closing turn, and on legacy scenes.
   */
  sceneBeatLine?: string | null;
  /** Who that line belongs to, taken from the scene ("Linh", "Nam"). */
  sceneCounterpart?: string | null;
  /**
   * The lesson the scene is built to make — set ONLY on the closing turn, so
   * the last reply lands it in the Coach's own words. Null otherwise.
   */
  sceneTakeaway?: string | null;
  /**
   * The scene's concrete move for its moment — set ONLY on the closing turn.
   * Offered beside the reader's own choice, and the default the model fills
   * `nextMove` with. Null otherwise.
   */
  sceneGoodMove?: string | null;
  /**
   * Whether the flow will actually give the reader a box to answer in.
   *
   * Only meaningful at `tell`. Short jumps straight to the reminder and a
   * late-night low day skips the follow-up, so a reply that ends in a question
   * there is a question nobody can answer — the same defect that shipped in the
   * scene beat and in ③A. Undefined means "not applicable".
   */
  followUpFollows?: boolean;
  /**
   * ③C — the free-talk budget is spent, so this reply is the last one.
   *
   * Passed in rather than left to the model: it is the flow that knows there is
   * no box after this, and a question asked here would join the others nobody
   * could answer.
   */
  freeTalkLastTurn?: boolean;
  /**
   * This is the SECOND attempt: the first reply asked something forbidden.
   *
   * Passed rather than folded into the step instruction so the corrective line
   * appears only when it is earned — every ordinary turn would otherwise carry
   * a paragraph about a mistake that had not happened.
   */
  retryAfterBannedQuestion?: boolean;
  /** This is the SECOND attempt: the first reply parroted the reader back. */
  retryAfterEcho?: boolean;
  /**
   * STORY_TALK — replies this conversation may still run AFTER this one. Zero
   * means this reply is the last and must ask nothing: a question with no box
   * under it has been this feature's recurring bug.
   */
  storyRoundsLeft?: number | null;
  /**
   * STORY_TALK — how many EARLIER sessions filed a line about the same habit
   * inside the pattern window. Counted by the server from the reader's own
   * rows; the prompt names the pattern only when this is set, and the model
   * never decides on its own that something "keeps happening".
   */
  storyRecurringSessions?: number | null;
  /** STORY_TALK on a low day — no probing question, shorter, gentler. */
  storyGentle?: boolean;
  /**
   * Luồng 1 — how the reader asked to be addressed (bạn · anh · chị · em · a
   * name). Only the model's lines carry it for now; the fixed lines still say
   * "bạn".
   */
  address?: string | null;
  /** Luồng 1 — `practice` readers asked for short replies. */
  readerStyle?: string | null;
  /**
   * THẺ NHỚ — tất cả những gì Coach biết về người này, trong một ngân sách cố
   * định (`MEMORY_CARD_MAX_CHARS`). Dựng sẵn ở lúc cô đọng, không dựng lại mỗi
   * lượt; xem `buildMemoryCard`.
   *
   * Thay `readerMemory` cũ, thứ được dựng lại từ bốn query mỗi lượt và lớn dần
   * theo lịch sử. Vẫn là thứ để NỐI VÀO, không phải dữ kiện để đọc lại.
   */
  readerCard?: string | null;
  /**
   * Chữ NGUYÊN VĂN người ta đã nói, tìm được vì họ vừa hỏi thẳng về quá khứ
   * ("còn nhớ mình từng kể…").
   *
   * Chỉ có mặt ở lượt có câu hỏi loại đó — xem `looksLikeRecallQuestion`. Thẻ
   * nhớ là bản cô đọng nên không trả lời được câu hỏi cụ thể; khối này trả.
   */
  readerRecall?: string | null;
  /**
   * ĐUÔI của phiên liền trước, cũ trước mới sau — xem `PRIOR_TAIL_LINES`.
   *
   * Khác `readerCard` ở chỗ đây là chữ NGUYÊN VĂN hai bên đã nói, không phải
   * bản cô đọng. Từ 2026-09-17 nó chỉ còn mấy dòng cuối chứ không phải 30 dòng:
   * thứ thẻ nhớ không thay được chỉ là "vừa nói ở trên" của một mạch chưa xong,
   * còn lại đã nằm trong thẻ. Ba mươi dòng raw là cách đắt nhất để nhớ, và là
   * cách lớn dần theo lịch sử.
   */
  priorTranscript?: Array<{ role: 'user' | 'coach'; text: string }> | null;
  /**
   * Điều CHÍNH USER đã khai với app ở onboarding — nghề, mục tiêu, rào cản,
   * cách học. Trước đây chỉ đi vào prompt SINH CẢNH, nên hỏi "tôi làm nghề gì"
   * thì Coach trả lời trung thực là không biết.
   */
  readerFacts?: string | null;
}

/** ②A — the commitment being checked in on, in the reader's own words. */
export interface CoachPlanQuote {
  context: string;
  action: string;
}

/** The closing line of a Home session — "câu chốt", ≤20 words, never a question. */
export interface CoachClosingLineResult {
  line: string;
}

/**
 * A plain reflective reply.
 *
 * One field, and that is the point: at every ordinary telling step the model's
 * entire job is to say something human and hand control straight back. It does
 * not decide what happens next — the state machine already knows.
 */
export interface CoachReflectResult {
  reply: string;
  /**
   * Two answers the reader could tap instead of typing.
   *
   * Generated with the reply rather than canned per step, because a canned one
   * cannot be right: the design's own samples ("the Tuesday meeting, I had a
   * different view and sat on it") only make sense for the habit its prototype
   * happens to be about. A suggestion that does not fit what is being discussed
   * is worse than an empty box — it tells the reader this thing is not
   * listening.
   *
   * They exist to lower the cost of the first word. Someone looking at a blank
   * field after being asked something hard closes the sheet.
   */
  samples: string[];
  /**
   * The reply that CLOSES a practice scene also names what the reader could
   * do next time in that moment — the lesson's move, or their own answer when
   * it already was a real action — and when. Both pre-fill the commitment form
   * (still theirs to edit). Null everywhere else, and null when nothing honest
   * can be named: an avoidant answer must not become "the plan".
   */
  nextMove?: string | null;
  nextMoment?: string | null;
}

/**
 * ⑦ — the two-column draft, built ONLY from lines the reader already said.
 *
 * `lines` are candidate rows for the left column ("what happened"). The service
 * checks every one against the transcript before showing it; anything the model
 * invented is dropped rather than corrected, because a draft that puts words in
 * the reader's mouth destroys the exercise.
 */
export interface CoachTwoColsResult {
  reply: string;
  lines: string[];
}

/**
 * STORY_TALK — the reply, and what kind of line it answered.
 *
 * One call for both on purpose: the owner has said twice that a second call
 * per turn is money and waiting ("tốn tiền", "đang đợi call"), and the kind is
 * a by-product of writing the reply, not a separate judgement.
 */
/** What the generator is given about one keypoint, in the reader's language. */
export interface CoachQuizGenerationInput {
  locale: string;
  keypointTitle: string;
  /** The keypoint's own text: theory paragraphs, and the authored questions as material. */
  material: string;
  count: number;
  /** Questions already stored for this keypoint — write different ones. */
  avoid: string[];
}

export interface CoachQuizGenerationResult {
  questions: Array<{
    question: string;
    options: string[];
    correctIndex: number;
    explanation?: string | null;
  }>;
}

export interface CoachStoryTalkResult {
  kind: CoachStoryKind;
  reply: string;
  /** The reader asked to be called something else — the word, as they said it. */
  newAddress?: string | null;
}

/**
 * Luồng 4 — the verdict on an answer to the Home scene.
 *
 * `onTrack` routes the machine (card, or the retry offer); `reply` is either
 * one specific piece of praise or a sample line plus one line of why. The
 * judge is the design's named exception to "không chấm" and runs under its
 * own rules, not CORE_RULES — see `buildSceneJudgePrompt`.
 */
export interface CoachSceneJudgeResult {
  /** False when the line did not attempt the question — see ENGAGEMENT_RULE. */
  engaged: boolean;
  onTrack: boolean;
  reply: string;
}

/**
 * Luồng 4 — the other person answering, mid-scene. One call does both jobs:
 * reading how the reader's line sits (`posture`) and writing what the other
 * person says back. Splitting them would cost a second round trip for nothing.
 */
/**
 * One named way forward, offered after the other person has reacted.
 *
 * The three of them are the practice's whole teaching move: a reader who only
 * ever sees a blank box learns whether their sentence worked, but never that
 * there were three different things they could have been doing. Named side by
 * side, the choice itself is the lesson.
 *
 * `key` is what the reader may type instead of a sentence ("A"). It is resolved
 * back to `text` server-side, so a one-letter answer is still scored as the
 * approach it stands for rather than as the letter.
 */
export interface CoachSceneOption {
  /** "A" · "B" · "C" — the shorthand the reader may answer with. */
  key: string;
  /** The approach's NAME, 2–4 words. */
  label: string;
  /** A short line in that approach's voice — concrete, never a finished answer. */
  text: string;
}

export interface CoachSceneReactResult {
  /** False when the line did not attempt the question — see ENGAGEMENT_RULE. */
  engaged: boolean;
  posture: CoachScenePosture;
  /** What the other person says, in their voice. */
  reply: string;
  /** The name the app labels that bubble with — the person in the scene. */
  speaker: string;
  /**
   * How the reader's line landed, in the speaker's own body — "An thở dài, vai
   * vẫn gồng lên:". Written to be read BEFORE the spoken line, and it carries
   * the attribution the `speaker` label used to: once a turn also names three
   * ways forward, the bubble label cannot be used (the app stamps it on every
   * paragraph of the reply, which would put the options in the speaker's
   * mouth). Empty is tolerated and the composer falls back to "Name:".
   */
  gesture: string;
  /**
   * Ways the reader could answer this reaction, named. Empty when the model
   * gave none usable, and the turn then reads exactly as it did before options
   * existed — a reaction and a blank box.
   */
  options: CoachSceneOption[];
}

/**
 * The memory extraction's input: one finished conversation, and what is
 * already known, so the model reinforces existing rows (by id) instead of
 * minting duplicates.
 */
export interface CoachMemoryExtractionInput {
  locale: string;
  transcript: Array<{ role: 'user' | 'coach'; text: string }>;
  memories: Array<{ id: string; type: string; content: string; status: string }>;
  goals: Array<{ id: string; goal: string; status: string }>;
  /** Thẻ nhớ hiện tại — ngữ cảnh gọn, để không phải đổ cả hồ sơ vào prompt. */
  card?: string | null;
  /**
   * Bao nhiêu dòng ĐẦU của `transcript` là ngữ cảnh đã cô đọng ở lần trước.
   *
   * Chúng có mặt để đoạn mới không mở đầu bằng một câu trả lời không có câu
   * hỏi. Prompt phải nói rõ ranh giới, không thì model "nghe lại" chuyện cũ và
   * `evidenceCount` tăng oan — cả tầng nhớ dựa vào con số đó.
   */
  alreadyRead?: number;
  /**
   * Phiên đã kết: xin thêm mảnh chủ đề cho câu chào lần mở sau.
   *
   * Gộp vào call cô đọng chứ không gọi riêng, vì câu chào phải được viết TRƯỚC,
   * off-clock — đường `open` đang mất 1–5s và không được thêm gì vào đó.
   */
  wantGreeting?: boolean;
}

/** What one conversation adds. Every list may be empty — most sessions add little. */
export interface CoachMemoryExtraction {
  memories: Array<{
    id?: string | null;
    type: string;
    content: string;
    confidence: number;
    status?: string | null;
  }>;
  goals: Array<{ id?: string | null; goal: string; status?: string | null; progress?: number | null }>;
  episodes: Array<{ situation: string; emotion?: string | null; insight?: string | null }>;
  progress: Array<{ goal: string; action: string; result: string }>;
  /** Mảnh chủ đề cho câu chào mở phiên sau, ≤`MEMORY_GREETING_TOPIC_MAX_CHARS`. */
  greetingTopic?: string | null;
}

/**
 * Luồng 2/3 — the talk after a keypoint, in four spoken moments. `summary`:
 * the part just learned, ≤60 words, ending in ONE question — scope is the
 * keypoint mid-lesson, the whole lesson at its last keypoint. `reply`: after
 * the reader's answer, ≤25 words; ONE of the three places advice is allowed —
 * about the move, never the person. `quizBack`: the wrong answers with their
 * right ones, ≤35 words, never a number; followed by one specific praise ≤25.
 * `recapWhy`: ≤25 words on the lesson they said stayed with them, claiming
 * nothing about its content.
 */
export interface CoachLessonTalkInput {
  mode: 'summary' | 'reply' | 'quizBack' | 'recapWhy' | 'free';
  scope?: 'keypoint' | 'lesson';
  title?: string | null;
  /** The theory text the summary is drawn from (mode summary). */
  body?: string | null;
  /** Mode quizBack: every question with its outcome. */
  results?: Array<{ question: string; passed: boolean; chosen?: string; correct?: string }>;
  /**
   * Mode free: the skill the course teaches. It is the FENCE for the follow-up
   * answers — they may go past the lesson's own text, but not past this.
   */
  skillTitle?: string | null;
  /** Mode recapWhy: the lesson title they picked, and the course. */
  lessonTitle?: string | null;
  courseTitle?: string | null;
}

/**
 * Luồng 5 — the in-chat quiz's two spoken moments. `wrong`: the answer was
 * not the right one — say which was and one line of why, about the content
 * ("chấm về nước đi"). `summary`: the run is over — one sentence on the
 * strongest spot and one on the one still slipping, and NEVER the score.
 */
export interface CoachQuizFeedbackInput {
  mode: 'wrong' | 'summary';
  /** The question just answered (mode wrong). */
  question?: string;
  chosen?: string;
  correct?: string;
  explanation?: string | null;
  /** Every question with its outcome (mode summary). */
  results?: Array<{ question: string; passed: boolean; correct: string }>;
}

/**
 * ③C — quietly matching a free-form story to a habit the reader already has,
 * or to none.
 *
 * `habitId` MUST come from the candidate list handed in. The service verifies
 * it anyway: a hallucinated id would send the reader to a habit that is not
 * theirs, which is both a bug and a small betrayal.
 */
export interface CoachHabitMatchResult {
  reply: string;
  habitId: string | null;
  confidence: number;
  /**
   * ③C — "I have heard enough to point this person somewhere."
   *
   * False means the reply ended in a question and the conversation should carry
   * on. It exists because the alternative is a fixed number of turns for
   * everybody, and the person who opens with a paragraph should not be
   * interviewed twice more to reach the same place.
   */
  enough: boolean;
}

/**
 * A spoken turn, turned into the reader's own words.
 *
 * The audio itself is never stored — the design is explicit that speech becomes
 * text and the recording is dropped. This returns only the text, and the bytes
 * exist for the length of one request.
 */
export interface CoachTranscriptResult {
  text: string;
}

/** One cached short situation: a scene, its script, and the ways into it. */
export interface CoachSituationResult {
  prompt: string;
  /**
   * The same scene told about "một người" for a low-mood day, ending in
   * "Nếu là người đó, bạn …?". Null when the model failed to write it — the
   * day then simply gets the second-person telling.
   */
  promptThirdPerson: string | null;
  /**
   * Chặng hai — the other person reacts, same people and place, one notch
   * harder, ending in a question. Null = one-stage scene (nhịp 4/5 skipped).
   */
  promptStage2: string | null;
  promptStage2ThirdPerson: string | null;
  /** Two ways in, cached with the scene so they stay the same for everyone. */
  samples: string[];
  /**
   * The three named ways to answer stage one, written WITH the scene.
   *
   * Cached rather than asked for when the reader arrives: the scene row already
   * serves every later reader of its slot, so the opening's approaches cost no
   * call of their own. Same shape as [CoachSceneOption] at a reaction, and
   * rendered the same way — as TEXT, never as pills. Empty on legacy rows and
   * whenever the model gave nothing usable, and the opening then reads exactly
   * as it did before this existed.
   */
  openingOptions: CoachSceneOption[];
  /**
   * The ordered probe intents the Coach walks after the first answer — one or
   * two, each a distinct thing to draw out. Length decides how many turns the
   * scene takes.
   */
  beats: string[];
  /** What the other person says at each beat, index-aligned with `beats`. */
  beatLines: string[];
  /** Who those lines belong to, as the scene names them. Null when solo. */
  counterpart: string | null;
  /** The lesson this scene is built to make — landed in the closing reply. */
  takeaway: string | null;
  /** The concrete move for this moment — the reminder's default pre-fill. */
  goodMove: string | null;
}

/** One criterion of a rubric, as the skill defines it. */
export interface CoachRubricCriterion {
  key: string;
  label: string;
}

/** What the Coach scored on one criterion. */
export interface CoachSceneScoreCriterion {
  key: string;
  /** 0–10, see `SCENE_SCORE_MAX`. */
  score: number;
  /** One short clause naming what in their answer earned this. */
  note: string;
}

/**
 * Tầng 4 "Reflect" — the rubric read on how the reader handled one scene.
 *
 * This is the one place in the feature where the Coach assesses the reader, and
 * it exists because the product owner asked for it (2026-08-27): "AI Coach đánh
 * giá" with a score, a tip, and a better phrasing to borrow. It runs ONCE, after
 * the scene is over, on the reader's answers taken together — never mid-scene,
 * where a grade would stop them talking.
 */
export interface CoachSceneScoreResult {
  criteria: CoachSceneScoreCriterion[];
  /** The one thing they did well, in their own scene's terms. */
  strength: string;
  /** The one thing to sharpen. Never a verdict on them, always about the move. */
  improve: string;
  /** The design's "Coach tip" — one transferable sentence. */
  tip: string;
  /**
   * A better way to say what they were trying to say, ready to borrow.
   *
   * Their words rewritten, not a script to memorise — the design's "💡 Có thể
   * nói: …". Empty when their own answer already was the strong version.
   */
  betterPhrasing: string;
}

/**
 * ⑧ — the risk read on one line of user text.
 *
 * `level` is advisory; `risk` is the switch. Kept separate so the threshold can
 * move without every caller re-learning the scale.
 */
export interface CoachRiskResult {
  risk: boolean;
  level: 'none' | 'low' | 'high';
}

/** ⑦ nhịp 2's gate. One decision: may this question reach the reader? */
export interface CoachQuestionVerdict {
  banned: boolean;
}

export interface CoachSituationInput {
  locale: string;
  variant: string;
  habitTitle: string;
  /** Keypoint prose the habit is attached to. Grounding, so scenes are not invented whole. */
  habitMaterial?: string | null;

  /** What the habit is and when it applies — the editor's own sentence. */
  habitDescription?: string | null;
  /** Moments the habit typically comes up, from the habit's `contexts`. */
  habitContexts?: string[];
  /** The one moment THIS scene must happen in — one of `habitContexts`, by slot. */
  sceneContext?: string | null;
  /**
   * This slot is a FREE one: invent a moment for the habit instead of taking an
   * authored one (owner 2026-09-05, "các tình huống hiện tại đang hơi cứng chỉ
   * loanh quanh 1 vài tình huống").
   *
   * Distinct from simply leaving `sceneContext` null, which lets the model PICK
   * from `habitContexts` — the very thing that produced four scenes about one
   * moment. Here the authored list is shown as ground already covered.
   */
  inventMoment?: boolean;

  /**
   * Register EXAMPLES for the setting — what "an ordinary moment with a small
   * cost" looks like, written for a student reader. The actual setting is
   * INVENTED per scene from habit × reader: "bối cảnh vẫn gắn chặt chẽ theo
   * habit, nhưng phụ thuộc vào độ tuổi, tính cách của từng user" (owner,
   * 2026-08-28). Never copied.
   */
  settingExamples?: string[];

  /**
   * The corner of life this reader's own words point at (nhóm bối cảnh —
   * công việc / gia đình / bạn bè / học tập / dịch vụ), as a preference for
   * where the invented setting lives. Null when they have written nothing.
   */
  settingGroup?: string | null;

  /**
   * The difficulty this scene is being written at, 1–5, and what that rung
   * MEANS for this skill (from the habit's `ladder`).
   *
   * Levels used to mean only "more pressure", which gave every skill the same
   * five shapes. The rung is the skill's own progression — "đối phương kích
   * thêm lần thứ hai" for an impulse habit is nothing like "cả nhóm vẫn đang
   * ngồi làm" for a rest habit — and the scene is built from it.
   */
  sceneLevel?: number | null;
  sceneLevelShape?: string | null;

  /** Who the scene is for — a sentence from COACH_AUDIENCE_HINT, or null. */
  audienceHint?: string | null;

  /** The reader's onboarding goal, in their own language. Flavour, never named. */
  goalLabel?: string | null;

  /** The previous attempt blew the word ceiling; say so and ask again. */
  retryTooLong?: boolean;

  /**
   * The previous attempt came back as a one-line caption; say so and ask again.
   *
   * The counterpart of `retryTooLong`, and the one that earns its keep: a scene
   * too thin to practise in is the defect this feature was rewritten to fix.
   */
  retryTooShort?: boolean;

  /**
   * The previous attempt's second stage NARRATED the reader's answer ("Bạn vừa
   * nhắn hỏi…") — the one thing it may never do, since it is written before
   * they answer. Say so and ask again.
   */
  retryStage2Assumed?: boolean;

  /**
   * The previous attempt's scene ended on a statement instead of a question.
   * The whole two-beat flow hangs off that question; say so and ask again.
   */
  retryNoQuestion?: boolean;

  /**
   * Chỉ viết những gì người đọc thấy khi cảnh MỞ RA.
   *
   * Chặng hai, bài học rút ra và nước đi tốt chiếm 39% đầu ra mà không cái nào
   * cần lúc đó — chúng được viết ở cú thứ hai, chạy nền trong lúc người đọc
   * còn đang đọc cảnh. Xem `SITUATION_OPENING_RESPONSE_SCHEMA`.
   */
  openingOnly?: boolean;

  /**
   * This input IS the rewrite — the one allowed for the whole scene.
   *
   * The four flags above say WHAT was wrong and are read by the prompt, which
   * appends a rejection paragraph per flag; this one says the second attempt
   * has been spent, and it is what stops them from being spent one at a time.
   * Whatever the rewrite still gets wrong is repaired in code rather than by a
   * third call: the reader is waiting on this.
   */
  retried?: boolean;

  /**
   * Scenes already in this key's pool. The new one must be a different
   * moment — different setting, people and trigger — not a paraphrase.
   */
  avoidPrompts?: string[];
}

/**
 * The provider boundary.
 *
 * Nothing outside `ai/` names Gemini, exactly as `LessonGenerator` does it for
 * the import feature. Five narrow tasks rather than one chat method, because
 * each has its own response schema and its own validation — and because a
 * single open-ended "talk to the reader" call is precisely the design this
 * feature rejected.
 */
/** Ba trường của pha hai — xem `SITUATION_REST_RESPONSE_SCHEMA`. */
export interface CoachSituationRest {
  promptStage2: string | null;
  takeaway: string | null;
  goodMove: string | null;
}

export abstract class CoachAi {
  /** False when no key is configured — checked before a session is offered. */
  abstract isConfigured(): boolean;

  abstract reflect(context: CoachTurnContext): Promise<CoachReflectResult>;

  abstract draftTwoCols(
    context: CoachTurnContext,
  ): Promise<CoachTwoColsResult>;

  /**
   * T3's conversation: reply to the line and say what kind of line it was.
   *
   * The kind routes the machine (`CoachStoryKind`), so a provider that cannot
   * classify must still answer — callers treat a missing kind as NORMAL.
   */
  abstract talkStory(context: CoachTurnContext): Promise<CoachStoryTalkResult>;

  /**
   * Luồng 4 — judge the reader's line against the scene and the habit.
   *
   * `retry` marks the second (last) try: the reply then knows the reader has
   * already heard one sample line, and must not repeat it.
   */
  abstract judgeScene(
    context: CoachTurnContext,
    scene: { prompt: string; retry: boolean },
  ): Promise<CoachSceneJudgeResult>;

  /**
   * Luồng 4 — the other person's reaction to what the reader just said, and
   * how that line sat in the scene. The scene is not scored here.
   */
  abstract reactScene(
    context: CoachTurnContext,
    input: { scene: string; said: string; habitTitle?: string | null },
  ): Promise<CoachSceneReactResult>;

  /** Luồng 5 — one line of quiz feedback; see `CoachQuizFeedbackInput`. */
  abstract quizFeedback(
    context: CoachTurnContext,
    quiz: CoachQuizFeedbackInput,
  ): Promise<{ reply: string }>;

  /**
   * Luồng 5 — write a quiz about ONE keypoint from its own teaching material.
   *
   * The catalogue's own exercises come in five kinds and a chat can only ask
   * one of them, so the Coach writes its own (owner, 2026-09-04). Generated
   * once and stored; this is not a per-turn call.
   */
  abstract makeQuiz(input: CoachQuizGenerationInput): Promise<CoachQuizGenerationResult>;

  /** The memory layer: what a finished conversation adds to what is known. */
  abstract extractMemory(
    input: CoachMemoryExtractionInput,
  ): Promise<CoachMemoryExtraction>;

  /** Luồng 2/3 — one spoken moment of the talk after a keypoint; see `CoachLessonTalkInput`. */
  abstract lessonTalk(
    context: CoachTurnContext,
    input: CoachLessonTalkInput,
  ): Promise<{ reply: string; engaged: boolean }>;

  abstract matchHabit(
    context: CoachTurnContext,
    candidates: Array<{ id: string; title: string }>,
  ): Promise<CoachHabitMatchResult>;

  /** Pha hai của một cảnh — xem `CoachSituationRest`. */
  abstract completeSituation(
    input: CoachSituationInput,
    scene: { prompt: string; counterpart: string | null },
  ): Promise<CoachSituationRest>;

  abstract generateSituation(
    input: CoachSituationInput,
  ): Promise<CoachSituationResult>;

  abstract classifyRisk(
    text: string,
    locale: string,
  ): Promise<CoachRiskResult>;

  /**
   * Score one finished scene against the skill's rubric.
   *
   * Separate from `reflect` because it is a different act with a different
   * failure mode: a reply that grades mid-conversation is the bug this feature
   * spent a month removing, so the assessor never runs while the scene is open.
   * Returns null-ish content rather than throwing when the rubric is empty —
   * callers skip the card, and the flow goes to the commitment as before.
   */
  abstract scoreScene(
    context: CoachTurnContext,
    rubric: CoachRubricCriterion[],
    scene: { prompt: string; takeaway?: string | null; goodMove?: string | null },
  ): Promise<CoachSceneScoreResult>;

  /**
   * ⑦ nhịp 2 — does this line ask a question the design forbids?
   *
   * Separate from `reflect` on purpose: a model cannot be trusted to police the
   * sentence it just wrote, and the diagram asks for a classifier rather than a
   * prompt line precisely because the prompt line kept losing.
   */
  abstract classifyQuestion(
    reply: string,
    locale: string,
  ): Promise<CoachQuestionVerdict>;

  abstract transcribe(
    audio: Buffer,
    mimeType: string,
    locale: string,
  ): Promise<CoachTranscriptResult>;

  /**
   * The closing line, built around the commitment the reader just made and the
   * time they asked to be reminded. Falls back to a fixed line on failure.
   */
  abstract closingLine(
    context: CoachTurnContext,
    plan: CoachPlanQuote,
    reminder: { enabled: boolean; hour: number; minute: number } | null,
  ): Promise<CoachClosingLineResult>;
}

/**
 * Thrown when the provider itself failed.
 *
 * Callers do not surface this to the reader — see the fallback in
 * `CoachTurnService`. Someone mid-sentence about something hard must never meet
 * an error screen, so a provider failure degrades to a neutral acknowledgement
 * and the flow continues.
 */
export class CoachAiError extends Error {
  /** The provider was busy, not wrong — worth exactly one more attempt. */
  readonly retryable: boolean;

  /**
   * How long the provider ASKED us to wait, in milliseconds, or null.
   *
   * A 429 body carries its own number ("Please retry in 23.6s") and it is the
   * only trustworthy one: anything sooner earns a second refusal.
   */
  readonly retryAfterMs: number | null;

  /** Our own abort fired — the provider never answered at all. */
  readonly timedOut: boolean;

  /**
   * The model refused `thinkingConfig` rather than the request.
   *
   * Its own flag rather than a plain 400 because the answer is different: not
   * "give up", and not "wait and try again", but "ask for less and go straight
   * back". The conversational model is an admin setting, so this is reachable
   * from a dropdown.
   */
  readonly unsupportedThinking: boolean;

  constructor(
    message: string,
    options: {
      retryable?: boolean;
      retryAfterMs?: number | null;
      timedOut?: boolean;
      unsupportedThinking?: boolean;
    } = {},
  ) {
    super(message);
    this.name = 'CoachAiError';
    this.retryable = options.retryable ?? false;
    this.retryAfterMs = options.retryAfterMs ?? null;
    this.timedOut = options.timedOut ?? false;
    this.unsupportedThinking = options.unsupportedThinking ?? false;
  }
}
