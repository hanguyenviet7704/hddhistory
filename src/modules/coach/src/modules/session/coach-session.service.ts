import {
  BadRequestException,
  ForbiddenException,
  GoneException,
  Injectable,
  Logger,
  NotFoundException,
  Optional,
} from '@nestjs/common';

import { RequestService } from '@base/service/request.service';
import { ITranslation } from '@utils/interface/common.interface';
import { viewerMarketsForRequest } from '@utils/market-query.util';
import { CourseRepository } from 'src/modules/courses/src/modules/course/repository/course.repository';
import {
  exercisesWithQuestionsOf,
  narratableItemsOf,
} from 'src/modules/courses/src/modules/course-version/content-projection';
import { ContentSource } from 'src/modules/courses/src/modules/course-version/content-source.service';
import { KeypointRepository } from 'src/modules/courses/src/modules/keypoint/repository/keypoint.repository';
import { ExerciseType } from 'src/modules/courses/src/modules/learning-item/enum/learning-item.enum';
import { LearningItemRepository } from 'src/modules/courses/src/modules/learning-item/repository/learning-item.repository';
import { LessonRepository } from 'src/modules/courses/src/modules/lesson/repository/lesson.repository';
import { UserProgressRepository } from 'src/modules/courses/src/modules/progress/src/modules/user-progress/repository/user-progress.repository';
import { SavedCourseRepository } from 'src/modules/courses/src/modules/saved-course/saved-course.repository';
import { HabitLibraryService } from 'src/modules/habit/src/modules/habit-library/habit-library.service';
import { GetListHabitPracticeDto } from 'src/modules/habit/src/modules/habit-practice/dto/habit-practice.dto';
import { SubmitHabitPracticeAttemptDto } from 'src/modules/habit/src/modules/habit-practice/dto/submit-habit-practice-attempt.dto';
import { HabitPracticeService } from 'src/modules/habit/src/modules/habit-practice/habit-practice.service';
import { CheckInUserHabitDto } from 'src/modules/habit/src/modules/user-habit/dto/check-in-user-habit.dto';
import {
  HabitCheckinMethod,
  UserHabitState,
} from 'src/modules/habit/src/modules/user-habit/enum/user-habit.enum';
import { HabitCheckinRepository } from 'src/modules/habit/src/modules/user-habit/repository/habit-checkin.repository';
import { UserHabitRepository } from 'src/modules/habit/src/modules/user-habit/repository/user-habit.repository';
import { UserHabitService } from 'src/modules/habit/src/modules/user-habit/user-habit.service';
import {
  coachRoomFor,
  SocketServerEvent,
} from 'src/modules/socket/src/modules/gateway/interface/socket.interface';
import { SocketGateway } from 'src/modules/socket/src/modules/gateway/socket.gateway';
import { UserRepository } from 'src/modules/user/src/modules/auth/repository/user.repository';
import { OnboardingService } from 'src/modules/user/src/modules/onboarding/onboarding.service';

import {
  COACH_CLOSING_HEARD_KEY,
  COACH_CLOSING_NO_PLAN_KEY,
  COACH_CLOSING_WITH_PLAN_KEY,
  COACH_COURSE_REASON,
  COACH_END_STOP_KEY,
  COACH_FALLBACK_REPLY_KEY,
  COACH_HUB_OPEN_KEY,
  COACH_INTENT_NONE_KEY,
  COACH_INTENT_TELL_DONE_ACK_KEY,
  COACH_INTENT_TELL_MISSED_ACK_KEY,
  COACH_INTENT_TELL_MISSED_KEY,
  COACH_JOT_ACK_KEY,
  COACH_LESSON_INTRO_KEY,
  COACH_NO_PROMPT_KEY,
  COACH_PROMPT_KEY_HUB_BACK,
  COACH_PLAN_SLEPT_KEY,
  COACH_PROBLEM_ACK_KEY,
  COACH_PROMPT_KEY,
  COACH_REDRAFT_KEY,
  COACH_RETRY_ACK_KEY,
  COACH_RETRY_INTRO_KEY,
  COACH_SCENE_ACK_KEY,
  COACH_SCENE_FEELING_ACK_KEY,
  COACH_SCENE_FEELING_THIRD_KEY,
  COACH_SCENE_DONE_KEY,
  COACH_SHRINK_DONE_KEY,
  COACH_SILENT_REASON,
  coachStoryOpenKey,
  COACH_STORY_MORE_KEY,
  COACH_TEASER_FIRST_HABIT_KEY,
  COACH_TEASER_HABIT_KEY,
  COACH_TEASER_HOME_KEY,
  COACH_TEASER_ONBOARD_KEY,
  COACH_TELL_FOLLOW_UP_KEY,
} from './coach-prompt-keys';
import {
  advance,
  afterCard,
  asksForAnotherScene,
  asksForOldScene,
  eligibleTasks,
  firstStepOf,
  guessDepth,
  isClosingStep,
  isOnboardStep,
  ONBOARD_ORDER,
  onboardPosition,
  holdsOnQuestion,
  routeHub,
  SCENE_RESUME_STEPS,
  saysStop,
  storyTalkCap,
  taskOf,
  sceneOnRequest,
  situationRoundsFor,
  storyTalkLeaves,
  CoachEvent,
  CoachMachineContext,
  isEscapeAvailable,
  isSituationProbeStep,
  isInScene,
  isSituationStep,
  requiresAi,
  resolveOpeningStep,
  situationVariantFor,
  uiFor,
} from './coach-state-machine';
import {
  addressVi,
  asksBack,
  fold,
  looksLikeEcho,
  looksLikeNoise,
  splitScene,
} from './coach-text';
import {
  CoachCourseAction,
  CoachTurnDto,
  CoachTurnEventKind,
  GetCoachBubbleDto,
  OpenCoachSessionDto,
} from './dto/coach-session.dto';
import { CoachSessionStatus, CoachTurnRole } from './enum/session.enum';
import {
  CoachBubbleResponse,
  CoachChoice,
  CoachReplayItem,
  CoachSilentResponse,
  CoachTurnResponse,
  CoachUiPayload,
} from './interface/coach-response.interface';
import {
  ICoachQuizItem,
  ICoachQuizResult,
  ICoachSession,
  ICoachShownTurn,
  ICoachTalkQuizResult,
} from './interface/session.interface';
import { CoachSessionRepository } from './repository/coach-session.repository';
import { CoachSession } from './schema/coach-session.schema';
import {
  coachAudienceFromAge,
  CoachAudience,
} from '../../shared/coach-audience';
import {
  COACH_REQUEST_BUDGET_MS,
  detachedFromCoachDeadline,
  withCoachDeadline,
} from '../../shared/coach-deadline';
import { withCoachStream } from '../../shared/coach-stream';
import {
  MEMORY_MIDSESSION_EVERY_LINES,
  PRIOR_TAIL_LINES,
  CHANGE_BLOCK_MIN_WEEKS,
  COACH_LATE_NIGHT_HOUR,
  COACH_MOOD_LOW_VALUES,
  COACH_RETRY_DOOR_ENABLED,
  COACH_SESSION_TTL_HOURS,
  COURSE_STRUGGLE_MIN_BARRIERS,
  LESSON_DOOR_MAX_PENDING_PLANS,
  MAX_INTENT_ROUNDS,
  NO_OCCASION_SLEEP_LIMIT,
  LONG_SCRIPT_MAX_TURNS,
  COACH_HUB_PILL_LIMIT,
  COACH_PLAN_ASK_DELAY_MINUTES,
  COACH_FIRST_HABIT_INVITE_LINE,
  COACH_SCENE_DEFAULT_QUESTION,
  COACH_SCENE_NOT_NOW_ENOUGH,
  COACH_SCENE_NOT_NOW_NO_HABIT,
  COACH_SCENE_OPENING_LEAD,
  COACH_SCENE_OPTIONS_LEAD,
  COACH_SCENE_RESUME_MAX_DAYS,
  COACH_SCENE_UNAVAILABLE_LINE,
  COACH_SCENE_CARD_LEAD_LINE,
  COACH_SCENE_GIVE_UP_LINE,
  COACH_SCENE_LATER_LINE,
  COACH_SCENE_PICK_MISS_LINE,
  COACH_STORY_CARD_LEAD_LINE,
  COACH_STORY_RESUME_LEAD_LINE,
  COACH_STORY_NO_COURSE_LINE,
  COACH_STORY_NO_MATCH_LINE,
  COACH_STORY_CONTINUE_LINE,
  COACH_STORY_OPEN_KEY,
  COACH_STORY_STOP_LINE,
  COACH_CHECKIN_ALL_DONE_LINE,
  COACH_CHECKIN_DONE_FALLBACK_LINE,
  COACH_CHECKIN_LATER_LINE,
  COACH_CHECKIN_MISSED_LINE,
  COACH_CHECKIN_OFFER_LINE,
  COACH_QUIZ_DONE_LINE,
  COACH_QUIZ_INTRO_LINE,
  COACH_QUIZ_QUESTION_LINE,
  COACH_QUIZ_RIGHT_LINE,
  COACH_QUIZ_WRONG_FALLBACK_LINE,
  QUIZ_IN_CHAT_COUNT,
  COACH_TALK_CONTINUE_LINE,
  COACH_TALK_FREE_DONE_LINE,
  COACH_TALK_FREE_FALLBACK_LINE,
  COACH_TALK_FREE_INVITE_LINE,
  COACH_TALK_LATER_LINE,
  COACH_TALK_SUMMARY_FALLBACK_LINE,
  RECAP_LESSON_CHIPS,
  RECAP_QUIZ_COUNT,
  TALK_BODY_MAX_CHARS,
  COACH_HISTORY_MAX_LINES,
  COACH_HISTORY_SESSIONS,
  COACH_ONBOARD_INTRO_LINES,
  COACH_ONBOARD_OPTIONS,
  ONBOARD_AGE_BY_AUDIENCE,
  ONBOARD_JOB_KEYWORDS,
  STORY_PATTERN_MIN_SESSIONS,
  STORY_PATTERN_WINDOW_DAYS,
  SCENE_DID_MIN_WORDS,
  COACH_SAFETY_ESCAPE_ENABLED,
  SCENE_COMPARE_MIN_WORDS,
  SITUATION_MAX_LEVEL,
  SITUATION_MIN_LEVEL,
  SCENE_DRAFT_MAX_WORDS,
  SITUATION_MAX_BEATS,
  SITUATION_START_LEVEL,
  TWO_COLS_DRAFT_LINES,
  TALK_FREE_MAX_TURNS_DEFAULT,
} from '../../shared/coach.constant';
import {
  CoachEntry,
  CoachHomeTier,
  CoachPersona,
  CoachScenePosture,
  CoachStep,
  CoachStoryKind,
  CoachUiKind,
} from '../../shared/coach.enum';
import {
  CoachAi,
  CoachSceneOption,
  CoachSceneScoreResult,
  CoachTurnContext,
} from '../ai/coach-ai.types';
import { CoachBoostService } from '../boost/coach-boost.service';
import { CoachBoostKind } from '../boost/enum/boost.enum';
import { CoachConfigService } from '../config/coach-config.service';
import { CoachDayLogService } from '../day-log/coach-day-log.service';
import { DayLogMoment } from '../day-log/enum/day-log.enum';
import { CoachMemoryService } from '../memory/coach-memory.service';
import { CoachMetricService } from '../metric/coach-metric.service';
import { CoachMetricKind } from '../metric/enum/coach-metric.enum';
import { CoachPlanService } from '../plan/coach-plan.service';
import { CoachPlanAnswer, CoachPlanSource } from '../plan/enum/plan.enum';
import { CoachProfileService } from '../profile/coach-profile.service';
import { CoachQuizService } from '../quiz/coach-quiz.service';
import { ICoachQuizQuestion } from '../quiz/interface/quiz.interface';
import { CoachRatingService } from '../rating/coach-rating.service';
import { CoachRatingChip, CoachRatingSource } from '../rating/enum/rating.enum';
import { shouldAskRating } from '../rating/rating-ask-gate';
import { sessionKindOf } from '../rating/session-kind';
import { CoachReflectionService } from '../reflection/coach-reflection.service';
import { CoachStatementKind } from '../reflection/interface/reflection.interface';
import { CoachSafetyService } from '../safety/coach-safety.service';
import { CoachScoreService } from '../score/coach-score.service';
import { CoachSituationService } from '../situation/coach-situation.service';
import {
  CoachSituationContextGroup,
  CoachSituationVariant,
} from '../situation/enum/situation.enum';

/**
 * Candidate habits handed to ③C's matcher.
 *
 * Capped because the list rides in the prompt on a turn a reader is waiting
 * through, and because a longer menu makes a spurious match MORE likely, not
 * less — a model given ninety options finds something in it. The reader's own
 * habits always lead the list, so the cap only ever trims library entries.
 */
const HABIT_MATCH_CANDIDATE_LIMIT = 60;

/**
 * How sure the silent match must be before its habit may carry a COURSE.
 *
 * The matcher is ordered to choose something whatever it hears, which is right
 * for the reply — a story deserves an answer — and wrong for a card, because
 * a course offered off a shrug is the "gợi bừa một khoá cho có" the doc bans.
 * Confidence has always been asked for; this is the first thing that reads it.
 * A model's 0-1 is not calibrated, so treat this as a dial, not a measurement.
 */
const HABIT_MATCH_CARD_MIN_CONFIDENCE = 0.5;

/** What the course selector hands back — the course, and the fact that put it there. */
interface PickedCourse {
  id: string;
  reasonKey: string;
  /** The habit title the reason quotes, in the reader's language. */
  reasonArg: string | null;
}

/**
 * Did this turn take the shallow branch of T3 — "Chỉ ghi lại thôi"?
 *
 * Both the write (the sentence, as a quick note) and the one fixed line hang
 * off it, and the branch is recognised by where it did NOT go: any answer at
 * the depth question that does not open nhịp 2 or ask again is a jot.
 */
function isShallowJot(
  step: CoachStep,
  nextStep: CoachStep,
  kind: CoachTurnEventKind,
  storyKind?: CoachStoryKind | null,
): boolean {
  const atFork =
    step === CoachStep.DEPTH ||
    (step === CoachStep.STORY && kind === CoachTurnEventKind.ACK);
  if (!atFork) return false;

  // A depth answer the machine routed by its KIND went deep, not shallow:
  // "thôi" and "làm sao để cải thiện?" are answers, not "chỉ ghi lại thôi".
  if (
    storyKind === CoachStoryKind.STOP ||
    storyKind === CoachStoryKind.ASKS_HOW
  ) {
    return false;
  }

  return (
    nextStep !== CoachStep.STORY_TALK &&
    nextStep !== CoachStep.TELL_2 &&
    nextStep !== CoachStep.TWO_COLS &&
    nextStep !== CoachStep.DEPTH
  );
}

/**
 * Steps that ask the reader to say something more.
 *
 * The turn ceiling only applies to these: a commitment form or a mood chip is
 * not "một lượt", and closing somebody out of the tail would lose the session's
 * own result.
 */
const CONVERSATION_STEPS: ReadonlySet<CoachStep> = new Set([
  CoachStep.STORY,
  CoachStep.DEPTH,
  CoachStep.STORY_TALK,
  CoachStep.CHECKIN_TELL,
  CoachStep.TELL_2,
  CoachStep.TWO_COLS,
  CoachStep.NEXT_ACTION,
  CoachStep.SCENE_FEELING,
  CoachStep.TELL_ONCE,
  CoachStep.SCENE_DID,
  CoachStep.SCENE_CHANGE,
  CoachStep.SCENE_AGAIN,
  CoachStep.INTENT_TELL,
]);

@Injectable()
export class CoachSessionService {
  private readonly logger = new Logger(CoachSessionService.name);

  constructor(
    private readonly sessionRepository: CoachSessionRepository,
    private readonly configService: CoachConfigService,
    private readonly profileService: CoachProfileService,
    private readonly planService: CoachPlanService,
    private readonly dayLogService: CoachDayLogService,
    private readonly reflectionService: CoachReflectionService,
    private readonly situationService: CoachSituationService,
    private readonly boostService: CoachBoostService,
    private readonly scoreService: CoachScoreService,
    private readonly ratingService: CoachRatingService,
    private readonly safetyService: CoachSafetyService,
    /**
     * Optional on purpose — the preview is a nicety, not a dependency.
     *
     * `@Optional()` so a context that does not wire the socket module (a spec,
     * a script, a future worker) still constructs this service and still
     * answers turns; it simply answers them without the typing effect.
     */
    @Optional()
    private readonly socketGateway: SocketGateway | null,
    private readonly metricService: CoachMetricService,
    private readonly habitLibraryService: HabitLibraryService,
    private readonly userHabitRepository: UserHabitRepository,
    private readonly userRepository: UserRepository,
    private readonly onboardingService: OnboardingService,
    private readonly savedCourseRepository: SavedCourseRepository,
    private readonly userProgressRepository: UserProgressRepository,
    private readonly courseRepository: CourseRepository,
    private readonly ai: CoachAi,
    private readonly userHabitService: UserHabitService,
    private readonly habitCheckinRepository: HabitCheckinRepository,
    private readonly habitPracticeService: HabitPracticeService,
    private readonly memoryService: CoachMemoryService,
    private readonly quizService: CoachQuizService,
    private readonly keypointRepository: KeypointRepository,
    private readonly lessonRepository: LessonRepository,
    private readonly learningItemRepository: LearningItemRepository,
    private readonly requestService: RequestService,
    private readonly contentSource: ContentSource,
  ) {}

  private get userId(): string {
    return this.requestService.user?.id?.toString?.();
  }

  /**
   * Minutes east of UTC for the caller.
   *
   * The header wins over the body for the same reason the habit domain prefers
   * it: it comes from the device making the call, so it survives travel and a
   * stale stored zone.
   */
  private tzOffset(dtoValue?: number): number {
    const raw = this.requestService.headers?.['x-timezone-offset'];
    const fromHeader = raw === undefined || raw === '' ? NaN : Number(raw);

    if (Number.isFinite(fromHeader)) return fromHeader;

    return Number.isFinite(dtoValue) ? (dtoValue as number) : 0;
  }

  private locale(dtoValue?: string): string {
    const header = this.requestService.headers?.['x-custom-lang'];

    return dtoValue || (typeof header === 'string' ? header : '') || 'en';
  }

  private startOfToday(tzOffsetMinutes: number): Date {
    return this.dayLogService.localDate(tzOffsetMinutes);
  }

  // ---------------------------------------------------------------- bubble

  /**
   * Whether the bubble renders, and whether it carries the dot.
   *
   * The dot appears in exactly one situation in the whole app — Home with a
   * pending commitment — and this is the only place that decides it. Keeping
   * the decision server-side is what stops it becoming "a dot whenever
   * something might be interesting", which is how notification badges die.
   */
  async getBubble(dto: GetCoachBubbleDto): Promise<CoachBubbleResponse> {
    const hidden: CoachBubbleResponse = {
      visible: false,
      dot: false,
      teaser: null,
    };

    if (!(await this.configService.isEnabled())) return hidden;
    if (!this.ai.isConfigured()) return hidden;

    const userId = this.userId;
    const tz = this.tzOffset(dto.tzOffsetMinutes);
    const entry = dto.entry ?? CoachEntry.HOME;

    // Luồng 2/3 — the lesson door is an INVITATION SCREEN after every keypoint
    // now, not an auto-bubble, so the old door's silences (two commitments
    // waiting, already appeared today) no longer gate it. Enabled + configured
    // is the whole test.
    if (entry === CoachEntry.LESSON) {
      void tz;

      return { visible: true, dot: false, teaser: null };
    }

    // Luồng 5 — the Habit screen. With habits in the kho the bubble is silent
    // (the sheet's two pills are the offer); with an EMPTY kho it says why it
    // is there at all, and tapping it opens the course that teaches a first
    // habit: "Chưa có thói quen nào trong kho. Học một bài để thêm nhé?"
    if (entry === CoachEntry.HABIT) {
      const owned = await this.userHabitRepository
        .countActiveForUser(userId)
        .catch(() => 0);

      return {
        visible: true,
        dot: false,
        teaser: null,
        teaserKey: owned > 0 ? COACH_TEASER_HABIT_KEY : COACH_TEASER_FIRST_HABIT_KEY,
      };
    }

    // Luồng 1 — a reader the Coach has not met yet sees the bubble whatever the
    // kho holds: their first Home session IS the onboarding, and a new reader's
    // kho is empty by definition. The kho rule below takes over once it ran.
    const profile = await this.profileService.get(userId).catch(() => null);
    if (profile && !profile.onboardedAt) {
      return { visible: true, dot: false, teaser: null, teaserKey: COACH_TEASER_ONBOARD_KEY };
    }

    // Luồng 4: the bubble is an invitation to practise, nothing more — no dot,
    // no teaser. It shows only while the kho has something to practise: "Kho
    // rỗng thì bong bóng ở Home không hiện." The ②A dot (a pending commitment)
    // and the ④ old-scene offer are retired with the doors they announced.
    const active = await this.userHabitRepository.findForUser(
      userId,
      UserHabitState.ACTIVE,
    );

    if (!active.length) return hidden;

    return { visible: true, dot: false, teaser: null, teaserKey: COACH_TEASER_HOME_KEY };
  }

  // ------------------------------------------------------------------ open

  /**
   * Opening a conversation, under the shared time budget.
   *
   * Opening is a reader-facing wait like any turn — and the most expensive one
   * in the product, because a practice door writes its scene before it can
   * answer. It gets the same ceiling for the same reason: past it, the app has
   * stopped listening and the work is finished for nobody.
   */
  async open(
    dto: OpenCoachSessionDto,
  ): Promise<CoachTurnResponse | CoachSilentResponse> {
    return this.watched(() =>
      withCoachDeadline(COACH_REQUEST_BUDGET_MS, () => this.openWithin(dto)),
    );
  }

  private async openWithin(
    dto: OpenCoachSessionDto,
  ): Promise<CoachTurnResponse | CoachSilentResponse> {
    if (!(await this.configService.isEnabled())) {
      return { silent: true, reasonKey: COACH_SILENT_REASON.DISABLED };
    }

    const userId = this.userId;
    const tz = this.tzOffset(dto.tzOffsetMinutes);
    const locale = this.locale(dto.locale);
    // The Habit door is retired; a client that still names it gets Home.
    // Luồng 5 — the Habit screen is a door of its own again: no mood, two
    // pills about the one habit it was opened from.
    const entry = dto.entry;

    // Luồng 2/3 — the lesson door redrawn: a keypoint id opens the TALK about
    // it, `recap` + a course id opens the course RECAP. Both are explicit taps
    // on an invitation, so the old door's silences (two commitments waiting,
    // already appeared today) do not apply. No keypoint → the legacy scene.
    const talkMode: 'talk' | 'recap' | null =
      entry === CoachEntry.LESSON
        ? dto.recap && dto.courseId
          ? 'recap'
          : dto.keypointId
            ? 'talk'
            : null
        : null;
    if (entry === CoachEntry.LESSON && !talkMode) {
      const reason = await this.lessonDoorSilence(userId, tz, dto.lessonId);
      if (reason) return { silent: true, reasonKey: reason };
    }

    // An ACTIVE session for this door opened TODAY is resumed, not replaced.
    //
    // "Close the sheet and it's gone" means the conversation ENDS when the
    // reader ends it — not when they swipe the sheet away, background the app,
    // or get a phone call. But a day is the unit: yesterday's half-told story
    // is closed here rather than put back in front of somebody whose mood
    // today nobody has asked. Everything it produced that matters was written
    // to its own collection the moment it was said.
    const today = this.startOfToday(tz);
    // Luồng 1 — an unfinished onboarding survives the day boundary: spared by
    // the close below, and resumed at the question they were on.
    const onboardSteps = [
      CoachStep.ONBOARD_INTRO,
      CoachStep.ONBOARD_ADDRESS_CONFIRM,
      ...ONBOARD_ORDER,
    ];
    // Scene steps are spared at EVERY door, alongside onboarding at Home: a
    // reader left mid-answer is the one case where closing the session throws
    // away work they had started, and it is the case the Coach's own "mai kể
    // tiếp cũng được" promises not to.
    await this.sessionRepository
      .closeActiveBefore(userId, entry, today, [
        ...(entry === CoachEntry.HOME ? onboardSteps : []),
        ...SCENE_RESUME_STEPS,
      ])
      .catch((error: any) =>
        this.logger.warn(`Coach could not close stale sessions: ${error?.message}`),
      );
    // Reopening the sheet starts a NEW conversation (owner, 2026-09-08). The
    // old one is not lost: `historyFor` puts it above the live thread with its
    // own divider — the reader can read it back, and `priorTranscript` hands
    // its verbatim lines to the model, so asking about it works.
    //
    // This reverses "the conversation ENDS when the reader ends it, not when
    // they swipe the sheet away". What that rule protected was work in
    // progress, and the two places where work is genuinely in progress are
    // spared below, so the promise it was making is still kept.
    const today_ = await this.sessionRepository.findActiveForEntry(
      userId,
      entry,
      today,
    );
    // Mid-scene survives: closing here throws away the answer they were part
    // way through writing, which is the one thing the Coach's own "mai kể tiếp
    // cũng được" promises not to do. Mid-onboarding survives for a plainer
    // reason — reopening must never mean filling the form in again.
    const midScene =
      today_ && SCENE_RESUME_STEPS.includes(today_.step) ? today_ : null;
    if (today_ && !midScene) {
      // Closed rather than left ACTIVE, or the next open would find it again.
      await this.sessionRepository
        .updateOne(
          { _id: today_._id },
          {
            status: CoachSessionStatus.CLOSED,
            closedAt: new Date(),
          } as Partial<CoachSession>,
        )
        .catch((error: any) =>
          this.logger.warn(`Coach could not close the previous session: ${error?.message}`),
        );
    }

    const resumable =
      (entry === CoachEntry.HOME
        ? await this.sessionRepository.findOnboardingInProgress(userId, onboardSteps)
        : null) ??
      midScene ??
      // Last: a scene left unanswered on an earlier day. After today's own
      // session, because a conversation started this morning is the one they
      // are in — yesterday's scene waits its turn rather than interrupting.
      (await this.sessionRepository.findSceneInProgress(
        userId,
        entry,
        [...SCENE_RESUME_STEPS],
        new Date(Date.now() - COACH_SCENE_RESUME_MAX_DAYS * 24 * 60 * 60 * 1000),
      ));
    // A Habit-door session is about ONE habit; opening another habit's screen
    // closes the old one rather than resuming a conversation about the wrong one.
    if (
      resumable &&
      entry === CoachEntry.HABIT &&
      resumable.habitId !== dto.habitId
    ) {
      await this.sessionRepository
        .updateOne(
          { _id: resumable._id },
          { status: CoachSessionStatus.CLOSED, closedAt: new Date() } as Partial<CoachSession>,
        )
        .catch(() => undefined);
    } else if (resumable) {
      // Picked back up with everything it showed, under the earlier sessions.
      const session = resumable as CoachSession;

      return this.respond(session, session.step, null, {
        replay: this.shownOf(session),
        history: await this.historyFor(userId, resumable._id.toString()),
      });
    }

    // Luồng 4: Home has no tiers. The check-in door (②A), the old-scene door
    // (④) and the "most due habit" pre-selection are retired — the session
    // opens on "Hôm nay bạn muốn làm gì?" and SCENE_PICK asks which habit.
    const [profile, ownedCount] = await Promise.all([
      this.profileService.get(userId),
      this.userHabitRepository.countActiveForUser(userId).catch(() => 0),
    ]);

    // Luồng 5 — the door opened from the Habit TAB names no habit: the Coach
    // takes the first one still unwritten today (the thing the tab is for),
    // and falls back to any owned habit when they are all written. An empty
    // kho leaves it null and the session opens on the course card instead.
    const tabHabitId =
      entry === CoachEntry.HABIT && !dto.habitId
        ? await this.firstHabitForDoor(userId)
        : null;

    // Luồng 5 — what the Habit door has to offer about this habit: its quiz
    // (snapshotted now, judged against what was shown), whether today is
    // already written, and whether another habit is still unwritten.
    const habitDoor =
      entry === CoachEntry.HABIT ? (dto.habitId ?? tabHabitId) : null;
    const [quizItems, checkedToday, nextHabitId] = habitDoor
      ? await Promise.all([
          this.generatedQuizFor(userId, habitDoor, locale),
          this.checkedToday(userId, habitDoor),
          this.nextUnwrittenHabit(userId, habitDoor),
        ])
      : [[] as ICoachQuizItem[], false, null];

    // Luồng 1 — the first Home session ever runs the onboarding before the
    // mood; `onboardedAt` on the profile is what makes it once per reader.
    const onboarding = entry === CoachEntry.HOME && !profile.onboardedAt;
    const config = onboarding ? await this.configService.get() : null;

    // Luồng 2/3 — what the talk or the recap is about, frozen at open.
    const talk =
      talkMode === 'talk'
        ? await this.talkSetupFor(userId, dto.keypointId as string)
        : null;
    const recap =
      talkMode === 'recap'
        ? await this.recapSetupFor(dto.courseId as string, locale)
        : null;

    // ① — the habits added today, most recent first. Two or more and the door
    // asks which one ("◇ Mấy habit mới? khi có ≥2"); one needs no question.
    const newHabitIds =
      entry !== CoachEntry.LESSON
        ? []
        : dto.habitId
          ? // The app that did the adopting already named the habit
            // (`_justAdded.single`). Asking "mình nói về cái nào trước?" after
            // that is asking a question the reader has answered — and it was
            // asked, because the count below counted the whole DAY (owner
            // 2026-09-05: "tôi chỉ vừa thêm 1 habit ... lại đề xuất 3").
            [String(dto.habitId)]
          : await this.newHabitsForLesson(userId, tz, dto.lessonId ?? null);

    // ① never ASKS for mood, but it does read the day's if there already is one:
    // "cửa ① đọc mood đầu ngày nếu hôm nay đã có, để chọn biến thể cảnh, nhưng
    // không hỏi". `moodAsked` stays true there so the graph never opens on the
    // question.
    const [moodAsked, moodLow] = await Promise.all([
      entry === CoachEntry.HOME
        ? this.dayLogService.hasStartMoodToday(userId, tz)
        : Promise.resolve(true),
      this.startMoodLowToday(userId, tz),
    ]);
    const moodStart = await this.startMoodValueToday(userId, tz);

    const context: CoachMachineContext = {
      entry,
      tier: null,
      moodAlreadyAskedToday: moodAsked,
      // Frozen here on purpose: a commitment made later in THIS session must
      // not be asked back about in the same session.
      planQueueLength: 0,
      planIndex: 0,
      planSlept: false,
      ratingHidden: profile.ratingHidden,
      moodLow,
      newHabitCount: newHabitIds.length,
      tasksRun: 0,
      // Home: "T2 is eligible" means the kho has something to practise; the
      // habit itself is chosen at SCENE_PICK. The lesson door knows its habit.
      hasHabit:
        entry === CoachEntry.HOME
          ? ownedCount > 0
          : !talkMode && Boolean(dto.habitId ?? newHabitIds[0]),
      hasPlanPending: false,
      hasQuiz: quizItems.length > 0,
      checkinDone: checkedToday,
      hasNextHabit: Boolean(nextHabitId),
      talkMode,
      onboarding,
      onboardAsk: config
        ? {
            style: config.onboardAskStyle,
            age: config.onboardAskAge,
            gender: config.onboardAskGender,
            job: config.onboardAskJob,
          }
        : undefined,
      viLocale: locale === 'vi',
      storyTold: false,
      moodEndAsked: false,
      ratingAsked: false,
      moodEndLow: false,
      hasCourse: false,
      hasScene: true,
      lateNightLow: false,
      draftRejected: false,
      situationRound: 0,
      sceneContinues: false,
      intentMissed: false,
    };

    // Luồng 5 — the Habit tab with an empty kho: the session IS the course
    // card ("học bài → thêm habit → mình dựng tình huống"). The card itself is
    // resolved on the turn that shows it, exactly as the empty-kho Home
    // session's claim is.
    if (entry === CoachEntry.HABIT && !habitDoor) context.hasCourse = true;

    const step =
      entry === CoachEntry.HABIT && !habitDoor
        ? CoachStep.COURSE_CARD
        : resolveOpeningStep(context);

    const expiresAt = new Date(
      Date.now() + COACH_SESSION_TTL_HOURS * 60 * 60 * 1000,
    );

    void this.metricService.bump(CoachMetricKind.SESSION_OPENED, entry);

    const session = await this.sessionRepository.create({
      userId,
      entry,
      tier: null,
      step,
      status: CoachSessionStatus.ACTIVE,
      // The door's own habit when the caller did not name one — ① takes the
      // habit just added (the picker chooses when there are several). Home
      // opens with none: SCENE_PICK asks, and the story's silent match may set
      // it (luồng 4).
      // The talk and the recap are about a keypoint / a course, not a habit:
      // no habit bar. The habit the keypoint teaches rides in `talkHabitId`.
      // Luồng 5 — the door opened from the Habit TAB picked its own habit
      // (`habitDoor`): without it the session has no habit at all, so the
      // "Đang nói về · X" bar never appears and the check-in has nothing to
      // write against.
      habitId: talkMode ? null : (dto.habitId ?? habitDoor ?? newHabitIds[0] ?? null),
      lessonId: dto.lessonId ?? null,
      situationId: null,
      talkMode,
      keypointId: talkMode === 'talk' ? (dto.keypointId ?? null) : null,
      courseId: talkMode === 'recap' ? (dto.courseId ?? null) : null,
      talkHabitId: talk?.habitId ?? null,
      summaryScope: talk?.scope ?? null,
      recapLessons: recap?.lessons ?? [],
      // The voice is no longer a control the reader sees (design v2 has no
      // persona pill); the last one chosen still shapes the model's register.
      persona: profile.lastPersona ?? CoachPersona.FRIEND,
      newHabitIds,
      planQueue: [],
      planIndex: 0,
      activePlanId: null,
      escapeAvailable: isEscapeAvailable(step),
      moodLow,
      moodStart,
      locale,
      tzOffsetMinutes: tz,
      turns: [],
      expiresAt,
      // Luồng 5 — the bar reads "Đang nói về · X" from the first frame: the
      // reader opened this habit's own screen, so the habit is certain.
      quizItems: recap ? recap.quizItems : quizItems,
      habitConfirmed: Boolean(habitDoor),
      onboarding,
      onboardAnswers: {},
      address: profile.address ?? null,
      khoSize: ownedCount,
    });

    // Câu chào nhắc lại chuyện hôm trước.
    //
    // Chỉ cửa Home và chỉ ở bộ điều phối: cửa Lesson/Habit có câu mở riêng
    // theo đúng việc người ta vừa bấm vào, và chen một câu chào vào đó là lấy
    // mất ngữ cảnh họ đang cần. Mảnh chủ đề được viết TỪ LÚC PHIÊN TRƯỚC KẾT
    // (off-clock, gộp vào call cô đọng), nên ở đây không có call AI nào —
    // đường `open` đang mất 1–5s và không được thêm gì vào.
    const [history, greetingTopic] = await Promise.all([
      this.historyFor(userId, session._id.toString()),
      entry === CoachEntry.HOME && step === CoachStep.HUB
        ? this.memoryService.greetingTopicFor(userId, locale)
        : Promise.resolve(null),
    ]);

    // Đánh dấu đã dùng ngay, không chờ: chào hai lần cùng một chuyện là lỗi
    // người đọc nhìn thấy, còn mất một câu chào vì ghi trượt thì không.
    if (greetingTopic) void this.memoryService.markGreetingUsed(userId);

    return this.respond(session, step, null, {
      history,
      // The empty-kho Habit session opens ON the card: resolve it here, since
      // no turn has run yet to pay for the claim above.
      openingCard: step === CoachStep.COURSE_CARD,
      ...(greetingTopic
        ? {
            promptKeyOverride: COACH_PROMPT_KEY_HUB_BACK,
            promptArgs: { topic: greetingTopic },
          }
        : {}),
    });
  }

  // ------------------------------------------------------------------ turn

  /**
   * One turn, under the shared time budget — see `COACH_REQUEST_BUDGET_MS`.
   *
   * The budget is what stops the retries inside one turn from stacking past the
   * point the app is still waiting: every provider call below takes the lesser
   * of its own timeout and what is left here.
   */
  async turn(sessionId: string, dto: CoachTurnDto): Promise<CoachTurnResponse> {
    return this.watched(() =>
      withCoachDeadline(COACH_REQUEST_BUDGET_MS, () =>
        this.turnWithin(sessionId, dto),
      ),
    );
  }

  /**
   * Runs a request with its prose mirrored to the reader as it is written.
   *
   * The socket is a PREVIEW and nothing else: what this returns is still the
   * whole answer, and the client still renders from it. So every failure here
   * is swallowed — a socket that will not emit costs the typing effect, never
   * the turn. That is also why there is no wait on delivery and no retry: a
   * chunk that misses its moment has no second moment worth having.
   */
  private watched<T>(run: () => Promise<T>): Promise<T> {
    const userId = this.userId;
    const room = coachRoomFor(userId);
    const server = this.socketGateway?.server;

    if (!server) return run();

    const emit = (event: SocketServerEvent, payload?: unknown) => {
      try {
        server.to(room).emit(event, payload ?? {});
      } catch (error: any) {
        this.logger.warn(`Coach preview could not emit: ${error?.message}`);
      }
    };

    emit(SocketServerEvent.COACH_STARTED);

    return withCoachStream(
      { push: (delta: string) => emit(SocketServerEvent.COACH_CHUNK, { delta }) },
      run,
    ).finally(() => emit(SocketServerEvent.COACH_ENDED));
  }

