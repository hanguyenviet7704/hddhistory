import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  ValidateNested,
  IsBoolean,
  IsEnum,
  IsIn,
  Matches,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

import {
  COACH_MAX_INPUT_LENGTH,
  COACH_MOOD_MAX,
  COACH_MOOD_MIN,
  RATING_NOTE_MAX_LENGTH,
} from '../../../shared/coach.constant';
import {
  CoachEntry,
  CoachPersona,
  CoachScript,
} from '../../../shared/coach.enum';
import { CoachPlanAnswer, CoachReminderDays } from '../../plan/enum/plan.enum';
import { CoachRatingChip, CoachRatingThumb } from '../../rating/enum/rating.enum';

/**
 * The event kinds a client may send.
 *
 * Mirrors the state machine's own event union. Sent explicitly rather than
 * inferred from which fields are populated, so a malformed turn is a validation
 * error rather than a wrong guess about what the reader did.
 */
export enum CoachTurnEventKind {
  MOOD = 'mood',
  PICK_NEW = 'pickNew',
  /** RETIRED with the Nav Habit door. */
  PICK_HABIT = 'pickHabit',
  /** RETIRED as a step — the voice is set through `PATCH sessions/:id/persona`. */
  PERSONA = 'persona',
  /** RETIRED: no length question any more. */
  TIME = 'time',
  TEXT = 'text',
  /** STORY — "hoặc bỏ qua". */
  SKIP = 'skip',
  INTENT = 'intent',
  /** RETIRED. */
  CHECKIN = 'checkin',
  /** DEPTH — `deep` true for "Kể sâu hơn", false for "Chỉ ghi lại thôi". */
  DEPTH = 'depth',
  /** RETIRED (doc v4): nhịp 4 no longer asks them to say it again. */
  SCENE_AGAIN = 'sceneAgain',
  /** SCENE_MET — nhịp 6, `met` true for "Gặp rồi", false for "Chưa gặp". */
  SCENE_MET = 'sceneMet',
  /** HUB — the reader picked a task by name (`task`). */
  TASK = 'task',
  /** HUB — "Mình dừng ở đây": start the closing sequence. */
  STOP = 'stop',
  /**
   * Thanh habit — "đổi": list the reader's own kho and let them pick again.
   *
   * Valid at any step, and never refused: "nút này thuộc quyền của user —
   * không bao giờ được ẩn theo điều kiện".
   */
  CHANGE_HABIT = 'changeHabit',
  /** SHRINK — `accept` true takes the smaller commitment (edited fields optional). */
  SHRINK = 'shrink',
  /** CONTEXT_ASK — `keep` true leaves the context alone. */
  CONTEXT = 'context',
  /** INVITE — `accept` true opens the one situation. */
  INVITE = 'invite',
  /** PLAN_ASK — `accept` true opens the commitment form. */
  /** The rubric card — `retry` true replays the same scene once. */
  SCENE_SCORE = 'sceneScore',
  /** Luồng 5 — QUIZ_IN_CHAT: the option the reader tapped. */
  QUIZ_ANSWER = 'quizAnswer',
  /** Luồng 2/3 — a generic chip pick for the talk/recap steps: `value`. */
  PICK = 'pick',
  /** Luồng 2 — the keypoint quiz ran on its own screen and came back with results. */
  QUIZ_DONE = 'quizDone',
  PLAN_ASK = 'planAsk',
  PLAN = 'plan',
  SCHEDULE = 'schedule',
  LOOP = 'loop',
  /** COURSE_CARD — `courseAction` open · save · close. */
  COURSE = 'course',
  MOOD_END = 'moodEnd',
  RATING = 'rating',
  /** NEXT_SESSION — `again` true loops back to the story. */
  NEXT_SESSION = 'nextSession',
  ESCAPE = 'escape',
  /** ⑤ — "Không đúng với mình". Throws the whole draft away. */
  REJECT_DRAFT = 'rejectDraft',
  /** Nhịp 5 is read-only; one tap moves past it. */
  ACK = 'ack',
}

/** The three ways out of the course card (design v2). */
export enum CoachCourseAction {
  /** "Đi tới khoá học" → one short line, then the app leaves for the Roadmap. */
  OPEN = 'open',
  /** "Lưu để sau" → the course goes to Để dành, and the tail goes on. */
  SAVE = 'save',
  /** "Bỏ qua" → the tail goes on. */
  CLOSE = 'close',
  /**
   * "Luyện cảnh khó hơn" → a NEW scene about the same habit, one rung up the
   * skill's ladder, instead of ending the session.
   *
   * Lives here rather than as its own event kind because the card is where the
   * two ways forward sit side by side — study the course, or practise again
   * harder — and the reader is choosing between them, not doing two things.
   */
  HARDER = 'harder',
}

/** The voice, changeable at any step — a header control, never a step of its own. */
export class SetCoachPersonaDto {
  @ApiProperty({ enum: CoachPersona })
  @IsEnum(CoachPersona)
  persona: CoachPersona;
}

export class OpenCoachSessionDto {
  @ApiProperty({ enum: CoachEntry })
  @IsEnum(CoachEntry)
  entry: CoachEntry;

  @ApiPropertyOptional({ description: '① the lesson just finished.' })
  @IsOptional()
  @IsString()
  lessonId?: string;

  @ApiPropertyOptional({ description: 'Luồng 2 — the keypoint just finished: opens the talk about it.' })
  @IsOptional()
  @IsString()
  keypointId?: string;

  @ApiPropertyOptional({ description: 'Luồng 3 — the course just finished, with `recap: true`.' })
  @IsOptional()
  @IsString()
  courseId?: string;

  @ApiPropertyOptional({ description: 'Luồng 3 — open the course recap instead of the talk.' })
  @IsOptional()
  @IsBoolean()
  recap?: boolean;

  @ApiPropertyOptional({
    description: '② the habit, when opened from its own detail screen.',
  })
  @IsOptional()
  @IsString()
  habitId?: string;

  @ApiPropertyOptional({
    description:
      'App language. The Coach replies in this, whatever language the reader writes in.',
  })
  @IsOptional()
  @IsString()
  locale?: string;