  private async turnWithin(
    sessionId: string,
    dto: CoachTurnDto,
  ): Promise<CoachTurnResponse> {
    const userId = this.userId;
    const session = await this.sessionRepository.findActive(sessionId, userId);

    if (!session) {
      // Expired by TTL, or never existed. Either way the client should open a
      // new one rather than see a failure — 410 is the signal for that.
      throw new GoneException('Coach session is no longer available');
    }
    if (session.status !== CoachSessionStatus.ACTIVE) {
      throw new GoneException('Coach session is already closed');
    }

    // Bản app tới 2026-09-04 gửi MỌI chip của khung hub bằng `pickTask`, kể cả
    // ⟨Tóm tắt⟩/⟨Làm quiz⟩ của TALK_ASK — mà hai cái đó là LỰA CHỌN, không phải
    // task, nên advance() trả null và user thấy "Có lỗi ở phía mình". Client đã
    // sửa để gửi `pick`; dịch ở đây để bản cũ đang cài trên máy chạy lại được
    // ngay sau khi deploy API. Chuẩn hoá đúng một chỗ, các tầng dưới không phải
    // biết gì về dạng cũ.
    if (
      dto.kind === CoachTurnEventKind.TASK &&
      (dto.task === 'summary' || dto.task === 'talkQuiz')
    ) {
      dto.value = dto.task;
      dto.task = undefined;
      dto.kind = CoachTurnEventKind.PICK;
    }

    // A scene's ways forward are named in the reply's own text, not as pills,
    // so the reader may answer with the letter — "A". Expanded to the line it
    // stands for HERE, above the safety gate and everything below it, so no
    // layer sees the shorthand: the letter would otherwise be what the rubric
    // scores and what the answer row keeps forever.
    if (dto.kind === CoachTurnEventKind.TEXT && dto.text) {
      const picked = this.resolveSceneOption(session as CoachSession, dto.text);
      if (picked) dto.text = picked;
    }

    const step = session.step;
    const text = (dto.text ?? '').trim();

    // ⑧ before anything else. The keyword net is synchronous and local, so a
    // plain statement of intent never reaches the model, never reaches a
    // repository, and never becomes a row. Behind the owner's switch — see
    // COACH_SAFETY_ESCAPE_ENABLED.
    if (
      COACH_SAFETY_ESCAPE_ENABLED &&
      dto.kind === CoachTurnEventKind.TEXT &&
      text
    ) {
      if (this.safetyService.screen(text)) {
        return this.enterSafety(session as CoachSession);
      }
    }

    // Thanh habit — the chip's "đổi" button, and the choice it opens. Neither is
    // a step of the flow: "không phải một lượt tương tác… nút này thuộc quyền
    // của user, không bao giờ được ẩn theo điều kiện". So they are handled here,
    // before the graph, and they put the reader back exactly where they were.
    if (dto.kind === CoachTurnEventKind.CHANGE_HABIT) {
      // With a habitId this IS the pick — accept it from any client shape
      // rather than bouncing them back into the picker.
      if (dto.habitId) {
        return this.pickHabitBack(session as CoachSession, dto.habitId);
      }

      return this.openHabitPicker(session as CoachSession);
    }
    if (
      dto.kind === CoachTurnEventKind.PICK_NEW &&
      step === CoachStep.PICK_HABIT &&
      dto.habitId
    ) {
      return this.pickHabitBack(session as CoachSession, dto.habitId);
    }

    const profile = await this.profileService.get(userId);
    const ctx = this.buildContext(
      session as CoachSession,
      profile.ratingHidden,
      this.isLateNightLow(session as CoachSession),
    );

    const event = this.toEvent(dto);
    if (!event) throw new BadRequestException('Unsupported coach event');

    // Facts the graph needs that only a read can supply, folded into the
    // context rather than patched onto its answer afterwards.
    if (
      event.kind === 'intent' &&
      event.answer === CoachPlanAnswer.NONE &&
      session.activePlanId
    ) {
      ctx.planSlept = await this.wouldSleep(session.activePlanId);
    }
    // Luồng 2 — the follow-up floor's budget. Read here, where the config is
    // reachable, so the machine stays a pure function: it is told whether this
    // answer is the last one, it does not work it out.
    //
    // The ceiling counts ANSWERS given, so `turns >= max` after this one means
    // the floor closes with it. A ceiling of 0 makes the grading turn the last
    // thing said, which is the pre-2026-09-05 behaviour and is what an admin
    // gets by setting it to 0.
    if (step === CoachStep.TALK_SUMMARY || step === CoachStep.TALK_FREE) {
      const maxTurns = (await this.configService.get()).talkFreeMaxTurns ?? TALK_FREE_MAX_TURNS_DEFAULT;
      const spent = session.talkFreeTurns ?? 0;
      ctx.talkFreeExhausted =
        step === CoachStep.TALK_SUMMARY ? maxTurns <= 0 : spent + 1 >= maxTurns;
    }
    // Luồng 4 — the card connects to the habit THIS session settled on: the
    // one the story matched (in or out of the kho) or the one picked for the
    // scene. Practice → a course in the same skill set ("cùng skill set với
    // habit đang tập"); story → a course that teaches the matched habit ("chỉ
    // gợi khi có khoá khớp rõ với chuyện user kể"). Nothing to connect →
    // nothing offered, and never on ①.
    let pickedCourse: PickedCourse | null = null;
    // Luồng 3 — the recap's card: a course in the same skill set as the one
    // just finished, never the one just finished.
    if (session.talkMode === 'recap' && !session.cardShown) {
      pickedCourse = await this.pickRecapCourse(session as CoachSession);
      ctx.hasCourse = Boolean(pickedCourse);
    }
    // Luồng 5 — the Habit door writes and quizzes, and sells nothing AROUND
    // those two things. It carries the story task now, so a reader who asks
    // there for something to learn gets the same answer they would get at
    // Home: silence to a direct request reads as being ignored (owner, on the
    // simulator 2026-09-04).
    const habitDoorTalking =
      session.entry === CoachEntry.HABIT &&
      (step === CoachStep.STORY || step === CoachStep.STORY_TALK || step === CoachStep.DEPTH);
    if (
      session.entry !== CoachEntry.LESSON &&
      (session.entry !== CoachEntry.HABIT || habitDoorTalking) &&
      !session.cardShown
    ) {
      const connected = session.cardHabitId ?? session.habitId ?? null;
      if (connected) {
        pickedCourse = await this.pickCourseConnected(
          session as CoachSession,
          connected,
          taskOf(step) === 'T2'
            ? COACH_COURSE_REASON.SKILLSET
            : COACH_COURSE_REASON.STORY,
        );
      }
      // Nothing connected — no habit matched the story at all, or the matched
      // habit had no course left to offer. Fall back to the course they are
      // already partway through, so the session has somewhere to go instead of
      // a closing sentence and a Đóng button (owner 2026-09-05).
      if (!pickedCourse) {
        pickedCourse = await this.pickResumeCourse(session as CoachSession);
      }
      ctx.hasCourse = Boolean(pickedCourse);
    }
    // "Tập thử một cảnh" needs a habit to build the scene from; without one the
    // invitation is never OFFERED — it used to be, and the reader who accepted
    // landed on the commitment question with no scene in between.
    ctx.hasScene = Boolean(session.habitId);

    // DEPTH — "Coach đọc input kế tiếp để đoán ý", no model call. The pills win
    // over the guess whenever one is pressed; this only reads typing.
    ctx.depthReasked = session.depthReasked ?? false;
    if (step === CoachStep.DEPTH && event.kind === 'text') {
      ctx.depthGuess = guessDepth(text);
    }

    // A question back is not an answer to the step's question (owner
    // 2026-09-05). Set for every text turn; `advance` decides which steps care.
    if (event.kind === 'text') ctx.readerAsksBack = asksBack(text);

    // The coordinator routes typing to a task by keyword — no model call.
    // STORY_TALK reads it too: a reader mid-conversation who types "luyện tình
    // huống khác" is asking for a scene, not telling one (owner 2026-09-05).
    if (
      (step === CoachStep.HUB || step === CoachStep.STORY_TALK) &&
      event.kind === 'text'
    ) {
      ctx.hubRoute = routeHub(text);
    }

    // "Cho mình lại tình huống cũ" — the one thing nothing else in this product
    // does. Every other practice path means a DIFFERENT scene: the pool excludes
    // what they answered, `resolve` writes a fresh one each time, and SCENE_RETRY
    // is documented as "a DIFFERENT scene about the same habit". So the reader
    // who wants the scene they were in has to ask for it, and this is where the
    // asking is heard.
    //
    // Resolved here rather than inside the graph: `advance` is pure, and whether
    // a stored scene exists is a question for the database. The graph is handed
    // the answer as a flag.
    // "Luyện cảnh khó hơn" on the card — the other way forward beside the
    // course. One rung above the scene they just practised, read from that
    // scene rather than from the reader's ladder position: they are asking for
    // harder than THIS, and the ladder average would sometimes hand back the
    // same level again.
    let harderLevel: number | null = null;
    if (
      dto.kind === CoachTurnEventKind.COURSE &&
      dto.courseAction === CoachCourseAction.HARDER &&
      session.situationId
    ) {
      const practised = (await this.situationService
        .findById(session.situationId)
        .catch(() => null)) as { level?: number | null } | null;
      harderLevel = Math.min(
        SITUATION_MAX_LEVEL,
        (practised?.level ?? SITUATION_MIN_LEVEL) + 1,
      );
    }

    let replay: { situationId: string; habitId: string | null } | null = null;
    if (
      (step === CoachStep.HUB || step === CoachStep.STORY_TALK) &&
      event.kind === 'text' &&
      asksForOldScene(text)
    ) {
      replay = await this.reflectionService
        // Narrowed to the habit once the session has settled on one: at the
        // coordinator it has not, and then the whole history is the right place
        // to look for "the scene I was in".
        .findLatestAnswered(userId, session.habitId ?? null)
        .catch(() => null);
      ctx.hubReplayScene = Boolean(replay);
    }

    // "Cho tôi tình huống khác", typed INSIDE a scene. Mid-scene every line is
    // the answer, so without this the request was filed as `sceneFirstLine` and
    // graded (owner, 2026-09-08). Set only when they may actually have another
    // — the ceiling still holds, and the refusal below says so out loud rather
    // than silently scoring the request as an answer.
    const sceneSwapAsked =
      isInScene(step) &&
      event.kind === 'text' &&
      asksForAnotherScene(text);
    ctx.sceneSwapAsked = sceneSwapAsked;

    // The story conversation: how many replies it has run, and — before any
    // model is asked anything — whether this short line says stop. "User không
    // muốn tiếp tục → dừng, không recommend": the reader's "thôi" is answered
    // with a fixed line, never sent to a model to be replied to.
    ctx.storyTalkRounds = session.storyTalkRounds ?? 0;
    if (step === CoachStep.STORY_TALK && event.kind === 'text' && saysStop(text)) {
      ctx.storyKind = CoachStoryKind.STOP;
    }

    // Luồng 4 — SCENE_PICK: a habit typed by name is matched against the kho
    // by folded title ("hoặc gõ tên habit bạn muốn tập"); nothing matches →
    // the picker asks again rather than guessing.
    let pickedHabitId: string | null = null;
    if (step === CoachStep.SCENE_PICK && event.kind === 'text') {
      pickedHabitId = await this.matchOwnedHabitByName(
        session.userId,
        text,
        session.locale,
      );
      ctx.pickedHabit = Boolean(pickedHabitId);
    }

    // Luồng 2/3 — the chip's value, read by the step it was tapped on.
    if (event.kind === 'pick') ctx.pick = dto.value?.trim() ?? null;

    // Luồng 1 — the admin's toggles decide which questions exist; a typed
    // pronoun at the address question counts as the chip, anything else typed
    // there is a NAME to confirm first.
    let onboardName: string | null = null;
    if (isOnboardStep(step)) {
      const config = await this.configService.get();
      ctx.onboardAsk = {
        style: config.onboardAskStyle,
        age: config.onboardAskAge,
        gender: config.onboardAskGender,
        job: config.onboardAskJob,
      };
      if (step === CoachStep.ONBOARD_ADDRESS && event.kind === 'text') {
        const pronoun = this.onboardPronounOf(text);
        if (pronoun) {
          ctx.pick = pronoun;
        } else {
          ctx.onboardNamed = true;
          onboardName = text.trim().slice(0, 30);
        }
      }
    }

    // Luồng 5 — the Habit door reads the day's ledger every turn: is THIS
    // habit written today, and which one is still unwritten for the offer.
    let nextHabitId: string | null = null;
    if (session.entry === CoachEntry.HABIT && session.habitId) {
      const [checked, next] = await Promise.all([
        this.checkedToday(session.userId, session.habitId),
        this.nextUnwrittenHabit(session.userId, session.habitId),
      ]);
      ctx.checkinDone = checked;
      ctx.hasNextHabit = Boolean(next);
      nextHabitId = next;
    }

    // 6d's answer IS the occasion, so T4 becomes possible on this very turn
    // — read from the session it would still be a turn behind, and the reader
    // would finish a scene that just produced a real occasion without ever
    // being offered the commitment it exists for. (SCENE_WHEN kept for parked
    // sessions.)
    if (
      (step === CoachStep.SCENE_WHEN || step === CoachStep.SCENE_CHANGE) &&
      event.kind === 'text' &&
      text
    ) {
      ctx.hasDip = true;
    }

    // 6b — a dead answer (nothing worth keeping, or a question back at the
    // Coach) skips 6d and makes no dip: "phiên chưa có dịp thật nên không mời
    // T4" (mẫu #7, #13).
    if (step === CoachStep.SCENE_DID && event.kind === 'text') {
      const words = text.trim().split(/\s+/).filter(Boolean).length;
      ctx.sceneDidDead = words < SCENE_DID_MIN_WORDS || /[?？]/.test(text);
    }

    // Nhịp 4 exists only when the scene on screen has a written second stage.
    if (step === CoachStep.TELL_ONCE) {
      ctx.hasStage2 = Boolean(session.scenePromptStage2?.trim());
    }

    // Luật trần — at most two add-ons may ask for a tap in one sheet-open, and
    // mood outranks the rating. Read as "already asked" whatever this sheet has
    // spent, then let the boost service decide; a refusal is expressed to the
    // graph the same way the old flags were, so no transition had to change.
    const spent: CoachBoostKind[] = [
      ...(session.moodEndAsked ? [CoachBoostKind.MOOD_END] : []),
      ...(session.ratingAsked ? [CoachBoostKind.RATING] : []),
    ];
    const [moodEndAllowed, ratingAllowed] = await Promise.all([
      this.boostService
        .allows({
          userId,
          kind: CoachBoostKind.MOOD_END,
          alreadyAsked: spent,
        })
        .catch(() => true),
      this.boostService
        .allows({
          userId,
          kind: CoachBoostKind.RATING,
          alreadyAsked: spent,
          // "Bật ngay bất kể tần suất" — the reader has just told the Coach its
          // draft was not theirs, and that is the feedback worth having now.
          urgent: event.kind === 'rejectDraft' || session.draftRejected,
        })
        .catch(() => true),
    ]);
    if (!moodEndAllowed) ctx.moodEndAsked = true;
    if (!ratingAllowed) ctx.ratingHidden = true;



    // The model call and the risk classifier race rather than queue: running
    // them in sequence would add the classifier's latency to every ordinary
    // turn in the product.
    const [firstOutcome, verdict] = await Promise.all([
      this.runAi(session as CoachSession, step, event, text, ctx),
      COACH_SAFETY_ESCAPE_ENABLED &&
      dto.kind === CoachTurnEventKind.TEXT &&
      text
        ? this.safetyService.classify(text, session.locale)
        : Promise.resolve({ risk: false, by: 'none' as const }),
    ]);
    let aiOutcome = firstOutcome;

    if (verdict.risk) return this.enterSafety(session as CoachSession);

    // The story conversation is routed by the KIND of line the model reported
    // — read into the context now, so `advance` below sees it on this very
    // turn. A stop, whichever net caught it, is answered with the fixed line:
    // the one thing not to do to somebody who just said enough is keep talking.
    if (aiOutcome?.storyKind && !ctx.storyKind) ctx.storyKind = aiOutcome.storyKind;
    if (ctx.storyKind === CoachStoryKind.STOP) {
      aiOutcome = {
        ...(aiOutcome ?? { reply: null }),
        reply:
          this.fixedLine(COACH_STORY_STOP_LINE, session),
        // The stop line IS the goodbye; END must not add its own under it.
        promptKeyOverride: COACH_NO_PROMPT_KEY,
      };
    }

    // Luồng 4 — the judge's verdict routes the Home scene on this very turn.
    // A provider failure is not the reader's fault: an unjudged line counts
    // as on track, and the fixed acknowledgement stands in for the praise.
    // The scene is scored on the reader's SECOND line — or on the first when
    // the other person never managed to answer it.
    const judged =
      event.kind === 'text' &&
      (step === CoachStep.SCENE_STAGE2 ||
        ((step === CoachStep.TELL_ONCE || step === CoachStep.SCENE_RETRY) &&
          !aiOutcome?.awaitingSecondLine));
    if (judged) ctx.sceneOnTrack = aiOutcome?.sceneOnTrack ?? true;
    // The machine reads this to decide whether this line is answered or scored.
    // True means the other person just spoke and the reader still owes their
    // second line; false means this line is the one to score.
    ctx.sceneAwaitingSecondLine = Boolean(aiOutcome?.awaitingSecondLine);

    // Owner 2026-09-05: "luôn luôn khi có cơ hội thì điều hướng đề xuất cho
    // user học một bài nào đó". Cổng cũ chỉ cho hiện card khi người đọc đã tỏ ý
    // muốn khá hơn (WANTS_IMPROVE / ASKS_HOW) — đảo lại: CƠ HỘI giờ chính là
    // "có khoá khớp thật", và `pickCourseFor` vốn đã đòi một match thật chứ
    // không gợi bừa.
    //
    // Quyết định này lật một quyết định cũ ghi ngay tại đây: "Course là bước
    // tiếp theo trong hành trình của user, không phải mục tiêu của mọi
    // conversation." Giữ `improveSignal` trên session vì nó vẫn được ghi và
    // vẫn đọc được cho thống kê.
    const improveSignal =
      Boolean(session.improveSignal) ||
      ctx.storyKind === CoachStoryKind.WANTS_IMPROVE ||
      ctx.storyKind === CoachStoryKind.ASKS_HOW;

    // Luồng 5 — the quiz question just answered: judged against the snapshot,
    // spoken about (right: one fixed word; wrong: the right answer and why),
    // and the next question read out. The last answer files the attempt.
    let quizPatch: Partial<CoachSession> = {};
    if (step === CoachStep.QUIZ_IN_CHAT && event.kind === 'quizAnswer') {
      const answered = await this.answerQuizQuestion(
        session as CoachSession,
        dto.quizAnswer ?? '',
      );
      quizPatch = answered.patch;
      aiOutcome = { ...(aiOutcome ?? { reply: null }), reply: answered.reply };
    }

    // Luồng 5 — the one sentence about the occasion earned its line; the
    // fixed one stands in when the model could not write it.
    if (
      step === CoachStep.CHECKIN_TELL &&
      event.kind === 'text' &&
      !aiOutcome?.reply
    ) {
      aiOutcome = {
        ...(aiOutcome ?? { reply: null }),
        reply:
          this.fixedLine(COACH_CHECKIN_DONE_FALLBACK_LINE, session),
      };
    }

    // The silent match scans the WHOLE catalogue, and its answer goes to one of
    // two places: a habit in the reader's kho becomes the session's habit — to
    // practise, to hang a commitment on — and one outside it becomes the card,
    // the only road to a habit they do not have. "Một phiên có thể trỏ tới hai
    // habit khác nhau."
    let matchedOutside: string | null = null;
    if (aiOutcome?.matchedHabitId) {
      const owned = await this.ownsHabit(
        session.userId,
        aiOutcome.matchedHabitId,
      );
      // The course is picked on the closing turn from the ids stored here —
      // not now, when the conversation has only just begun.
      //
      // Owner 2026-09-05: "đề xuất khoá học ko lquan". The match prompt ORDERS
      // a pick — "CHOOSE ONE. Whatever they told you, something on this list
      // bears on it… Answer null ONLY if the list above is empty" — so a story
      // about nothing in the catalogue still comes back with a habit, and the
      // course hung off it reads as fired by keystrokes. `confidence` was
      // already asked for and parsed, then dropped on the floor ("is for us,
      // not a gate"). It is a gate now, for the CARD only: the forced pick
      // still shapes the reply, which is what it was good for.
      // …and never off a line that was not a line. A course offered on the back
      // of "qqqqq" is the clearest possible version of "an advert fired by
      // keystrokes" (owner 2026-09-05).
      if (
        !owned &&
        !looksLikeNoise(text) &&
        (aiOutcome.matchConfidence ?? 0) >= HABIT_MATCH_CARD_MIN_CONFIDENCE
      ) {
        matchedOutside = aiOutcome.matchedHabitId;
      }
    }


    // The scene's replies never ask anything, never repeat the second stage,
    // and arrive ONE SENTENCE PER BUBBLE — none of which a lite model can be
    // trusted to format. The reply is rebuilt here sentence by sentence:
    // question-sentences go (the app asks the next thing itself), sentences
    // already inside the authored second stage go (it says them one bubble
    // later), a "cách khác" reduced to its bare mandatory phrase goes, and
    // what survives is joined with blank lines so the app renders each
    // sentence as its own bubble ("mỗi câu gửi một lần" — owner, 2026-08-28).
    if (step === CoachStep.TELL_ONCE && !judged && aiOutcome?.reply) {
      const norm = (value: string) =>
        value.toLowerCase().replace(/[^\p{L}\p{N}]+/gu, ' ').trim();
      const stage = session.scenePromptStage2
        ? norm(session.scenePromptStage2)
        : null;
      const sentences =
        aiOutcome.reply.match(/[^.!?。！？…\n]+[.!?。！？…]*/g) ?? [];
      const kept = sentences
        .map((sentence) => sentence.trim())
        .filter((sentence) => sentence && !/[?？]/.test(sentence))
        .filter((sentence) => {
          const bare = norm(sentence);
          if (bare.length < 4) return false;
          if (stage && stage.includes(bare)) return false;
          // c stripped of its content ("Một cách khác không phải tốt hơn,
          // chỉ là khác.") is a phrase pointing at nothing.
          const residue = bare
            .replace('không phải tốt hơn chỉ là khác', '')
            .replace('một cách khác', '')
            .replace('cách khác', '')
            .trim();
          return residue.length >= 8;
        });
      aiOutcome.reply = kept.length ? kept.join('\n\n') : null;
    }

    // The regex above catches a question back; the model catches the rest — a
    // line that simply talks about something else. It has the question and the
    // answer in front of it and costs nothing extra, because it is the call
    // that was writing the reply anyway (owner 2026-09-05, "fix triệt để").
    if (event.kind === 'text' && aiOutcome?.engaged === false) {
      ctx.readerAsksBack = true;
    }

    let nextStep = advance(step, event, ctx);

    // "Tối đa 6 lượt/phiên — một lượt = một lần user nói + Coach đáp. Hết lượt
    // là đóng." The flow is bounded by construction well under this, so hitting
    // it means something looped; it jumps to the commitment rather than cutting
    // the reader off mid-thought.
    if (
      nextStep &&
      (session.turnCount ?? 0) + 1 >= LONG_SCRIPT_MAX_TURNS &&
      CONVERSATION_STEPS.has(nextStep)
    ) {
      this.logger.warn(
        `Coach session ${session._id} hit the ${LONG_SCRIPT_MAX_TURNS}-turn ceiling at ${nextStep}`,
      );
      nextStep =
        session.entry === CoachEntry.LESSON ? CoachStep.PLAN_ASK : CoachStep.END;
    }

    if (!nextStep) {
      throw new BadRequestException(
        `Event "${dto.kind}" is not valid at step "${step}"`,
      );
    }

    // Asked for a different scene, and allowed one: the stored scene has to go
    // BEFORE anything peeks at it. `reusesStored` just below treats a set
    // `situationId` at TELL_ONCE as "second beat of the scene we already have"
    // and would hand back the very scene they asked to leave. Same field list
    // as changing habit mid-practice, which restarts the practice for exactly
    // this reason. `sceneFirstLine` is not in it because entering a scene
    // clears it already.
    if (
      ctx.sceneSwapAsked &&
      isInScene(step) &&
      sceneOnRequest(ctx)
    ) {
      const cleared = {
        situationId: null,
        situationRound: 0,
        sceneBeats: [],
        sceneBeatLines: [],
        sceneCounterpart: null,
        sceneTakeaway: null,
        sceneGoodMove: null,
        sceneLevel: null,
        scenePrompt: null,
        scenePromptStage2: null,
        sceneDidAnswer: null,
        sceneRetried: false,
      } as Partial<CoachSession>;
      Object.assign(session, cleared);
      await this.sessionRepository
        .updateOne({ _id: session._id }, cleared)
        .catch((error: any) =>
          this.logger.warn(`Coach could not clear the scene: ${error?.message}`),
        );
    }

    // A scene we cannot build must never leave the Coach silent on an empty
    // scene step — the design skips a missing scene and goes to the commitment
    // ("a missing scene is a shorter conversation, not a broken one"). Scenes
    // are WRITTEN at render now, so the peek must not resolve one — that call
    // would generate a scene the render then generates again. A second beat
    // re-reads the stored scene (cheap, so it is checked for real); a fresh
    // scene only needs a habit to write about, and render falls back to the
    // habit's stored rows if the provider fails mid-turn.
    if (isSituationStep(nextStep) && nextStep !== step) {
      const peekHabitId = dto.habitId ?? aiOutcome?.matchedHabitId ?? session.habitId;
      const reusesStored =
        Boolean(session.situationId) &&
        (nextStep === CoachStep.TELL_ONCE ||
          nextStep === CoachStep.RETRY_SCENE ||
          session.sceneRetried);
      const buildable = reusesStored
        ? await this.situationService
            .findById(session.situationId!)
            .catch(() => null)
        : peekHabitId;
      if (!buildable) {
        this.logger.warn(
          `Coach scene unavailable at ${nextStep} for session ${session._id}; skipping to commitment`,
        );
        // No habit at all means no commitment to hang either — the useful next
        // thing is the road to a FIRST habit: a course whose opening lesson
        // teaches one ("đề xuất người dùng học bài để add habit", owner
        // 2026-08-29). The commitment stays the fallback of the fallback.
        if (!peekHabitId) {
          pickedCourse =
            pickedCourse ??
            (await this.pickCourseForFirstHabit(session as CoachSession));
          ctx.hasCourse = Boolean(pickedCourse) || ctx.hasCourse;
        }
        nextStep =
          !peekHabitId && pickedCourse
            ? CoachStep.COURSE_CARD
            : CoachStep.PLAN_ASK;
      }
    }

    // "Lưu để sau" needs the course id; it is resolved on the way in and
    // remembered on the session — with its reason — so a resumed card still
    // shows the same course for the same reason.
    let enteringCard = nextStep === CoachStep.COURSE_CARD && nextStep !== step;
    // The empty-kho claim above promised a card it had not resolved yet; this
    // is the turn that pays for it. A library with nothing left to offer means
    // the closing continues from exactly where the card would have stood.
    if (enteringCard && !pickedCourse) {
      pickedCourse = await this.pickCourseForFirstHabit(session as CoachSession);
      if (!pickedCourse) {
        nextStep = afterCard(ctx);
        enteringCard = false;
      }
    }
    const card = enteringCard ? pickedCourse : null;
    // The first-habit card is a DIRECTION, not an ad — the Coach says the road
    // out loud: học bài → thêm habit → mình dựng tình huống cho bạn (owner,
    // 2026-08-29). Only that card; the outside-match card keeps its own line.
    const firstHabitInvite =
      enteringCard && card?.reasonKey === COACH_COURSE_REASON.HABIT
        ? (this.fixedLine(COACH_FIRST_HABIT_INVITE_LINE, session))
        : null;
    const courseCardId = enteringCard
      ? card?.id ?? null
      : session.courseCardId ?? null;
    const courseCardReasonKey = enteringCard
      ? card?.reasonKey ?? null
      : session.courseCardReasonKey ?? null;
    const courseCardReasonArg = enteringCard
      ? card?.reasonArg ?? null
      : session.courseCardReasonArg ?? null;
    if (enteringCard && card) {
      void this.metricService.bump(CoachMetricKind.COURSE_SHOWN, card.reasonKey);
    }
    // Luồng 4 — a scene done right is a PRACTICE that counts: the day's
    // check-in for the habit, method EXERCISE. Filed as practice — "tập trong
    // app KHÔNG tính là đã làm thật ngoài đời" is what the method says.
    // Luồng 7 — the habit was added minutes ago at the end of a lesson, so
    // there is no day to write yet: "KHÔNG ghi habit_checkins — habit vừa
    // thêm, chưa tới ngày đầu". Every other door files the practice.
    if (judged && ctx.sceneOnTrack && session.entry !== CoachEntry.LESSON) {
      await this.recordSceneCheckin(session as CoachSession);
    }

    // Luồng 5 — both check-in answers WRITE: ⟨Chưa⟩ as done:false at once,
    // ⟨Có⟩ as done:true once the sentence has landed, method COACH.
    if (
      session.entry === CoachEntry.HABIT &&
      step === CoachStep.CHECKIN_ASK &&
      event.kind === 'checkin' &&
      !event.done
    ) {
      await this.recordCoachCheckin(session as CoachSession, false, null);
    }
    if (
      session.entry === CoachEntry.HABIT &&
      step === CoachStep.CHECKIN_TELL &&
      event.kind === 'text'
    ) {
      await this.recordCoachCheckin(session as CoachSession, true, text);
    }
    // The finished quiz files the attempt, which files today's EXERCISE check-in.
    if (
      step === CoachStep.QUIZ_IN_CHAT &&
      event.kind === 'quizAnswer' &&
      nextStep !== CoachStep.QUIZ_IN_CHAT
    ) {
      await this.submitQuizAttempt({ ...session, ...quizPatch } as CoachSession);
      // "Sau mỗi lần user luyện thì gen lại quizz" — the next set is written
      // now, off the reader's clock, so tomorrow's quiz is waiting rather than
      // costing a model call at the moment it is asked for.
      if (session.habitId) {
        const passed = new Set(
          (await this.userProgressRepository
            .findPassedKeypointIds(session.userId)
            .catch(() => [])) as string[],
        );
        // Detached: writing a quiz is allowed 40s of its own, and it is
        // launched from inside a turn that is allowed 20. An async context
        // follows an un-awaited promise just as faithfully as an awaited one,
        // so without this the next quiz would inherit whatever milliseconds
        // this turn had left and be cut off — the one call in the feature that
        // is deliberately NOT on the reader's clock.
        detachedFromCoachDeadline(() =>
          this.quizService.replenish({
            habitId: session.habitId,
            locale: session.locale,
            allowedKeypointIds: passed,
          }),
        );
      }
    }

    // Luồng 2/3 — the lines that belong to the step being ENTERED rather than
    // to what the reader typed: the summary, the quiz's debrief with its one
    // praise, the recap's one line about the lesson they picked.
    const talkLine = await this.talkTransitionLine({
      session: { ...session, talkQuizResults: dto.quizResults ?? session.talkQuizResults } as CoachSession,
      step,
      event,
      nextStep,
      pick: ctx.pick ?? null,
    });
    if (talkLine) {
      aiOutcome = {
        ...(aiOutcome ?? { reply: null }),
        reply: [aiOutcome?.reply, talkLine].filter(Boolean).join('\n\n'),
      };
    }

    // Luồng 2 — "Học tiếp" / "Để sau" both write the day's check-in for the
    // habit this keypoint teaches (EXERCISE when the quiz ran, COACH when they
    // only listened) — when they have that habit at all.
    let turnAction: string | null = null;
    // Nhánh "Bàn luận về bài vừa học": the check-in is written when the branch
    // actually ENDS, which since 2026-09-05 is after the follow-up floor closes
    // (TALK_FREE → END) — or straight after the grading turn when an admin has
    // set the floor's budget to 0, which sends TALK_SUMMARY → END as before.
    //
    // No `turnAction` at all any more. `keypointDone` drew the sheet's bottom
    // button ("Đóng · về Roadmap") and `nextKeypoint` before it closed the
    // sheet outright; both pushed the reader onward at exactly the moment the
    // floor is meant to stay open (owner, 2026-09-05: "bỏ phần đóng học phần
    // tiếp theo"). The way out is the sheet's own Đóng, and the next keypoint
    // is started from the Roadmap.
    if (
      (step === CoachStep.TALK_SUMMARY || step === CoachStep.TALK_FREE) &&
      nextStep === CoachStep.END
    ) {
      await this.recordTalkCheckin({
        ...session,
        talkQuizResults: session.talkQuizResults,
      } as CoachSession);
    }
    if (step === CoachStep.TALK_WHEN && event.kind === 'pick' && nextStep === CoachStep.END) {
      await this.recordTalkCheckin({
        ...session,
        talkQuizResults: session.talkQuizResults,
      } as CoachSession);
      if (ctx.pick === 'continue') turnAction = 'nextKeypoint';
    }

    // The offer names both habits — the one just written and the next one.
    const offerTitles =
      nextStep === CoachStep.CHECKIN_OFFER && nextHabitId
        ? {
            done: (await this.habitTitleOf(session.habitId, session.locale)) ?? '',
            next: (await this.habitTitleOf(nextHabitId, session.locale)) ?? '',
          }
        : null;

    // The fixed lines that bridge or close a beat (luồng 4). Whenever one is
    // said, the step's own line is suppressed: the card's "Có một khoá gần
    // với…" and END's "Vậy mình dừng ở đây nhé." would otherwise double it.
    const bridge = this.bridgeLineFor({
      step,
      event,
      ctx,
      nextStep,
      session: session as CoachSession,
      judged,
      offerTitles,
      cardReasonKey: card?.reasonKey ?? null,
    });
    // Entering the quiz: its intro and the first question, in the Coach's voice.
    const quizOpening =
      nextStep === CoachStep.QUIZ_IN_CHAT && step !== CoachStep.QUIZ_IN_CHAT
        ? this.quizOpeningLine({ ...session, ...quizPatch } as CoachSession)
        : null;
    if (quizOpening) {
      aiOutcome = {
        ...(aiOutcome ?? { reply: null }),
        reply: [aiOutcome?.reply, quizOpening].filter(Boolean).join('\n\n'),
        promptKeyOverride: COACH_NO_PROMPT_KEY,
      };
    }
    if (bridge) {
      aiOutcome = {
        ...(aiOutcome ?? { reply: null }),
        reply: [aiOutcome?.reply, bridge].filter(Boolean).join('\n\n'),
        promptKeyOverride: COACH_NO_PROMPT_KEY,
      };
    }

    const createdPlanId = await this.applyWrites({
      session: { ...session, courseCardId } as CoachSession,
      step,
      nextStep,
      dto,
      text,
      storyKind: ctx.storyKind ?? null,
    });

    this.countFunnel(step, event, dto, session as CoachSession);

    const patch: Partial<CoachSession> = {
      step: nextStep,
      escapeAvailable: isEscapeAvailable(nextStep),
      courseCardId,
      courseCardReasonKey,
      courseCardReasonArg,
      // "Tối đa một card mỗi phiên."
      ...(enteringCard ? { cardShown: true } : {}),
      // Luồng 2 — one follow-up answered, one turn of the budget gone. Counted
      // on the way OUT of TALK_FREE (not on the way in) so the answer that
      // closes the floor is counted too, and counted even when the model
      // failed and the reader got the fallback line.
      ...(step === CoachStep.TALK_FREE
        ? { talkFreeTurns: (session.talkFreeTurns ?? 0) + 1 }
        : {}),
    };
    if (createdPlanId) {
      patch.activePlanId = createdPlanId;
      patch.createdPlanId = createdPlanId;
    }

    if (dto.kind === CoachTurnEventKind.PICK_NEW && dto.habitId) {
      patch.habitId = dto.habitId;
    }
    // Luồng 4 — the habit named at SCENE_PICK.
    if (pickedHabitId) patch.habitId = pickedHabitId;
    if (improveSignal && !session.improveSignal) patch.improveSignal = true;
    // Luồng 1 — the answer just given, by field; a typed name waits for its
    // confirmation; leaving the onboarding writes the profile in one go.
    if (isOnboardStep(step)) {
      const answers = { ...(session.onboardAnswers ?? {}) };
      const answered = this.onboardAnswerOf(session as CoachSession, step, event, ctx.pick ?? null, text);
      Object.assign(answers, answered);
      // The chip picked here, so "← Câu trước" comes back with it lit.
      if (ctx.pick && !['skip', 'back', 'start'].includes(ctx.pick)) {
        patch.onboardPicks = { ...(session.onboardPicks ?? {}), [step]: ctx.pick };
      }
      if (onboardName) patch.onboardName = onboardName;
      patch.onboardAnswers = answers;
      if (!isOnboardStep(nextStep)) {
        await this.completeOnboarding(session as CoachSession, answers);
        patch.address = answers.address ?? session.address ?? null;
      }
    }

    // Luồng 2/3 — the quiz's results as the app reported them; the lesson picked.
    if (step === CoachStep.QUIZ_RUN && event.kind === 'quizDone') {
      patch.talkQuizResults = (dto.quizResults ?? []) as ICoachTalkQuizResult[];
    }
    if (step === CoachStep.RECAP_PICK && event.kind === 'pick' && ctx.pick) {
      patch.recapLessonId = ctx.pick;
    }
    // Luồng 5 — the quiz's progress, the offer's target, and the switch to it.
    Object.assign(patch, quizPatch);
    if (nextStep === CoachStep.QUIZ_IN_CHAT && step !== CoachStep.QUIZ_IN_CHAT) {
      patch.quizIndex = 0;
      patch.quizResults = [];
    }
    if (nextStep === CoachStep.CHECKIN_OFFER && nextHabitId) {
      patch.checkinOfferHabitId = nextHabitId;
    }
    if (
      step === CoachStep.CHECKIN_OFFER &&
      event.kind === 'invite' &&
      event.accept &&
      session.checkinOfferHabitId
    ) {
      patch.habitId = session.checkinOfferHabitId;
      patch.checkinOfferHabitId = null;
    }
    // Luồng 4 — the retry is offered once; the flag closes the door after it.
    // The retry gets a DIFFERENT scene about the same habit ("đưa tình huống
    // tương tự, không lặp lại y nguyên" — owner, 2026-09-04), so the snapshot
    // of the old one is cleared here and `situationFor` writes the new one.
    if (step === CoachStep.SCENE_FIX && nextStep === CoachStep.SCENE_RETRY) {
      patch.sceneRetried = true;
      patch.sceneShownIds = [
        ...(session.sceneShownIds ?? []),
        ...(session.situationId ? [session.situationId] : []),
      ];
      patch.situationId = null;
      patch.scenePrompt = null;
      patch.scenePromptStage2 = null;
    }

    // Luồng 4 — the two lines of one scene. The first is kept for the verdict;
    // both are cleared when a new scene starts, so a retry cannot be scored
    // against what was said in the scene before it.
    if (aiOutcome?.sceneFirstLine) {
      patch.sceneFirstLine = aiOutcome.sceneFirstLine;
      patch.sceneReacted = Boolean(aiOutcome.sceneReacted);
    }
    // The offer on screen, and the run of postures this scene has produced.
    // Appended rather than replaced: the closing reply reads the RUN ("hai lượt
    // vừa rồi bạn đều lùi"), which one value cannot say.
    if (aiOutcome?.sceneOptions) {
      patch.sceneOptions = aiOutcome.sceneOptions;
    }
    if (aiOutcome?.scenePosture) {
      patch.scenePostures = [
        ...(session.scenePostures ?? []),
        aiOutcome.scenePosture,
      ];
    }
    if (nextStep === CoachStep.SCENE_RETRY || nextStep === CoachStep.TELL_ONCE) {
      patch.sceneFirstLine = null;
      patch.sceneReacted = false;
      // A new scene starts with no offer and no history — a retry scored
      // against the posture of the scene before it would be a different reader.
      patch.sceneOptions = [];
      patch.scenePostures = [];
      // An asked-for difficulty is spent on the scene it was asked for. The
      // "harder" block below runs AFTER this one and re-sets it on that turn.
      patch.sceneTargetLevel = null;
    }
    const lowValues = COACH_MOOD_LOW_VALUES as readonly number[];
    if (event.kind === 'mood') {
      patch.moodLow = lowValues.includes(dto.mood as number);
      patch.moodStart = (dto.mood as number) ?? null;
      void this.boostService.shown(session.userId, CoachBoostKind.MOOD_START);
      void this.boostService.answered(session.userId, CoachBoostKind.MOOD_START);
    }
    if (event.kind === 'moodEnd') {
      patch.moodEndAsked = true;
      patch.moodEndLow = lowValues.includes(dto.mood as number);
      void this.boostService.shown(session.userId, CoachBoostKind.MOOD_END);
      void this.boostService.answered(session.userId, CoachBoostKind.MOOD_END);
    }
    if (event.kind === 'rating') {
      patch.ratingAsked = true;
      void this.boostService.shown(session.userId, CoachBoostKind.RATING);
      void this.boostService.answered(session.userId, CoachBoostKind.RATING);
    }
    if (dto.kind === CoachTurnEventKind.INTENT && dto.answer) {
      patch.lastIntent = dto.answer;
    }
    // The match's answer, filed on the side it belongs to.
    if (aiOutcome?.matchedHabitId && !matchedOutside) {
      patch.habitId = aiOutcome.matchedHabitId;
    }
    if (matchedOutside) patch.cardHabitId = matchedOutside;
    // Nhịp 4 → the tail: "ghi nhớ keypoint_id đã dùng — cuối phiên sẽ gợi đúng
    // khoá chứa nó." Kept even when the reply itself failed: the idea was
    // retrieved for this session either way, and a card is better than none.
    if (step === CoachStep.NEXT_ACTION && aiOutcome?.keypointId) {
      patch.keypointIds = [
        ...new Set([...(session.keypointIds ?? []), aiOutcome.keypointId]),
      ];
    }
    if (aiOutcome?.lines) {
      patch.draftLeft = aiOutcome.lines;
      patch.draftRight = [];
      // Kept untouched so the impose metric can compare against what the
      // reader ended up with.
      patch.draftProposed = aiOutcome.lines;
    }

    // The registry's bookkeeping. A task that just ended costs one run of the
    // three (T4 excepted — it is the session's result, not a way to spend the
    // evening) and cannot be offered again.
    const fromTask = taskOf(step);
    const toTask = taskOf(nextStep);
    // A skipped opener is a DECLINE, not a run: it marks T3 done so the pill
    // is not offered again ("Coach không mời lại"), but it spends none of the
    // three runs — nothing was said and nothing cost anything.
    const skippedStory = step === CoachStep.STORY && event.kind === 'skip';
    if (fromTask && fromTask !== toTask) {
      if (fromTask !== 'T4' && !skippedStory) {
        patch.tasksRun = (session.tasksRun ?? 0) + 1;
      }
      if (fromTask === 'T1') patch.t1Done = true;
      if (fromTask === 'T2') patch.t2Done = true;
      if (fromTask === 'T3') patch.t3Done = true;
    }

    // The habit is CONFIRMED the moment a habit-bound task starts — that is the
    // tap the chip has been waiting for. Never cleared: "shown from the moment
    // the habit is certain to the end of the session".
    if (!session.habitConfirmed && taskOf(nextStep) === 'T2') {
      patch.habitConfirmed = true;
    }

    // The commitment is offered once per session, however that offer went.
    if (nextStep === CoachStep.PLAN_ASK && step !== CoachStep.PLAN_ASK) {
      patch.t4Offered = true;
    }

    // The closing sequence latches: a commitment made inside it goes on to the
    // tail, not back to the coordinator. PLAN_ASK is only reachable from the
    // closing chain or from an explicit choice at the coordinator.
    if (
      !session.closing &&
      (event.kind === 'stop' ||
        isClosingStep(nextStep) ||
        (nextStep === CoachStep.PLAN_ASK &&
          event.kind !== 'task' &&
          // 6d hands straight over to the commitment now, mid-session. It is
          // the scene's result, not the session's: latching `closing` here
          // would skip the course card (which stands BEFORE the commitment in
          // the closing sequence) and shut the session around a reader who
          // still has a story in them.
          step !== CoachStep.SCENE_CHANGE))
    ) {
      patch.closing = true;
    }

    // RETIRED path, parked sessions only — "Lúc đó là lúc nào?".
    if (step === CoachStep.SCENE_WHEN && event.kind === 'text' && text) {
      patch.dip = text.trim();
      patch.sceneContextDraft = text.trim();
      patch.sceneActionDraft = await this.habitTitleOf(
        session.habitId,
        session.locale,
      );
    }

    // 6b — the real occurrence, remembered so 6d can hand it to the reminder
    // when the answer is "không đổi". Typing the telling AT 6a (mẫu #10) is
    // the same telling. A dead answer keeps nothing.
    if (
      (step === CoachStep.SCENE_DID || step === CoachStep.SCENE_MET) &&
      event.kind === 'text' &&
      text &&
      !ctx.sceneDidDead
    ) {
      patch.sceneDidAnswer = text.trim();
    }

    // 6d — either answer makes the dip. "Muốn khác" carries their words into
    // the reminder; a bare "không đổi" carries the very thing they did at 6b —
    // "cả hai đều ra Nhắc hẹn", and the form stays theirs to edit.
    if (step === CoachStep.SCENE_CHANGE && event.kind === 'text' && text) {
      const said = text.trim();
      const real = (session.sceneDidAnswer ?? '').trim();
      const keepOnly =
        /(kh[ôo]ng|gi[ữu]\s*nguy[êe]n|v[ẫa]n\s*(v[ậa]y|th[êế])|no|keep|same)/i.test(
          said,
        ) && said.split(/\s+/).length <= 6;
      patch.dip = real || said;
      patch.sceneContextDraft = keepOnly && real ? real : said;
      patch.sceneActionDraft =
        (keepOnly && real ? real : said) ||
        (await this.habitTitleOf(session.habitId, session.locale));
    }

    // T3 has actually started — the reader asked to go deeper. The rating ask
    // hangs off this ("chỉ hiện sau phiên CÓ kể chuyện… không hiện sau phiên
    // chỉ tập tình huống hoặc chỉ ghi một câu"), so answering the opener and
    // then filing it is deliberately NOT a story.
    const wentDeep =
      step === CoachStep.DEPTH &&
      ((event.kind === 'depth' && event.deep) ||
        (event.kind === 'text' && ctx.depthGuess === 'deep'));
    if (wentDeep) patch.storyTold = true;

    // Every reply in the story conversation counts against its cap — the one
    // that answers the depth question included. Counted whether or not the
    // model managed to say anything: the cap bounds cost, not quality.
    if (wentDeep || (step === CoachStep.STORY_TALK && event.kind === 'text')) {
      patch.storyTalkRounds = (session.storyTalkRounds ?? 0) + 1;
    }
    if (aiOutcome?.patternNamed) patch.patternNamed = true;

    // "Có vấn đề" — the first difficulty they name IS the session's occasion
    // (what the two-column draft's right column used to be): it pre-fills the
    // reminder's "khi…", and the action comes from the habit's NAME, never from
    // anything said inside an invented scene.
    if (
      ctx.storyKind === CoachStoryKind.PROBLEM &&
      event.kind === 'text' &&
      text &&
      !session.dip?.trim()
    ) {
      patch.dip = text.trim();
      if (!session.sceneContextDraft?.trim()) patch.sceneContextDraft = text.trim();
      if (!session.sceneActionDraft?.trim()) {
        patch.sceneActionDraft = await this.habitTitleOf(
          session.habitId,
          session.locale,
        );
      }
    }
    // The depth question has been asked once; a second unclear answer is filed
    // rather than asked about again.
    if (step === CoachStep.DEPTH && nextStep === CoachStep.DEPTH) {
      patch.depthReasked = true;
    }

    // The commitment form's pre-fill, from the scene. While the scene is still
    // open the reader's latest word stands in; on the CLOSING reply the model's
    // `nextMove` wins — the lesson's move it set beside their choice, or their
    // own choice when that was already a real action — falling back to the
    // scene's authored `goodMove`. `nextMoment` gives the "when". An avoidant
    // answer with no move offered and no authored move leaves it empty, so "Tôi
    // tắt luôn cho nhẹ" never arrives in the form as the plan. The final turn is
    // decided the same way the machine decides it — by the round count, not by
    // whether the model happened to ask. Still theirs to edit, every time.
    // The commitment form's pre-fill comes from the scene's OWN authored
    // `goodMove` — no model call, and nothing the Coach said in its reply. The
    // reply itself may not name a move at all now (a · b · c never prescribes
    // one), and a pre-fill invented at reply time would be exactly the "đáp án
    // mẫu" the doc bans. Still the reader's field, still editable.
    // Nothing said inside an invented scene pre-fills a commitment: "dịp lấy từ
    // chữ user, hành động lấy từ TÊN HABIT — không bao giờ lấy từ câu user nói
    // trong bối cảnh giả". The occasion arrives at nhịp 6 instead.

    // A TURN is somebody telling the Coach something. Chip taps and form saves
    // are not.
    // The onboarding's eight answers are not "lượt" — they must not eat into
    // the conversation ceiling of the session that follows.
    if (dto.kind === CoachTurnEventKind.TEXT && text && !isOnboardStep(step)) {
      patch.turnCount = (session.turnCount ?? 0) + 1;
    }

    if (isSituationProbeStep(step) && dto.kind === CoachTurnEventKind.TEXT && text) {
      patch.situationRound = (session.situationRound ?? 0) + 1;
    }
    // A new T2 RUN — not a new beat inside one. `situationFor` looks the scene
    // up BY ID whenever the session already holds one, and a scene already in
    // the transcript is then skipped as "alreadyShown": asking for a second
    // scene therefore produced the habit picker followed by a bare question
    // with no situation above it (owner 2026-09-05: "coach đang bị loạn").
    //
    // Narrower than the reset below on purpose — that one also fires between
    // the beats of a single scene, and clearing the id there would delete the
    // scene the reader is halfway through.
    if (nextStep === CoachStep.SCENE_PICK && taskOf(step) !== 'T2') {
      patch.sceneShownIds = [
        ...(session.sceneShownIds ?? []),
        ...(session.situationId ? [session.situationId] : []),
      ];
      patch.situationId = null;
      patch.scenePrompt = null;
      patch.scenePromptStage2 = null;
      patch.sceneFirstLine = null;
      patch.sceneReacted = false;
      // The retry door belongs to the scene that opened it.
      patch.sceneRetried = false;
    }

    // A DIFFERENT scene is starting: its own answers begin at zero, and the
    // previous scene's script is cleared so it cannot leak into the new one.
    // Coming back from "Nói lại" is NOT a different scene — it is the same one,
    // answered a second time, and resetting there would loop forever.
    if (
      isSituationStep(nextStep) &&
      nextStep !== step &&
      step !== CoachStep.SCENE_AGAIN &&
      // Feeling → question is one scene in two beats, not a new scene.
      step !== CoachStep.SCENE_FEELING
      // NOT excluding SCENE_FIX any more. The comment here read "the retry IS
      // the same scene, answered a second time" — untrue since 2026-09-04: the
      // transition into SCENE_RETRY nulls `situationId` and files the old scene
      // under `sceneShownIds` precisely so a DIFFERENT one gets written.
      //
      // Leaving it excluded meant `situationRound` stayed above zero into the
      // retry, and the whole scene-attach block is gated on `=== 0` — so the
      // retry rendered its label ("Một tình huống tương tự:") with nothing
      // underneath, and even the provider-failure fallback never ran (owner
      // 2026-09-05, on device). Same stale assumption `4b672b5` removed from
      // the by-id lookup; it was written in two places and only one was fixed.
    ) {
      patch.situationRound = 0;
      patch.sceneBeats = [];
      patch.sceneBeatLines = [];
      patch.sceneCounterpart = null;
      patch.sceneTakeaway = null;
      patch.sceneGoodMove = null;
      patch.sceneLevel = null;
    }

    // ⑤ — "xoá sạch bản nháp". Not saved, but COUNTED: the rejection rate is
    // the one number that says whether nhịp 3 is imposing.
    if (event.kind === 'rejectDraft') {
      patch.draftRejected = true;
      patch.draftLeft = [];
      patch.draftRight = [];
      patch.draftProposed = [];
      void this.metricService.bump(CoachMetricKind.DRAFT_REJECTED);
    }
    if (dto.leftLines || dto.rightLines) {
      patch.draftLeft = dto.leftLines ?? session.draftLeft;
      patch.draftRight = dto.rightLines ?? session.draftRight;

      // The story's own "về đích": the right column IS the reader's better line
      // in their own words — the twoCols equivalent of a scene's goodMove. Carry
      // it into the reminder pre-fill so a session that tells a story but skips
      // the practice scene still reaches the commitment with something filled
      // in. A scene practised afterwards overwrites this on its closing turn;
      // the reader edits either, always.
      const ownLine = (dto.rightLines ?? [])
        .map((line) => line.trim())
        .find(Boolean);
      if (ownLine) patch.sceneActionDraft = ownLine;
    }

    // Walking to the next pending commitment.
    if (event.kind === 'loop' && event.keepGoing) {
      const nextIndex = session.planIndex + 1;
      patch.planIndex = nextIndex;
      patch.activePlanId = session.planQueue[nextIndex] ?? null;
      patch.lastIntent = null;
    }

    // "Phiên mới" — the same sheet-open, a fresh conversation. Everything that
    // belongs to the conversation resets; everything asked once per sheet-open
    // (mood-end, rating) stays answered.
    const startsAgain = event.kind === 'nextSession' && event.again;
    if (startsAgain) {
      Object.assign(patch, {
        turns: [],
        turnCount: 0,
        storyTold: false,
        draftRejected: false,
        draftProposed: [],
        draftLeft: [],
        draftRight: [],
        situationId: null,
        situationRound: 0,
        sceneBeats: [],
        sceneBeatLines: [],
        sceneCounterpart: null,
        sceneTakeaway: null,
        sceneGoodMove: null,
        sceneLevel: null,
        sceneRetried: false,
        sceneScore: null,
        courseCardId: null,
        courseCardReasonKey: null,
        courseCardReasonArg: null,
        createdPlanId: null,
        sceneActionDraft: null,
        sceneContextDraft: null,
        lastIntent: null,
        // "Chọn phiên mới thì reset trần task về 0" — without this the second
        // session in one sheet-open opens with every task already marked done,
        // the coordinator has nothing to offer, and it closes on the spot.
        tasksRun: 0,
        t1Done: false,
        t2Done: false,
        t3Done: false,
        depthReasked: false,
        storyTalkRounds: 0,
        patternNamed: false,
        improveSignal: false,
        closing: false,
        // The occasion, the card and the one commitment offer belong to the
        // session that produced them.
        dip: null,
        t4Offered: false,
        cardShown: false,
        cardHabitId: null,
        scenePrompt: null,
        scenePromptStage2: null,
      } as Partial<CoachSession>);

      // "Bắt đầu phiên mới" (parked tail) starts Home over with NO habit —
      // SCENE_PICK asks, the story's match may answer (luồng 4).
      if (session.entry === CoachEntry.HOME) {
        patch.habitId = null;
        patch.situationId = null;
        patch.habitConfirmed = false;
      }
    }

    // A harder scene: a NEW one, so the id is cleared and the one just
    // practised is filed under `sceneShownIds` — the same three lines the
    // retry does, for the same reason (`avoid` must not hand it back).
    if (harderLevel && nextStep === CoachStep.TELL_ONCE) {
      patch.sceneShownIds = [
        ...(session.sceneShownIds ?? []),
        ...(session.situationId ? [session.situationId] : []),
      ];
      patch.situationId = null;
      patch.scenePrompt = null;
      patch.scenePromptStage2 = null;
      patch.situationRound = 0;
      patch.sceneRetried = false;
      patch.sceneTargetLevel = harderLevel;
      // The card was the tail; asking for another scene takes it back.
      patch.closing = false;
    }

    // Going back to a stored scene. Pointing the session at it is the whole
    // mechanism: `attachSituation` reads `situationId` by id at RETRY_SCENE
    // instead of resolving, so the reader gets the scene they asked for rather
    // than a fresh one about the same habit.
    if (replay && nextStep === CoachStep.TELL_ONCE) {
      patch.situationId = replay.situationId;
      // The coordinator may never have settled a habit — the stored answer
      // knows which one the scene belongs to.
      if (!session.habitId && replay.habitId) {
        patch.habitId = replay.habitId;
        patch.habitConfirmed = true;
      }
      // A replay starts at the top of the scene, and carries none of the
      // previous run's state: the round counter gates whether the scene is even
      // rendered, and a stale first line would be scored together with the new
      // one.
      // `sceneFirstLine`, `sceneReacted`, `sceneOptions` and `scenePostures`
      // are already cleared above for every entry into TELL_ONCE.
      patch.situationRound = 0;
      patch.sceneRetried = false;
    }

    // The closing line is written on the way INTO the last step, from the
    // commitment made in this session — a fixed line stands in when there is
    // none, or when the model could not write one.
    const closing =
      nextStep === CoachStep.NEXT_SESSION && nextStep !== step
        ? await this.closingLine({ ...session, ...patch } as CoachSession)
        : null;

    if (!startsAgain) {
      patch.turns = [
        ...session.turns,
        ...(text
          ? [{ role: CoachTurnRole.USER, text, step, at: new Date() }]
          : []),
        ...(aiOutcome?.reply
          ? [{ role: CoachTurnRole.COACH, text: aiOutcome.reply, step, at: new Date() }]
          : []),
        ...(closing?.reply
          ? [{ role: CoachTurnRole.COACH, text: closing.reply, step: nextStep, at: new Date() }]
          : []),
        ...(firstHabitInvite
          ? [{ role: CoachTurnRole.COACH, text: firstHabitInvite, step: nextStep, at: new Date() }]
          : []),
      ];
    }

    // The rating's cadence counts CHANCES, not sessions: a story was told, the
    // ask was due, and it still did not appear — that is one of the three.
    if (
      nextStep === CoachStep.NEXT_SESSION &&
      nextStep !== step &&
      (session.storyTold ?? false) &&
      !(patch.ratingAsked ?? session.ratingAsked)
    ) {
      void this.boostService.countedEligible(session.userId, CoachBoostKind.RATING);
    }

    await this.sessionRepository.updateOne({ _id: sessionId }, patch);

    const updated = { ...session, ...patch } as CoachSession;

    // RAW — every line of this turn, kept for good (the session's own copy
    // expires). Awaited because the extraction below reads it back.
    const spokenLines = [
      aiOutcome?.reply ?? null,
      closing?.reply ?? null,
      firstHabitInvite,
    ].filter(Boolean) as string[];
    const tapped = !text && dto.label?.trim() ? dto.label.trim() : null;
    await this.memoryService.record([
      ...(tapped
        ? [
            {
              userId: session.userId,
              sessionId,
              entry: session.entry,
              role: 'user' as const,
              step,
              content: tapped,
            },
          ]
        : []),
      ...(text
        ? [
            {
              userId: session.userId,
              sessionId,
              entry: session.entry,
              role: 'user' as const,
              step,
              content: text,
            },
          ]
        : []),
      ...spokenLines.map((content) => ({
        userId: session.userId,
        sessionId,
        entry: session.entry,
        role: 'coach' as const,
        step: nextStep,
        content,
      })),
    ]);

    // MEMORY giữa phiên — một phiên Home không có hồi kết
    // (`storyRoundsLeft = null`) chỉ dừng khi user bấm Đóng, nên chờ tới END
    // là có thể chờ rất lâu: mọi thứ user kể trong lúc đó không vào memory,
    // và phiên SAU không biết gì về nó. Cô đọng lại mỗi
    // MEMORY_MIDSESSION_EVERY_LINES lượt user, off-clock như bản ở END.
    //
    // Không chạy nếu lượt này đã là END — chỗ dưới lo, khỏi làm hai lần.
    const spokenCount = patch.turnCount ?? session.turnCount ?? 0;
    if (
      nextStep !== CoachStep.END &&
      spokenCount > 0 &&
      spokenCount % MEMORY_MIDSESSION_EVERY_LINES === 0
    ) {
      void detachedFromCoachDeadline(() =>
        this.extractMemoryFrom(session, sessionId, false),
      );
    }

    // MEMORY — the conversation is over: what did it add? Off the reader's
    // clock; a failure is logged and nothing else.
    if (nextStep === CoachStep.END && nextStep !== step) {
      void detachedFromCoachDeadline(() =>
        this.extractMemoryFrom(session, sessionId, true),
      );
      // Luồng 6 — a session that ran to its end breaks the "closed against the
      // plea" run.
      void this.profileService.resetExitStreak(session.userId).catch(() => undefined);
    }

    const spoken = [closing?.reply ?? aiOutcome?.reply, firstHabitInvite]
      .filter(Boolean)
      .join('\n\n');

    return this.respond(updated, nextStep, spoken || null, {
      action: turnAction,
      // Luồng 4 — the reaction is the OTHER PERSON talking, so the bubble is
      // labelled with their name; without it the push-back reads as the Coach
      // suddenly making demands.
      speaker: aiOutcome?.speaker ?? null,
      userLine: dto.label?.trim() || text || null,
      samples: aiOutcome?.samples ?? [],
      sceneOptions: aiOutcome?.sceneOptionList ?? [],
      aiFailed: requiresAi(step) && Boolean(text) && !aiOutcome?.reply,
      promptKeyOverride:
        closing?.promptKeyOverride ??
        aiOutcome?.promptKeyOverride ??
        this.promptOverrideFor(step, nextStep, event, aiOutcome),
      promptArgs: closing?.promptArgs ?? null,
      noteKey: this.noteKeyFor({
        step,
        nextStep,
        event,
        session: updated,
        ctx,
        aiReplied: Boolean(aiOutcome?.reply),
      }),
    });
  }

  /**
   * A reply with its question sentences removed — for the last turn of a
   * scene, where a question has no box to land in. Null when nothing that
   * says anything survives; the caller then uses the fixed closing line.
   */
  private withoutQuestions(reply: string): string | null {
    const kept = reply
      .split(/(?<=[.!?。！？…])\s+/)
      .filter((sentence) => !/[?？]/.test(sentence))
      .join(' ')
      .trim();

    return kept.length >= 12 ? kept : null;
  }

  /** Fixed lines that REPLACE a step's own line on one specific transition. */
  private promptOverrideFor(
    step: CoachStep,
    nextStep: CoachStep,
    event: CoachEvent,
    aiOutcome: { reply: string | null } | null,
  ): string | null {
    // ⑤ — TELL_2 is re-entered on "Mình hiểu sai rồi. Vậy bạn kể lại giúp
    // mình: chuyện gì đã xảy ra?" rather than a fresh model question.
    if (event.kind === 'rejectDraft') return COACH_REDRAFT_KEY;

    // Nhịp 2's question when the model could not write one: a fixed question
    // about what happened, never a blank box. Only when nhịp 2 is where the
    // flow is actually going — the story beat itself now leads to the depth
    // question, whose line is written and must not be overridden.
    if (
      (step === CoachStep.DEPTH || step === CoachStep.STORY_TALK) &&
      nextStep === CoachStep.STORY_TALK &&
      !aiOutcome?.reply
    ) {
      return COACH_TELL_FOLLOW_UP_KEY;
    }

    return null;
  }

  /**
   * The fixed line said BEFORE the next step's own line.
   *
   * These are the design's acknowledgements — "Mình lưu nguyên văn câu bạn vừa
   * kể.", "Đó là câu của bạn, mình không sửa." — and they are fixed on
   * purpose: each one closes a beat, and a generated closing was the model
   * commenting on words it had been told not to touch.
   */
  private noteKeyFor(params: {
    step: CoachStep;
    nextStep: CoachStep;
    event: CoachEvent;
    session: CoachSession;
    ctx: CoachMachineContext;
    aiReplied: boolean;
  }): string | null {
    const { step, nextStep, event, session, ctx, aiReplied } = params;

    // The third "không có tình huống" in a row put the plan to sleep — the
    // line says so instead of promising to keep it.
    if (ctx.planSlept) return COACH_PLAN_SLEPT_KEY;
    if (event.kind === 'intent' && event.answer === CoachPlanAnswer.NONE) {
      return COACH_INTENT_NONE_KEY;
    }
    // The smaller commitment replaced the old one; the reminder came with it.
    if (event.kind === 'plan' && step === CoachStep.SHRINK) {
      return COACH_SHRINK_DONE_KEY;
    }
    // T4's one fixed line, ≤15 words, said ON THE WAY to the commitment
    // question rather than as a step of its own — "ra ở đâu: THẲNG tới Muốn
    // đặt Nhắc hẹn không?". No interpretation, no reflection, no model call.
    if (
      isShallowJot(
        step,
        nextStep,
        event.kind === 'ack'
          ? CoachTurnEventKind.ACK
          : CoachTurnEventKind.DEPTH,
        ctx.storyKind,
      )
    ) {
      return COACH_JOT_ACK_KEY;
    }

    // Nhịp 4 — "Đủ rồi". The way out of the scene, acknowledged in one written
    // line rather than left silent before the commitment question.
    if (event.kind === 'sceneAgain' && !event.again) return COACH_SCENE_DONE_KEY;

    if (event.kind !== 'text') return null;

    switch (step) {
      case CoachStep.INTENT_TELL:
        // DONE's reply is the model's praise; the fixed line stands in only
        // when it failed. MISSED is fixed by design — the shrink offer speaks.
        return session.lastIntent === CoachPlanAnswer.DONE
          ? aiReplied
            ? null
            : COACH_INTENT_TELL_DONE_ACK_KEY
          : COACH_INTENT_TELL_MISSED_ACK_KEY;
      case CoachStep.TWO_COLS:
      case CoachStep.REDRAFT:
        return COACH_PROBLEM_ACK_KEY;
      case CoachStep.SCENE_FEELING:
        // The feeling is heard in one fixed line; the scene's own question
        // follows it. No model call — commenting on a feeling is not its job.
        return COACH_SCENE_FEELING_ACK_KEY;
      case CoachStep.TELL_ONCE:
        // The scene's reply is the model's; this stands in only when it failed.
        return aiReplied ? null : COACH_SCENE_ACK_KEY;
      case CoachStep.SCENE_STAGE2:
        // Nhịp 5 skipped — the answer was too short to praise anything specific,
        // which the doc treats as a shortcut rather than a failure.
        return aiReplied ? null : COACH_SCENE_DONE_KEY;
      case CoachStep.RETRY_SCENE:
        return COACH_RETRY_ACK_KEY;
      default:
        return null;
    }
  }

  // --------------------------------------------------------------- persona

  /**
   * The voice, changed from the header at any step.
   *
   * Not a transition: nothing about where the reader is in the flow moves.
   * Remembered so the next session pre-lights it — never applied FOR them.
   */
  async setPersona(
    sessionId: string,
    persona: CoachPersona,
  ): Promise<{ persona: CoachPersona }> {
    const session = await this.sessionRepository.findActive(sessionId, this.userId);
    if (!session) throw new GoneException('Coach session is no longer available');

    await Promise.all([
      this.sessionRepository.updateOne(
        { _id: sessionId },
        { persona } as Partial<CoachSession>,
      ),
      this.profileService.rememberPersona(session.userId, persona),
    ]);

    return { persona };
  }

  // ---------------------------------------------------------------- rating

  // ------------------------------------------------------------ transcribe

  /**
   * Speech to the reader's own words.
   *
   * The bytes live for the length of this call and are written nowhere — the
   * design's rule is that voice becomes text and the recording is dropped, and
   * the only way to keep that promise is to never give the audio a home in the
   * first place. What comes back goes into the composer for the reader to edit
   * before they send it, so a bad transcription is theirs to fix rather than
   * something filed under their name.
   */
  async transcribe(dto: {
    audio: string;
    mimeType?: string;
    locale?: string;
  }): Promise<{ text: string }> {
    if (!(await this.configService.isEnabled())) {
      throw new ForbiddenException('Coach is disabled');
    }
    if (!this.ai.isConfigured()) {
      throw new BadRequestException('Coach AI is not configured');
    }

    const bytes = Buffer.from(dto.audio, 'base64');
    if (!bytes.length) throw new BadRequestException('Empty audio');

    try {
      const result = await this.ai.transcribe(
        bytes,
        dto.mimeType || 'audio/m4a',
        this.locale(dto.locale),
      );

      return { text: result.text };
    } catch (error: any) {
      // An empty string, not an error: the composer simply stays as it was and
      // the reader types instead. Failing loudly here would put an error in
      // front of somebody who just tried to say something difficult out loud.
      this.logger.warn(`Coach transcription failed: ${error?.message}`);

      return { text: '' };
    }
  }

  // ----------------------------------------------------------------- close

  async close(sessionId: string): Promise<{ closed: boolean }> {
    const userId = this.userId;
    const session = await this.sessionRepository.findActive(sessionId, userId);
    if (!session) throw new NotFoundException('Coach session not found');

    // A sheet closed mid-way is still a conversation that happened — and it is
    // the last thing it will ever be, so this is the pass that writes the
    // greeting for the next open.
    void detachedFromCoachDeadline(() =>
      this.extractMemoryFrom(session, sessionId, true),
    );

    await this.sessionRepository.updateOne(
      { _id: sessionId },
      {
        status: CoachSessionStatus.CLOSED,
        closedAt: new Date(),
      } as Partial<CoachSession>,
    );

    return { closed: true };
  }

  // ----------------------------------------------------------------- parts

  /**
   * ① stays quiet in two situations, and neither is an error.
   *
   * Two commitments already waiting means a third would be a backlog; a Coach
   * that already appeared in this lesson today has had its turn.
   */
  private async lessonDoorSilence(
    userId: string,
    tzOffsetMinutes: number,
    lessonId?: string | null,
  ): Promise<string | null> {
    // "Chỉ khi vừa thêm habit" — the door is about the habit the reader just
    // adopted, and with none there is nothing for it to say.
    const added = await this.newHabitsForLesson(
      userId,
      tzOffsetMinutes,
      lessonId ?? null,
    );
    if (!added.length) return COACH_SILENT_REASON.NO_NEW_HABIT;

    const pendingCount = await this.planService.countPending(userId);
    if (pendingCount >= LESSON_DOOR_MAX_PENDING_PLANS) {
      return COACH_SILENT_REASON.TOO_MANY_PENDING;
    }

    // "Đã mở hôm nay rồi" KHÔNG còn làm cửa này im.
    //
    // Cửa luồng 7 chỉ mở từ đúng một chỗ: người đọc bấm ⟨Tập thử ngay⟩ trên
    // lời mời "vừa thêm thói quen". Không có đường nào mở nó mà không phải một
    // cú bấm, nên cái chốt "một lần một ngày" chưa bao giờ chặn được một lần
    // hiện tự động — nó chỉ chặn được cú bấm THỨ HAI. Owner on-device
    // 2026-09-09: "nếu bấm đóng, sau đó bấm tập thử ngay ở đây thì sẽ bị out
    // luôn" — đóng sheet rồi bấm lại là rơi vào đúng nhánh im lặng này, sheet
    // mở ra rồi tự đóng ngay.
    //
    // Đây cũng chính là lý lẽ `open()` đã viết cho luồng 2/3 ngay phía trên:
    // "Both are explicit taps on an invitation, so the old door's silences ...
    // do not apply." Luồng 7 cũng là một cú bấm vào lời mời, chỉ là lúc đó
    // chưa ai áp lý lẽ ấy cho nó.
    //
    // Hai chốt còn lại ở trên vẫn giữ: không có habit mới thì không có gì để
    // nói, và quá nhiều lời hứa đang treo thì đừng thêm.
    return null;
  }

  /**
   * ① — "habit mới": adopted since the reader's own midnight.
   *
   * Read from `user_habits` (the app writes those rows, never the Coach) rather
   * than passed by the client: the drawing's data column reads "ĐỌC UserHabit",
   * and a client-supplied list could claim adoptions that never happened.
   * Today-wide rather than per-lesson because the adoption row does not record
   * the lesson — and a reader who adds a habit and finishes the NEXT lesson ten
   * minutes later still deserves the door.
   */
  /**
   * Habits adopted from THIS lesson today — not everything adopted since
   * midnight.
   *
   * `user_habits` records `sourceKeypointId`, so "added in today's lesson" —
   * which is what ①'s drawing means by "habit mới", and what this repository's
   * own comment promises — is answerable. Reading the whole day instead offered
   * habits picked up in an earlier lesson this morning as though they had just
   * been added (owner, 2026-09-05).
   *
   * A lesson that cannot be read falls back to the day: showing a habit the
   * reader did add today is a smaller wrong than showing none at all.
   */
  private async newHabitsForLesson(
    userId: string,
    tzOffsetMinutes: number,
    lessonId: string | null,
  ): Promise<string[]> {
    const rows = (await this.userHabitRepository
      .findCreatedSince(userId, this.startOfToday(tzOffsetMinutes))
      .catch(() => [])) as Array<{
      habitId?: unknown;
      sourceKeypointId?: unknown;
    }>;
    if (!rows.length || !lessonId) return this.uniqueHabitIds(rows);

    const [lesson] = (await this.lessonRepository
      .findByIds([lessonId])
      .catch(() => [])) as Array<{ keypoints?: unknown[] }>;
    const keypointIds = new Set(
      (lesson?.keypoints ?? []).map((id) => String(id)),
    );
    if (!keypointIds.size) return this.uniqueHabitIds(rows);

    const fromLesson = rows.filter(
      (row) =>
        row.sourceKeypointId && keypointIds.has(String(row.sourceKeypointId)),
    );

    // Older rows predate `sourceKeypointId`, so an empty result means "cannot
    // tell", not "none from this lesson".
    return this.uniqueHabitIds(fromLesson.length ? fromLesson : rows);
  }

  private uniqueHabitIds(rows: Array<{ habitId?: unknown }>): string[] {
    return [
      ...new Set(
        rows.map((row) => (row.habitId ? String(row.habitId) : '')).filter(Boolean),
      ),
    ];
  }