  @ApiPropertyOptional({
    description:
      "Minutes east of UTC. Decides the reader's local day for the mood-once-a-day rule.",
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  tzOffsetMinutes?: number;
}

export class GetCoachBubbleDto {
  @ApiPropertyOptional({ enum: CoachEntry })
  @IsOptional()
  @IsEnum(CoachEntry)
  entry?: CoachEntry;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  lessonId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  tzOffsetMinutes?: number;
}

/**
 * One turn.
 *
 * Flat rather than a discriminated union: class-validator handles a flat shape
 * with optional fields cleanly, and the state machine rejects any event that
 * does not belong to the current step anyway — so a client that sends
 * `kind: 'mood'` at the commitment step gets a clean refusal rather than a
 * half-applied turn.
 */
/** Luồng 2 — one question of the keypoint quiz, as the reader answered it. */
export class CoachQuizResultDto {
  @ApiProperty()
  @IsString()
  exerciseId: string;

  @ApiProperty()
  @IsBoolean()
  passed: boolean;

  @ApiPropertyOptional({ description: 'The question, as text.' })
  @IsOptional()
  @IsString()
  question?: string;

  @ApiPropertyOptional({ description: 'What they chose, as text.' })
  @IsOptional()
  @IsString()
  chosen?: string;

  @ApiPropertyOptional({ description: 'The right answer, as text.' })
  @IsOptional()
  @IsString()
  correct?: string;
}

/** Luồng 6 — the plea's answer: stayed (true) or closed anyway (false). */
export class CoachExitDto {
  @ApiProperty({ description: 'True when the reader chose ⟨Ở lại một câu⟩.' })
  @IsBoolean()
  stayed: boolean;

  /**
   * Why they left, from the sheet shown after ⟨Vẫn đóng⟩ — the rating toast's
   * own chips, asked about a different thing. Absent when they skipped it, and
   * always absent when `stayed` is true: there is nothing to explain.
   */
  @ApiPropertyOptional({ enum: CoachRatingChip, isArray: true })
  @IsOptional()
  @IsArray()
  @IsEnum(CoachRatingChip, { each: true })
  chips?: CoachRatingChip[];

  @ApiPropertyOptional({ description: '"Khác" — the reader\'s own words.' })
  @IsOptional()
  @IsString()
  @MaxLength(RATING_NOTE_MAX_LENGTH)
  note?: string;
}

export class CoachTurnDto {
  @ApiProperty({ enum: CoachTurnEventKind })
  @IsEnum(CoachTurnEventKind)
  kind: CoachTurnEventKind;

  @ApiPropertyOptional({ minimum: COACH_MOOD_MIN, maximum: COACH_MOOD_MAX })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(COACH_MOOD_MIN)
  @Max(COACH_MOOD_MAX)
  mood?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  habitId?: string;

  @ApiPropertyOptional({ enum: CoachPersona })
  @IsOptional()
  @IsEnum(CoachPersona)
  persona?: CoachPersona;

  @ApiPropertyOptional({ enum: CoachScript })
  @IsOptional()
  @IsEnum(CoachScript)
  script?: CoachScript;

  @ApiPropertyOptional({ enum: CoachPlanAnswer })
  @IsOptional()
  @IsEnum(CoachPlanAnswer)
  answer?: CoachPlanAnswer;

  @ApiPropertyOptional({ description: '③B — has the habit come up recently.' })
  @IsOptional()
  @IsBoolean()
  used?: boolean;

  @ApiPropertyOptional({ maxLength: COACH_MAX_INPUT_LENGTH })
  @IsOptional()
  @IsString()
  @MaxLength(COACH_MAX_INPUT_LENGTH)
  text?: string;

  @ApiPropertyOptional({
    description: 'The words on the chip that was tapped, as the app showed them in its bubble — kept so a reopened sheet can draw the answer again.',
    maxLength: 200,
  })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  label?: string;

  @ApiPropertyOptional({ description: 'The "when" of a commitment, verbatim.' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  planContext?: string;

  @ApiPropertyOptional({ description: 'The "I will" of a commitment, verbatim.' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  planAction?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  reminderEnabled?: boolean;

  @ApiPropertyOptional({ minimum: 0, maximum: 23 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(23)
  reminderHour?: number;

  @ApiPropertyOptional({ minimum: 0, maximum: 59 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(59)
  reminderMinute?: number;

  @ApiPropertyOptional({ enum: CoachReminderDays })
  @IsOptional()
  @IsEnum(CoachReminderDays)
  reminderDays?: CoachReminderDays;

  @ApiPropertyOptional({
    description:
      'SCHEDULE with days=once — the reader-local date to fire on, YYYY-MM-DD.',
  })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  reminderDate?: string;

  @ApiPropertyOptional({ description: 'LOOP — walk another pending commitment.' })
  @IsOptional()
  @IsBoolean()
  keepGoing?: boolean;

  @ApiPropertyOptional({ description: 'DEPTH — "Kể sâu hơn" (true) or "Chỉ ghi lại thôi" (false).' })
  @IsOptional()
  @IsBoolean()
  deep?: boolean;

  @ApiPropertyOptional({
    description:
      'SHRINK / INVITE / PLAN_ASK — the reader took the offer. For SHRINK, `planContext`/`planAction` may carry the edited wording.',
  })
  @IsOptional()
  @IsBoolean()
  accept?: boolean;

  @ApiPropertyOptional({
    description:
      'SCENE_SCORE — "Thử lại tình huống này" (true) replays the same scene once; anything else moves on to the commitment.',
  })
  @IsOptional()
  @IsBoolean()
  retry?: boolean;

  @ApiPropertyOptional({ description: 'CONTEXT — keep the commitment\'s context as it is.' })
  @IsOptional()
  @IsBoolean()
  keep?: boolean;

  @ApiPropertyOptional({ enum: CoachCourseAction, description: 'COURSE — what the reader did with the card.' })
  @IsOptional()
  @IsEnum(CoachCourseAction)
  courseAction?: CoachCourseAction;

  @ApiPropertyOptional({
    description: 'SCENE_MET — nhịp 6: have they been in a situation like this?',
  })
  @IsOptional()
  @IsBoolean()
  met?: boolean;

  @ApiPropertyOptional({
    enum: ['T1', 'T2', 'T3', 'T4', 'checkin', 'quiz', 'summary', 'talkQuiz'],
    description:
      'TASK — which task to run next, from the coordinator. `checkin` and `quiz` are the Habit screen’s two (luồng 5). `summary`/`talkQuiz` are NOT tasks — they are TALK_ASK’s two picks, accepted here only because app builds up to 2026-09-04 send every hub chip as a task; newer builds send them as `pick`.',
  })
  @IsOptional()
  @IsIn(['T1', 'T2', 'T3', 'T4', 'checkin', 'quiz', 'summary', 'talkQuiz'])
  task?:
    | 'T1'
    | 'T2'
    | 'T3'
    | 'T4'
    | 'checkin'
    | 'quiz'
    | 'summary'
    | 'talkQuiz';

  @ApiPropertyOptional({ description: 'CHECKIN — luồng 5: did they do the habit today?' })
  @IsOptional()
  @IsBoolean()
  done?: boolean;

  @ApiPropertyOptional({ description: 'QUIZ_ANSWER — luồng 5: the index of the option tapped.' })
  @IsOptional()
  @IsString()
  quizAnswer?: string;

  @ApiPropertyOptional({ description: 'PICK — luồng 2/3: the chip value (summary/quiz, start/later, continue/later, try/later, a lessonId).' })
  @IsOptional()
  @IsString()
  value?: string;

  @ApiPropertyOptional({
    isArray: true,
    type: CoachQuizResultDto,
    description: 'QUIZ_DONE — luồng 2: one entry per question of the keypoint quiz.',
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CoachQuizResultDto)
  quizResults?: CoachQuizResultDto[];

  @ApiPropertyOptional({
    description:
      'NEXT_SESSION — start a new session in the same sheet. SCENE_AGAIN — answer the same scene again.',
  })
  @IsOptional()
  @IsBoolean()
  again?: boolean;

  @ApiPropertyOptional({
    isArray: true,
    type: Number,
    description: 'SCHEDULE with days=custom — ISO weekdays 1 (Mon) … 7 (Sun).',
  })
  @IsOptional()
  @IsArray()
  @IsInt({ each: true })
  @Min(1, { each: true })
  @Max(7, { each: true })
  reminderCustomDays?: number[];

  @ApiPropertyOptional({ enum: CoachRatingThumb })
  @IsOptional()
  @IsEnum(CoachRatingThumb)
  thumb?: CoachRatingThumb;

  @ApiPropertyOptional({ enum: CoachRatingChip, isArray: true })
  @IsOptional()
  @IsArray()
  @IsEnum(CoachRatingChip, { each: true })
  chips?: CoachRatingChip[];

  @ApiPropertyOptional({ description: 'RATING — the reader declined to answer.' })
  @IsOptional()
  @IsBoolean()
  ratingSkipped?: boolean;

  @ApiPropertyOptional({
    maxLength: RATING_NOTE_MAX_LENGTH,
    description: 'RATING — "Khác": what went wrong, in the reader\'s words.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(RATING_NOTE_MAX_LENGTH)
  ratingNote?: string;

  @ApiPropertyOptional({
    isArray: true,
    type: String,
    description: '⑦ — lines left in the "what happened" column.',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  leftLines?: string[];

  @ApiPropertyOptional({
    isArray: true,
    type: String,
    description: '⑦ — lines dragged into "the real problem".',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  rightLines?: string[];
}

/**
 * A spoken turn, uploaded as base64 rather than multipart.
 *
 * The body-parser ceiling is already 25mb for the bulk-import endpoints (see
 * `main.ts`), and a clip this short lands far inside it — so this rides the
 * same JSON path every other Coach call uses instead of adding a file
 * interceptor for one endpoint.
 */
export class CoachTranscribeDto {
  @ApiProperty({ description: 'Base64 audio. Never stored — see the controller.' })
  @IsString()
  audio: string;

  @ApiPropertyOptional({ example: 'audio/m4a' })
  @IsOptional()
  @IsString()
  mimeType?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  locale?: string;
}

/**
 * "Giải thích đơn giản hơn" on one of the keypoints the closing beat offered.
 *
 * Writes nothing about the reader — it increments a weekly count against the
 * CONTENT, which is what feeds the editorial queue. A keypoint people keep
 * asking to have re-explained is a keypoint that needs rewriting.
 */
export class CoachExplainAgainDto {
  @ApiProperty({ description: 'The keypoint that was not clear.' })
  @IsString()
  keypointId: string;
}