  /**
   * ②A's queue: pending commitments the sheet may ask about today.
   *
   * Two filters, both about time. A commitment made TODAY sits out — asking
   * "có dịp nào chưa?" ten minutes after somebody typed it is nagging, and the
   * fixed line ("Hôm trước bạn nói…") would be a lie. And one asked about since
   * yesterday's midnight sits out too — "nhắc hẹn nào vừa được hỏi hôm qua thì
   * bỏ qua vòng này". The bubble reads the same list, so the dot never promises
   * a question the sheet will not ask.
   */
  private async pendingForAsking(
    userId: string,
    tzOffsetMinutes: number,
    limit: number,
  ) {
    const today = this.startOfToday(tzOffsetMinutes);
    const yesterdayStart = new Date(today.getTime() - 24 * 60 * 60 * 1000);
    const justMade = new Date(Date.now() - COACH_PLAN_ASK_DELAY_MINUTES * 60_000);

    // A few more than needed: the filters below drop some.
    const all = await this.planService.findPending(userId, limit + 4);

    return all
      .filter((plan) => {
        const created =
          plan.createdAt instanceof Date ? plan.createdAt : null;
        // The doc's condition is "chưa hỏi hôm nay", not "chưa đặt hôm nay" —
        // a commitment made this morning and never asked about IS due. Only a
        // commitment made minutes ago is skipped: "có dịp nào chưa?" about
        // something promised before the sheet was even closed is absurd, and
        // the whole day's worth of exclusion is what made the check-in
        // unreachable for anyone testing on the day they set it up.
        const brandNew = created !== null && created >= justMade;
        const askedRecently =
          plan.lastAskedAt instanceof Date && plan.lastAskedAt >= yesterdayStart;

        return !brandNew && !askedRecently;
      })
      .slice(0, limit);
  }

  /**
   * ② — which branch of the Home door this session lands on, AND which habit
   * it is about.
   *
   * ②A: a pending commitment, and its habit. ④: a scene answered three weeks
   * ago, to answer again. ②B: neither; the habit most due for practice stands
   * in until the story says otherwise. Never null when the reader has any
   * habit — without one `attachSituation` has nothing to build a scene from.
   */
  private async resolveTier(
    userId: string,
    pending: Array<{ habitId?: string | null }>,
    tzOffsetMinutes: number,
  ): Promise<{
    tier: CoachHomeTier;
    habitId: string | null;
    situationId: string | null;
  }> {
    if (pending.length > 0) {
      return {
        tier: CoachHomeTier.PLAN,
        habitId: pending[0].habitId ?? null,
        situationId: null,
      };
    }

    // ④ at most once a day — see `getBubble`. Off this release: see
    // COACH_RETRY_DOOR_ENABLED.
    const retry =
      !COACH_RETRY_DOOR_ENABLED ||
      (await this.retryOfferedToday(userId, tzOffsetMinutes))
        ? null
        : await this.retryCandidate(userId);
    if (retry) {
      return {
        tier: CoachHomeTier.RETRY,
        habitId: retry.habitId,
        situationId: retry.situationId,
      };
    }

    // ②C — "kho habit còn rỗng, hoặc user đã luyện tập habit hôm nay rồi".
    const today = this.startOfToday(tzOffsetMinutes);
    const [ownedCount, practisedToday] = await Promise.all([
      this.userHabitRepository.countActiveForUser(userId).catch(() => 0),
      this.reflectionService
        .countAnswersBetween(userId, today, new Date())
        .catch(() => 0),
    ]);
    if (!ownedCount || practisedToday > 0) {
      return {
        tier: CoachHomeTier.GUIDED,
        // A habit is still settled up front when there IS a kho: "user không kể
        // gì → habit đến hạn luyện tập nhất trong kho". Without it a reader who
        // practised earlier today and then skips the opener has no task left at
        // all, and the session ends two lines after it began — which is what
        // "cụt" looked like on the simulator. Only an empty kho has no habit,
        // and that session ends on the course card instead.
        habitId: ownedCount ? await this.mostDueHabitId(userId) : null,
        situationId: null,
      };
    }

    return {
      tier: CoachHomeTier.FREE,
      // "Người dùng không kể gì thì chọn habit ĐẾN HẠN LUYỆN TẬP NHẤT trong
      // kho" (`ai-coach-tom-tat_2.md`). Not the first, and not random: the doc
      // wants the habit that has waited longest. When they DO tell a story, the
      // silent match overrides this later in the turn. ②A stays on the habit of
      // the commitment it is checking in on.
      habitId: await this.mostDueHabitId(userId),
      situationId: null,
    };
  }

  /**
   * The adopted habit that has waited longest for practice.
   *
   * "Đến hạn nhất" reads BOTH practice signals: HDDhistory's own check-in
   * (`lastCheckInDate`) and the latest scene answered in the Coach itself.
   * The Coach signal is what makes the queue MOVE — it used to read check-ins
   * alone, and practising a habit three times in the Coach still put the same
   * habit first on every open ("bấm 3 lần đều ra giữ tò mò", owner
   * 2026-08-28). A habit never practised anywhere comes first, then the
   * oldest practice, then the one adopted earliest. Still deterministic: the
   * same habit greets them until they actually practise it — but practising
   * it now counts. Null when the kho is empty.
   */
  private async mostDueHabitId(userId: string): Promise<string | null> {
    const [active, practised] = await Promise.all([
      this.userHabitRepository
        .findForUser(userId, UserHabitState.ACTIVE)
        .catch(() => []),
      this.reflectionService
        .latestPracticeByHabit(userId)
        .catch(() => new Map<string, Date>()),
    ]);
    const rows = active as Array<{
      habitId?: unknown;
      lastCheckInDate?: Date | null;
      startedAt?: Date | null;
    }>;

    const owned = rows.filter((row) => Boolean(row.habitId));
    if (!owned.length) return null;

    const at = (value?: Date | null) =>
      value ? new Date(value).getTime() : Number.NEGATIVE_INFINITY;
    const lastPractice = (row: (typeof owned)[number]) =>
      Math.max(
        at(row.lastCheckInDate),
        at(practised.get(String(row.habitId)) ?? null),
      );

    const due = owned.reduce((oldest, row) => {
      const gap = lastPractice(row) - lastPractice(oldest);
      if (gap !== 0) return gap < 0 ? row : oldest;

      return at(row.startedAt) < at(oldest.startedAt) ? row : oldest;
    });

    return String(due.habitId);
  }

  /**
   * The funnel — what happened at this turn, counted by week with no reader
   * attached. Fire-and-forget like every other metric here.
   */
  private countFunnel(
    step: CoachStep,
    event: CoachEvent,
    dto: CoachTurnDto,
    session: CoachSession,
  ) {
    const bump = (kind: CoachMetricKind, refId: string | null = null): void => {
      void this.metricService.bump(kind, refId);
    };

    switch (event.kind) {
      case 'planAsk':
        return bump(
          event.accept ? CoachMetricKind.PLAN_ASK_YES : CoachMetricKind.PLAN_ASK_NO,
        );
      case 'intent':
        if (event.answer === CoachPlanAnswer.DONE) return bump(CoachMetricKind.INTENT_DONE);
        if (event.answer === CoachPlanAnswer.MISSED) return bump(CoachMetricKind.INTENT_MISSED);

        return bump(CoachMetricKind.INTENT_NONE);
      case 'shrink':
        return bump(
          event.accept ? CoachMetricKind.SHRINK_ACCEPTED : CoachMetricKind.SHRINK_KEPT,
        );
      case 'course':
        if (dto.courseAction === CoachCourseAction.OPEN) return bump(CoachMetricKind.COURSE_OPENED);
        if (dto.courseAction === CoachCourseAction.SAVE) return bump(CoachMetricKind.COURSE_SAVED);

        return bump(CoachMetricKind.COURSE_SKIPPED);
      case 'text':
        // The FIRST answer to a scene — the one that is filed. The feeling
        // beat is the lead-in, not the answer; counting it would double every
        // scene.
        if (
          isSituationStep(step) &&
          step !== CoachStep.SCENE_FEELING &&
          (session.situationRound ?? 0) === 0
        ) {
          return bump(CoachMetricKind.SCENE_ANSWERED);
        }

        return;
      default:
        return;
    }
  }

  /** ④ was already put in front of the reader today, answered or not. */
  private async retryOfferedToday(
    userId: string,
    tzOffsetMinutes: number,
  ): Promise<boolean> {
    return this.sessionRepository.existsSince({
      userId,
      entry: CoachEntry.HOME,
      tier: CoachHomeTier.RETRY,
      since: this.startOfToday(tzOffsetMinutes),
    });
  }

  /**
   * ④ — a scene this reader answered at least three weeks ago and not since.
   *
   * The same gap the recap's "ĐỔI THAY" block uses, so a second answer taken
   * here is exactly the pair that block will set side by side.
   */
  private async retryCandidate(
    userId: string,
  ): Promise<{ situationId: string; habitId: string | null } | null> {
    const before = new Date(
      Date.now() - CHANGE_BLOCK_MIN_WEEKS * 7 * 24 * 60 * 60 * 1000,
    );

    return this.reflectionService
      .findRetryCandidate(userId, before)
      .catch(() => null);
  }

  /** Did the reader start today low? Read once at open; the MOOD answer then owns the flag. */
  private async startMoodLowToday(
    userId: string,
    tzOffsetMinutes: number,
  ): Promise<boolean> {
    const today = this.dayLogService.localDate(tzOffsetMinutes);
    const logs = await this.dayLogService.findBetween(userId, today, today);

    return logs.some(
      (log) =>
        log.moment === DayLogMoment.START &&
        typeof log.mood === 'number' &&
        (COACH_MOOD_LOW_VALUES as readonly number[]).includes(log.mood),
    );
  }

  /** Today's start mood as a number, or null when it was never answered. */
  private async startMoodValueToday(
    userId: string,
    tzOffsetMinutes: number,
  ): Promise<number | null> {
    const today = this.dayLogService.localDate(tzOffsetMinutes);
    const logs = await this.dayLogService
      .findBetween(userId, today, today)
      .catch(() => []);

    const start = logs.find(
      (log) => log.moment === DayLogMoment.START && typeof log.mood === 'number',
    );

    return (start?.mood as number) ?? null;
  }

  private buildContext(
    session: CoachSession,
    ratingHidden: boolean,
    lateNightLow = false,
  ): CoachMachineContext {
    return {
      entry: session.entry,
      tier: session.tier,
      // Every ordinary session is past its opening by the time a turn arrives,
      // so the mood was asked (or skipped) already. The ONBOARDING session is
      // the exception: it opens before the mood, and `afterOnboarding` reads
      // this flag to decide whether the mood question still owes — probe
      // 2026-09-04 showed it landing on HUB with the mood never asked.
      moodAlreadyAskedToday: session.onboarding ? session.moodStart != null : true,
      planQueueLength: session.planQueue.length,
      planIndex: session.planIndex,
      planSlept: false,
      ratingHidden,
      moodLow: Boolean(session.moodLow),
      newHabitCount: session.newHabitIds?.length ?? 0,
      // The task registry, read off the session. `hasPlanPending` and
      // `hasStage2` are filled in by the caller, which is the only place that
      // knows what the queue and the scene on screen actually hold.
      tasksRun: session.tasksRun ?? 0,
      t1Done: session.t1Done ?? false,
      t2Done: session.t2Done ?? false,
      t3Done: session.t3Done ?? false,
      // Home picks its habit at SCENE_PICK, so "can practise a scene" is about
      // the KHO, not about this session — reading `habitId` here is what left
      // the coordinator with only "Kể chuyện hôm nay" on it (owner, 2026-09-04).
      hasHabit:
        session.entry === CoachEntry.HOME
          ? (session.khoSize ?? 0) > 0
          : Boolean(session.habitId),
      // "Phiên đã có một dip thật" — the phrase they typed after "Gặp rồi", or a
      // story they actually told. A twenty-second jot is not an occasion.
      hasDip: Boolean(session.dip?.trim()) || Boolean(session.storyTold),
      t4Offered: session.t4Offered ?? false,
      cardShown: session.cardShown ?? false,
      closing: session.closing ?? false,
      hasPlanPending: session.planIndex < session.planQueue.length,
      storyTold: session.storyTold ?? false,
      moodEndAsked: session.moodEndAsked ?? false,
      ratingAsked: session.ratingAsked ?? false,
      moodEndLow: session.moodEndLow ?? false,
      hasCourse: false,
      hasScene: true,
      lateNightLow,
      draftRejected: session.draftRejected,
      situationRound: session.situationRound ?? 0,
      sceneContinues: false,
      // A scripted scene decides its own turn count from the beats snapshotted
      // when it was shown; a legacy scene leaves these unset and the machine
      // falls back to the old improvised ceiling.
      talkMode: session.talkMode ?? null,
      // Luồng 1 — still inside the onboarding while its steps are running.
      onboarding: Boolean(session.onboarding) && isOnboardStep(session.step),
      viLocale: session.locale === 'vi',
      // Luồng 5 — the quiz snapshot decides the pill and the turn count.
      hasQuiz: (session.quizItems?.length ?? 0) > 0,
      quizDone:
        (session.quizItems?.length ?? 0) > 0 &&
        (session.quizResults?.length ?? 0) >= (session.quizItems?.length ?? 0),
      quizRemaining:
        (session.quizItems?.length ?? 0) - (session.quizIndex ?? 0),
      sceneScripted: (session.sceneBeats?.length ?? 0) > 0,
      sceneRounds:
        (session.sceneBeats?.length ?? 0) > 0
          ? Math.min(session.sceneBeats!.length, SITUATION_MAX_BEATS) + 1
          : undefined,
      intentMissed: session.lastIntent === CoachPlanAnswer.MISSED,
    };
  }

  /** The skill's rubric criteria, or an empty list when the habit has none. */
  private async rubricFor(habitId: string, locale: string) {
    const habit = (await this.habitLibraryService
      .findOne(habitId)
      .catch(() => null)) as { rubric?: ITranslation | null } | null;

    return this.scoreService.parseRubric(habit?.rubric ?? null, locale);
  }

  /**
   * Tầng 4 — assess the finished scene, file the score, and build the card.
   *
   * Runs once, between the last answer and the card. Best-effort by design: a
   * provider failure returns null and the caller routes past the card to the
   * commitment, because a reader who has just practised something must never
   * meet an error screen holding their answer.
   */
  private async scoreScene(
    session: CoachSession,
    rubric: Array<{ key: string; label: string }>,
    lastAnswer: string,
  ): Promise<{ card: ICoachSession['sceneScore'] } | null> {
    if (!rubric.length || !session.habitId) return null;

    const scene = session.situationId
      ? ((await this.situationService
          .findById(session.situationId)
          .catch(() => null)) as {
          prompt?: string;
          takeaway?: string | null;
          goodMove?: string | null;
        } | null)
      : null;
    if (!scene?.prompt) return null;

    // The transcript must include the answer just sent — it is usually the one
    // that matters most, since it is where they either held the line or folded.
    const transcript = [
      ...session.turns.map((t) => ({
        role: t.role === CoachTurnRole.COACH ? ('coach' as const) : ('user' as const),
        text: t.text,
      })),
      ...(lastAnswer ? [{ role: 'user' as const, text: lastAnswer }] : []),
    ];

    const result: CoachSceneScoreResult | null = await this.ai
      .scoreScene(
        {
          locale: session.locale,
          step: CoachStep.SCENE_SCORE,
          persona: session.persona,
          script: null,
          habitTitle: await this.habitTitleOf(session.habitId, session.locale),
          habitContext: null,
          transcript,
          input: lastAnswer,
        },
        rubric,
        {
          prompt: scene.prompt,
          takeaway: scene.takeaway ?? null,
          goodMove: scene.goodMove ?? null,
        },
      )
      .catch((error: any) => {
        this.logger.warn(`Coach scene scoring failed: ${error?.message}`);

        return null;
      });
    if (!result?.criteria?.length) return null;

    const labels = new Map(rubric.map((c) => [c.key, c.label]));
    const criteria = result.criteria.map((c) => ({
      key: c.key,
      label: labels.get(c.key) ?? c.key,
      score: c.score,
      note: c.note || null,
    }));
    const overall =
      Math.round(
        (criteria.reduce((sum, c) => sum + c.score, 0) / criteria.length) * 10,
      ) / 10;

    // Filed BEFORE the card is built: the skill number on the card has to
    // include the scene it is reporting on, or the reader watches a number that
    // is always one practice behind.
    await this.scoreService.record({
      userId: session.userId,
      habitId: session.habitId,
      situationId: session.situationId ?? null,
      level: session.sceneLevel ?? SITUATION_START_LEVEL,
      criteria: criteria.map(({ key, score, note }) => ({ key, score, note })),
      overall,
      strength: result.strength || null,
      improve: result.improve || null,
      tip: result.tip || null,
      retry: session.sceneRetried ?? false,
    });

    return {
      card: {
        criteria,
        overall,
        strength: result.strength || null,
        improve: result.improve || null,
        tip: result.tip || null,
        betterPhrasing: result.betterPhrasing || null,
      },
    };
  }

  /**
   * The slice of the scene's script the reply needs THIS turn.
   *
   * On a non-final probe it hands over that beat's intent, so the question is
   * the authored one rather than an improvised guess; on the closing turn it
   * hands over the lesson to land and the move to offer. Empty on legacy scenes
   * (no `sceneBeats`), which keep the old improvised behaviour.
   */
  private sceneScriptFor(
    session: CoachSession,
    step: CoachStep,
  ): {
    sceneBeatIntent?: string | null;
    sceneBeatLine?: string | null;
    sceneCounterpart?: string | null;
    sceneTakeaway?: string | null;
    sceneGoodMove?: string | null;
  } {
    if (!isSituationProbeStep(step)) return {};

    // The authored PROBES are gone with the doc of 2026-08-27: a scene takes two
    // answers and each reply has a fixed shape (a-b-c, then the one difference),
    // so there is no beat for the model to walk. What survives of the script is
    // the lesson and the move — both belong to the reply that closes the scene.
    return {
      sceneBeatIntent: null,
      sceneBeatLine: null,
      sceneCounterpart: session.sceneCounterpart ?? null,
      sceneTakeaway: session.sceneTakeaway ?? null,
      sceneGoodMove: session.sceneGoodMove ?? null,
    };
  }

  /** The reader's own day as a whole number — rotates the opener's variant. */
  private localDayOf(session: CoachSession): number {
    const shifted = Date.now() + session.tzOffsetMinutes * 60 * 1000;

    return Math.floor(shifted / 86_400_000);
  }

  /**
   * Is this a low day, late at night?
   *
   * Both halves matter: late alone is fine, and low alone is exactly what the
   * feature is for. Together they are the one combination where asking someone
   * to go deeper makes the night worse.
   */
  private isLateNightLow(session: CoachSession): boolean {
    const now = new Date();
    const localMinutes =
      (now.getUTCHours() * 60 + now.getUTCMinutes() + session.tzOffsetMinutes + 1440) % 1440;

    return localMinutes / 60 >= COACH_LATE_NIGHT_HOUR && Boolean(session.moodLow);
  }

  /** ②A "chưa gặp dịp": would THIS answer be the third in a row? */
  private async wouldSleep(planId: string): Promise<boolean> {
    const plan = await this.planService.findById(planId);
    if (!plan) return false;

    return plan.consecutiveNoOccasion + 1 >= NO_OCCASION_SLEEP_LIMIT;
  }

  private toEvent(dto: CoachTurnDto): CoachEvent | null {
    switch (dto.kind) {
      case CoachTurnEventKind.MOOD:
        return dto.mood ? { kind: 'mood' } : null;
      case CoachTurnEventKind.PICK_NEW:
        return dto.habitId ? { kind: 'pickNew' } : null;
      case CoachTurnEventKind.TEXT:
        return dto.text?.trim() ? { kind: 'text' } : null;
      case CoachTurnEventKind.SKIP:
        return { kind: 'skip' };
      case CoachTurnEventKind.INTENT:
        return dto.answer ? { kind: 'intent', answer: dto.answer } : null;
      case CoachTurnEventKind.DEPTH:
        return { kind: 'depth', deep: Boolean(dto.deep) };
      case CoachTurnEventKind.SHRINK:
        return { kind: 'shrink', accept: Boolean(dto.accept) };
      case CoachTurnEventKind.CONTEXT:
        return { kind: 'context', keep: dto.keep !== false };
      case CoachTurnEventKind.INVITE:
        return { kind: 'invite', accept: Boolean(dto.accept) };
      case CoachTurnEventKind.ACK:
        return { kind: 'ack' };
      case CoachTurnEventKind.SCENE_AGAIN:
        return { kind: 'sceneAgain', again: Boolean(dto.again) };
      case CoachTurnEventKind.SCENE_MET:
        return { kind: 'sceneMet', met: Boolean(dto.met) };
      case CoachTurnEventKind.STOP:
        return { kind: 'stop' };
      case CoachTurnEventKind.TASK:
        // `summary`/`talkQuiz` đã được `turn()` dịch thành `pick` trước khi tới
        // đây, nên chúng không bao giờ lọt vào nhánh này — loại tường minh để
        // kiểu khớp `CoachTask` và để bất biến đó đọc được ngay tại chỗ.
        return dto.task && dto.task !== 'summary' && dto.task !== 'talkQuiz'
          ? { kind: 'task', task: dto.task }
          : null;
      case CoachTurnEventKind.SCENE_SCORE:
        return { kind: 'sceneScore', retry: Boolean(dto.retry) };
      // Luồng 5 — the Habit screen's two answers.
      case CoachTurnEventKind.CHECKIN:
        return { kind: 'checkin', done: Boolean(dto.done) };
      case CoachTurnEventKind.QUIZ_ANSWER:
        return dto.quizAnswer !== undefined && dto.quizAnswer !== null
          ? { kind: 'quizAnswer' }
          : null;
      // Luồng 2/3 — a chip pick (its value rides in the context) and the quiz's return.
      case CoachTurnEventKind.PICK:
        return dto.value?.trim() ? { kind: 'pick' } : null;
      case CoachTurnEventKind.QUIZ_DONE:
        return { kind: 'quizDone' };
      case CoachTurnEventKind.PLAN_ASK:
        return { kind: 'planAsk', accept: Boolean(dto.accept) };
      case CoachTurnEventKind.PLAN:
        return dto.planContext?.trim() && dto.planAction?.trim()
          ? { kind: 'plan' }
          : null;
      case CoachTurnEventKind.SCHEDULE:
        return { kind: 'schedule' };
      case CoachTurnEventKind.LOOP:
        return { kind: 'loop', keepGoing: Boolean(dto.keepGoing) };
      case CoachTurnEventKind.COURSE:
        return dto.courseAction
          ? {
              kind: 'course',
              open: dto.courseAction === CoachCourseAction.OPEN,
              harder: dto.courseAction === CoachCourseAction.HARDER,
            }
          : null;
      case CoachTurnEventKind.MOOD_END:
        return dto.mood ? { kind: 'moodEnd' } : null;
      case CoachTurnEventKind.RATING:
        return { kind: 'rating' };
      case CoachTurnEventKind.NEXT_SESSION:
        return { kind: 'nextSession', again: Boolean(dto.again) };
      case CoachTurnEventKind.ESCAPE:
        return { kind: 'escape' };
      case CoachTurnEventKind.REJECT_DRAFT:
        return { kind: 'rejectDraft' };
      case CoachTurnEventKind.ACK:
        return { kind: 'ack' };
      default:
        return null;
    }
  }

  /**
   * The model half of a turn.
   *
   * Three jobs and no more: nhịp 2's one question about what happened, nhịp
   * 3's draft, and the one reply after a scene. Every path swallows provider
   * failures and returns a null reply instead: `respond` then falls back to a
   * fixed line. Someone mid-sentence about something hard must never meet an
   * error screen.
   */
  /**
   * Điều chính user đã khai ở onboarding, dựng thành mấy dòng cho prompt.
   *
   * Đọc `coach_profiles` mỗi lượt có gọi AI: đó là một read có index, đứng
   * cạnh một call Gemini nên không đáng kể — và để nó ở đây thì không phải
   * bơm profile xuyên qua năm tầng gọi.
   *
   * Null khi user chưa khai gì: thiếu khối này còn hơn có một khối rỗng, vì
   * một danh sách trống làm model tưởng nó ĐÃ hỏi mà user từ chối trả lời.
   */
  /**
   * Cô đọng phần CHƯA cô đọng của một phiên, rồi ghi lại vạch.
   *
   * Vạch (`memoryExtractedAt`) sống trên doc phiên vì nó là trạng thái của một
   * cuộc nói chuyện; module memory trả về vạch mới và chỗ này ghi nó, để module
   * đó không phải biết gì về schema của phiên.
   *
   * `final` = phiên này sẽ không nói gì nữa (END, hoặc người ta đóng sheet):
   * đó là lần duy nhất xin thêm mảnh chủ đề cho câu chào lần mở sau.
   */
  private async extractMemoryFrom(
    session: CoachSession,
    sessionId: string,
    final: boolean,
  ): Promise<void> {
    // Đọc lại vạch từ DB chứ không tin `session` trong tay: một phiên dài cô
    // đọng nhiều lần, và bản `session` ở đây có thể đã được đọc trước lần cô
    // đọng ngay trước đó. Tin bản cũ là đọc lại một đoạn đã đọc, tức đúng thứ
    // thay đổi này sinh ra để bỏ.
    const fresh = await this.sessionRepository
      .findOne({ _id: sessionId })
      .catch(() => null);
    const since =
      (fresh as CoachSession | null)?.memoryExtractedAt ??
      session.memoryExtractedAt ??
      null;

    const mark = await this.memoryService.extractFromSession({
      userId: session.userId,
      sessionId,
      locale: session.locale,
      since,
      final,
    });

    if (!mark) return;

    await this.sessionRepository
      .updateOne({ _id: sessionId }, { memoryExtractedAt: mark })
      .catch((error: any) =>
        this.logger.warn(
          `Coach could not store the memory watermark: ${error?.message}`,
        ),
      );
  }

  private async readerFactsFor(userId: string): Promise<string | null> {
    try {
      const p = await this.profileService.get(userId);
      const lines: string[] = [];

      const job = [p.occupation, p.occupationRaw]
        .map((v) => v?.trim())
        .filter(Boolean);
      if (job.length) {
        lines.push(
          `- what they do: ${job[0]}${job[1] && job[1] !== job[0] ? ` (their own words: "${job[1]}")` : ''}`,
        );
      }
      if (p.goalText?.trim()) {
        lines.push(`- what they want to get better at: ${p.goalText.trim()}`);
      }
      if (p.barrierText?.trim()) {
        lines.push(`- what gets in the way: ${p.barrierText.trim()}`);
      }
      if (p.currentPractice?.trim()) {
        lines.push(`- what they already do about it: ${p.currentPractice.trim()}`);
      }

      return lines.length ? lines.join('\n') : null;
    } catch (error: any) {
      this.logger.warn(`Coach could not read the reader's facts: ${error?.message}`);

      return null;
    }
  }

  private async runAi(
    session: CoachSession,
    step: CoachStep,
    event: CoachEvent,
    text: string,
    ctx: CoachMachineContext,
  ): Promise<{
    reply: string | null;
    samples?: string[];
    sceneOptionList?: CoachSceneOption[];
    lines?: string[];
    /** ②B — the story quietly matched one of the reader's own habits. */
    matchedHabitId?: string | null;
    /** How sure the silent match was, 0..1 — gates the course card, not the reply. */
    matchConfidence?: number;
    /** False when the model says the line did not attempt the step's question. */
    engaged?: boolean;
    /** Set when the guard replaced a banned question with the fixed line. */
    promptKeyOverride?: string | null;
    /** The scene's closing reply: what to do next time, and when — for the form. */
    nextMove?: string | null;
    nextMoment?: string | null;
    /** Nhịp 4 — the keypoint this reply spoke from, for the tail's course card. */
    keypointId?: string | null;
    /** STORY_TALK — what kind of line the model says it answered. */
    storyKind?: CoachStoryKind | null;
    /** STORY_TALK — this reply named the recurring subject. */
    patternNamed?: boolean;
    /** Luồng 4 — the judge's verdict on the scene, read from both lines. */
    sceneOnTrack?: boolean | null;
    /** Luồng 4 — the other person answered this line; the next one is the scored one. */
    sceneReacted?: boolean;
    /** Luồng 4 — the reader's first line, kept for the verdict. */
    sceneFirstLine?: string;
    /** Luồng 4 — who said the reaction, for the bubble's label. */
    speaker?: string | null;
    /** Luồng 4 — the other person spoke; the scene is scored on the NEXT line. */
    awaitingSecondLine?: boolean;
    /** The ways forward the reaction named, packed `key|label|text`. */
    sceneOptions?: string[];
    /** How the answered line sat — appended to the scene's run of postures. */
    scenePosture?: CoachScenePosture;
  } | null> {
    // Nhịp 1 — the first thing they tell the Coach. Typed at the coordinator it
    // is the same thing: `advance(HUB, text)` treats an unrouted line as nhịp 1
    // of the story task and never re-asks the opener, so the silent habit match
    // has to run here too. Without this, ②B/②C — which OPEN on the coordinator
    // now — lost the match entirely: the session never settled on the habit the
    // story was about, and ②C's reflection and course card never happened.
    const isStory =
      event.kind === 'text' &&
      Boolean(text) &&
      (step === CoachStep.STORY ||
        (step === CoachStep.HUB && !ctx.hubRoute));

    // "Kể sâu hơn" — by pill, or read off what they typed. Nhịp 2's question is
    // paid for HERE and not at nhịp 1 any more: a reader who chooses to file
    // their sentence instead costs zero calls, which is what T4 promises.
    const goingDeep =
      step === CoachStep.DEPTH &&
      ((event.kind === 'depth' && event.deep) ||
        (event.kind === 'text' && ctx.depthGuess === 'deep'));

    // T1 nhánh ① — the câu kể earns the one reply the check-in is allowed:
    // "nhắc lại MỘT cụm chữ của chính user + khen MỘT điều cụ thể" (1 call).
    // MISSED keeps its fixed lines; DONE's fixed ack stays as the fallback.
    const isIntentDone =
      step === CoachStep.INTENT_TELL &&
      session.lastIntent === CoachPlanAnswer.DONE &&
      Boolean(text);

    // "Lần 2 gõ quá ngắn để so sánh → bỏ hẳn nhịp 5, không gọi AI lần hai."
    // The fixed closing line stands in — see `COACH_SCENE_DONE_KEY`.
    // "User không trả lời chặng hai hoặc gõ quá ngắn → bỏ nhịp 5, thẳng nhịp 6,
    // không gọi AI lần hai."
    const tooShortToCompare =
      step === CoachStep.SCENE_STAGE2 &&
      text.trim().split(/\s+/).length < SCENE_COMPARE_MIN_WORDS;

    // 6b answered with nothing worth keeping — no mirror, no call. A QUESTION
    // back still earns its call (the reply answers it, mẫu #13).
    const sceneDidSilent =
      step === CoachStep.SCENE_DID &&
      text.trim().split(/\s+/).filter(Boolean).length < SCENE_DID_MIN_WORDS;

    if (
      tooShortToCompare ||
      sceneDidSilent ||
      // A stop read off the words costs nothing — the fixed line answers it.
      ctx.storyKind === CoachStoryKind.STOP ||
      (!isStory && !goingDeep && !isIntentDone && !(requiresAi(step) && text))
    ) {
      return null;
    }

    const beat =
      step === CoachStep.NEXT_ACTION ? await this.keypointBeat(session) : {};

    // Luồng 1 — how they asked to be addressed, and how they like to learn.
    const reader = await this.profileService.get(session.userId).catch(() => null);

    // Thẻ nhớ, và chữ nguyên văn nếu user vừa hỏi thẳng về quá khứ.
    //
    // Song song với `readerFactsFor` chứ không xếp hàng sau nó: cả ba đều ở
    // trên clock của user, và ba await nối nhau trong một object literal là ba
    // lượt đi về database trước khi call AI kịp bắt đầu.
    //
    // `recallFor` không tốn query nào ở lượt bình thường — nó rẽ ra ngay ở
    // regex, và chỉ đi tìm khi câu vừa gõ đúng là một câu hỏi về quá khứ.
    const [readerCard, readerRecall, readerFacts] = await Promise.all([
      this.memoryService.cardFor(session.userId),
      this.memoryService.recallFor(session.userId, text),
      this.readerFactsFor(session.userId),
    ]);

    const turnContext: CoachTurnContext = {
      locale: session.locale,
      // Luồng 5 — the sentence about the occasion is acknowledged the way ②A's
      // "đã làm được" was: quote one phrase, name one hard thing, ask nothing.
      step: step === CoachStep.CHECKIN_TELL ? CoachStep.INTENT_TELL : step,
      address: reader?.address ?? null,
      readerStyle: reader?.learningStyle ?? null,
      persona: session.persona,
      script: null,
      habitTitle: await this.habitTitleOf(session.habitId, session.locale),
      habitContext: null,
      // The lesson's material rides along on the scene steps only — it is what
      // the closing reply sets beside the reader's choice. Everywhere else the
      // model still knows only the habit's name.
      habitMaterial:
        isSituationProbeStep(step) || step === CoachStep.NEXT_ACTION
          ? await this.situationService
              .materialFor(session.habitId, session.locale)
              .catch(() => null)
          : null,
      // Nhịp 4 — the one idea to pass on, chosen here so the session can
      // remember which keypoint it used and the tail can offer the course that
      // holds it. Retrieved, never named by the model.
      keypointTitle: beat.keypointTitle ?? null,
      keypointBody: beat.keypointBody ?? null,
      transcript: session.turns.map((t) => ({
        role: t.role === CoachTurnRole.COACH ? ('coach' as const) : ('user' as const),
        text: t.text,
      })),
      // THẺ NHỚ — mọi thứ Coach biết về người này, dựng sẵn lúc cô đọng, cap
      // cứng. Trước 2026-09-17 khối nhớ chỉ có ở prompt kể chuyện; giờ nó vào
      // cả lời nhìn lại, bài học và câu chốt — tức mọi chỗ người ta nói
      // chuyện.
      readerCard,
      // Chỉ có mặt ở lượt user hỏi thẳng về quá khứ của họ.
      readerRecall,
      // Điều user tự khai ở onboarding. Trước đây chỉ prompt sinh cảnh có,
      // nên hỏi "tôi làm nghề gì" thì Coach nói không biết.
      readerFacts,
      // ĐUÔI phiên trước KHÔNG nằm ở đây: chỉ prompt kể chuyện đọc nó, nên nó
      // được lấy trong `runStoryTalk`. Ở đây thì mọi bước — kể cả cho điểm một
      // cảnh, chấm một câu quiz — đều phải chờ một query không ai dùng.

      input: text,
      situationRound: isSituationProbeStep(step)
        ? (session.situationRound ?? 0)
        : null,
      situationRoundsTotal: isSituationProbeStep(step)
        ? situationRoundsFor(ctx)
        : null,
      // The a-b-c reply is followed on the very next line by the scene's
      // authored second stage — part b must lead into it, not invent its own.
      sceneStage2:
        step === CoachStep.TELL_ONCE
          ? (session.scenePromptStage2 ?? null)
          : null,
      // The scene's authored script, so the reply walks the intended beats
      // instead of improvising: the probe's own intent on a non-final turn, the
      // lesson and the move to offer on the closing one. All null on legacy
      // scenes (no `sceneBeats`), which keep the improvised path.
      ...this.sceneScriptFor(session, step),
    };

    try {
      // Nhịp 1 — the story is heard, and ONE silent match runs on it: ②B picks
      // which of the reader's own habits the session is about, ②C which habit
      // of the whole catalogue the story is about. Nothing is said back yet;
      // the next thing the reader sees is the depth question, whose words are
      // written, not generated.
      if (isStory) {
        const guided = session.tier === CoachHomeTier.GUIDED;
        const matching =
          guided || session.tier === CoachHomeTier.FREE
            ? this.runSilentMatch(turnContext, session).catch(() => null)
            : Promise.resolve(null);

        // The FIRST line of a story used to be met with silence, because the
        // written depth question came next and said the only thing that was
        // said. Home has no depth question any more (luồng 4), so silence is
        // all the reader got — they told the Coach about their day and nothing
        // came back (probe, 2026-09-04). The story reply is written here, and
        // the silent match runs alongside it rather than before it.
        if (session.entry !== CoachEntry.LESSON) {
          const [matched, talked] = await Promise.all([
            matching,
            this.runStoryTalk(session, turnContext, ctx, text),
          ]);

          return {
            ...talked,
            matchedHabitId: matched?.habitId ?? null,
            matchConfidence: matched?.confidence ?? 0,
          };
        }

        // ②B stays silent: the written depth question is the next thing said.
        // ②C is the one tier where the match's own line is used — "phản chiếu
        // lời user", the reflection that carries the course card, and the only
        // reply that branch gets.
        const matched = await matching;

        return {
          reply: guided ? (matched?.reply ?? null) : null,
          matchedHabitId: matched?.habitId ?? null,
          matchConfidence: matched?.confidence ?? 0,
        };
      }

      // The story conversation — the depth answer that opens it, and every
      // line inside it. One call: the reply, and the kind of line it answered.
      // Asked about the story itself when the depth answer was a pill.
      if (goingDeep || step === CoachStep.STORY_TALK) {
        // Routed to a task: "muốn luyện tình huống tiếp" is a REQUEST, not a
        // story about their day. Answering it as a story and then starting the
        // task is what put a scene-shaped paragraph above "Hà muốn tập cái nào
        // trong kho của Hà?" — two replies to one line, in the wrong order.
        // Asked for a different scene from inside one. Allowed: the new scene
        // is the whole reply. Refused: say why — the graph held the step, so
        // without a line here the request would meet silence.
        if (ctx.sceneSwapAsked && isInScene(step)) {
          return sceneOnRequest(ctx)
            ? { reply: null }
            : {
                reply: this.fixedLine(COACH_SCENE_NOT_NOW_ENOUGH, session),
              };
        }

        // Suppressed ONLY when the request really is about to start a task —
        // `storyTalkLeaves` is the same predicate the graph routes on, so the
        // two cannot disagree and leave a turn with no answer in the gap.
        if (step === CoachStep.STORY_TALK && ctx.hubRoute) {
          if (storyTalkLeaves(ctx)) return { reply: null };

          // They asked for a scene and may not have one. Say which of the two
          // reasons it is: one of them is "add a habit", the other is "come
          // back tomorrow", and answering with a story question said neither.
          if (ctx.hubRoute === 'T2') {
            return {
              reply: this.fixedLine(
                ctx.hasHabit
                  ? COACH_SCENE_NOT_NOW_ENOUGH
                  : COACH_SCENE_NOT_NOW_NO_HABIT,
                session,
              ),
            };
          }

          // T1/T4 are not reachable from inside the conversation, and a line
          // that merely MENTIONS a reminder is not a request to open one. Fall
          // through and answer it as the story it is.
        }

        const said = text || this.lastReaderLine(session) || '';

        return this.runStoryTalk(session, turnContext, ctx, said);
      }

      // PARKED — nhịp 2's answer used to build the two columns. A session
      // standing on TELL_2 still gets its draft. No reply: `coach.prompt.twoCols`
      // says this in five languages.
      if (step === CoachStep.TELL_2) {
        const drafted = await this.ai.draftTwoCols(turnContext);

        return {
          reply: null,
          lines: this.tidyDraftLines(drafted.lines, this.coachLines(session)),
        };
      }

      // Luồng 2 — what they remember, or their answer to the summary's
      // question: the one ≤25-word reply that may advise about the move.
      // Luồng 2 — a follow-up question on the open floor. Same lesson text as
      // the grading turn, plus the course's skill as the fence the answer may
      // range inside (owner 2026-09-05: "tự do trong chủ đề kỹ năng").
      if (step === CoachStep.TALK_FREE) {
        const { title, body } = await this.talkBodyFor(session);
        const asked = await this.ai
          .lessonTalk(turnContext, {
            mode: 'free',
            scope: session.summaryScope ?? 'keypoint',
            title,
            body,
            skillTitle: await this.talkSkillTitleFor(session),
          })
          .catch(() => ({ reply: null as string | null }));

        // A failed answer still SPENDS the turn (the counter is bumped by the
        // caller either way): a model that errors must not become an unlimited
        // supply of free turns.
        return { reply: asked.reply || this.fixedLine(COACH_TALK_FREE_FALLBACK_LINE, session) };
      }

      if (step === CoachStep.TALK_ASK || step === CoachStep.TALK_SUMMARY) {
        // Chấm phần nhớ được thì phải có bài để đối chiếu (owner 2026-09-04) —
        // trước đây mode này chỉ khuyên nên không cần `body`. Không đọc được
        // bài thì prompt tự rơi về "ghi nhận một câu rồi dừng" chứ không bịa.
        const { title, body } = await this.talkBodyFor(session);
        const talked = await this.ai.lessonTalk(turnContext, {
          mode: 'reply',
          scope: session.summaryScope ?? 'keypoint',
          title,
          body,
        });

        return { reply: talked.reply || null, engaged: talked.engaged };
      }

      // Held on a question back: the step's own AI would score their question
      // AS the answer (the scene judge) or react to it in character (the
      // scene's other person). Neither answers them. The story path does —
      // its `asks_how` branch is written to "answer their question plainly" —
      // and the step re-asks itself underneath the reply.
      if (ctx.readerAsksBack && holdsOnQuestion(step)) {
        return this.runStoryTalk(session, turnContext, ctx, text);
      }

      // Luồng 4 — the Home scene is JUDGED, not reflected on: on track, or a
      // sample line and why. The lesson door keeps the a-b-c reply until
      // luồng 2 replaces it.
      // Luồng 4, reactive branching: the FIRST line in a scene is answered by
      // the other person, not scored; the second is what the verdict reads —
      // together with the first. Applies at every door that runs a scene, the
      // lesson one included (owner, 2026-09-04).
      if (step === CoachStep.TELL_ONCE || step === CoachStep.SCENE_RETRY) {
        return this.runSceneReact(session, turnContext, text);
      }
      if (step === CoachStep.SCENE_STAGE2) {
        // Which answer is this one? `situationRound` counts the answers already
        // spent, so this text is the next one. Every answer but the LAST gets
        // another reaction — and with it another set of named ways forward, in
        // a situation the previous choice created. The last one is judged.
        const answerNumber = (session.situationRound ?? 0) + 1;
        if (answerNumber < situationRoundsFor(ctx)) {
          return this.runSceneReact(session, turnContext, text);
        }

        return this.runSceneJudge(
          session,
          turnContext,
          text,
          Boolean(session.sceneRetried),
        );
      }

      // The scene's one reply (and the parked steps that still cost a call).
      let reflected = await this.ai.reflect(turnContext);

      if (looksLikeEcho(reflected.reply, text)) {
        void this.metricService.bump(CoachMetricKind.ECHOED_READER);
        reflected = await this.ai
          .reflect({ ...turnContext, retryAfterEcho: true })
          .catch(() => reflected);
      }

      return {
        reply: reflected.reply,
        nextMove: reflected.nextMove ?? null,
        nextMoment: reflected.nextMoment ?? null,
        keypointId: beat.keypointId ?? null,
      };
    } catch (error: any) {
      this.logger.warn(
        `Coach AI failed at step=${step} session=${session._id}: ${error?.message}`,
      );

      return { reply: null };
    }
  }

  /**
   * ⑦ nhịp 2 — refuse to hand the reader a question the design bans.
   *
   * "Điều đó có ý nghĩa gì với bạn?" is the single most likely sentence a
   * helpful model reaches for, and the diagram says in capitals to enforce the
   * ban with a classifier rather than a prompt rule. It is right to: the prompt
   * rule was already there, and the rule kept losing.
   *
   * One retry, then the fixed line. Dropping the model's words entirely on the
   * second failure is deliberate — keeping the acknowledgement would mean
   * keeping the banned question attached to it, which is the whole thing being
   * prevented.
   *
   * Fails OPEN: if the classifier itself errors or times out, the reply goes
   * through. A conversation that stops is worse than one imperfect question,
   * and the same trade is already documented in the safety layer.
   */
  // ---------------------------------------------------- luồng 5 · Habit door

  /**
   * The habit's quiz, as the chat can read it: single-choice questions with
   * one right option, text drawn from the exercise's own documents, shuffled
   * and cut to `QUIZ_IN_CHAT_COUNT`. "Coach KHÔNG tự sinh câu hỏi" — these are
   * the habit's authored practices (or the keypoint's exercises they derive
   * from), nothing else. Empty when the habit has none: the quiz pill is then
   * simply not offered.
   */
  /**
   * Luồng 5 — the quiz the chat asks: written by the Coach from the keypoint
   * and stored, not taken from the authored exercises.
   *
   * "Quizz đang ở hết trong Exercise… nhiều dạng lắm" (owner, 2026-09-04): the
   * catalogue's exercises are drag-and-drop, recordings and multi-select as
   * well as single choice, and a chat can only ask the last kind. The generated
   * sets are single-choice by construction, are about what the reader actually
   * studied, and a set is served to a reader only once.
   *
   * The authored exercises stay the fallback: a keypoint whose quiz could not
   * be written (no material, provider down) still has its deck.
   */
  private async generatedQuizFor(
    userId: string,
    habitId: string,
    locale: string,
  ): Promise<ICoachQuizItem[]> {
    const passed = new Set(
      (await this.userProgressRepository
        .findPassedKeypointIds(userId)
        .catch(() => [])) as string[],
    );
    const generated = await this.quizService
      .quizForHabit({
        userId,
        habitId,
        locale,
        allowedKeypointIds: passed,
        // Người đọc đang nhìn cái vòng xoay khi hàm này chạy: nó nằm trong
        // `open()`, và cái nó quyết định chỉ là `hasQuiz` — có mời làm quiz hay
        // không. Cạn kho thì lấy bộ đã soạn sẵn dưới đây, đừng bắt chờ Gemini
        // (2.3s trung bình trên dev) cho một lời mời có thể không ai bấm.
        write: false,
      })
      .catch(() => null);

    if (generated?.questions.length) {
      return generated.questions.map((question: ICoachQuizQuestion, index: number) => ({
        // The attempt is filed against the keypoint's set rather than an
        // authored exercise; the id says which, so a wrong answer can be
        // traced back to the question that was actually asked.
        learningItemId: generated.keypointId,
        exerciseId: `${generated.setId}:${index}`,
        question: question.question,
        options: question.options,
        correctIndex: question.correctIndex,
        explanation: question.explanation ?? null,
      }));
    }

    return this.quizItemsFor(habitId, locale);
  }

  private async quizItemsFor(
    habitId: string,
    locale: string,
  ): Promise<ICoachQuizItem[]> {
    const practices = (await this.habitPracticeService
      .findForHabit({ habitId } as GetListHabitPracticeDto)
      .catch(() => [])) as Array<{
      learningItem?: {
        _id: unknown;
        questions?: Array<{
          id?: number;
          exerciseId?: string;
          type?: string;
          document?: Array<{ data?: { content?: ITranslation } }>;
          explanation?: ITranslation;
          options?: Array<{ value?: ITranslation; isCorrect?: boolean }>;
        }>;
      } | null;
    }>;

    return this.quizItemsFromItems(
      practices.map((practice) => practice?.learningItem ?? null),
      locale,
      QUIZ_IN_CHAT_COUNT,
    );
  }

  /** Single-choice questions with one right option, as the chat can read them. */
  private quizItemsFromItems(
    learningItems: Array<{
      _id: unknown;
      questions?: Array<{
        id?: number;
        exerciseId?: string;
        type?: string;
        document?: Array<{ data?: { content?: ITranslation } }>;
        explanation?: ITranslation;
        options?: Array<{ value?: ITranslation; isCorrect?: boolean }>;
      }>;
    } | null>,
    locale: string,
    count: number,
  ): ICoachQuizItem[] {
    const items: ICoachQuizItem[] = [];
    for (const item of learningItems) {
      if (!item) continue;
      for (const q of item.questions ?? []) {
        if (q.type !== ExerciseType.SINGLE_CHOICE) continue;
        const options = (q.options ?? []).map((o) => ({
          text: this.pickTranslation(o.value, locale) ?? '',
          isCorrect: o.isCorrect === true,
        }));
        const correctIndex = options.findIndex((o) => o.isCorrect);
        if (options.length < 2 || correctIndex < 0) continue;
        if (options.filter((o) => o.isCorrect).length !== 1) continue;
        if (options.some((o) => !o.text)) continue;
        const question = (q.document ?? [])
          .map((d) => this.pickTranslation(d.data?.content, locale) ?? '')
          .filter(Boolean)
          .join(' ')
          .trim();
        if (!question) continue;

        items.push({
          learningItemId: String(item._id),
          exerciseId: q.exerciseId ?? String(q.id ?? ''),
          question,
          options: options.map((o) => o.text),
          correctIndex,
          explanation: this.pickTranslation(q.explanation, locale),
        });
      }
    }

    return items.sort(() => Math.random() - 0.5).slice(0, count);
  }

  // ------------------------------------------------ luồng 2/3 · lesson door

  /**
   * What the talk after a keypoint is about: the habit that keypoint teaches
   * — when the reader has it — and whether this is the lesson's LAST keypoint
   * (then the summary covers the whole lesson: "keypoint cuối của bài → tóm
   * tắt cả bài; giữa bài → chỉ keypointBody").
   */
  private async talkSetupFor(
    userId: string,
    keypointId: string,
  ): Promise<{ habitId: string | null; scope: 'keypoint' | 'lesson' }> {
    const [lesson] = (await this.lessonRepository
      .findByKeypointIds([keypointId])
      .catch(() => [])) as Array<{ keypoints?: unknown[] }>;
    const ids = (lesson?.keypoints ?? []).map((id) => String(id));
    const scope: 'keypoint' | 'lesson' =
      ids.length && ids[ids.length - 1] === keypointId ? 'lesson' : 'keypoint';

    const owned = (await this.userHabitRepository
      .findForUser(userId, UserHabitState.ACTIVE)
      .catch(() => [])) as Array<{ habitId?: unknown }>;
    const habits = (await this.habitLibraryService
      .findByIds(owned.map((row) => String(row.habitId ?? '')).filter(Boolean))
      .catch(() => [])) as Array<{ _id: unknown; keypointIds?: unknown[] }>;
    const teaching = habits.find((habit) =>
      (habit.keypointIds ?? []).some((id) => String(id) === keypointId),
    );

    return { habitId: teaching ? String(teaching._id) : null, scope };
  }

  /**
   * What the course recap offers: the lessons as chips (newest first, at most
   * `RECAP_LESSON_CHIPS`) and `RECAP_QUIZ_COUNT` random questions drawn from
   * every keypoint of the course — read in the chat like the habit quiz.
   */
  private async recapSetupFor(
    courseId: string,
    locale: string,
  ): Promise<{ lessons: Array<{ id: string; title: string }>; quizItems: ICoachQuizItem[] }> {
    // Chip bài học là chữ user đọc, nên theo tag đang phát hành.
    // Xem `plans/260907-course-content-versions/README.md`.
    const lessons = (await this.contentSource
      .getLessonChipsByCourse(courseId, this.requestService.headers)
      .catch(() => [])) as Array<{ _id: unknown; title?: ITranslation; keypoints?: unknown[] }>;
    const chips = lessons
      .map((lesson) => ({
        id: String(lesson._id),
        title: this.pickTranslation(lesson.title, locale) ?? '',
      }))
      .filter((lesson) => lesson.title)
      .slice(0, RECAP_LESSON_CHIPS);

    const keypointIds = [
      ...new Set(lessons.flatMap((lesson) => (lesson.keypoints ?? []).map((id) => String(id)))),
    ];
    const exercises = keypointIds.length
      ? ((await this.contentSource
          .getLearningItemsByKeypointIdsAcrossVersions(
            keypointIds,
            this.requestService.headers,
          )
          .then(exercisesWithQuestionsOf)
          .catch(() => [])) as Array<{ _id: unknown; questions?: unknown[] }>)
      : [];

    return {
      lessons: chips,
      quizItems: this.quizItemsFromItems(exercises as never, locale, RECAP_QUIZ_COUNT),
    };
  }

  /** The theory text the summary is drawn from — the keypoint's, or the whole lesson's. */
  /**
   * Thanh phạm vi của luồng 2/3: keypoint vừa học, hoặc cả khoá ở bản recap.
   *
   * Đọc tiêu đề mỗi lượt thay vì lưu lên session: một read có index, đứng cạnh
   * một call Gemini — và tránh thêm một field schema chỉ để cache một chuỗi.
   */
  private async talkScopeFor(
    session: CoachSession,
  ): Promise<{ kind: 'keypoint' | 'course'; title: string } | null> {
    try {
      if (session.talkMode === 'recap' && session.courseId) {
        const [course] = (await this.courseRepository
          .findBriefByIds([session.courseId])
          .catch(() => [])) as Array<{ title?: ITranslation }>;
        const title = this.pickTranslation(course?.title, session.locale);

        return title ? { kind: 'course', title } : null;
      }
      if (session.keypointId) {
        const [keypoint] = (await this.contentSource
          .getKeypointBriefsAcrossVersions(
            [session.keypointId],
            this.requestService.headers,
          )
          .catch(() => [])) as Array<{ title?: ITranslation }>;
        const title = this.pickTranslation(keypoint?.title, session.locale);

        return title ? { kind: 'keypoint', title } : null;
      }

      return null;
    } catch (error: any) {
      this.logger.warn(`Coach could not read the talk scope: ${error?.message}`);

      return null;
    }
  }

  /**
   * The skill this session's course teaches — the fence for the follow-up
   * floor's answers (mode `free`).
   *
   * Null is fine and means "no fence named": the prompt then keeps to the
   * lesson text alone, which is the safer of the two failure directions.
   */
  private async talkSkillTitleFor(session: CoachSession): Promise<string | null> {
    if (!session.courseId) return null;
    const [course] = (await this.courseRepository
      .findBriefByIds([session.courseId])
      .catch(() => [])) as Array<{ skillset?: { title?: ITranslation }; title?: ITranslation }>;

    return (
      this.pickTranslation(course?.skillset?.title, session.locale) ||
      this.pickTranslation(course?.title, session.locale) ||
      null
    );
  }

  private async talkBodyFor(
    session: CoachSession,
  ): Promise<{ title: string | null; body: string | null }> {
    if (!session.keypointId) return { title: null, body: null };
    const locale = session.locale;

    const [keypoint] = (await this.contentSource
      .getKeypointBriefsAcrossVersions(
        [session.keypointId],
        this.requestService.headers,
      )
      .catch(() => [])) as Array<{ title?: ITranslation }>;
    const title = this.pickTranslation(keypoint?.title, locale);

    let keypointIds = [session.keypointId];
    if (session.summaryScope === 'lesson') {
      const [lesson] = (await this.lessonRepository
        .findByKeypointIds([session.keypointId])
        .catch(() => [])) as Array<{ keypoints?: unknown[] }>;
      keypointIds = (lesson?.keypoints ?? []).map((id) => String(id));
      if (!keypointIds.length) keypointIds = [session.keypointId];
    }

    const items = (await this.contentSource
      .getLearningItemsByKeypointIdsAcrossVersions(
        keypointIds,
        this.requestService.headers,
      )
      .then(narratableItemsOf)
      .catch(() => [])) as Array<{
      type?: string;
      documents?: Array<{ document?: Array<{ data?: { content?: ITranslation } }> }>;
      description?: ITranslation;
    }>;
    // A theory's text sits THREE levels down — `documents[].document[].data
    // .content` — and it is authored HTML. This used to read
    // `documents[].data.content`, a path that exists nowhere in the schema, so
    // the body came back empty for every keypoint in the catalogue (owner
    // 2026-09-05: "Nội dung trống nên không có ý nào được ghi nhận"). The
    // summary branch hid it, because its prompt falls back to summarising from
    // the title alone and a title is enough to write one plausible sentence;
    // the grading branch could not hide it. `voiceover.service.ts` walks the
    // same three levels — that reader is the one proven against the catalogue.
    const text = items
      .filter((item) => item.type === 'theory')
      .flatMap((item) => [
        this.pickTranslation(item.description, locale) ?? '',
        ...(item.documents ?? []).flatMap((tdoc) =>
          (tdoc?.document ?? []).map(
            (block) => this.pickTranslation(block?.data?.content, locale) ?? '',
          ),
        ),
      ])
      .map((part) => this.stripHtml(part))
      .filter(Boolean)
      .join('\n')
      .slice(0, TALK_BODY_MAX_CHARS);

    return { title, body: text || null };
  }

  /**
   * Luồng 2/3 — the line said on the way INTO a step, when that step has one:
   * the summary (entering TALK_SUMMARY), the quiz debrief + one praise (the
   * quiz came back), the recap's line about the lesson picked.
   */
  private async talkTransitionLine(params: {
    session: CoachSession;
    step: CoachStep;
    event: CoachEvent;
    nextStep: CoachStep;
    pick: string | null;
  }): Promise<string | null> {
    const { session, step, event, nextStep, pick } = params;
    if (!session.talkMode) return null;
    const line = (map: Record<string, string>) => this.fixedLine(map, session);
    const context: CoachTurnContext = {
      locale: session.locale,
      step: nextStep,
      persona: session.persona,
      script: null,
      transcript: session.turns.map((t) => ({
        role: t.role === CoachTurnRole.COACH ? ('coach' as const) : ('user' as const),
        text: t.text,
      })),
      // Luồng 2 bàn về keypoint vừa học: profile để cá nhân hoá lời đáp. KHÔNG
      // kèm `priorTranscript` — chủ đề là bài đang đọc, kéo chuyện phiên cũ
      // vào chỉ làm lạc đề.
      readerFacts: await this.readerFactsFor(session.userId),
      input: '',
    };

    if (step === CoachStep.TALK_ASK && nextStep === CoachStep.TALK_SUMMARY) {
      const { title, body } = await this.talkBodyFor(session);

      return this.ai
        .lessonTalk(context, {
          mode: 'summary',
          scope: session.summaryScope ?? 'keypoint',
          title,
          body,
        })
        .then((r) => r.reply)
        .catch(() => line(COACH_TALK_SUMMARY_FALLBACK_LINE));
    }

    if (step === CoachStep.QUIZ_RUN && event.kind === 'quizDone') {
      const results = (session.talkQuizResults ?? []).map((r) => ({
        question: r.question ?? '',
        passed: r.passed,
        chosen: r.chosen,
        correct: r.correct,
      }));

      return this.ai
        .lessonTalk(context, {
          mode: 'quizBack',
          scope: session.summaryScope ?? 'keypoint',
          results,
        })
        .then((r) => r.reply)
        .catch(() => null);
    }

    if (step === CoachStep.RECAP_PICK && event.kind === 'pick' && pick) {
      const lessonTitle =
        (session.recapLessons ?? []).find((lesson) => lesson.id === pick)?.title ?? '';
      const [course] = (await this.courseRepository
        .findBriefByIds([session.courseId ?? ''])
        .catch(() => [])) as Array<{ title?: ITranslation }>;

      return this.ai
        .lessonTalk(context, {
          mode: 'recapWhy',
          lessonTitle,
          courseTitle: this.pickTranslation(course?.title, session.locale),
        })
        .then((r) => r.reply)
        .catch(() => null);
    }

    return null;
  }

  /**
   * Luồng 2 — the check-in the talk earns for the habit this keypoint teaches:
   * EXERCISE (with the attempt) when the quiz ran, COACH when they listened
   * only. Nothing when the reader has no such habit. Best effort.
   */
  private async recordTalkCheckin(session: CoachSession): Promise<void> {
    if (!session.talkHabitId) return;
    try {
      const row = await this.userHabitRowFor(session.userId, session.talkHabitId);
      if (!row) return;
      const results = session.talkQuizResults ?? [];
      if (results.length && session.keypointId) {
        const [exercise] = (await this.learningItemRepository
          .findExercisesByKeypoints([session.keypointId])
          .catch(() => [])) as Array<{ _id: unknown }>;
        if (exercise) {
          await this.habitPracticeService.submitAttempt({
            userHabitId: String(row._id),
            method: HabitCheckinMethod.EXERCISE,
            learningItemId: String(exercise._id),
            exercisesResult: results.map((r) => ({
              exerciseId: r.exerciseId,
              passed: r.passed,
              score: r.passed ? 1 : 0,
            })),
            score: results.filter((r) => r.passed).length,
            total: results.length,
          } as unknown as SubmitHabitPracticeAttemptDto);

          return;
        }
      }
      await this.userHabitService.checkIn(String(row._id), {
        done: true,
        method: HabitCheckinMethod.COACH,
      } as CheckInUserHabitDto);
    } catch (error: any) {
      this.logger.warn(`Coach could not file the talk check-in: ${error?.message}`);
    }
  }

  /** Luồng 3 — a random published course in the same skill set, never the one just finished. */
  private async pickRecapCourse(session: CoachSession): Promise<PickedCourse | null> {
    if (!session.courseId || session.moodEndLow) return null;
    const [course] = (await this.courseRepository
      .findBriefByIds([session.courseId])
      .catch(() => [])) as Array<{ skillsetId?: unknown; title?: ITranslation }>;
    const skillsetId = course?.skillsetId ? String(course.skillsetId) : null;
    if (!skillsetId) return null;

    const id = await this.courseRepository
      .findRandomPublishedCourseIdInSkillset(skillsetId, session.courseId)
      .catch(() => null);
    if (!id) return null;

    return {
      id,
      reasonKey: COACH_COURSE_REASON.RECAP,
      reasonArg: this.pickTranslation(course?.title, session.locale),
    };
  }

  /**
   * The course the reader is already in the middle of — the card of last
   * resort, when nothing in the conversation connected to a habit.
   *
   * Owner 2026-09-05: "luôn luôn khi có cơ hội thì điều hướng đề xuất cho user
   * học một bài nào đó trong hệ thống". Every other picker needs a habit to
   * connect through, so a story about waiting for somebody after work matched
   * nothing and the session ended on a closing sentence and a Đóng button.
   *
   * This does not break "tuyệt đối không gợi bừa một khoá cho có": a course
   * they opened themselves and have not finished is not a suggestion at all,
   * it is the thing they were already doing. It stays LAST so a real match
   * always wins, and it never re-offers the course this very session is about.
   */
  private async pickResumeCourse(session: CoachSession): Promise<PickedCourse | null> {
    if (session.moodEndLow) return null;

    const latest = await this.userProgressRepository
      .findLatestStudiedKeypoint(session.userId)
      .catch(() => null);
    const courseId = latest?.courseId ? String(latest.courseId) : null;
    if (!courseId || courseId === session.courseId) return null;

    // Published-only, and it must still exist: progress rows outlive the
    // catalogue, and a card opening a retired course is a dead end.
    const [course] = (await this.courseRepository
      .findBriefByIds([courseId])
      .catch(() => [])) as Array<{ title?: ITranslation }>;
    if (!course) return null;

    const allowed = await this.boostService
      .allows({
        userId: session.userId,
        kind: CoachBoostKind.COURSE_CARD,
        refId: courseId,
        alreadyAsked: [],
      })
      .catch(() => true);
    if (!allowed) return null;

    return {
      id: courseId,
      reasonKey: COACH_COURSE_REASON.RESUME,
      reasonArg: this.pickTranslation(course?.title, session.locale),
    };
  }

  /** The reader's active row for a library habit, or null. */
  private async userHabitRowFor(
    userId: string,
    habitId: string,
  ): Promise<{ _id: unknown; habitId?: unknown } | null> {
    const owned = (await this.userHabitRepository
      .findForUser(userId, UserHabitState.ACTIVE)
      .catch(() => [])) as Array<{ _id: unknown; habitId?: unknown }>;

    return owned.find((row) => String(row.habitId) === habitId) ?? null;
  }

  /** Is today's check-in for this habit already written — done OR "chưa có dịp"? */
  private async checkedToday(userId: string, habitId: string): Promise<boolean> {
    const row = await this.userHabitRowFor(userId, habitId);
    if (!row) return false;
    const today = await this.userHabitService.localToday();
    const rows = (await this.habitCheckinRepository
      .findTodayForUserHabits([String(row._id)], today)
      .catch(() => [])) as unknown[];

    return rows.length > 0;
  }

  /**
   * "Trong kho còn «Y» chưa ghi hôm nay" — the first other habit with no
   * check-in row today, in kho order. Null when every habit is written.
   */
  private async nextUnwrittenHabit(
    userId: string,
    exceptHabitId: string,
  ): Promise<string | null> {
    const owned = (await this.userHabitRepository
      .findForUser(userId, UserHabitState.ACTIVE)
      .catch(() => [])) as Array<{ _id: unknown; habitId?: unknown }>;
    const candidates = owned.filter(
      (row) => String(row.habitId) !== exceptHabitId,
    );
    if (!candidates.length) return null;

    const today = await this.userHabitService.localToday();
    const written = new Set(
      (
        (await this.habitCheckinRepository
          .findTodayForUserHabits(
            candidates.map((row) => String(row._id)),
            today,
          )
          .catch(() => [])) as Array<{ userHabitId?: unknown }>
      ).map((row) => String(row.userHabitId)),
    );
    const next = candidates.find((row) => !written.has(String(row._id)));

    return next ? String(next.habitId) : null;
  }

  /**
   * Luồng 5 — `habit_checkins { method: COACH }`: ⟨Có⟩ writes done:true with
   * their sentence as the note, ⟨Chưa⟩ writes done:false — "không bỏ trống
   * ngày". Best effort, like the scene's write.
   */
  private async recordCoachCheckin(
    session: CoachSession,
    done: boolean,
    note: string | null,
  ): Promise<void> {
    if (!session.habitId) return;
    try {
      const row = await this.userHabitRowFor(session.userId, session.habitId);
      if (!row) return;
      await this.userHabitService.checkIn(String(row._id), {
        done,
        method: HabitCheckinMethod.COACH,
        ...(note ? { note } : {}),
      } as CheckInUserHabitDto);
    } catch (error: any) {
      this.logger.warn(`Coach could not file the check-in: ${error?.message}`);
    }
  }

  /** "{n} câu, mình hỏi trong chat luôn." + the first question. */
  private quizOpeningLine(session: CoachSession): string | null {
    const items = session.quizItems ?? [];
    if (!items.length) return null;
    const line = (map: Record<string, string>) => this.fixedLine(map, session);

    return [
      line(COACH_QUIZ_INTRO_LINE).replace('{n}', String(items.length)),
      this.quizQuestionLine(session, 0),
    ]
      .filter(Boolean)
      .join('\n\n');
  }

  private quizQuestionLine(session: CoachSession, index: number): string | null {
    const item = (session.quizItems ?? [])[index];
    if (!item) return null;
    const line = (map: Record<string, string>) => this.fixedLine(map, session);

    return line(COACH_QUIZ_QUESTION_LINE)
      .replace('{i}', String(index + 1))
      .replace('{q}', item.question);
  }

  /**
   * One answer of the in-chat quiz. Right → one fixed word. Wrong → the right
   * answer and one line of why (model, with a fixed fallback). Then the next
   * question, or — after the last — the closing summary. Never a number:
   * "không đọc điểm số, chỉ nói câu nào chưa đúng và nên trả lời thế nào".
   */
  private async answerQuizQuestion(
    session: CoachSession,
    answer: string,
  ): Promise<{ reply: string; patch: Partial<CoachSession> }> {
    const items = session.quizItems ?? [];
    const index = session.quizIndex ?? 0;
    const item = items[index];
    const line = (map: Record<string, string>) => this.fixedLine(map, session);
    if (!item) return { reply: line(COACH_QUIZ_DONE_LINE), patch: {} };

    const chosen = Number.parseInt(answer, 10);
    const passed = chosen === item.correctIndex;
    const results: ICoachQuizResult[] = [
      ...(session.quizResults ?? []),
      { exerciseId: item.exerciseId, passed, chosenIndex: chosen },
    ];
    const context: CoachTurnContext = {
      locale: session.locale,
      step: CoachStep.QUIZ_IN_CHAT,
      persona: session.persona,
      script: null,
      habitTitle: await this.habitTitleOf(session.habitId, session.locale),
      transcript: [],
      input: item.options[chosen] ?? answer,
    };

    const feedback = passed
      ? line(COACH_QUIZ_RIGHT_LINE)
      : await this.ai
          .quizFeedback(context, {
            mode: 'wrong',
            question: item.question,
            chosen: item.options[chosen] ?? answer,
            correct: item.options[item.correctIndex],
            explanation: item.explanation ?? null,
          })
          .then((r) => r.reply)
          .catch(() =>
            line(COACH_QUIZ_WRONG_FALLBACK_LINE).replace(
              '{a}',
              item.options[item.correctIndex],
            ),
          );

    const last = index + 1 >= items.length;
    const tail = last
      ? await this.ai
          .quizFeedback(context, {
            mode: 'summary',
            results: items.map((it, i) => ({
              question: it.question,
              passed: results[i]?.passed ?? false,
              correct: it.options[it.correctIndex],
            })),
          })
          .then((r) => r.reply)
          .catch(() => line(COACH_QUIZ_DONE_LINE).replace('{n}', String(items.length)))
      : this.quizQuestionLine(session, index + 1);

    return {
      reply: [feedback, tail].filter(Boolean).join('\n\n'),
      patch: { quizIndex: index + 1, quizResults: results },
    };
  }

  /**
   * The finished quiz → `habit_practice_attempts` with per-question results,
   * which files today's EXERCISE check-in through the practice service —
   * exactly the write the Habit screen's own quiz row makes.
   */
  private async submitQuizAttempt(session: CoachSession): Promise<void> {
    const items = session.quizItems ?? [];
    const results = session.quizResults ?? [];
    if (!session.habitId || !items.length || !results.length) return;
    try {
      const row = await this.userHabitRowFor(session.userId, session.habitId);
      if (!row) return;
      await this.habitPracticeService.submitAttempt({
        userHabitId: String(row._id),
        method: HabitCheckinMethod.EXERCISE,
        learningItemId: items[0].learningItemId,
        exercisesResult: results.map((r) => ({
          exerciseId: r.exerciseId,
          type: ExerciseType.SINGLE_CHOICE,
          passed: r.passed,
          score: r.passed ? 1 : 0,
        })),
        score: results.filter((r) => r.passed).length,
        total: results.length,
      } as unknown as SubmitHabitPracticeAttemptDto);
    } catch (error: any) {
      this.logger.warn(`Coach could not file the quiz attempt: ${error?.message}`);
    }
  }

  // ------------------------------------------------ luồng 1 · Onboarding Coach

  /** "bạn / anh / chị / em" typed instead of tapped — with or without accents. */
  private onboardPronounOf(text: string): string | null {
    const said = fold(text);
    const map: Record<string, string> = { ban: 'bạn', anh: 'anh', chi: 'chị', em: 'em' };
    for (const [key, value] of Object.entries(map)) {
      if (said === key || said === `goi minh la ${key}` || said === `goi ${key}`) return value;
    }

    return null;
  }

  /** The six groups from a typed job title — a keyword net, no model call. */
  private occupationGroupOf(text: string): string {
    for (const [group, pattern] of ONBOARD_JOB_KEYWORDS) {
      if (pattern.test(text)) return group;
    }

    return 'other';
  }

  /**
   * The answer just given, as profile fields. A chip gives its value (and its
   * label where the field is text); typing gives the words verbatim — "chip là
   * gợi ý, không phải danh sách đóng".
   */
  private onboardAnswerOf(
    session: CoachSession,
    step: CoachStep,
    event: CoachEvent,
    pick: string | null,
    text: string,
  ): Record<string, string> {
    if (pick === 'skip' || pick === 'start' || pick === 'back') return {};
    const label = (field: string, value: string) =>
      COACH_ONBOARD_OPTIONS[field]?.find((o) => o.value === value)?.label[session.locale] ??
      COACH_ONBOARD_OPTIONS[field]?.find((o) => o.value === value)?.label.en ??
      value;
    const typed = event.kind === 'text' ? text.trim() : '';

    switch (step) {
      case CoachStep.ONBOARD_ADDRESS:
        return pick ? { address: pick } : {};
      case CoachStep.ONBOARD_ADDRESS_CONFIRM:
        return pick === 'yes' && session.onboardName ? { address: session.onboardName } : {};
      case CoachStep.ONBOARD_GOAL:
        return { goalText: pick ? label('goal', pick) : typed };
      case CoachStep.ONBOARD_BARRIER:
        return { barrierText: pick ? label('barrier', pick) : typed };
      case CoachStep.ONBOARD_CURRENT:
        return { currentPractice: pick ? label('current', pick) : typed };
      case CoachStep.ONBOARD_STYLE:
        return pick ? { learningStyle: pick } : typed ? { learningStyle: 'other' } : {};
      case CoachStep.ONBOARD_AGE:
        return pick ? { age: label('age', pick) } : typed ? { age: typed } : {};
      case CoachStep.ONBOARD_GENDER:
        return pick ? { gender: pick, genderLabel: label('gender', pick) } : typed ? { gender: 'other', genderLabel: typed } : {};
      case CoachStep.ONBOARD_JOB:
        return pick
          ? { occupation: pick, occupationRaw: label('job', pick) }
          : typed
            ? { occupation: this.occupationGroupOf(typed), occupationRaw: typed }
            : {};
      default:
        return {};
    }
  }

  /**
   * The chips for one onboarding question: the answers (lit where the reader
   * already picked one, else where the app already knows), then "← Câu trước"
   * on every question after the address.
   */
  private async onboardChoicesFor(
    session: CoachSession,
    step: CoachStep,
  ): Promise<CoachChoice[]> {
    const base = await this.onboardChoicesBase(session, step);
    const picked = session.onboardPicks?.[step] ?? null;
    const lit =
      picked && base.some((c) => c.value === picked)
        ? base.map(({ selected: _selected, ...c }) => (c.value === picked ? { ...c, selected: true } : c))
        : base;
    const canGoBack = ONBOARD_ORDER.includes(step) && step !== CoachStep.ONBOARD_ADDRESS;
    if (!canGoBack) return lit;

    return [
      ...lit,
      ...(COACH_ONBOARD_OPTIONS.nav ?? []).map((o) => ({
        value: o.value,
        label: o.label[session.locale] ?? o.label.en,
      })),
    ];
  }

  private async onboardChoicesBase(
    session: CoachSession,
    step: CoachStep,
  ): Promise<CoachChoice[]> {
    const locale = session.locale;
    const chips = (field: string, selected: string | null) =>
      (COACH_ONBOARD_OPTIONS[field] ?? []).map((o) => ({
        value: o.value,
        label: o.label[locale] ?? o.label.en,
        ...(selected && o.value === selected ? { selected: true } : {}),
      }));

    switch (step) {
      case CoachStep.ONBOARD_INTRO:
        return chips('intro', null);
      case CoachStep.ONBOARD_ADDRESS:
        return chips('address', null);
      case CoachStep.ONBOARD_ADDRESS_CONFIRM:
        return [];
      case CoachStep.ONBOARD_GOAL: {
        // The goal the app's own onboarding recorded — lit, so they confirm or
        // change it rather than being asked cold for what they already said.
        const profile = await this.readerProfile(session).catch(() => null);
        const known = fold(profile?.goalLabel ?? '');
        const hit = known
          ? (COACH_ONBOARD_OPTIONS.goal ?? []).find((o) => {
              const l = fold(o.label[locale] ?? o.label.en);

              return Boolean(l) && (known.includes(l) || l.includes(known));
            })
          : null;

        return chips('goal', hit?.value ?? null);
      }
      case CoachStep.ONBOARD_BARRIER:
        return chips('barrier', null);
      case CoachStep.ONBOARD_CURRENT:
        return chips('current', null);
      case CoachStep.ONBOARD_STYLE:
        return chips('style', null);
      case CoachStep.ONBOARD_AGE: {
        const user = (await this.userRepository.findById(session.userId).catch(() => null)) as {
          age?: string | null;
        } | null;
        const audience = coachAudienceFromAge(user?.age);

        return chips('age', ONBOARD_AGE_BY_AUDIENCE[audience] ?? null);
      }
      case CoachStep.ONBOARD_GENDER: {
        const user = (await this.userRepository.findById(session.userId).catch(() => null)) as {
          gender?: string | null;
        } | null;
        const g = fold(user?.gender ?? '');
        const selected = /\b(nu|female|woman|girl)\b/.test(g)
          ? 'female'
          : /\b(nam|male|man|boy)\b/.test(g)
            ? 'male'
            : null;

        return chips('gender', selected);
      }
      case CoachStep.ONBOARD_JOB:
        return chips('job', null);
      default:
        return [];
    }
  }

  /**
   * Leaving the onboarding — finished or skipped — writes what was answered to
   * the profile, and what the app's own tables hold (age, gender) to the user,
   * so the scene generator's audience reads it too. Best effort.
   */
  private async completeOnboarding(
    session: CoachSession,
    answers: Record<string, string>,
  ): Promise<void> {
    try {
      await this.profileService.completeOnboarding(session.userId, {
        address: answers.address ?? null,
        goalText: answers.goalText ?? null,
        barrierText: answers.barrierText ?? null,
        currentPractice: answers.currentPractice ?? null,
        learningStyle: answers.learningStyle ?? null,
        occupation: answers.occupation ?? null,
        occupationRaw: answers.occupationRaw ?? null,
      });
      const userSet: Record<string, string> = {};
      if (answers.age) userSet.age = answers.age;
      if (answers.genderLabel && answers.gender !== 'private') userSet.gender = answers.genderLabel;
      if (Object.keys(userSet).length) {
        await this.userRepository.updateOne({ _id: session.userId }, userSet as never);
      }
    } catch (error: any) {
      this.logger.warn(`Coach could not write the onboarding: ${error?.message}`);
    }
  }

  /**
   * Luồng 5 — which habit the Habit TAB's door is about: one taken at RANDOM
   * from the kho (owner, 2026-09-04), preferring the ones still unwritten
   * today. Random rather than "the first row" so a reader with five habits is
   * not asked about the same one every single day, and the bar at the top of
   * the sheet says which one it landed on. Null when the kho is empty.
   */
  private async firstHabitForDoor(userId: string): Promise<string | null> {
    const owned = (await this.userHabitRepository
      .findForUser(userId, UserHabitState.ACTIVE)
      .catch(() => [])) as Array<{ _id: unknown; habitId?: unknown }>;
    const withHabit = owned.filter((row) => row.habitId);
    if (!withHabit.length) return null;

    // Nothing left to write: any of them will do, so vary which one the door
    // opens on rather than showing the same habit every time.
    const anyOf = (rows: typeof withHabit) =>
      String(rows[Math.floor(Math.random() * rows.length)].habitId);

    const today = await this.userHabitService.localToday().catch(() => null);
    if (today) {
      const written = new Set(
        (
          (await this.habitCheckinRepository
            .findTodayForUserHabits(
              withHabit.map((row) => String(row._id)),
              today,
            )
            .catch(() => [])) as Array<{ userHabitId?: unknown }>
        ).map((row) => String(row.userHabitId)),
      );
      const unwritten = withHabit.filter((row) => !written.has(String(row._id)));
      // The FIRST one still unwritten, not a random one (owner 2026-09-05).
      // `findForUser` sorts by `createdAt`, which is the order the Habit tab
      // itself lists them in — so the door opens on the habit the reader is
      // looking at, and opens on the same one if they close and tap again.
      // Picking at random here meant the Coach could land on a habit further
      // down the list while the one showing "Cần luyện tập" sat untouched.
      if (unwritten.length) return String(unwritten[0].habitId);
    }

    return anyOf(withHabit);
  }

  /**
   * Luồng 7 — which keypoint this habit was added from, as the app recorded it
   * when the reader adopted it at the end of the lesson. Null for a habit that
   * came from anywhere else.
   */
  private async sourceKeypointOf(
    userId: string,
    habitId: string,
  ): Promise<string | null> {
    const row = (await this.userHabitRowFor(userId, habitId).catch(() => null)) as {
      sourceKeypointId?: unknown;
    } | null;
    const id = row?.sourceKeypointId ? String(row.sourceKeypointId) : '';

    return id || null;
  }

  // ------------------------------------------------ the fixed lines

  /**
   * A server line in the session's language — and, in Vietnamese, addressed
   * the way the reader asked ("bạn" → «anh» / «chị» / «em» / their name).
   */
  private fixedLine(
    map: Record<string, string>,
    session: Pick<CoachSession, 'locale' | 'address'>,
  ): string {
    return addressVi(map[session.locale] ?? map.en, session.locale === 'vi' ? session.address : null);
  }

  /**
   * A cached scene's narration, addressed to THIS reader.
   *
   * The scene row is shared: one generation serves every reader of its slot, so
   * it cannot be written with anybody's name in it and stores "bạn". The fixed
   * lines around it already go through `addressVi`, which left one screen
   * saying both — the scene asking "**Bạn** mở mục nào trước?" two bubbles
   * above a lead that said "**Hà** sẽ…" (owner on-device 2026-09-08).
   *
   * ONLY for text told TO the reader — the scene's setup, its question, the
   * second stage. NOT for an approach's sample sentence: that is the reader
   * speaking to the other person, so a "bạn" in it means THEM, and rewriting it
   * would put the reader's own name in a line they are saying to somebody else.
   */
  private toldToReader(
    text: string,
    session: Pick<CoachSession, 'locale' | 'address'>,
  ): string {
    return addressVi(text, session.locale === 'vi' ? session.address : null);
  }

  private fixedLines(
    map: Record<string, string[]>,
    session: Pick<CoachSession, 'locale' | 'address'>,
  ): string[] {
    return (map[session.locale] ?? map.en).map((line) =>
      addressVi(line, session.locale === 'vi' ? session.address : null),
    );
  }

  // ------------------------------------------------ the reader's own replay

  /** One drawn exchange, appended to the session. Best effort, never rewritten. */
  private async recordShown(session: CoachSession, item: ICoachShownTurn): Promise<void> {
    if (
      !item.userLine &&
      !item.reply &&
      !item.noteKey &&
      !item.promptKey &&
      !item.situation &&
      !item.scene
    ) {
      return;
    }
    await this.sessionRepository
      .appendShown(session._id.toString(), [item])
      .catch((error: any) =>
        this.logger.warn(`Coach could not record the exchange: ${error?.message}`),
      );
  }

  /** What a session showed — or, for one from before the store, its plain lines. */
  private shownOf(session: Pick<CoachSession, 'shown' | 'turns'>): ICoachShownTurn[] {
    if (session.shown?.length) return session.shown;

    return (session.turns ?? []).map((t) => ({
      at: t.at,
      step: t.step,
      ...(t.role === CoachTurnRole.COACH ? { reply: t.text } : { userLine: t.text }),
    }));
  }

  private replayItemOf(t: ICoachShownTurn): CoachReplayItem {
    return {
      at: new Date(t.at).toISOString(),
      step: t.step ?? null,
      userLine: t.userLine ?? null,
      reply: t.reply ?? null,
      speaker: t.speaker ?? null,
      noteKey: t.noteKey ?? null,
      promptKey: t.promptKey ?? null,
      promptArgs: t.promptArgs ?? null,
      situation: t.situation ?? null,
      scene: t.scene ?? null,
      isCoach: !t.userLine,
      text: t.userLine ?? t.reply ?? '',
    };
  }

  /** The line between two sessions: when it was, and at which door. */
  private dividerItem(session: Pick<CoachSession, 'createdAt' | 'entry'>): CoachReplayItem {
    const at = new Date(session.createdAt ?? Date.now()).toISOString();

    return { at, divider: { at, entry: session.entry }, isCoach: true, text: '' };
  }

  /**
   * Earlier sessions to draw above today's, oldest first — whole sessions,
   * newest kept first, until the next one would push past the line cap.
   */
  private async historyFor(userId: string, excludeId: string | null): Promise<CoachReplayItem[]> {
    try {
      const sessions = await this.sessionRepository.findRecentWithLines(
        userId,
        excludeId,
        COACH_HISTORY_SESSIONS,
      );
      const blocks: CoachReplayItem[][] = [];
      let total = 0;
      for (const s of sessions) {
        const lines = this.shownOf(s as CoachSession).map((t) => this.replayItemOf(t));
        if (!lines.length) continue;
        // A session the reader never spoke in is not a conversation — it is a
        // sheet they opened and closed. Replaying those stacked four identical
        // "Hôm nay bạn muốn làm gì?" openers above the live one (owner, on the
        // simulator 2026-09-04).
        if (!lines.some((line) => line.userLine)) continue;
        if (blocks.length && total + lines.length + 1 > COACH_HISTORY_MAX_LINES) break;
        blocks.unshift([this.dividerItem(s as CoachSession), ...lines]);
        total += lines.length + 1;
      }

      return blocks.flat();
    } catch (error: any) {
      this.logger.warn(`Coach could not read the reader's history: ${error?.message}`);

      return [];
    }
  }

  /**
   * Luồng 4 — the Home scene's answer, judged.
   *
   * No echo net here on purpose: the on-track praise QUOTES the reader's own
   * words by instruction, which is exactly what `looksLikeEcho` catches.
   */
  private async runSceneJudge(
    session: CoachSession,
    turnContext: CoachTurnContext,
    said: string,
    retry: boolean,
  ): Promise<{ reply: string | null; sceneOnTrack: boolean; engaged: boolean }> {
    const scene = session.situationId
      ? ((await this.situationService
          .findById(session.situationId)
          .catch(() => null)) as { prompt?: string } | null)
      : null;

    // Both of the reader's lines, in order: the one that provoked the other
    // person and the one that answered them. Scoring the last line alone would
    // praise somebody who opened by dodging and then recovered — and blame
    // somebody who said the thing outright and then softened it.
    const first = session.sceneFirstLine?.trim();
    const input = first ? `${first}\n\n${said}` : said;

    const judged = await this.ai.judgeScene(
      { ...turnContext, step: CoachStep.TELL_ONCE, input },
      { prompt: scene?.prompt ?? '', retry },
    );

    return {
      reply: judged.reply || null,
      sceneOnTrack: judged.onTrack,
      engaged: judged.engaged,
    };
  }

  /**
   * Luồng 4 — the other person answers the reader's first line.
   *
   * Not a verdict: the beat exists so the reader FEELS what their line did
   * before anyone grades it ("trong đời thực, khi Hà nói… Trang sẽ phản ứng
   * lại"). The posture only shapes that reaction's tone; the scene is scored
   * on the next turn, on both lines. A provider failure leaves `sceneReacted`
   * false, and the machine scores the beat on the one line rather than
   * stranding the reader in a scene nobody answered.
   */
  private async runSceneReact(
    session: CoachSession,
    turnContext: CoachTurnContext,
    said: string,
  ): Promise<{
    reply: string | null;
    speaker?: string | null;
    sceneReacted: boolean;
    /** Set only when this reaction answers the scene's FIRST line. */
    sceneFirstLine?: string;
    sceneOnTrack?: boolean;
    /** True while the scene is mid-beat: the other person spoke, the verdict has not. */
    awaitingSecondLine?: boolean;
    /** False when the line did not attempt the scene — a question back, say. */
    engaged?: boolean;
    /** The ways forward just offered, packed `key|label|text` for the session. */
    sceneOptions?: string[];
    /**
     * The same trio, structured, for the bubbles.
     *
     * The opening of a scene renders its approaches from `ui.scene.options` and
     * gets the letter and the name in a bold heading; this beat used to write
     * them into the reply TEXT instead, so the same three approaches arrived as
     * plain single lines with no letters — "câu trên thì in đậm nhưng các câu
     * trả lời tiếp theo thì lại không" (owner on-device 2026-09-08). One channel
     * for both moments, so they read as one feature.
     */
    sceneOptionList?: CoachSceneOption[];
    /** Those same lines as tappable chips — see the note where they are set. */
    samples?: string[];
    /** How the line that triggered this reaction sat. */
    scenePosture?: CoachScenePosture;
  }> {
    const scene = session.situationId
      ? ((await this.situationService
          .findById(session.situationId)
          .catch(() => null)) as { prompt?: string } | null)
      : null;

    const reacted = await this.ai
      .reactScene(turnContext, {
        scene: scene?.prompt ?? '',
        said,
        habitTitle: turnContext.habitTitle ?? null,
      })
      .catch((error: any) => {
        this.logger.warn(`Coach could not react in the scene: ${error?.message}`);

        return null;
      });

    // The other person could not answer. Rather than leave the reader looking
    // at a scene nobody replied to, the beat falls back to what it did before
    // this existed: score this one line and move on.
    if (!reacted?.reply) {
      // The session is passed through unchanged rather than with
      // `sceneFirstLine: null`. On the FIRST answer the two are identical (it
      // is cleared on the way into the scene), and on a middle answer forcing
      // null threw the opening line away and scored the middle one alone —
      // which since the scene runs three answers is a real case, not a
      // theoretical one.
      const judged = await this.runSceneJudge(
        session,
        turnContext,
        said,
        Boolean(session.sceneRetried),
      );

      return {
        ...judged,
        sceneReacted: true,
        sceneFirstLine: session.sceneFirstLine?.trim() ? undefined : said,
      };
    }

    // The attribution moves from the bubble's label into the prose, because the
    // app stamps `speaker` on EVERY paragraph of a reply and this reply now has
    // two: the other person talking, and the ways forward. Labelled, the second
    // one would read as the other person reciting the reader's options back at
    // them. `gesture` already opens with their name and ends with a colon; when
    // the model left it empty, the name alone does the same job.
    const lead =
      reacted.gesture || (reacted.speaker ? `${reacted.speaker}:` : '');
    const spoken = lead ? `${lead}\n"${reacted.reply}"` : reacted.reply;

    return {
      // The approaches no longer ride in here — they go out structured, so the
      // app can set the letter and the name in the bubble's bold heading the
      // way it already does at a scene's opening.
      reply: spoken,
      speaker: null,
      sceneReacted: true,
      // Only the FIRST answer claims this. The verdict reads first-and-last on
      // purpose — "praise somebody who opened by dodging and then recovered" —
      // and a middle answer overwriting it would leave the judge comparing the
      // last line with itself.
      sceneFirstLine: session.sceneFirstLine?.trim() ? undefined : said,
      sceneOptions: reacted.options.map(
        (option: CoachSceneOption) =>
          `${option.key}|${option.label}|${option.text}`,
      ),
      sceneOptionList: reacted.options,
      // The chips carry the LABEL only — "Cố làm tiếp", not the whole line.
      // The lines are already written out in the reply above them, and a chip
      // row is one horizontally scrolling line: a full sentence per chip pushed
      // the third one off-screen and cut the first two mid-word (owner, on the
      // device). Tapping one fills the box with the label, and
      // `resolveSceneOption` expands it back to that approach's sentence on the
      // way in — which is why it matches on the label and not only on "A".
      //
      // This does not reopen "no answer-suggestion pills at a scene": that rule
      // guards the moment the scene is FIRST shown, where the reader's own
      // unprompted sentence is what is practised and scored, and it still holds
      // there (`ui.samples = []` on every situation step; this turn is
      // SCENE_STAGE2, which is not one). By here the first line is already
      // given and what is being taught is the choice between named approaches.
      samples: reacted.options.map((option: CoachSceneOption) => option.label),
      scenePosture: reacted.posture,
      awaitingSecondLine: true,
      engaged: reacted.engaged,
    };
  }

  /**
   * The scene's own ways in, shaped for the opening bubble.
   *
   * Returns nothing at all when the scene has none — legacy rows, and any row
   * whose generation gave nothing usable — so the opening reads exactly as it
   * did before this existed rather than showing an empty heading.
   *
   * TEXT, never pills: the rule this sits under is the owner's and it is about
   * this exact moment — "có nút đó thì người dùng sẽ bấm và chép, và cả bài tập
   * mất nghĩa". Naming the approaches teaches the contrast; the sentence that
   * gets sent is still one the reader typed, which is what `sceneFirstLine`
   * files and what the verdict reads first-and-last.
   */
  private openingOptionsFor(
    options: CoachSceneOption[] | undefined,
    session: CoachSession,
  ):
    | { options: CoachSceneOption[]; optionsLead: string }
    | Record<string, never> {
    if (!options?.length) return {};

    return {
      options,
      // The OPENING's lead, not the reaction's: the scene just asked its own
      // question, so the reaction's "Bạn sẽ đáp lại thế nào?" would repeat it.
      optionsLead: this.fixedLine(COACH_SCENE_OPENING_LEAD, session),
    };
  }

  /**
   * The approaches as printable lines, one per approach.
   *
   * Shared with the scene's OPENING, which shows the same trio under the
   * question rather than after a reaction. One formatter so the two moments
   * cannot drift into looking like different features — and so the letter the
   * reader may type back means the same thing in both.
   */
  private sceneOptionLines(options: CoachSceneOption[]): string[] {
    return options.map(
      (option) => `${option.key}. ${option.label} — "${option.text}"`,
    );
  }

  /**
   * A one-letter answer, turned back into the approach it stands for.
   *
   * The reader is shown "A. Phản ánh cảm xúc — …" and may simply type "A". Left
   * alone, that letter would be what the risk gate reads, what the rubric
   * scores and what the answer row keeps forever — a scene answered "B" tells
   * nobody anything later. Resolved here, at the one place the turn's text is
   * normalised, so no layer below has to know the shorthand exists.
   *
   * Only a bare key or a bare label counts. Someone who wrote a real sentence
   * that happens to begin with "A" is answering in their own words, and their
   * words are the thing being practised.
   */
  private resolveSceneOption(
    session: CoachSession,
    raw: string,
  ): string | null {
    const packed = session.sceneOptions ?? [];
    if (!packed.length) return null;

    // Strip the punctuation a person types round a choice — "A.", "(B)", "C)",
    // "Lựa chọn A" — then compare on the bare token.
    const said = raw
      .trim()
      .replace(/^[(\[]|[)\].:,]+$/g, '')
      .replace(/^(lựa chọn|lua chon|option|đáp án|dap an)\s+/i, '')
      .trim();
    if (!said || said.length > 40) return null;

    for (const entry of packed) {
      const [key, label, text] = entry.split('|');
      if (!text) continue;
      if (
        said.localeCompare(key ?? '', undefined, { sensitivity: 'base' }) === 0 ||
        said.localeCompare(label ?? '', undefined, { sensitivity: 'base' }) === 0
      ) {
        return text;
      }
    }

    return null;
  }

  /**
   * Luồng 4 — the fixed line that bridges or closes a beat, if this turn has
   * one. Server-owned text in five languages; see the constants for why.
   */
  private bridgeLineFor(params: {
    step: CoachStep;
    event: CoachEvent;
    ctx: CoachMachineContext;
    nextStep: CoachStep;
    session: CoachSession;
    judged: boolean;
    /** Luồng 5 — the titles the offer line names. */
    offerTitles?: { done: string; next: string } | null;
    /** Which card this turn is entering, so its lead line can match it. */
    cardReasonKey?: string | null;
  }): string | null {
    const { step, event, ctx, nextStep, session, judged, offerTitles, cardReasonKey } =
      params;
    const line = (map: Record<string, string>) => this.fixedLine(map, session);

    // Luồng 2 — TALK_WHEN's two closing lines. Nothing else the lesson door
    // says is fixed here.
    if (session.talkMode === 'talk') {
      if (step === CoachStep.TALK_WHEN && event.kind === 'pick' && nextStep === CoachStep.END) {
        return line(ctx.pick === 'continue' ? COACH_TALK_CONTINUE_LINE : COACH_TALK_LATER_LINE);
      }
      // The grading turn now OPENS the floor instead of closing the branch:
      // the reader has just been told what they missed, which is exactly when
      // questions arrive (owner, 2026-09-05).
      if (step === CoachStep.TALK_SUMMARY && nextStep === CoachStep.TALK_FREE) {
        return line(COACH_TALK_FREE_INVITE_LINE);
      }
      // The budget ran out. Nothing here points at the next keypoint — the
      // reader leaves by the sheet's own Đóng and starts it from the Roadmap.
      if (step === CoachStep.TALK_FREE && nextStep === CoachStep.END) {
        return line(COACH_TALK_FREE_DONE_LINE);
      }

      return null;
    }
    if (session.entry === CoachEntry.LESSON) return null;

    // Luồng 5 — the Habit door's fixed lines.
    if (session.entry === CoachEntry.HABIT) {
      const parts: string[] = [];
      if (step === CoachStep.CHECKIN_ASK && event.kind === 'checkin' && !event.done) {
        parts.push(line(COACH_CHECKIN_MISSED_LINE));
      }
      if (nextStep === CoachStep.CHECKIN_OFFER && offerTitles) {
        parts.push(
          line(COACH_CHECKIN_OFFER_LINE)
            .replace('{done}', offerTitles.done)
            .replace('{next}', offerTitles.next),
        );
      }
      if (step === CoachStep.CHECKIN_OFFER && event.kind === 'invite' && !event.accept) {
        parts.push(line(COACH_CHECKIN_LATER_LINE));
      }
      if (
        nextStep === CoachStep.END &&
        (step === CoachStep.CHECKIN_ASK ||
          step === CoachStep.CHECKIN_TELL ||
          step === CoachStep.QUIZ_IN_CHAT)
      ) {
        parts.push(line(COACH_CHECKIN_ALL_DONE_LINE));
      }
      if (parts.length) return parts.join('\n\n');
    }

    // A habit name that matched nothing: say so, and the picker asks again.
    if (
      step === CoachStep.SCENE_PICK &&
      event.kind === 'text' &&
      nextStep === CoachStep.SCENE_PICK
    ) {
      return line(COACH_SCENE_PICK_MISS_LINE);
    }

    // On track, and a card follows: the second sentence, "để card không rơi
    // xuống đột ngột". Two sentences, never merged into one.
    if (judged && ctx.sceneOnTrack && nextStep === CoachStep.COURSE_CARD) {
      return line(COACH_SCENE_CARD_LEAD_LINE);
    }

    // Off track twice — close on one line, count nothing.
    if (step === CoachStep.SCENE_RETRY && judged && !ctx.sceneOnTrack) {
      return line(COACH_SCENE_GIVE_UP_LINE);
    }
    if (
      step === CoachStep.SCENE_FIX &&
      event.kind === 'sceneAgain' &&
      (nextStep === CoachStep.END || nextStep === CoachStep.STORY_TALK)
    ) {
      return line(
        event.again ? COACH_SCENE_GIVE_UP_LINE : COACH_SCENE_LATER_LINE,
      );
    }

    // Home never closes on its own: the card put away, or a scene done right
    // with no course to show, leaves the box open under one line.
    if (
      nextStep === CoachStep.STORY_TALK &&
      ((step === CoachStep.COURSE_CARD && event.kind === 'course') ||
        (judged && ctx.sceneOnTrack && step !== CoachStep.STORY_TALK))
    ) {
      return line(COACH_STORY_CONTINUE_LINE);
    }

    // FREE_TALK reached its cap (or asked how): a course when the story
    // connects to one — and the Coach says where it connects from — otherwise
    // one closing sentence. "Tuyệt đối không gợi bừa một khoá cho có."
    const storyEnds =
      (step === CoachStep.STORY_TALK || step === CoachStep.DEPTH) &&
      event.kind !== 'ack' &&
      ctx.storyKind !== CoachStoryKind.STOP;
    if (storyEnds && nextStep === CoachStep.COURSE_CARD) {
      // The resume card matched nothing — claiming "có một khoá nói đúng về
      // nó" over it would be exactly the "gợi bừa một khoá cho có" the doc
      // forbids, so it gets its own honest sentence.
      return line(
        cardReasonKey === COACH_COURSE_REASON.RESUME
          ? COACH_STORY_RESUME_LEAD_LINE
          : COACH_STORY_CARD_LEAD_LINE,
      );
    }
    if (storyEnds && nextStep === CoachStep.END) {
      return line(COACH_STORY_NO_COURSE_LINE);
    }
    // They asked to be pointed somewhere and the library had nothing: say so.
    // The conversation carries on underneath — this is a sentence, not an end.
    if (
      storyEnds &&
      nextStep === CoachStep.STORY_TALK &&
      ctx.storyKind === CoachStoryKind.ASKS_HOW
    ) {
      return line(COACH_STORY_NO_MATCH_LINE);
    }

    return null;
  }

  /**
   * Luồng 4 — "→ habit_checkins { method: EXERCISE, done: true }": the scene
   * done right files the day's check-in for the habit it practised. Best
   * effort: a failed write must never break the reply that earned it.
   */
  private async recordSceneCheckin(session: CoachSession): Promise<void> {
    if (!session.habitId) return;
    try {
      const owned = (await this.userHabitRepository.findForUser(
        session.userId,
        UserHabitState.ACTIVE,
      )) as Array<{ _id: unknown; habitId?: unknown }>;
      const row = owned.find((h) => String(h.habitId) === session.habitId);
      if (!row) return;

      await this.userHabitService.checkIn(String(row._id), {
        done: true,
        method: HabitCheckinMethod.EXERCISE,
      } as CheckInUserHabitDto);
    } catch (error: any) {
      this.logger.warn(
        `Coach could not file the scene check-in: ${error?.message}`,
      );
    }
  }

  /**
   * SCENE_PICK — "hoặc gõ tên habit bạn muốn tập": the typed name against the
   * kho, accents dropped both ways. Only the reader's own habits — "không sinh
   * habit mới và không gợi habit ngoài kho".
   */
  private async matchOwnedHabitByName(
    userId: string,
    text: string,
    locale: string,
  ): Promise<string | null> {
    const said = fold(text);
    if (!said) return null;

    const owned = (await this.userHabitRepository
      .findForUser(userId, UserHabitState.ACTIVE)
      .catch(() => [])) as Array<{ habitId?: unknown }>;
    const choices = await this.habitChoicesFor(
      owned.map((row) => String(row.habitId ?? '')).filter(Boolean),
      locale,
    );

    const hit = choices.find((choice) => {
      const title = fold(choice.label);

      return Boolean(title) && (said.includes(title) || title.includes(said));
    });

    return hit?.value ?? null;
  }

  /**
   * Luồng 4 — the one course the session may offer, connected to a habit.
   *
   * First a course that TEACHES the habit and the reader has not started;
   * for the practice branch, failing that, any unstarted course in the same
   * skill set ("cùng skill set với habit đang tập"). Random among what
   * qualifies, per-course fatigue respected, and NOTHING when nothing
   * qualifies — a card for the sake of a card is the upsell this feature
   * keeps refusing to become.
   */
  private async pickCourseConnected(
    session: CoachSession,
    habitId: string,
    reasonKey: string,
  ): Promise<PickedCourse | null> {
    if (session.moodEndLow) return null;

    const [progressIds, containing] = await Promise.all([
      this.userProgressRepository
        .findCourseIdsForUser(session.userId)
        .catch(() => [] as string[]),
      this.habitLibraryService.coursesWithHabit(habitId).catch(() => []),
    ]);
    const started = new Set(progressIds as string[]);
    const rows = containing as Array<{ id: string; skillsetId?: string }>;
    const allowed = (courseId: string) =>
      this.boostService
        .allows({
          userId: session.userId,
          kind: CoachBoostKind.COURSE_CARD,
          refId: courseId,
          alreadyAsked: [],
        })
        .catch(() => true);
    const reasonArg = await this.habitTitleOf(habitId, session.locale);

    for (const course of [...rows].sort(() => Math.random() - 0.5)) {
      if (started.has(course.id)) continue;
      if (!(await allowed(course.id))) continue;

      return { id: course.id, reasonKey, reasonArg };
    }

    if (reasonKey !== COACH_COURSE_REASON.SKILLSET) return null;

    const skillsetIds = [
      ...new Set(rows.map((row) => row.skillsetId).filter(Boolean)),
    ] as string[];
    if (!skillsetIds.length) return null;

    const inSkillset = (await this.courseRepository
      .findPublishedInSkillsets({
        skillsetIds,
        excludeIds: [...started, ...rows.map((row) => row.id)],
        limit: 10,
      })
      .catch(() => [])) as Array<{ _id: unknown }>;
    for (const course of [...inSkillset].sort(() => Math.random() - 0.5)) {
      const id = String(course._id);
      if (!(await allowed(id))) continue;

      return { id, reasonKey, reasonArg };
    }

    return null;
  }

  /**
   * One line of the story conversation, answered.
   *
   * The owner's table of 2026-09-04 lives in the prompt; what lives here is
   * everything the model is not trusted with. The recurring-subject count is
   * read from the reader's own filed rows (a model deciding "you do this a
   * lot" from one message is the diagnosis the rules forbid), the reply goes
   * through the same echo and banned-question nets every other reply does,
   * and the LAST reply of the conversation has its questions stripped — there
   * is no box under it for an answer.
   */
  private async runStoryTalk(
    session: CoachSession,
    turnContext: CoachTurnContext,
    ctx: CoachMachineContext,
    said: string,
  ): Promise<{
    reply: string | null;
    storyKind: CoachStoryKind;
    patternNamed: boolean;
    promptKeyOverride?: string | null;
  }> {
    const spent = ctx.storyTalkRounds ?? 0;
    // Home has no cap (owner, 2026-09-04): null tells the prompt "no end of
    // its own". The lesson door's parked depth talk keeps its rounds.
    const roundsLeft =
      ctx.entry === CoachEntry.HOME ? null : Math.max(0, storyTalkCap(ctx) - spent - 1);

    // "Có vấn đề lặp lại → xác định pattern" — counted once per session, and
    // only while the session knows which habit the story is about.
    let recurring = 0;
    if (!session.patternNamed && session.habitId) {
      recurring = await this.reflectionService
        .countSessionsAboutHabit({
          userId: session.userId,
          habitId: session.habitId,
          since: new Date(
            Date.now() - STORY_PATTERN_WINDOW_DAYS * 24 * 60 * 60 * 1000,
          ),
          exceptSessionId: session._id.toString(),
        })
        .catch(() => 0);
    }
    const naming = recurring >= STORY_PATTERN_MIN_SESSIONS;

    const asking: CoachTurnContext = {
      ...turnContext,
      step: CoachStep.STORY_TALK,
      input: said,
      storyRoundsLeft: roundsLeft,
      storyRecurringSessions: naming ? recurring : null,
      storyGentle: Boolean(ctx.moodLow || ctx.lateNightLow),
      // ĐUÔI của phiên trước, nguyên văn — lấy ở đây vì `buildStoryTalkPrompt`
      // là prompt DUY NHẤT đọc nó. Thứ thẻ nhớ không thay được chỉ là mấy câu
      // cuối của một mạch chưa xong ("vừa nói ở trên"); phần xa hơn đã nằm
      // trong thẻ, và 30 dòng raw là cách lớn dần theo lịch sử.
      priorTranscript: await this.memoryService
        .priorLinesFor(session.userId, String(session._id), PRIOR_TAIL_LINES)
        .catch(() => []),
    };

    let talked = await this.ai.talkStory(asking);
    if (talked.reply && looksLikeEcho(talked.reply, said)) {
      void this.metricService.bump(CoachMetricKind.ECHOED_READER);
      talked = await this.ai
        .talkStory({ ...asking, retryAfterEcho: true })
        .catch(() => talked);
    }

    let reply: string | null = talked.reply || null;
    let promptKeyOverride: string | null = null;

    // The banned-question net, only when there is a question to judge.
    if (reply && /[?？]/.test(reply)) {
      const verdict = await this.ai
        .classifyQuestion(reply, session.locale)
        .catch(() => ({ banned: false }));
      if (verdict.banned) {
        void this.metricService.bump(CoachMetricKind.BANNED_QUESTION);
        const retried = await this.ai
          .talkStory({ ...asking, retryAfterBannedQuestion: true })
          .catch(() => null);
        const second = retried?.reply
          ? await this.ai
              .classifyQuestion(retried.reply, session.locale)
              .catch(() => ({ banned: false }))
          : { banned: true };
        if (retried?.reply && !second.banned) {
          reply = retried.reply;
        } else {
          void this.metricService.bump(CoachMetricKind.BANNED_QUESTION_FALLBACK);
          reply = null;
          // A fixed question about what happened stands in — but only while
          // there is still a turn for the answer to land in.
          promptKeyOverride = roundsLeft === null || roundsLeft > 0 ? COACH_TELL_FOLLOW_UP_KEY : null;
        }
      }
    }

    // The last reply must not leave a question hanging over a closed box.
    if (reply && roundsLeft === 0) reply = this.withoutQuestions(reply);

    // "Đừng xưng anh nữa": the reader renamed themselves mid-talk. Written to
    // the profile and onto this session at once, so the very next fixed line
    // already follows — and into the live object, so this turn's reply does.
    const renamed = this.normalizeAddress(talked.newAddress);
    if (renamed && renamed !== session.address) {
      session.address = renamed;
      await Promise.all([
        this.profileService.setAddress(session.userId, renamed),
        this.sessionRepository.updateOne({ _id: session._id }, { address: renamed } as Partial<CoachSession>),
      ]).catch((error: any) => this.logger.warn(`Coach could not change the address: ${error?.message}`));
    }

    return { reply, storyKind: talked.kind, patternNamed: naming, promptKeyOverride };
  }

  /** A pronoun in its canonical lowercase form, a name as given, or nothing usable. */
  private normalizeAddress(raw?: string | null): string | null {
    const word = raw?.trim().replace(/^[«"“']+|[»"”'.]+$/g, '') ?? '';
    if (!word || word.length > 30) return null;
    const pronoun: Record<string, string> = { ban: 'bạn', anh: 'anh', chi: 'chị', em: 'em', minh: 'bạn', toi: 'bạn' };

    return pronoun[fold(word)] ?? word;
  }

  /**
   * ②B — "đối chiếu ngầm": which of the reader's OWN habits the story bears on.
   *
   * Candidates are the habits in their store and nothing else — the Coach
   * "chỉ CHỌN trong danh sách, không sinh habit mới, không đổi tên habit".
   * The id must come back from the list we handed over; anything else is
   * dropped and the due habit chosen at open stands.
   */
  private async runSilentMatch(
    turnContext: CoachTurnContext,
    session: CoachSession,
  ): Promise<{
    habitId: string | null;
    reply: string | null;
    confidence: number;
  } | null> {
    const owned = await this.userHabitRepository.findForUser(
      session.userId,
      UserHabitState.ACTIVE,
    );
    const ownedIds = owned.map((h: { habitId: unknown }) => String(h.habitId));

    // "Đối chiếu ngầm quét TOÀN DANH MỤC HDDhistory, không chỉ kho của user" — the
    // whole point is that the answer may be a habit they do not have yet, which
    // is what the course card is for. Still only CHOOSING: the model may never
    // invent a habit or rename one. The reader's own shelf is read anyway,
    // because which side of it the answer falls on decides everything after.
    void ownedIds;
    const habits = (
      (await this.habitLibraryService.findAll({} as never).catch(() => [])) as unknown[]
    ).slice(0, HABIT_MATCH_CANDIDATE_LIMIT);
    const candidates = (habits as Array<{ _id: unknown; title?: ITranslation }>)
      .map((h) => ({
        id: String(h._id),
        title: this.pickTranslation(h.title, session.locale) ?? '',
      }))
      .filter((c) => c.title);
    if (!candidates.length) return null;

    const asking: CoachTurnContext = { ...turnContext, freeTalkLastTurn: true };
    let match = await this.ai.matchHabit(asking, candidates);

    // ②C SAYS this line out loud, so it goes through the same echo guard the
    // scene reply does: "Chen ngang lúc Nam đang nói." handed back to somebody
    // who just wrote that exact sentence is a transcription, not a reflection.
    if (looksLikeEcho(match.reply, turnContext.input)) {
      void this.metricService.bump(CoachMetricKind.ECHOED_READER);
      match = await this.ai
        .matchHabit({ ...asking, retryAfterEcho: true }, candidates)
        .catch(() => match);
    }

    const valid =
      match.habitId && candidates.some((c) => c.id === match.habitId);
    if (match.habitId && !valid) {
      this.logger.warn(
        `Coach habit match returned an id outside the candidate list: ${match.habitId}`,
      );
    }

    return {
      habitId: valid ? (match.habitId as string) : null,
      reply: match.reply?.trim() || null,
      confidence: match.confidence ?? 0,
    };
  }

  /**
   * Nhịp 4's keypoint, as prompt fields plus the id to remember.
   *
   * Returns an empty object when the habit has no keypoint attached: the reply
   * then writes nhịp 5 alone, which the instruction allows for explicitly. A
   * habit with nothing to teach from is a content gap, not a broken turn.
   */
  private async keypointBeat(session: CoachSession): Promise<{
    keypointTitle?: string | null;
    keypointBody?: string | null;
    keypointId?: string | null;
  }> {
    const keypoint = await this.situationService
      .keypointFor(session.habitId, session.locale)
      .catch(() => null);
    if (!keypoint) return {};

    return {
      keypointTitle: keypoint.title,
      keypointBody: keypoint.description,
      keypointId: keypoint.id,
    };
  }

  /**
   * "Đổi" — the Coach says one line and lists the reader's OWN kho.
   *
   * Only habits they already have: "chỉ chọn trong kho, không sinh habit mới".
   * The step they were on is remembered so the picker is a detour, not a
   * branch — nothing about where they are in the conversation moves.
   */
  private async openHabitPicker(
    session: CoachSession,
  ): Promise<CoachTurnResponse> {
    // ⇄ tapped while the picker is ALREADY open used to record PICK_HABIT as
    // the way back — picking then returned to the picker itself, forever
    // ("đổi habit thì không có gì xảy ra", owner on-device 2026-08-28). The
    // way back is always a real step.
    const habitReturnStep =
      session.step === CoachStep.PICK_HABIT
        ? (session.habitReturnStep ?? CoachStep.HUB)
        : session.step;
    await this.sessionRepository.updateOne(
      { _id: session._id },
      {
        step: CoachStep.PICK_HABIT,
        habitReturnStep,
      } as Partial<CoachSession>,
    );

    return this.respond(
      {
        ...session,
        step: CoachStep.PICK_HABIT,
        habitReturnStep,
      } as CoachSession,
      CoachStep.PICK_HABIT,
      null,
    );
  }

  /** The picker's answer: the session is about that habit now, and nothing else moved. */
  private async pickHabitBack(
    session: CoachSession,
    habitId: string,
  ): Promise<CoachTurnResponse> {
    const owns = await this.ownsHabit(session.userId, habitId);
    if (!owns) throw new BadRequestException('Habit is not in the reader kho');

    const returnStep = session.habitReturnStep ?? CoachStep.HUB;
    // Mid-practice the old habit's scene stayed on screen — "bị cứng nhắc 1
    // habit user đã chọn trước đó", and picking looked like nothing happened
    // (owner, on-device 2026-08-28). A scene belongs to the habit that built
    // it, so switching habits anywhere inside T2 restarts the practice: the
    // scene state is cleared and TELL_ONCE writes a fresh scene for the NEW
    // habit. Every other step just resumes where they were.
    const scenic = taskOf(returnStep) === 'T2';
    // Picked from the tail — the card, the mood, the rating, the closing line —
    // the old code put the reader straight back there, so changing habit read
    // as "the conversation just ended" (bug sheet 2026-08-28 16:18). A habit
    // chosen ON PURPOSE is the start of something: the coordinator asks what to
    // do with it, with Kể chuyện and Luyện tập tình huống on the pills.
    const back = scenic
      ? CoachStep.TELL_ONCE
      : isClosingStep(returnStep)
        ? CoachStep.HUB
        : returnStep;
    void this.metricService.bump(CoachMetricKind.HABIT_CHANGED);
    const patch = {
      habitId,
      step: back,
      // They picked it themselves — nothing is more confirmed than that.
      habitConfirmed: true,
      habitReturnStep: null,
      ...(scenic
        ? {
            situationId: null,
            situationRound: 0,
            sceneBeats: [],
            sceneBeatLines: [],
            sceneCounterpart: null,
            sceneTakeaway: null,
            sceneGoodMove: null,
            sceneLevel: null,
            scenePrompt: null,
            scenePromptStage2: null,
            sceneDidAnswer: null,
            sceneRetried: false,
          }
        : {}),
    } as Partial<CoachSession>;
    await this.sessionRepository.updateOne({ _id: session._id }, patch);

    return this.respond(
      { ...session, ...patch } as CoachSession,
      back,
      null,
    );
  }

  /** The last thing the reader actually wrote in this session, or null. */
  private lastReaderLine(session: CoachSession): string | null {
    const said = [...(session.turns ?? [])]
      .reverse()
      .find((turn) => turn.role === CoachTurnRole.USER && turn.text?.trim());

    return said?.text?.trim() ?? null;
  }

  /** The commitment being checked in on, in the reader's words — or null. */
  private async planQuote(
    planId?: string | null,
  ): Promise<{ context: string; action: string } | null> {
    if (!planId) return null;
    const plan = await this.planService.findById(planId).catch(() => null);
    if (!plan) return null;

    return { context: plan.context, action: plan.action };
  }

  /**
   * The one course the tail offers — chosen for THIS reader, with the reason.
   *
   * "Truy xuất MỘT course, không trả danh sách" still holds; what changed is
   * who it is for. The old pick (the course with the most of this habit's
   * keypoints) was, for almost everyone, the course they had just taken — the
   * habit came from it. A card that points back to where the reader is
   * standing is not a direction.
   *
   * Server-side, data only, first rung that yields wins:
   *   0. Never a course with any progress row, nor the `sourceCourseId` of a
   *      habit they follow.
   *   1. The habit they keep STOPPING at (≥ `COURSE_STRUGGLE_MIN_BARRIERS`
   *      barrier rows) — a course that teaches it.
   *   2. The habit this session is about — a course that teaches it.
   *   3. Same skillset as a habit they practise — not started.
   *   4. Saved from an earlier card, never opened.
   *   5. Nothing new → no card. Re-offering an old course is worse than none.
   *
   * The reason is a FACT about the reader for the card to state, never a
   * model's opinion; that is what lets the card read as the app having
   * listened rather than an advert fired on a keyword.
   */
  private async pickCourseFor(
    session: CoachSession,
  ): Promise<PickedCourse | null> {
    const userId = session.userId;
    const locale = session.locale;

    // "KHÔNG bật: cửa ① · phiên đã kích hoạt đường thoát an toàn · mood cuối
    // phiên ở mức thấp." A course offered to somebody who just said their day
    // was bad reads as a shop assistant, not a coach.
    if (session.entry === CoachEntry.LESSON || session.moodEndLow) return null;

    // The card has exactly ONE job (doc v4): the road to a habit the reader does
    // NOT have yet — "không phải lời mời học thêm về habit user đã có". So the
    // habit it points at is the one the silent match found outside their kho,
    // and the keypoint the Coach spoke from at nhịp 4 has nothing to do with it
    // ("keypoint KHÔNG dẫn tới card course, không ghi nhớ keypoint_id").
    const outsideHabitId = session.cardHabitId ?? null;
    if (!outsideHabitId) return null;

    const [progressIds, containing] = await Promise.all([
      this.userProgressRepository.findCourseIdsForUser(userId).catch(() => []),
      this.habitLibraryService
        .coursesWithHabit(outsideHabitId)
        .catch(() => []),
    ]);

    const started = new Set(progressIds);

    // Owner's call (2026-08-27), loosening the doc's first-lesson rule: any
    // course CONTAINING the habit qualifies, and the pick is RANDOM among them
    // — the same story does not always point at the same course. Started
    // courses and per-course fatigue still filter first.
    const shuffled = [...(containing as Array<{ id: string }>)].sort(
      () => Math.random() - 0.5,
    );
    for (const course of shuffled) {
      if (started.has(course.id)) continue;

      // Per-COURSE fatigue: "đóng card 3 lần cho cùng một course → không gợi
      // course đó nữa. Course khác vẫn gợi bình thường."
      const allowed = await this.boostService
        .allows({
          userId,
          kind: CoachBoostKind.COURSE_CARD,
          refId: course.id,
          alreadyAsked: [],
        })
        .catch(() => true);
      if (!allowed) continue;

      return {
        id: course.id,
        // "Chuyện bạn vừa kể chạm tới một thứ chưa có trong kho của bạn." One
        // written line; the habit's name rides along for the card's subtitle.
        reasonKey: COACH_COURSE_REASON.OUTSIDE,
        reasonArg: await this.habitTitleOf(outsideHabitId, locale),
      };
    }

    // "Không có khoá nào thoả → KHÔNG hiện card." No fallback to a course that
    // merely shares a skillset: that was this file's own invention, and it is
    // how the tail turned into an upsell.
    return null;
  }

  /**
   * Kho rỗng: the road to a FIRST habit — "đề xuất người dùng học bài để add
   * habit" (owner, 2026-08-29). Nothing was matched because nothing was told,
   * so the pick walks a handful of published library habits at random and
   * offers the first course that opens with one of them (falling back to any
   * course containing it) that the reader has not started. Per-course fatigue
   * still counts, and the card reads `reasonHabit` — "Bài đầu tiên của khoá
   * này là «X»" — a key every shipped client already maps.
   */
  private async pickCourseForFirstHabit(
    session: CoachSession,
  ): Promise<PickedCourse | null> {
    if (session.moodEndLow) return null;

    const habits = (await this.habitLibraryService
      .findAll({} as never)
      .catch(() => [])) as Array<{ _id: unknown }>;
    if (!habits.length) return null;

    const started = new Set(
      (await this.userProgressRepository
        .findCourseIdsForUser(session.userId)
        .catch(() => [])) as string[],
    );

    const sampled = [...habits].sort(() => Math.random() - 0.5).slice(0, 6);
    for (const habit of sampled) {
      const habitId = String(habit._id);
      const opening = (await this.habitLibraryService
        .coursesOpeningWithHabit(habitId)
        .catch(() => [])) as Array<{ id: string }>;
      const containing = opening.length
        ? opening
        : ((await this.habitLibraryService
            .coursesWithHabit(habitId)
            .catch(() => [])) as Array<{ id: string }>);

      for (const course of containing) {
        if (started.has(course.id)) continue;

        const allowed = await this.boostService
          .allows({
            userId: session.userId,
            kind: CoachBoostKind.COURSE_CARD,
            refId: course.id,
            alreadyAsked: [],
          })
          .catch(() => true);
        if (!allowed) continue;

        return {
          id: course.id,
          reasonKey: COACH_COURSE_REASON.HABIT,
          reasonArg: await this.habitTitleOf(habitId, session.locale),
        };
      }
    }

    return null;
  }

  /**
   * The card as the thread draws it — from the id and reason REMEMBERED on
   * the session, never re-picked: the selector reads live data, and a card
   * that names a different course on resume than it did a minute ago reads as
   * the Coach changing its story.
   */
  private async courseCardFor(
    session: CoachSession,
  ): Promise<CoachUiPayload['course']> {
    if (!session.courseCardId) return null;

    const [course] = (await this.courseRepository
      .findPublishedSummariesByIds([session.courseCardId])
      .catch(() => [])) as Array<{
      _id: unknown;
      title?: ITranslation;
      image?: string;
      author?: string | null;
      viewCount?: number | null;
    }>;
    if (!course) return null;

    return {
      courseId: String(course._id),
      title: this.pickTranslation(course.title, session.locale) ?? '',
      image: course.image || null,
      habitTitle: await this.habitTitleOf(session.habitId, session.locale),
      author: course.author ?? null,
      viewCount: typeof course.viewCount === 'number' ? course.viewCount : null,
      reasonKey: session.courseCardReasonKey ?? null,
      reasonArgs: session.courseCardReasonArg
        ? { habit: session.courseCardReasonArg }
        : null,
    };
  }

  /** The habit's `contexts` block in the reader's language, raw (newline-joined). */
  private async habitContextsOf(
    habitId: string | null | undefined,
    locale: string,
  ): Promise<string | null> {
    if (!habitId) return null;
    const habit = await this.habitLibraryService.findOne(habitId).catch(() => null);

    return this.pickTranslation(
      (habit as { contexts?: ITranslation | null } | null)?.contexts ?? undefined,
      locale,
    );
  }

  /** "One moment per line" → trimmed lines; tolerant of `;`/`|` from sheets. */
  private splitHabitContexts(value: string | null): string[] {
    if (!value) return [];

    return value
      .split(/\r?\n|;|\|/)
      .map((line) => line.trim().replace(/^[-•·]\s*/, ''))
      .filter(Boolean);
  }

  private async habitTitleOf(
    habitId: string | null | undefined,
    locale: string,
  ): Promise<string | null> {
    if (!habitId) return null;

    const habit = await this.habitLibraryService
      .findOne(habitId)
      .catch(() => null);

    return this.pickTranslation(
      (habit as { title?: ITranslation } | null)?.title,
      locale,
    );
  }

  /**
   * The closing line — "câu chốt".
   *
   * Written from the commitment made in THIS session and the reminder set for
   * it; a fixed line stands in when there is no commitment or the model failed.
   * Never a question: the model's line is rejected if it asks one.
   */
  private async closingLine(session: CoachSession): Promise<{
    reply: string | null;
    promptKeyOverride: string | null;
    promptArgs: Record<string, string> | null;
  }> {
    const noPlan: {
      reply: string | null;
      promptKeyOverride: string | null;
      promptArgs: Record<string, string> | null;
    } = {
      reply: null,
      promptKeyOverride: COACH_CLOSING_NO_PLAN_KEY,
      promptArgs: null,
    };
    const planId = session.createdPlanId;
    if (!planId) {
      // ②C files nothing — "câu chuyện không được lưu, phiên đóng là mất" — so
      // "Ghi lại rồi nhé" would be a promise the app did not keep.
      return session.tier === CoachHomeTier.GUIDED
        ? { ...noPlan, promptKeyOverride: COACH_CLOSING_HEARD_KEY }
        : noPlan;
    }

    const plan = await this.planService.findById(planId).catch(() => null);
    if (!plan) return noPlan;

    const reminder = plan.reminder?.enabled
      ? { enabled: true, hour: plan.reminder.hour, minute: plan.reminder.minute }
      : null;
    const args: Record<string, string> = {
      context: plan.context,
      action: plan.action,
      time: reminder
        ? `${String(reminder.hour).padStart(2, '0')}:${String(reminder.minute).padStart(2, '0')}`
        : '',
    };

    try {
      const written = await this.ai.closingLine(
        {
          locale: session.locale,
          step: CoachStep.NEXT_SESSION,
          persona: session.persona,
          script: null,
          transcript: [],
          input: '',
        },
        { context: plan.context, action: plan.action },
        reminder,
      );

      return { reply: written.line, promptKeyOverride: null, promptArgs: args };
    } catch (error: any) {
      this.logger.warn(`Coach closing line failed: ${error?.message}`);

      return {
        reply: null,
        promptKeyOverride: COACH_CLOSING_WITH_PLAN_KEY,
        promptArgs: args,
      };
    }
  }

  /** The Coach's half of this session's transcript, for the draft filter. */
  private coachLines(session: CoachSession): string[] {
    return session.turns
      .filter((t) => t.role === CoachTurnRole.COACH)
      .map((t) => t.text);
  }

  /**
   * Hygiene on the model's five offered lines — hygiene only.
   *
   * Dedupes (a model asked for five distinct aspects sometimes pads with a
   * paraphrase), drops blanks and essays, drops anything lifted from the
   * Coach's own questions (that is the model filing its question as the
   * reader's story), and caps the count. The draft is an offer the reader
   * curates; the curation UI is the guarantee that what SURVIVES is theirs.
   */
  private tidyDraftLines(lines: string[], coachLines: string[] = []): string[] {
    const seen = new Set<string>();
    const kept: string[] = [];
    const coach = coachLines.map((l) => fold(l));

    for (const raw of lines) {
      const line = raw.trim();
      if (!line || line.length > 120) continue;

      const key = fold(line);
      if (seen.has(key)) continue;
      // A short Coach line must not be able to empty the whole draft: `fold`
      // does not trim, so a blank or near-blank Coach turn folds to something
      // every line contains and the reader arrives at two empty columns. Both
      // sides of the containment test need real length to mean anything.
      if (
        coach.some(
          (c) =>
            c.length >= 12 &&
            (c.includes(key) || (key.length >= 12 && key.includes(c))),
        )
      ) {
        continue;
      }
      seen.add(key);

      kept.push(line);
      if (kept.length >= TWO_COLS_DRAFT_LINES) break;
    }

    return kept;
  }

  /**
   * Everything a completed transition writes, in one place.
   *
   * Returns the id of a commitment CREATED on this turn, so the session can
   * remember it — the closing line quotes it back.
   */
  private async applyWrites(params: {
    session: CoachSession;
    step: CoachStep;
    /** Where the graph is going — how a depth answer says "file it and move on". */
    nextStep: CoachStep;
    dto: CoachTurnDto;
    text: string;
    /** STORY_TALK — what kind of line this was; decides what, if anything, is filed. */
    storyKind?: CoachStoryKind | null;
  }): Promise<string | null> {
    const { session, step, nextStep, dto, text, storyKind } = params;
    const userId = session.userId;
    const sessionId = session._id.toString();

    // T4 — "Chỉ ghi lại thôi", however it was said: the pill on the opener, the
    // pill under the depth question, or words the classifier read as closing
    // the subject. All three land on the commitment question, and what gets
    // filed is the sentence they had ALREADY written.
    const jotting = isShallowJot(step, nextStep, dto.kind, storyKind);
    if (jotting) await this.fileQuickNote(session);

    switch (dto.kind) {
      case CoachTurnEventKind.MOOD:
        await this.dayLogService.recordMood({
          userId,
          tzOffsetMinutes: session.tzOffsetMinutes,
          moment: DayLogMoment.START,
          mood: dto.mood as number,
          sessionId,
        });

        return null;

      case CoachTurnEventKind.MOOD_END:
        await this.dayLogService.recordMood({
          userId,
          tzOffsetMinutes: session.tzOffsetMinutes,
          moment: DayLogMoment.END,
          mood: dto.mood as number,
          sessionId,
        });

        return null;

      case CoachTurnEventKind.INTENT:
        if (dto.answer && session.activePlanId) {
          await this.planService.recordAnswer(session.activePlanId, dto.answer);
        }

        return null;

      case CoachTurnEventKind.PLAN: {
        // At SHRINK the form REPLACES the commitment it was pre-filled from:
        // the old row stays in the habit's history as `replaced`, the new one
        // inherits the reminder. Two live promises about one thing is a backlog.
        if (step === CoachStep.SHRINK && session.activePlanId) {
          const shrunk = await this.planService.shrink(session.activePlanId, {
            context: dto.planContext as string,
            action: dto.planAction as string,
          });

          return shrunk?._id.toString() ?? null;
        }

        const created = await this.planService.create({
          userId,
          context: dto.planContext as string,
          action: dto.planAction as string,
          source: this.planSource(session),
          habitId: session.habitId,
        });

        return created._id.toString();
      }

      case CoachTurnEventKind.SCHEDULE:
        if (session.activePlanId) {
          await this.planService.setReminder(session.activePlanId, {
            enabled: Boolean(dto.reminderEnabled),
            hour: dto.reminderHour,
            minute: dto.reminderMinute,
            days: dto.reminderDays,
            customDays: dto.reminderCustomDays,
            onceDate: dto.reminderDate ?? null,
          });
        }

        return null;

      case CoachTurnEventKind.COURSE:
        // "Lưu" → Để dành. The reader is not made to study now to keep it.
        if (dto.courseAction === CoachCourseAction.SAVE && session.courseCardId) {
          await this.savedCourseRepository
            .save(userId, session.courseCardId)
            .catch((error: any) =>
              this.logger.warn(`Coach could not save course: ${error?.message}`),
            );
        }

        return null;

      case CoachTurnEventKind.RATING:
        // The 👍/👎 toast was removed on 2026-09-14 and the machine no longer
        // routes to its step, so nothing should send this. A build still in
        // somebody's hands might: ignored rather than rejected, because a
        // retired question must not be able to fail a live session.
        return null;

      case CoachTurnEventKind.TEXT:
        await this.writeTextTurn(session, step, text, dto, storyKind);

        return null;

      default:
        return null;
    }
  }

  /**
   * File the sentence the reader already wrote, as the twenty-second jot.
   *
   * Tagged `QUICK_NOTE` so the recap's "chữ của chính bạn" does not mix it in
   * with a sentence somebody arrived at after pulling their story apart.
   * Nothing is filed when they wrote nothing: silence is the answer to "có
   * muốn ghi lại không", and the answer is no.
   */
  private async fileQuickNote(session: CoachSession) {
    const said = this.lastReaderLine(session);
    if (!said) return;

    await this.reflectionService
      .recordProblemStatement({
        userId: session.userId,
        sessionId: session._id.toString(),
        habitId: session.habitId,
        content: said,
        kind: CoachStatementKind.QUICK_NOTE,
      })
      .catch((error: any) =>
        this.logger.warn(`Coach could not file the jot: ${error?.message}`),
      );
  }

  /** Free-text turns, each of which lands in a different collection or none. */
  private async writeTextTurn(
    session: CoachSession,
    step: CoachStep,
    text: string,
    dto?: CoachTurnDto,
    storyKind?: CoachStoryKind | null,
  ) {
    const userId = session.userId;
    const sessionId = session._id.toString();

    // The story conversation files ONE thing: a difficulty the reader named,
    // in their words — what the two-column draft's right column used to
    // produce, now without the form. A success, a feeling, an ordinary line
    // stay unwritten like the rest of the story: "chỉ giữ kết luận họ tự rút".
    if (
      (step === CoachStep.STORY_TALK || step === CoachStep.DEPTH) &&
      storyKind === CoachStoryKind.PROBLEM &&
      text
    ) {
      await this.reflectionService.recordProblemStatement({
        userId,
        sessionId,
        habitId: session.habitId,
        content: text,
        kind: CoachStatementKind.PROBLEM_STATEMENT,
      });

      return;
    }

    // ⑥ — their line for the day. Stored as the reader's own words like every
    // other sentence here, but tagged so the recap's "chữ của chính bạn" does
    // not mix a twenty-second jot in with the sentence somebody arrived at
    // after pulling their story apart.
    if (step === CoachStep.JOT && text) {
      await this.reflectionService.recordProblemStatement({
        userId,
        sessionId,
        habitId: session.habitId,
        content: text,
        kind: CoachStatementKind.QUICK_NOTE,
      });

      return;
    }

    // T4 reached by the pill: "user đã nói gì ở bước CÂU MỞ" IS the thing being
    // filed — the task has no question of its own, so the sentence to keep is
    // the last one they wrote. Nothing is filed when they wrote nothing: the
    // silence is the answer to "có muốn ghi lại không", and it is no.
    if (step === CoachStep.STORY && !text) {
      const said = [...session.turns]
        .reverse()
        .find((turn) => turn.role === CoachTurnRole.USER && turn.text?.trim());
      if (said) {
        await this.reflectionService.recordProblemStatement({
          userId,
          sessionId,
          habitId: session.habitId,
          content: said.text,
          kind: CoachStatementKind.QUICK_NOTE,
        });
      }

      return;
    }

    // ③ "Đổi bối cảnh" — their words replace the plan's context, nothing else.
    if (step === CoachStep.CONTEXT_EDIT && text && session.activePlanId) {
      await this.planService
        .updateContext(session.activePlanId, text)
        .catch((error: any) =>
          this.logger.warn(`Could not change a plan's context: ${error?.message}`),
        );

      return;
    }

    // Nhịp 3 and ⑤ — "the real problem is …", in their words either way.
    if (step === CoachStep.TWO_COLS || step === CoachStep.REDRAFT) {
      const proposed = session.draftProposed?.length ?? 0;
      // The reader's moves, edits and deletions arrive ON THIS TURN and are
      // written to the session AFTER this runs, so the kept count has to be
      // read from the request rather than from the stored draft.
      const kept = (dto?.leftLines ?? session.draftLeft)?.length ?? 0;

      await this.reflectionService.recordProblemStatement({
        userId,
        sessionId,
        habitId: session.habitId,
        content: text,
        kind: CoachStatementKind.PROBLEM_STATEMENT,
        draftProposedCount: proposed,
        draftKeptCount: kept,
      });

      // A draft nobody had to touch is the model imposing, not the model being
      // right — the pair of counters is what makes that visible weekly.
      if (proposed > 0) {
        void this.metricService.bump(
          proposed === kept
            ? CoachMetricKind.DRAFT_UNTOUCHED
            : CoachMetricKind.DRAFT_EDITED,
        );
      }

      return;
    }

    // ②A "Đã làm được" — the ONE transition that produces evidence. Nothing
    // else may. The only record that counts as having happened in the world.
    if (step === CoachStep.INTENT_TELL) {
      if (session.lastIntent === CoachPlanAnswer.DONE && session.activePlanId) {
        await this.reflectionService.recordEvidence({
          userId,
          planId: session.activePlanId,
          habitId: session.habitId,
          content: text,
        });
      }

      // "Có dịp mà chưa làm" → what stopped them, tied to the commitment. The
      // most valuable row in the feature: it is how a commitment learns it was
      // too big. Never evidence — nothing happened in the world.
      if (session.lastIntent === CoachPlanAnswer.MISSED) {
        await this.reflectionService.recordProblemStatement({
          userId,
          sessionId,
          habitId: session.habitId,
          content: text,
          kind: CoachStatementKind.BARRIER,
          planId: session.activePlanId ?? null,
        });
      }

      return;
    }

    // ②A "Có dịp mà chưa làm" — what stopped them, tied to the commitment. The
    // most valuable row in the feature: it is how a commitment learns it was
    // too big.
    if (step === CoachStep.BARRIER) {
      await this.reflectionService.recordProblemStatement({
        userId,
        sessionId,
        habitId: session.habitId,
        content: text,
        kind: CoachStatementKind.BARRIER,
        planId: session.activePlanId ?? null,
      });

      return;
    }

    // ②A "Đổi bối cảnh" — the promise stands, the setting moves.
    if (step === CoachStep.CONTEXT_EDIT) {
      if (session.activePlanId) {
        await this.planService.updateContext(session.activePlanId, text);
      }

      return;
    }

    // 6b — the real occurrence: CauVanDe(lan_da_qua), never a câu kể. "Không
    // tính vào chuỗi luyện tập của habit" — it records that a moment happened,
    // not that the habit was done. Questions and dead answers file nothing.
    if (
      (step === CoachStep.SCENE_DID || step === CoachStep.SCENE_MET) &&
      text.trim().split(/\s+/).filter(Boolean).length >= SCENE_DID_MIN_WORDS &&
      !/[?？]/.test(text)
    ) {
      await this.reflectionService.recordProblemStatement({
        userId,
        sessionId,
        habitId: session.habitId,
        content: text,
        kind: CoachStatementKind.LAN_DA_QUA,
        planId: null,
      });

      return;
    }

    // ★ — the answer to the scene. ⑤ "ĐỔI THAY" compares this row against the
    // one from three weeks ago, which is only honest for the answer to the
    // SAME question — so only the scene's own answer is filed.
    if (
      (isSituationStep(step) || step === CoachStep.SCENE_STAGE2) &&
      // The feeling answer is context, not the scene's answer — the recap
      // compares what they would DO, and the pair must stay two of the same.
      step !== CoachStep.SCENE_FEELING &&
      session.situationId
    ) {
      await this.reflectionService.recordSituationAnswer({
        userId,
        sessionId,
        situationId: session.situationId,
        habitId: session.habitId,
        variant: situationVariantFor(step, Boolean(session.moodLow), session.entry),
        content: text,
        // The stage they are actually answering — nhịp 4 asks a different
        // question, and filing the opening one against it would misread them.
        promptSnapshot:
          step === CoachStep.SCENE_STAGE2
            ? (session.scenePromptStage2 ?? session.scenePrompt ?? null)
            : (session.scenePrompt ?? null),
        // "Lưu TraLoiTinhHuong nguyên văn, cả hai lượt (lan = 1 hoặc 2)" — the
        // pair is the whole point: nhịp 5 compares them, and so does the recap.
        round: (session.situationRound ?? 0) + 1,
      });

      return;
    }

    // STORY, nhịp 1, nhịp 2, nhịp 4 — deliberately unwritten. The story the
    // reader told is theirs; close the sheet and it is gone. Only the
    // conclusions they drew themselves are kept.
  }

  private planSource(session: CoachSession): CoachPlanSource {
    if (session.entry === CoachEntry.LESSON) return CoachPlanSource.LESSON_END;
    if (session.tier === CoachHomeTier.PLAN) return CoachPlanSource.HOME_TIER_A;
    if (session.tier === CoachHomeTier.RETRY) return CoachPlanSource.RETRY;

    return CoachPlanSource.HOME_TIER_B;
  }

  /** ⑧ — stop everything. Nothing is written, including the message that triggered it. */
  private async enterSafety(session: CoachSession): Promise<CoachTurnResponse> {
    await this.sessionRepository.updateOne(
      { _id: session._id },
      {
        step: CoachStep.SAFETY,
        escapeAvailable: false,
      } as Partial<CoachSession>,
    );

    const hotlines = await this.safetyService.resolveHotlines(session.locale);

    return {
      sessionId: session._id.toString(),
      step: CoachStep.SAFETY,
      reply: null,
      promptKey: COACH_PROMPT_KEY[CoachStep.SAFETY] ?? null,
      ui: {
        kind: CoachUiKind.SAFETY,
        hotlines,
        escapeAvailable: false,
      },
      ended: true,
    };
  }

  /** Assemble what the client renders for the step it has arrived at. */
  private async respond(
    session: CoachSession,
    stepIn: CoachStep,
    replyIn: string | null,
    extra?: {
      samples?: string[];
      /**
       * The reaction's three approaches, structured. Rendered exactly like a
       * scene's opening trio — bold letter and name, quote underneath — rather
       * than as plain lines inside the reply text.
       */
      sceneOptions?: CoachSceneOption[];
      /** On resume: this session's exchange so far, as the app drew it. */
      replay?: ICoachShownTurn[];
      /** Earlier sessions' exchanges, each behind a divider, drawn above. */
      history?: CoachReplayItem[];
      /** What the reader typed or tapped on this turn, as their bubble showed it. */
      userLine?: string | null;
      /** The reader spoke and the model did not answer. */
      aiFailed?: boolean;
      /** A fixed line replacing the step's own (a guard fell back, or a closing template). */
      promptKeyOverride?: string | null;
      promptArgs?: Record<string, string> | null;
      /** A fixed line shown BEFORE the step's own. */
      noteKey?: string | null;
      /** Tầng 3 — the reply is the scene's other person talking, by name. */
      speaker?: string | null;
      /** Luồng 2 — `keypointDone`: the talk is over; the sheet stays open and closes to the Roadmap. */
      action?: string | null;
      /** Luồng 5 — an empty-kho Habit session that OPENS on the course card. */
      openingCard?: boolean;
    },
  ): Promise<CoachTurnResponse> {
    let reply = replyIn;
    let step = stepIn;
    const ui: CoachUiPayload = {
      kind: uiFor(step),
      escapeAvailable: isEscapeAvailable(step),
      // The suggestions belong to the step being ENTERED. A scene brings its
      // own cached pair (attached below); everything else carries the pair the
      // reply was written with.
      samples: extra?.samples ?? [],
    };
    let noteKey = extra?.noteKey ?? null;
    let promptArgs = extra?.promptArgs ?? null;

    if (step === CoachStep.TWO_COLS) {
      ui.columns = { left: session.draftLeft, right: session.draftRight };
      ui.rejectAvailable = !session.draftRejected;
    }

    if (isSituationStep(step) && (session.situationRound ?? 0) === 0) {
      // On resume the scene on screen is the scene — re-resolving would write
      // a second one under the reader mid-thought.
      const situation = await this.attachSituation(
        session,
        step,
        true,
        Boolean(extra?.replay),
      );

      // Render-time miss. The peek before the transition only proves a habit
      // exists, but the scene is WRITTEN on this very turn — a provider
      // failure, a missing API key on the deployment, or an empty fallback
      // pool still lands here, and shipping the step with no scene is a
      // silent Coach ("AI coach im luôn", owner on-device 2026-08-29). Same
      // escape the design gives the peek: say so, ask for the commitment.
      if (!situation) {
        this.logger.warn(
          `Coach scene failed at render (${step}) for session ${session._id}; falling back to commitment`,
        );
        await this.sessionRepository.updateOne(
          { _id: session._id },
          { step: CoachStep.PLAN_ASK } as Partial<CoachSession>,
        );
        const line =
          this.fixedLine(COACH_SCENE_UNAVAILABLE_LINE, session);

        return this.respond(
          { ...session, step: CoachStep.PLAN_ASK } as CoachSession,
          CoachStep.PLAN_ASK,
          [reply, line].filter(Boolean).join('\n\n'),
          // The scene's own trimmings (samples, speaker, prompt override)
          // belong to the step that failed, not to the commitment.
          { replay: extra?.replay, aiFailed: extra?.aiFailed },
        );
      }

      // A resumed session already carries the scene in its replay. Sending it
      // again here is how reopening the sheet would show the same scene twice.
      const fresh = Boolean(situation) && !situation?.alreadyShown;
      ui.situation = fresh
        ? this.toldToReader(situation?.prompt ?? '', session) || null
        : null;
      // No answer-suggestion pills at a scene: "Không có nút gợi ý câu trả lời
      // — có nút đó thì người dùng sẽ bấm và chép, và cả bài tập mất nghĩa."
      ui.samples = [];

      // Chips at the scene's opening, carrying the approach NAMES.
      //
      // This is the owner reversing "no answer-suggestion pills at a scene"
      // for this moment, twice asked (2026-09-08). What makes it survivable is
      // that a chip FILLS the box rather than sending: the reader still presses
      // send and can edit first. What it costs is real and worth knowing — a
      // reader who taps and sends unchanged has `sceneFirstLine` recorded as
      // the authored sentence, and that is half of what the verdict reads.
      if (situation?.openingOptions?.length && step !== CoachStep.SCENE_FEELING) {
        ui.samples = situation.openingOptions.map((option) => option.label);
      }

      // The same scene, split for the app's separate bubbles. ① already opens
      // with "Bạn vừa thêm “X”", so it does not repeat the habit's name here.
      // At SCENE_FEELING the scene's own question is held back: the beat asks
      // the feeling first (the step's fixed line), and "bạn nói gì?" waits.
      if (fresh && situation?.prompt) {
        const parts = this.splitScene(
          this.toldToReader(situation.prompt, session),
        );
        // The feeling beat holds the scene's question back, so the ways of
        // ANSWERING it are held back with it — offered there they would answer
        // a question that has not been asked.
        const asksItsOwn = step !== CoachStep.SCENE_FEELING;
        ui.scene = {
          habit:
            session.entry === CoachEntry.LESSON
              ? null
              : await this.habitTitleOf(session.habitId, session.locale),
          setup: parts.setup,
          question: asksItsOwn ? parts.question : null,
          ...(asksItsOwn
            ? this.openingOptionsFor(situation.openingOptions, session)
            : {}),
        };
      }

      // The led scene's second beat: the feeling was answered, and only now is
      // the scene's own question asked — on its own, since the scene is already
      // in the thread. A scene whose question cannot be split out (an old row
      // ending on a statement) falls back to the server's plain one: the
      // feeling beat must NEVER be followed by silence.
      if (!fresh && step === CoachStep.TELL_ONCE && situation?.prompt) {
        const question =
          this.splitScene(this.toldToReader(situation.prompt, session))
            .question ??
          this.fixedLine(COACH_SCENE_DEFAULT_QUESTION, session);
        ui.scene = {
          habit: null,
          setup: '',
          question,
          ...this.openingOptionsFor(situation.openingOptions, session),
        };
      }

      // ① opens its scene by naming the habit — "Bạn vừa thêm “…”. Một cảnh
      // ngắn:" — and ④ by dating it: "ba tuần trước". Only on the scene's
      // first showing, for the same reason as above.
      if (fresh && step === CoachStep.RETRY_SCENE) {
        noteKey = noteKey ?? COACH_RETRY_INTRO_KEY;
      }
      if (
        fresh &&
        (step === CoachStep.SCENE_FEELING || step === CoachStep.TELL_ONCE) &&
        session.entry === CoachEntry.LESSON
      ) {
        noteKey = noteKey ?? COACH_LESSON_INTRO_KEY;
        promptArgs = {
          ...(promptArgs ?? {}),
          habit: (await this.habitTitleOf(session.habitId, session.locale)) ?? '',
        };
      }
    }

    // Luồng 5 — the check-in asks about ONE habit, so it says which. Without
    // the title the line could only point at it with "nó", which read as a
    // form rather than a question, and asked the same way about every habit
    // in the kho (owner, 2026-09-05). The app falls back to a title-less
    // wording when this comes back empty.
    if (step === CoachStep.CHECKIN_ASK) {
      promptArgs = {
        ...(promptArgs ?? {}),
        habit: (await this.habitTitleOf(session.habitId, session.locale)) ?? '',
      };
    }

    // PLAN — deliberately NO pre-fill (owner, 2026-08-28: "phần nhắc hẹn này
    // luôn luôn phải rỗng"). The form said "chữ của bạn" while arriving with
    // both fields already written — a commitment they typed themselves is the
    // whole point. What the scene produced still gates T4; it just does not
    // write the reminder for them. SHRINK keeps its pre-fill below: editing
    // the OLD wording smaller is that form's entire job.

    // Thanh habit — from the moment the habit is CONFIRMED to the end of the
    // session. The chip is UI, never a line of dialogue: "Coach không nhắc tên
    // habit trong câu nói của mình."
    //
    // Confirmed, not merely resolved: ② picks the most-due habit at open so a
    // scene can be built the moment one is asked for, and shipping the chip on
    // that made the sheet announce "Đang nói về X" before the reader had chosen
    // anything at all (bug sheet 2026-08-28 16:18: "không hiện pill Habit khi
    // user chưa xác nhận bắt đầu task với Habit nào"). `habitConfirmed` is set
    // when a habit-bound task actually starts, and stays set for the session.
    if (session.habitId && (session.habitConfirmed || taskOf(step) === 'T2')) {
      const title = await this.habitTitleOf(session.habitId, session.locale);
      if (title) ui.habit = { id: session.habitId, title };
    }

    // Luồng 2/3 dùng cùng thanh đó nhưng phạm vi là keypoint hoặc khoá — hai
    // cửa này không có habitId nên nhánh trên luôn bỏ qua, và thanh biến mất
    // dù design có nó. Chỉ đặt khi chưa có thanh habit: một phiên không bao
    // giờ vừa bàn habit vừa bàn keypoint.
    if (!ui.habit && session.talkMode) {
      const scope = await this.talkScopeFor(session);
      if (scope) ui.scope = scope;
    }

    // The picker behind the chip's "đổi": the reader's own kho, nothing else.
    // Luồng 4 — SCENE_PICK offers the same list: the reader's own habits.
    if (step === CoachStep.PICK_HABIT || step === CoachStep.SCENE_PICK) {
      const owned = (await this.userHabitRepository
        .findForUser(session.userId, UserHabitState.ACTIVE)
        .catch(() => [])) as Array<{ habitId?: unknown }>;
      const ids = owned.map((row) => String(row.habitId ?? '')).filter(Boolean);

      // Cả hai bước gửi CẢ KHO và để app lo việc chỉ hiện ba cái.
      //
      // Trước 2026-09-04 SCENE_PICK tự chia ba và kèm một chip ⟨Xáo trộn⟩ gửi
      // lên server, nên mỗi lần đổi để lại hai bong bóng trong hội thoại (chữ
      // của chip, rồi Coach hỏi lại). Owner: "có nút bấm phát thay đổi ra các
      // habit khác luôn" — nên việc đổi chuyển hẳn về client (`_HabitPickPills`
      // đã làm đúng thế cho `pickNew`/`pickHabit`): đổi tại chỗ, không tốn
      // lượt, không ghi gì vào hội thoại.
      ui.choices = await this.habitChoicesFor(ids, session.locale);
    }

    // Nhịp 4 — the scene's second stage is the step's own line: the other person
    // reacting, ending in a question again. Split like stage one — the body in
    // `situation`, the question on its own in `scene.question` — so the app
    // shows two short bubbles instead of one block ("mỗi câu gửi một lần").
    if (step === CoachStep.SCENE_STAGE2) {
      // Owner 2026-09-05 — "tôi trả lời là mở tài liệu học luôn còn bảo úp
      // điện thoại là sao".
      //
      // `promptStage2` is written when the SCENE is generated, in the same call
      // as stage one, long before the reader answers. It therefore asserts its
      // own continuation ("bạn vừa úp màn hình điện thoại xuống") and invents
      // details nobody gave — and when the model HAS answered this turn, that
      // reply was written against what they actually said, so the stored text
      // is both redundant and contradictory beside it.
      //
      // Kept as the fallback for a turn the model did not answer: a scene that
      // stops dead mid-beat is worse than a stiff second stage.
      const raw = reply?.trim() ? null : (session.scenePromptStage2 ?? null);
      const stage2 = raw ? this.toldToReader(raw, session) : null;
      const parts = stage2 ? this.splitScene(stage2) : null;
      ui.situation = parts?.question ? parts.setup : stage2;
      if (parts?.question) {
        ui.scene = { habit: null, setup: '', question: parts.question };
      }
    }

    // The reaction's approaches, onto the scene payload the app already knows
    // how to draw. Merged rather than assigned: this turn may already have set
    // `ui.scene` for the stored second stage, and its question must survive.
    // The lead is the REACTION's — "Bạn sẽ đáp lại thế nào?" is the right
    // question here, where somebody has just spoken; the scene's opening uses
    // the shorter one because the scene asked its own question a bubble above.
    if (extra?.sceneOptions?.length) {
      ui.scene = {
        habit: ui.scene?.habit ?? null,
        setup: ui.scene?.setup ?? '',
        question: ui.scene?.question ?? null,
        options: extra.sceneOptions,
        optionsLead: this.fixedLine(COACH_SCENE_OPTIONS_LEAD, session),
      };
    }

    // Bộ điều phối — up to two task suggestions, most important first. Values
    // only: the words are the client's, so they arrive in the reader's language
    // and the server never ships a label it cannot translate.
    //
    // When the session already holds a real occasion, the FIRST suggestion is
    // the reminder — the session's result must never hide behind "Mình dừng ở
    // đây": a reader who has just pulled their story apart and been told "xong
    // rồi" with nothing to do about it is standing in a dead end.
    // Luồng 1 — the onboarding: chips per question (lit where the app already
    // holds the answer), the progress strip, the address for the fixed lines.
    if (isOnboardStep(step)) {
      const ctxNow = this.buildContext(session, false);
      const config = await this.configService.get();
      ctxNow.onboardAsk = {
        style: config.onboardAskStyle,
        age: config.onboardAskAge,
        gender: config.onboardAskGender,
        job: config.onboardAskJob,
      };
      ui.choices = await this.onboardChoicesFor(session, step);
      const position =
        step === CoachStep.ONBOARD_INTRO
          ? { step: 0, total: onboardPosition(CoachStep.ONBOARD_GOAL, ctxNow).total }
          : onboardPosition(
              step === CoachStep.ONBOARD_ADDRESS_CONFIRM ? CoachStep.ONBOARD_ADDRESS : step,
              ctxNow,
            );
      ui.onboard = {
        ...position,
        skippable:
          step !== CoachStep.ONBOARD_ADDRESS &&
          step !== CoachStep.ONBOARD_ADDRESS_CONFIRM,
      };
      // The address for the fixed lines, as picked or typed (the app decides
      // its case per sentence). Outside Vietnamese the default "bạn" is no
      // address at all, so the app falls back to its neutral wording.
      const address = session.onboardAnswers?.address ?? '';
      promptArgs = {
        ...(promptArgs ?? {}),
        address: address && (session.locale === 'vi' || address !== 'bạn') ? address : '',
        name: session.onboardName ?? '',
      };
      if (step === CoachStep.ONBOARD_INTRO && !reply && !extra?.replay) {
        reply = this.fixedLines(COACH_ONBOARD_INTRO_LINES, session).join('\n\n');
      }
    }

    // Every fixed line the app renders follows the reader's address — the one
    // thing "lúc thì anh lúc thì bạn" came from (owner, 2026-09-04). Vietnamese
    // only: it is the language where the second person is a choice.
    if (
      !isOnboardStep(step) &&
      session.locale === 'vi' &&
      session.address &&
      session.address !== 'bạn'
    ) {
      promptArgs = { ...(promptArgs ?? {}), address: session.address };
    }

    // Luồng 5 — the Habit tab with an empty kho opens straight on the card:
    // resolve it here (no turn has run), and say the road out loud with the
    // same line the empty-kho Home session uses. Nothing to offer → one line
    // and the sheet is done.
    if (extra?.openingCard) {
      const picked = await this.pickCourseForFirstHabit(session);
      if (picked) {
        // Onto the session first: `courseCardFor` below reads it from there,
        // and the reader tapping "Học ngay" needs the id to still be around.
        Object.assign(session, {
          cardShown: true,
          courseCardId: picked.id,
          courseCardReasonKey: picked.reasonKey,
          courseCardReasonArg: picked.reasonArg ?? null,
        });
        await this.sessionRepository
          .updateOne({ _id: session._id }, {
            cardShown: true,
            courseCardId: picked.id,
            courseCardReasonKey: picked.reasonKey,
            courseCardReasonArg: picked.reasonArg ?? null,
          } as Partial<CoachSession>)
          .catch(() => undefined);
        void this.metricService.bump(CoachMetricKind.COURSE_SHOWN, picked.reasonKey);
        reply = this.fixedLine(COACH_FIRST_HABIT_INVITE_LINE, session);
      } else {
        // Nothing left in the library to point at: say so plainly rather than
        // opening an empty card.
        step = CoachStep.END;
        ui.kind = uiFor(step);
        reply = this.fixedLine(COACH_STORY_CONTINUE_LINE, session);
      }
    }

    // Home · "Kể chuyện hôm nay": an open question and an empty box — no skip
    // pill, no habit picker, no samples (owner, 2026-09-04). The story talk
    // reads "không có gì" for itself if that is what they type.
    const storyOpen = step === CoachStep.STORY && session.entry === CoachEntry.HOME;
    if (storyOpen) {
      ui.kind = CoachUiKind.TEXT;
      ui.samples = [];
    }

    // Luồng 2/3 — the talk's pills, the quiz on its own screen, the recap's lessons.
    if (step === CoachStep.TALK_ASK) {
      ui.choices = [
        { value: 'summary', label: null },
        { value: 'talkQuiz', label: null },
      ];
    }
    if (step === CoachStep.QUIZ_RUN) ui.action = 'runQuiz';
    if (extra?.action) ui.action = extra.action;
    if (step === CoachStep.RECAP_PICK) {
      ui.choices = (session.recapLessons ?? []).map((lesson) => ({
        value: lesson.id,
        label: lesson.title,
      }));
    }

    // Luồng 5 — the current question's options are the chips.
    if (step === CoachStep.QUIZ_IN_CHAT) {
      const item = (session.quizItems ?? [])[session.quizIndex ?? 0];
      ui.choices = (item?.options ?? []).map((option, index) => ({
        value: String(index),
        label: option,
      }));
      ui.quizRemaining =
        (session.quizItems?.length ?? 0) - (session.quizIndex ?? 0);
    }

    if (step === CoachStep.HUB) {
      const ctx = this.buildContext(session, false);
      // Luồng 5 — the "write today" pill is gone once today is written.
      if (session.entry === CoachEntry.HABIT && session.habitId) {
        ctx.checkinDone = await this.checkedToday(session.userId, session.habitId);
      }
      // Luồng 4: two pills at most — the practice and the story. The
      // commitment is no longer offered anywhere.
      const tasks: string[] = eligibleTasks(ctx);
      ui.choices = tasks
        .slice(0, COACH_HUB_PILL_LIMIT)
        .map((task) => ({ value: task, label: null }));
    }

    // ① with several habits just added: "Mình nói về cái nào trước?" — the
    // chips are the habits themselves, from the list frozen at open.
    if (step === CoachStep.PICK_NEW) {
      ui.choices = await this.habitChoicesFor(
        session.newHabitIds ?? [],
        session.locale,
      );
    }

    // SHRINK — the commitment form, pre-filled with the OLD wording so the
    // reader edits it smaller rather than writing a new promise from nothing.
    if (step === CoachStep.SHRINK) {
      const plan = await this.planQuote(session.activePlanId);
      if (plan) ui.suggested = { context: plan.context, action: plan.action };
    }

    // The card in the thread: one course, read from the library, with the
    // habit that led to it. LEAVE keeps it on screen under the Coach's last
    // line, because "Sang Roadmap khoá học" needs to know where to go.
    if (step === CoachStep.COURSE_CARD || step === CoachStep.LEAVE) {
      ui.course = await this.courseCardFor(session);
    }

    if (step === CoachStep.NEXT_SESSION) {
      // "Mood cuối phiên thấp → ẩn nút phiên mới, chỉ còn Dừng."
      ui.allowNewSession = !session.moodEndLow;
    }

    // ②A's question is built from the reader's own words: the commitment
    // being asked about.
    if (step === CoachStep.INTENT || step === CoachStep.CONTEXT_ASK) {
      const plan = await this.planQuote(session.activePlanId);
      if (plan) promptArgs = { context: plan.context, action: plan.action };
    }
    // Luồng 3 — "Bạn vừa xong «{course}»…"
    if (step === CoachStep.RECAP_PICK && session.courseId) {
      const [course] = (await this.courseRepository
        .findBriefByIds([session.courseId])
        .catch(() => [])) as Array<{ title?: ITranslation }>;
      promptArgs = { course: this.pickTranslation(course?.title, session.locale) ?? '' };
    }

    const stepKey = this.promptKeyFor(session, step);

    const promptKey =
      extra?.promptKeyOverride ??
      (storyOpen ? COACH_STORY_OPEN_KEY : stepKey) ??
      (extra?.aiFailed && !ui.situation ? COACH_FALLBACK_REPLY_KEY : null);

    // The exchange as it will be drawn, kept for the reader's own replay. Not
    // on resume — those lines are already in `replay` — and a resumed step's
    // fixed lines are held back for the same reason (unless the session
    // predates the store and has nothing there to show instead).
    const resumed = Boolean(extra?.replay);
    // Held back only when the step is the one ALREADY DRAWN. A resume that
    // lands on a DIFFERENT step than the session was parked on has never said
    // that step's question, so there is nothing in the replay for it to be
    // redundant with — suppressing it left the reader looking at a new input
    // placeholder with nothing asking them anything (owner on-device
    // 2026-09-08, 16:07). Nothing does that today; the invariant is written
    // into the condition so the next thing that tries cannot reintroduce it.
    const suppressFixed =
      resumed && (session.shown?.length ?? 0) > 0 && step === session.step;
    if (!resumed) {
      await this.recordShown(session, {
        at: new Date(),
        step,
        userLine: extra?.userLine ?? null,
        reply,
        speaker: extra?.speaker ?? null,
        noteKey: noteKey ?? null,
        promptKey: promptKey === COACH_NO_PROMPT_KEY ? null : promptKey,
        promptArgs: promptArgs ?? null,
        situation: ui.situation ?? null,
        scene: ui.scene ?? null,
      });
    }
    const history = extra?.history ?? [];
    const replay =
      resumed || history.length
        ? [
            ...history,
            ...(history.length ? [this.dividerItem(session)] : []),
            ...(extra?.replay ?? []).map((t) => this.replayItemOf(t)),
          ]
        : undefined;

    return {
      sessionId: session._id.toString(),
      step,
      reply,
      // A step that asks for free text and has no fixed line of its own would
      // otherwise answer a failed model call with an empty screen. "Mình nghe
      // rồi." keeps the thread moving.
      promptKey: suppressFixed ? null : promptKey,
      promptArgs,
      noteKey: suppressFixed ? null : noteKey,
      // Tầng 3 — the app labels the bubble with the scene's other person when
      // this reply was theirs, not the Coach's.
      speaker: extra?.speaker ?? null,
      persona: session.persona ?? null,
      ui,
      courseInvite: null,
      // Only on resume: the exchange so far, so reopening the sheet picks the
      // thread up mid-sentence instead of greeting the reader from scratch.
      replay,
      resumed,
      ended:
        step === CoachStep.END ||
        step === CoachStep.LEAVE ||
        step === CoachStep.SAFETY,
      // Luồng 6 — the close button pleads once, and never again after two
      // sessions closed against it.
      exitPlea: await this.profileService
        .exitPleaEnabled(session.userId)
        .catch(() => true),
      // Luồng 6 — the rating sheet AFTER ⟨Vẫn đóng⟩, not instead of the plea:
      // the design asks them to stay first and asks how it went only once they
      // have said no. Resolved here, at open, for the same reason `exitPlea` is
      // — the sheet must know its own shape before the reader reaches for the
      // close button, not a round-trip later.
      exitFeedback: await this.resolveRatingAsk(session.userId).catch(() => false),
      // Which chip set that sheet must draw. Sent every turn rather than once at
      // open: the reader moves between kinds inside one session — hub → story →
      // scene — and the question has to be about where they actually are when
      // they reach for ⟨Đóng⟩, not where they came in.
      sessionKind: sessionKindOf(step),
    };
  }

  /**
   * Whether this reader gets the rating sheet on the way out of this session.
   *
   * Every knob lives in admin (see `shouldAskRating`), so the answer can change
   * between two sessions without a deploy. Failing closed is deliberate: if the
   * config cannot be read, the reader leaves unbothered.
   */
  private async resolveRatingAsk(userId: string): Promise<boolean> {
    const config = await this.configService.get();
    const profile = await this.profileService.get(userId);

    return shouldAskRating({
      config,
      state: {
        ratingAskedAt: profile.ratingAskedAt,
        ratingSnoozedAt: profile.ratingSnoozedAt,
        ratingAskCount: profile.ratingAskCount,
        exitCount: profile.exitCount,
      },
      now: new Date(),
      roll: Math.random,
    });
  }

  /** Luồng 6 — the plea's answer, on the reader's profile. */
  async recordExit(
    sessionId: string,
    stayed: boolean,
    chips?: CoachRatingChip[],
    note?: string,
  ): Promise<{ exitPlea: boolean }> {
    const userId = this.userId;
    const session = await this.sessionRepository.findActive(sessionId, userId);
    if (!session) throw new NotFoundException('Coach session not found');

    // What they said on the way out. No thumb: the chips carry the sentiment,
    // and praise is filed exactly like a complaint so the queue's numbers mean
    // something next to a total.
    //
    // Never awaited and never allowed to throw: the sheet is already closing,
    // and losing the answer is a smaller failure than making leaving fail.
    if (!stayed) {
      const answered = Boolean(chips?.length) || Boolean(note?.trim());
      if (answered) {
        void this.ratingService
          .record({
            userId,
            sessionId,
            chips,
            note: note ?? null,
            source: CoachRatingSource.EXIT,
            // Read from the session on the server, never from the client: the
            // row has to say which question was answered, and a stale build
            // must not be able to file scene chips against a hub exit.
            sessionKind: sessionKindOf(session.step),
          })
          .catch((error: any) =>
            this.logger.warn(`Coach could not file exit feedback: ${error?.message}`),
          );
      }

      // ⟨Để sau⟩ is counted too, and deliberately: without it "nobody minds the
      // Coach" and "nobody will answer a form" look identical on the admin
      // screen. The two land on different clocks — see `recordRatingAsk`.
      void this.profileService
        .recordRatingAsk(userId, answered)
        .catch((error: any) =>
          this.logger.warn(`Coach could not record the rating ask: ${error?.message}`),
        );
    }

    return this.profileService.recordExit(userId, stayed);
  }

  /**
   * The step's fixed line, where the design gives the same step two of them.
   *
   * STORY: ②B opens on "có", everything after a check-in or a previous
   * session on "còn". INTENT_TELL: DONE and MISSED ask different sentences.
   * END: ① closes on "Tập vậy là đủ cho hôm nay.", ② on "Vậy mình dừng ở đây nhé."
   */
  private promptKeyFor(session: CoachSession, step: CoachStep): string | null {
    switch (step) {
      case CoachStep.STORY: {
        // "Còn" belongs to a reader who has already said something in this
        // session — after a check-in, or in a second session from the same
        // sheet-open. ②B and ②C both OPEN on the story question, and the day's
        // mood chooses which wording — see `coachStoryOpenKey`.
        const spokeAlready = (session.turns ?? []).some(
          (turn) => turn.role === CoachTurnRole.USER && turn.text?.trim(),
        );
        if (session.tier === CoachHomeTier.PLAN || spokeAlready) {
          return COACH_STORY_MORE_KEY;
        }

        return (
          coachStoryOpenKey(session.moodStart, this.localDayOf(session)) ??
          COACH_PROMPT_KEY[step] ??
          null
        );
      }
      case CoachStep.HUB: {
        // The coordinator is ②'s opening step now as well as the seam between
        // tasks. "Xong rồi. Còn gì bạn muốn nói không?" is a goodbye; before
        // anything has run, the line has to be an invitation instead.
        const spokeAlready = (session.turns ?? []).some(
          (turn) => turn.role === CoachTurnRole.USER && turn.text?.trim(),
        );
        if (spokeAlready || (session.tasksRun ?? 0) > 0) {
          return COACH_PROMPT_KEY[step] ?? null;
        }

        return COACH_HUB_OPEN_KEY;
      }
      case CoachStep.INTENT_TELL:
        return session.lastIntent === CoachPlanAnswer.MISSED
          ? COACH_INTENT_TELL_MISSED_KEY
          : (COACH_PROMPT_KEY[step] ?? null);
      case CoachStep.SCENE_FEELING:
        // A low day's scene is told about somebody else, so the feeling is
        // asked in the same person — "Nếu là người đó, lúc đó bạn…".
        return session.moodLow
          ? COACH_SCENE_FEELING_THIRD_KEY
          : (COACH_PROMPT_KEY[step] ?? null);
      case CoachStep.END:
        return session.entry === CoachEntry.LESSON
          ? (COACH_PROMPT_KEY[step] ?? null)
          : COACH_END_STOP_KEY;
      default:
        return COACH_PROMPT_KEY[step] ?? null;
    }
  }

  /**
   * Who this reader is, at the grain scenes are cached at.
   *
   * Both answers come from onboarding: `user.age` (the option's label — parsed
   * into a band, since the label is admin-authored text) and
   * `onboarding.learningGoal` (an option id, resolved against the onboarding
   * config for its stable trackingLabel and its label in the reader's own
   * language). Every miss degrades to 'unknown', which is the shared bucket
   * legacy scenes already live in — a reader who skipped onboarding gets the
   * generic scene, never no scene.
   */
  private async readerProfile(session: CoachSession): Promise<{
    audience: CoachAudience;
    goalKey: string;
    goalLabel: string | null;
  }> {
    const fallback = {
      audience: 'unknown' as CoachAudience,
      goalKey: 'unknown',
      goalLabel: null as string | null,
    };

    try {
      const user = await this.userRepository.findById(session.userId);
      if (!user) return fallback;

      const audience = coachAudienceFromAge(
        (user as { age?: string | null }).age,
      );

      const goalId = (
        user as { onboarding?: { learningGoal?: number | null } | null }
      ).onboarding?.learningGoal;
      if (goalId === undefined || goalId === null) {
        return { ...fallback, audience };
      }

      const config = await this.onboardingService.find().catch(() => null);
      const option = (
        config as {
          learningGoal?: Array<{
            id: number;
            trackingLabel?: string;
            label?: ITranslation;
            title?: ITranslation;
          }>;
        } | null
      )?.learningGoal?.find((item) => item.id === goalId);
      if (!option) return { ...fallback, audience };

      return {
        audience,
        goalKey: option.trackingLabel?.trim() || String(option.id),
        goalLabel:
          this.pickTranslation(option.label, session.locale) ??
          this.pickTranslation(option.title, session.locale),
      };
    } catch {
      return fallback;
    }
  }

  /**
   * Resolve the scene for a situation step and remember which one was shown.
   *
   * Stored on the session because the answer must be filed against the exact
   * situation the reader saw — that pairing is what ⑤ "ĐỔI THAY" reads three
   * weeks later.
   */
  private async attachSituation(
    session: CoachSession,
    step: CoachStep,
    persist = true,
    preferStored = false,
  ): Promise<{
    prompt: string;
    samples: string[];
    /** The scene's authored ways in, empty on rows written before they existed. */
    openingOptions: Array<{ key: string; label: string; text: string }>;
    alreadyShown: boolean;
  } | null> {
    type Scene = {
      prompt: string;
      promptThirdPerson?: string | null;
      promptStage2?: string | null;
      promptStage2ThirdPerson?: string | null;
      contextGroup?: string | null;
      samples?: string[];
      beats?: string[];
      beatLines?: string[];
      level?: number | null;
      counterpart?: string | null;
      takeaway?: string | null;
      goodMove?: string | null;
      openingOptions?: Array<{ key: string; label: string; text: string }>;
      _id: unknown;
    };

    // ④ shows the SAME scene that was answered three weeks ago — by id, never
    // re-resolved. A different scene would give the recap two answers to two
    // questions and call them a pair.
    // ④ and "thử lại tình huống này" both mean THE SAME scene, by id. A
    // re-resolve would hand back a different one, which for ④ breaks the pair
    // the recap compares and for a replay silently changes the exercise.
    // The second answer is to the SAME scene, so it is looked up by id — a
    // re-resolve would quietly hand back a different one and there would be
    // nothing to compare at nhịp 5.
    const byId =
      (step === CoachStep.RETRY_SCENE ||
        // NOT SCENE_RETRY. That case used to be listed here, with a comment
        // saying "the retry shows the SAME scene, by id" — the opposite of what
        // the flow does: the transition into SCENE_RETRY nulls `situationId`
        // and files the old scene under `sceneShownIds` so a DIFFERENT one gets
        // written ("đưa tình huống tương tự, không lặp lại y nguyên"). The
        // clause could never fire — `Boolean(session.situationId)` below is
        // already false by then — so it changed nothing and only told the next
        // reader the wrong thing.
        // TELL_ONCE is the led scene's SECOND beat now — the same scene the
        // feeling was just asked about, never a fresh resolve.
        step === CoachStep.TELL_ONCE ||
        // A resumed sheet re-renders the scene already on screen.
        preferStored ||
        session.sceneRetried ||
        (session.situationRound ?? 0) > 0) &&
      Boolean(session.situationId);
    let situation: Scene | null =
      byId && session.situationId
        ? ((await this.situationService
            .findById(session.situationId)
            .catch(() => null)) as Scene | null)
        : null;

    if (!situation) {
      if (!session.habitId) return null;

      const variant = (
        step === CoachStep.RETRY_SCENE
          ? 'default'
          : situationVariantFor(step, Boolean(session.moodLow), session.entry)
      ) as CoachSituationVariant;

      const [profile, avoid] = await Promise.all([
        this.readerProfile(session),
        // Never the scene they answered last time — the pool has others, and
        // when it does not, the one they answered longest ago.
        this.reflectionService
          .findAnsweredSituationIds(session.userId, session.habitId)
          .catch(() => [] as string[]),
      ]);

      // Which corner of life to set the scene in, inferred from words this
      // reader already wrote — never asked. A preference inside `resolve`.
      const contextGroup = await this.contextGroupFor(session);

      situation = (await this.situationService.resolve({
        // Lets `resolve` recognise a scene written ahead of time FOR this
        // reader and hand it over instead of spending 5–13 seconds writing one.
        userId: session.userId,
        habitId: session.habitId,
        locale: session.locale,
        variant,
        // Luồng 7 — the habit was added at the end of a lesson, so its scene
        // comes from THAT lesson rather than from the habit's material at
        // large ("cảnh sinh từ chính bài vừa học").
        preferKeypointId:
          session.entry === CoachEntry.LESSON
            ? await this.sourceKeypointOf(session.userId, session.habitId)
            : null,
        ...profile,
        // Plus whatever this session already showed: the scene they just
        // failed is not filed as "answered", and the retry must not be it.
        avoid: [...avoid, ...(session.sceneShownIds ?? [])],
        // Set only by "Luyện cảnh khó hơn"; null on every ordinary scene, which
        // then takes whatever level its slot gives it.
        level: session.sceneTargetLevel ?? null,
        contextGroup,
      })) as Scene | null;

      /**
       * Start writing the NEXT rung while this one is being answered.
       *
       * The reader is about to spend a minute or two reading a scene and typing
       * a reply; writing a scene takes 5–13 seconds. Doing it now means the tap
       * on "Luyện cảnh khó hơn" is answered out of storage instead of out of a
       * model call — which is the difference between instant and a timeout, since
       * that call's budget is 15s and its measured worst case was 13.2s.
       *
       * Fire-and-forget and detached from this turn's clock; it reserves the
       * scene for this reader so nobody else is handed it, and if the reader
       * never taps, the row simply becomes an ordinary pool scene.
       */
      if (situation) {
        this.situationService.prewarm({
          userId: session.userId,
          habitId: session.habitId,
          locale: session.locale,
          variant,
          audience: profile.audience,
          goalKey: profile.goalKey,
          goalLabel: profile.goalLabel,
          contextGroup,
          level: Math.min(
            SITUATION_MAX_LEVEL,
            (situation.level ?? SITUATION_MIN_LEVEL) + 1,
          ),
        });
      }
    }

    if (!situation) return null;

    const shown = situation;
    // Nhịp 4's line, snapshotted with the rest so an edit mid-session cannot
    // change the scene under the reader.
    // On a low day the scene is told about somebody else, so its second stage
    // has to be too — a first stage about "một người" answered by a second
    // about "bạn" is two scenes. Without a third-person second stage the day
    // simply gets the shorter scene: nhịp 4 and 5 are skipped.
    const stage2 = shown.promptStage2?.trim() || null;
    // ALWAYS the second-person telling (bug sheet 2026-08-28 16:18).
    // A low day used to be shown `promptThirdPerson` — "Một người thở dài…
    // Nếu là người đó, bạn phản hồi thế nào?" — and the reader could not tell
    // who the scene was about: "mô tả tình huống ko sử dụng các danh từ chung
    // kiểu 'Một người', 'Có người'… phần action ko cần phải nhắc lại 'Nếu là
    // bạn'". The whole app speaks to "bạn"; softening a low day is the scene's
    // PITCH, never its person. The third-person columns stay on the row for the
    // admin and for parked sessions, and nothing reads them any more.
    const told = shown.prompt;
    // On a replay the scene IS already in the thread, and that is exactly why it
    // has to be shown again: the reader is answering it a second time.
    const alreadyShown =
      !session.sceneRetried &&
      session.turns.some(
        (turn) => turn.role === CoachTurnRole.COACH && turn.text === told,
      );

    // The scene joins the transcript as a Coach line: the reply to the answer
    // is written against a question the model can see, and a reopened sheet
    // replays the scene instead of the reader's answer floating alone.
    const turns = alreadyShown
      ? session.turns
      : [
          ...session.turns,
          {
            role: CoachTurnRole.COACH,
            text: told,
            step,
            at: new Date(),
          },
        ];

    // A peek (persist = false) only reports whether a scene can be built, so
    // the caller can skip the scene step rather than strand the reader on it.
    // It must not mutate the session or claim a situationId — the real render
    // does that.
    if (persist) {
      if (!alreadyShown) session.turns = turns;

      // Snapshot the scene's script alongside its id, so the reply to each
      // answer walks the same beats even if an editor rewrites the scene
      // mid-session. Empty on a legacy scene, which then runs the old path.
      const sceneBeats = shown.beats ?? [];
      const sceneBeatLines = shown.beatLines ?? [];
      const sceneTakeaway = shown.takeaway ?? null;
      const sceneGoodMove = shown.goodMove ?? null;
      const sceneLevel = shown.level ?? SITUATION_START_LEVEL;
      const sceneCounterpart = shown.counterpart ?? null;
      session.sceneBeats = sceneBeats;
      session.sceneBeatLines = sceneBeatLines;
      session.sceneTakeaway = sceneTakeaway;
      session.sceneGoodMove = sceneGoodMove;
      session.sceneLevel = sceneLevel;
      session.sceneCounterpart = sceneCounterpart;
      session.scenePrompt = told;
      session.scenePromptStage2 = stage2;
      // The opening's three approaches, packed the same way a reaction's are.
      // Without this `resolveSceneOption` has nothing to match at the first
      // question, so a reader who answers "A" — or taps the chip, which fills
      // the box with the approach's NAME — would send a three-word fragment
      // and have that scored as their line.
      const openingPacked = (shown.openingOptions ?? []).map(
        (option) => `${option.key}|${option.label}|${option.text}`,
      );
      session.sceneOptions = openingPacked;

      await this.sessionRepository.updateOne(
        { _id: session._id },
        {
          situationId: String(shown._id),
          turns,
          sceneBeats,
          sceneBeatLines,
          sceneTakeaway,
          sceneGoodMove,
          sceneLevel,
          sceneCounterpart,
          scenePrompt: told,
          scenePromptStage2: stage2,
          sceneOptions: openingPacked,
        } as Partial<CoachSession>,
      );
    }

    return {
      prompt: told,
      samples: [],
      openingOptions: shown.openingOptions ?? [],
      alreadyShown,
    };
  }

  /**
   * "Giải thích đơn giản hơn."
   *
   * Increments a weekly count against the KEYPOINT, not the reader — a
   * keypoint people keep asking to have re-explained is a keypoint that needs
   * rewriting, and that is the only thing this is for.
   */
  async explainAgain(keypointId: string): Promise<{ counted: boolean }> {
    await this.metricService.bump(CoachMetricKind.EXPLAIN_AGAIN, keypointId);

    return { counted: true };
  }

  /**
   * A scene split into its setup and its closing question.
   *
   * The question is the LAST sentence that asks something — scenes are written
   * as "three or four sentences, then one question", so that is the whole rule.
   * A scene with no question (or one short enough to be only a question) comes
   * back whole as the setup: showing an empty bubble would be worse than
   * showing a slightly long one.
   */
  private splitScene(prompt: string): { setup: string; question: string | null } {
    return splitScene(prompt);
  }

  /**
   * Which corner of life this reader's scenes should be set in.
   *
   * "Không hỏi tuổi, không hỏi nghề, không có form khai báo. Bối cảnh suy ra từ
   * CHÍNH CHỮ người dùng đã viết" — the `boi_canh` they typed into a reminder
   * first, then anything they have said in this session. Keyword matching and
   * not a model call on purpose: this runs on every scene, the vocabulary is
   * small and Vietnamese-specific, and a wrong guess costs nothing (the group is
   * a preference). NEUTRAL when they have written nothing to go on.
   */
  private async contextGroupFor(session: CoachSession): Promise<string> {
    const plan = session.activePlanId
      ? await this.planQuote(session.activePlanId).catch(() => null)
      : null;

    const said = [
      plan?.context ?? '',
      ...session.turns
        .filter((turn) => turn.role === CoachTurnRole.USER)
        .map((turn) => turn.text),
    ]
      .join(' ')
      .toLowerCase();
    if (!said.trim()) return CoachSituationContextGroup.NEUTRAL;

    const groups: Array<[CoachSituationContextGroup, RegExp]> = [
      [
        CoachSituationContextGroup.WORK,
        /họp|công ty|đồng nghiệp|sếp|khách hàng|deadline|dự án|báo cáo|ca làm|meeting|manager|client|colleague|report/,
      ],
      [
        CoachSituationContextGroup.FAMILY,
        /bố|mẹ|ba mẹ|vợ|chồng|con|em trai|em gái|anh trai|chị gái|gia đình|bữa cơm|nhà mình|family|mum|mom|dad|wife|husband|kid/,
      ],
      [
        CoachSituationContextGroup.STUDY,
        /học|bài tập|thi|lớp|giảng viên|thầy|cô|trường|bài nhóm|assignment|exam|class|lecturer|homework/,
      ],
      [
        CoachSituationContextGroup.FRIENDS,
        /bạn bè|nhóm bạn|hội|rủ đi|đi chơi|bạn thân|friend|mate|hang out/,
      ],
      [
        CoachSituationContextGroup.SERVICE,
        /trả hàng|đổi hàng|nhân viên|quán|shop|đặt lịch|hoàn tiền|shipper|refund|waiter|booking/,
      ],
    ];

    for (const [group, pattern] of groups) {
      if (pattern.test(said)) return group;
    }

    return CoachSituationContextGroup.NEUTRAL;
  }

  /** Is this habit already on the reader's shelf? ②C turns on the answer. */
  private async ownsHabit(userId: string, habitId: string): Promise<boolean> {
    const owned = (await this.userHabitRepository
      .findForUser(userId, UserHabitState.ACTIVE)
      .catch(() => [])) as Array<{ habitId?: unknown }>;

    return owned.some((row) => String(row.habitId ?? '') === habitId);
  }

  /** Habit ids → picker chips, titles in the reader's locale. */
  private async habitChoicesFor(ids: string[], locale: string) {
    if (!ids.length) return [];

    const habits = await this.habitLibraryService.findByIds(ids).catch(() => []);

    return (habits as Array<{ _id: unknown; title?: ITranslation }>).map((h) => ({
      value: String(h._id),
      label: this.pickTranslation(h.title, locale) ?? '',
    }));
  }

  private pickTranslation(
    value: ITranslation | undefined,
    locale: string,
  ): string | null {
    if (!value) return null;

    const byLocale = (value as Record<string, string | undefined>)[locale];

    return byLocale || value.en || value.vi || null;
  }

  /**
   * Theory content is authored HTML. Handed to the model with its tags still
   * on, a short paragraph reads as mostly markup and the model spends its
   * budget on `<p>` instead of on what the lesson says.
   *
   * Same rules as `voiceover.service.ts` — block-ending tags become line
   * breaks so sentences do not run together, everything else becomes a space.
   */
  private stripHtml(html: string): string {
    return String(html || '')
      .replace(/<\s*(br|\/p|\/div|\/li|\/h[1-6])\s*\/?>/gi, '\n')
      .replace(/<[^>]+>/g, ' ')
      .replace(/&nbsp;/gi, ' ')
      .replace(/&amp;/gi, '&')
      .replace(/&lt;/gi, '<')
      .replace(/&gt;/gi, '>')
      .replace(/&#39;|&apos;/gi, "'")
      .replace(/&quot;/gi, '"')
      .replace(/[ \t]+/g, ' ')
      .replace(/\n{3,}/g, '\n\n')
      .replace(/[ \t]*\n[ \t]*/g, '\n')
      .trim();
  }
}
