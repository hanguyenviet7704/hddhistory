import {
  advance,
  asksForAnotherScene,
  asksForOldScene,
  eligibleTasks,
  firstStepOf,
  guessDepth,
  isEscapeAvailable,
  onboardPosition,
  requiresAi,
  resolveOpeningStep,
  routeHub,
  saysStop,
  situationRoundsFor,
  situationVariantFor,
  storyTalkCap,
  storyTalkLeaves,
  taskOf,
  uiFor,
  CoachMachineContext,
  TASK_RUN_LIMIT,
  holdsOnQuestion,
} from './coach-state-machine';
import { asksBack } from './coach-text';
import { MAX_INTENT_ROUNDS } from '../../shared/coach.constant';
import {
  CoachEntry,
  CoachHomeTier,
  CoachStep,
  CoachStoryKind,
  CoachUiKind,
} from '../../shared/coach.enum';
import { CoachPlanAnswer } from '../plan/enum/plan.enum';

/**
 * The graph, exercised without a database.
 *
 * The design is the doc of 2026-08-27 (v4): there is no per-door flow any more.
 * A door picks the FIRST task; after that every task runs its own script, stops
 * hard, and hands back to the coordinator, which offers whatever the registry
 * still allows. These tests are written the same way round — per task, plus the
 * registry and the closing sequence.
 */
const base: CoachMachineContext = {
  entry: CoachEntry.HOME,
  tier: CoachHomeTier.FREE,
  moodAlreadyAskedToday: false,
  planQueueLength: 0,
  planIndex: 0,
  planSlept: false,
  ratingHidden: false,
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
  tasksRun: 0,
  hasHabit: true,
};

const ctx = (over: Partial<CoachMachineContext> = {}): CoachMachineContext => ({
  ...base,
  ...over,
});

const lesson = (over: Partial<CoachMachineContext> = {}) =>
  ctx({ entry: CoachEntry.LESSON, tier: null, ...over });
const homeA = (over: Partial<CoachMachineContext> = {}) =>
  ctx({
    tier: CoachHomeTier.PLAN,
    planQueueLength: 1,
    hasPlanPending: true,
    ...over,
  });
const homeB = (over: Partial<CoachMachineContext> = {}) =>
  ctx({ tier: CoachHomeTier.FREE, ...over });
const homeD = (over: Partial<CoachMachineContext> = {}) =>
  ctx({ tier: CoachHomeTier.RETRY, ...over });

describe('coach state machine — doors pick the first task and nothing else', () => {
  it('① never asks mood and opens on the scene and its question', () => {
    expect(resolveOpeningStep(lesson())).toBe(CoachStep.TELL_ONCE);
    expect(resolveOpeningStep(lesson({ moodAlreadyAskedToday: false }))).toBe(
      CoachStep.TELL_ONCE,
    );
  });

  // "◇ Mấy habit mới? — ⟨Phương án⟩ khi có ≥2 · không bỏ qua được."
  it('① asks which habit only when the lesson added two or more', () => {
    expect(resolveOpeningStep(lesson({ newHabitCount: 2 }))).toBe(
      CoachStep.PICK_NEW,
    );
    expect(resolveOpeningStep(lesson({ newHabitCount: 1 }))).toBe(
      CoachStep.TELL_ONCE,
    );
    expect(advance(CoachStep.PICK_NEW, { kind: 'pickNew' }, lesson())).toBe(
      CoachStep.TELL_ONCE,
    );
  });

  // Owner 2026-09-05: BỎ HẲN hỏi mood. Home mở thẳng vào "Hôm nay bạn muốn
  // làm gì?" — không còn bước cảm xúc nào ở đầu phiên, và `moodAlreadyAskedToday`
  // không còn đổi được gì. Cửa ②A và ④ vốn đã nghỉ hưu từ trước.
  it('② mở thẳng vào bộ điều phối, không hỏi mood', () => {
    expect(resolveOpeningStep(homeA())).toBe(CoachStep.HUB);
    expect(resolveOpeningStep(homeA({ moodAlreadyAskedToday: true }))).toBe(
      CoachStep.HUB,
    );
    expect(resolveOpeningStep(homeB({ moodAlreadyAskedToday: true }))).toBe(
      CoachStep.HUB,
    );
    expect(resolveOpeningStep(homeD({ moodAlreadyAskedToday: true }))).toBe(
      CoachStep.HUB,
    );
    expect(advance(CoachStep.MOOD, { kind: 'mood' }, homeB())).toBe(
      CoachStep.HUB,
    );
  });

  it('knows which task every live step belongs to', () => {
    expect(taskOf(CoachStep.INTENT)).toBe('T1');
    expect(taskOf(CoachStep.SCENE_FEELING)).toBe('T2');
    expect(taskOf(CoachStep.TELL_ONCE)).toBe('T2');
    expect(taskOf(CoachStep.SCENE_WHEN)).toBe('T2');
    expect(taskOf(CoachStep.SCENE_DID)).toBe('T2');
    expect(taskOf(CoachStep.SCENE_CHANGE)).toBe('T2');
    expect(taskOf(CoachStep.SCENE_PICK)).toBe('T2');
    expect(taskOf(CoachStep.SCENE_FIX)).toBe('T2');
    expect(taskOf(CoachStep.SCENE_RETRY)).toBe('T2');
    expect(taskOf(CoachStep.DEPTH)).toBe('T3');
    expect(taskOf(CoachStep.SCHEDULE)).toBe('T4');
    expect(taskOf(CoachStep.HUB)).toBeNull();
    expect(firstStepOf('T3', homeB())).toBe(CoachStep.STORY);
    // Home asks WHICH habit first; the lesson door already knows.
    expect(firstStepOf('T2', homeB())).toBe(CoachStep.SCENE_PICK);
    expect(firstStepOf('T2', lesson())).toBe(CoachStep.TELL_ONCE);
  });
});

describe('coach state machine — the registry', () => {
  it('offers what is eligible, most important first', () => {
    // A habit sitting unpractised in the kho is offered before "kể chuyện"
    // (2026-08-28): "sau khi hỏi mood → habit → luyện tập tình huống / kể
    // chuyện". With two pills on screen the order IS the offer.
    // T1 (the reminder check-in) is retired with luồng 4: a pending
    // commitment no longer puts a pill on the coordinator.
    expect(eligibleTasks(homeA())).toEqual(['T2', 'T3']);
    expect(eligibleTasks(homeB())).toEqual(['T2', 'T3']);
    // T2 needs a habit to build a scene from; T3 runs once.
    expect(eligibleTasks(homeB({ hasHabit: false }))).toEqual(['T3']);
    expect(eligibleTasks(homeB({ t3Done: true }))).toEqual(['T2']);
  });

  /**
   * "Trần 3 lượt task" — but the ceiling is about the SCENE, not the talking.
   *
   * It used to empty the list outright, which took "kể chuyện" away with it and
   * left the coordinator with nothing at all: a reader reopening from Home after
   * a full evening was dropped back into the story they had stopped telling with
   * nothing to choose (owner on-device 2026-09-08). Keeping T3 costs nothing the
   * ceiling was protecting — the Home story is already endless once entered and
   * is one call per line, while T2 writes a scene.
   */
  it('drops the scene once the run ceiling is spent, and keeps the talking', () => {
    expect(eligibleTasks(homeA({ tasksRun: TASK_RUN_LIMIT }))).toEqual(['T3']);
    // Told a story already AND spent the ceiling: nothing to suggest, and the
    // box under the coordinator is what invites the next line.
    expect(
      eligibleTasks(homeA({ tasksRun: TASK_RUN_LIMIT, t3Done: true })),
    ).toEqual([]);
    // Under the ceiling nothing changes.
    expect(eligibleTasks(homeA({ tasksRun: TASK_RUN_LIMIT - 1 }))).toEqual([
      'T2',
      'T3',
    ]);
  });

  // T4 is never a suggestion: it is the session's result, offered once at the end.
  it('never suggests the commitment as a task', () => {
    expect(eligibleTasks(homeB({ hasDip: true }))).not.toContain('T4');
  });
});

describe('coach state machine — bộ điều phối', () => {
  it('starts the task the reader names, and refuses one the registry closed', () => {
    expect(
      advance(CoachStep.HUB, { kind: 'task', task: 'T2' }, homeB()),
    ).toBe(CoachStep.SCENE_PICK);
    expect(
      advance(CoachStep.HUB, { kind: 'task', task: 'T2' }, homeB({ t2Done: true })),
    ).toBeNull();
    // The commitment is no longer a task anybody can ask for (luồng 4).
    expect(
      advance(CoachStep.HUB, { kind: 'task', task: 'T4' }, homeB({ hasDip: true })),
    ).toBeNull();
  });

  // "User gõ tự do → classifier định tuyến." A line that is just their day
  // carrying on IS nhịp 1 of the story task — the opener is never re-asked.
  it('routes typing to a task, and treats anything else as the story itself', () => {
    expect(routeHub('cái hẹn hôm trước mình có thử')).toBe('T1');
    expect(routeHub('tập thử đi')).toBe('T2');
    expect(routeHub('lần tới mình sẽ nói ra ý mình')).toBe('T4');
    expect(routeHub('hôm nay họp nhóm mệt lắm')).toBeNull();

    expect(
      advance(CoachStep.HUB, { kind: 'text' }, homeB({ hubRoute: 'T2' })),
    ).toBe(CoachStep.SCENE_PICK);
    // "Gõ thẳng vào ô chat thì đi luôn nhánh kể chuyện" — the line IS the
    // story and the conversation answers it; no depth question in between.
    expect(
      advance(CoachStep.HUB, { kind: 'text' }, homeB({ hubRoute: null })),
    ).toBe(CoachStep.STORY_TALK);
    // A line asking for the retired check-in is just a line.
    expect(
      advance(CoachStep.HUB, { kind: 'text' }, homeB({ hubRoute: 'T1' })),
    ).toBe(CoachStep.STORY_TALK);
  });

  // Home has no tail any more (luồng 4): no commitment offer, no mood-end, no
  // rating. Stopping shows the card when there is one, otherwise ends.
  it('stopping ends the session — with the card when there is one', () => {
    expect(advance(CoachStep.HUB, { kind: 'stop' }, homeB())).toBe(CoachStep.STORY_TALK);
    expect(
      advance(CoachStep.HUB, { kind: 'stop' }, homeB({ hasCourse: true })),
    ).toBe(CoachStep.COURSE_CARD);
    expect(
      advance(CoachStep.HUB, { kind: 'stop' }, homeB({ hasDip: true })),
    ).toBe(CoachStep.STORY_TALK);
  });

  it('a closed sheet is not an event', () => {
    expect(advance(CoachStep.HUB, { kind: 'ack' }, homeB())).toBeNull();
  });

  // Owner, on the device: they answered the question the PREVIOUS session had
  // ended on, and the Coach replied "Bạn muốn tập cái nào trong kho của bạn?".
  // The paragraph contained the two words "trường hợp", which the T2 pattern
  // matches anywhere in a line — so a story was read as a request to practise.
  it('a paragraph is a story, however many keywords it happens to contain', () => {
    const said =
      'tiếp tục cuộc trò chuyện cũ ở trên. Sau khi cuộc trò chuyện kết thúc tôi ' +
      'không băn khoăn điều gì. Tôi chỉ rút ra bài học để xử lý nhanh hơn trong ' +
      'các trường hợp tương tự về sau';

    expect(routeHub(said)).toBeNull();
    // The same keyword in a SHORT line is still an ask — the guard is length,
    // not a hole punched in the pattern.
    expect(routeHub('trường hợp này mình nói thế nào')).toBe('T2');
  });

  // `tập` is a substring of ordinary words, and the pattern had no lookahead.
  it('does not read "tập trung" as a request to practise', () => {
    expect(routeHub('hôm nay tôi tập trung tốt hơn')).toBeNull();
    expect(routeHub('mình hay nghĩ về tập thể')).toBeNull();
    // The real asks survive.
    expect(routeHub('tập thử đi')).toBe('T2');
    expect(routeHub('cho mình luyện tập')).toBe('T2');
  });

  // The scene they were already in. Every other practice path in the product
  // means a DIFFERENT scene, so asking for the old one needs its own door.
  it('asking for the scene they already did replays it, not a new one', () => {
    expect(asksForOldScene('cho mình lại tình huống cũ')).toBe(true);
    expect(asksForOldScene('quay lại tình huống hôm qua')).toBe(true);
    expect(asksForOldScene('làm lại cái tình huống vừa rồi')).toBe(true);
    // Asking for a scene, but a NEW one — the ordinary T2 route owns this.
    expect(asksForOldScene('cho mình một tình huống khác')).toBe(false);
    expect(asksForOldScene('tập thử đi')).toBe(false);
    // Same length guard: inside a paragraph these words are narration.
    expect(
      asksForOldScene(
        'hôm qua tôi có kể về tình huống cũ ở chỗ làm rồi nhưng thật ra ' +
          'chuyện đó đã qua và tôi không còn nghĩ tới nữa đâu',
      ),
    ).toBe(false);

    // With a stored scene to go back to, the coordinator replays it.
    expect(
      advance(CoachStep.HUB, { kind: 'text' }, homeB({ hubReplayScene: true })),
    ).toBe(CoachStep.TELL_ONCE);
    // Mid-conversation too: the same reasoning as "luyện tình huống khác".
    expect(
      advance(
        CoachStep.STORY_TALK,
        { kind: 'text' },
        homeB({ hubReplayScene: true }),
      ),
    ).toBe(CoachStep.TELL_ONCE);
    // No stored scene — the words alone must not open the step, and the line
    // falls through to being the story it also is.
    expect(
      advance(CoachStep.HUB, { kind: 'text' }, homeB({ hubReplayScene: false })),
    ).toBe(CoachStep.STORY_TALK);
  });
});

describe('coach state machine — T1 check-in', () => {
  it('done and missed both ask one sentence back; none moves on', () => {
    expect(
      advance(
        CoachStep.INTENT,
        { kind: 'intent', answer: CoachPlanAnswer.DONE },
        homeA(),
      ),
    ).toBe(CoachStep.INTENT_TELL);
    expect(
      advance(
        CoachStep.INTENT,
        { kind: 'intent', answer: CoachPlanAnswer.MISSED },
        homeA(),
      ),
    ).toBe(CoachStep.INTENT_TELL);
    // "Chưa gặp dịp" asks about the occasion instead, and never a "why".
    expect(
      advance(
        CoachStep.INTENT,
        { kind: 'intent', answer: CoachPlanAnswer.NONE },
        homeA(),
      ),
    ).toBe(CoachStep.CONTEXT_ASK);
  });

  // PARKED ②A (luồng 4 retired the check-in door): the arrows still walk, and
  // the end of the task is the end of the Home session — no coordinator after.
  it('③ keep the occasion or retype it', () => {
    expect(
      advance(CoachStep.CONTEXT_ASK, { kind: 'context', keep: false }, homeA()),
    ).toBe(CoachStep.CONTEXT_EDIT);
    // Keeping it ends the task — the coordinator takes over.
    expect(
      advance(CoachStep.CONTEXT_ASK, { kind: 'context', keep: true }, homeA()),
    ).toBe(CoachStep.STORY_TALK);
  });

  it('after "missed" the sentence is followed by the offer to shrink', () => {
    expect(
      advance(CoachStep.INTENT_TELL, { kind: 'text' }, homeA({ intentMissed: true })),
    ).toBe(CoachStep.SHRINK_ASK);
    expect(advance(CoachStep.INTENT_TELL, { kind: 'text' }, homeA())).toBe(
      CoachStep.STORY_TALK,
    );
  });

  it('a second pending commitment is offered, never forced', () => {
    expect(
      advance(
        CoachStep.INTENT_TELL,
        { kind: 'text' },
        homeA({ planQueueLength: 2 }),
      ),
    ).toBe(CoachStep.LOOP);
    expect(advance(CoachStep.LOOP, { kind: 'loop', keepGoing: true }, homeA())).toBe(
      CoachStep.INTENT,
    );
    // Stopping the walk ends T1 — the coordinator decides what follows.
    expect(
      advance(CoachStep.LOOP, { kind: 'loop', keepGoing: false }, homeA()),
    ).toBe(CoachStep.STORY_TALK);
  });

  it('walks at most 2 commitments', () => {
    expect(
      advance(
        CoachStep.INTENT_TELL,
        { kind: 'text' },
        homeA({ planQueueLength: 5, planIndex: MAX_INTENT_ROUNDS - 1 }),
      ),
    ).toBe(CoachStep.STORY_TALK);
  });
});

describe('coach state machine — T3 kể chuyện', () => {
  // Owner, 2026-09-04: "bỏ 2 cột kéo kéo". Nhịp 2 → the draft → "bạn sẽ làm
  // gì" is gone; after the depth question the story is a CONVERSATION — one
  // step that repeats, routed by what kind of line the reader typed.
  it('nhịp 1 → the conversation, which repeats', () => {
    expect(advance(CoachStep.STORY, { kind: 'text' }, homeB())).toBe(
      CoachStep.STORY_TALK,
    );
    expect(
      advance(CoachStep.DEPTH, { kind: 'depth', deep: true }, homeB()),
    ).toBe(CoachStep.STORY_TALK);
    expect(
      advance(
        CoachStep.STORY_TALK,
        { kind: 'text' },
        homeB({ storyKind: CoachStoryKind.NORMAL, storyTalkRounds: 1 }),
      ),
    ).toBe(CoachStep.STORY_TALK);
    expect(taskOf(CoachStep.STORY_TALK)).toBe('T3');
    expect(uiFor(CoachStep.STORY_TALK)).toBe(CoachUiKind.TEXT);
  });

  // Chuyện bình thường · vui · có cảm xúc · có vấn đề · muốn cải thiện — all
  // five keep talking. None of them is a branch.
  it.each([
    CoachStoryKind.NORMAL,
    CoachStoryKind.SUCCESS,
    CoachStoryKind.FEELING,
    CoachStoryKind.PROBLEM,
    CoachStoryKind.WANTS_IMPROVE,
  ])('%s keeps the conversation going', (storyKind) => {
    expect(
      advance(
        CoachStep.STORY_TALK,
        { kind: 'text' },
        homeB({ storyKind, storyTalkRounds: 1 }),
      ),
    ).toBe(CoachStep.STORY_TALK);
  });

  // Three replies, then T3 closes itself and the coordinator decides. The
  // rounds already spent are read off the context; the line being answered is
  // the one that spends the last.
  it('closes after three replies — two on a low day', () => {
    expect(storyTalkCap(homeB())).toBe(3);
    expect(storyTalkCap(homeB({ moodLow: true }))).toBe(2);
    // One task per session (luồng 4): the cap ends the session — through the
    // card when the story connected to a course, otherwise on one line.
    expect(
      advance(
        CoachStep.STORY_TALK,
        { kind: 'text' },
        homeB({ storyKind: CoachStoryKind.NORMAL, storyTalkRounds: 2 }),
      ),
    ).toBe(CoachStep.STORY_TALK);
    expect(
      advance(
        CoachStep.STORY_TALK,
        { kind: 'text' },
        homeB({ storyKind: CoachStoryKind.NORMAL, storyTalkRounds: 2, hasCourse: true }),
      ),
    ).toBe(CoachStep.STORY_TALK);
    expect(
      advance(
        CoachStep.STORY_TALK,
        { kind: 'text' },
        homeB({ storyKind: CoachStoryKind.NORMAL, storyTalkRounds: 1, moodLow: true }),
      ),
    ).toBe(CoachStep.STORY_TALK);
  });

  // "User chủ động hỏi cách cải thiện → recommend Course." The card, NOW —
  // when there is one. A habit already in the kho has no course to point at,
  // so the coordinator offers the practice instead. Neither waits for the cap.
  it('asking how opens the card now, or ends when there is none to show', () => {
    expect(
      advance(
        CoachStep.STORY_TALK,
        { kind: 'text' },
        homeB({ storyKind: CoachStoryKind.ASKS_HOW, hasCourse: true }),
      ),
    ).toBe(CoachStep.COURSE_CARD);
    expect(
      advance(
        CoachStep.STORY_TALK,
        { kind: 'text' },
        homeB({ storyKind: CoachStoryKind.ASKS_HOW, hasCourse: true, cardShown: true }),
      ),
    ).toBe(CoachStep.STORY_TALK);
    expect(
      advance(
        CoachStep.STORY_TALK,
        { kind: 'text' },
        homeB({ storyKind: CoachStoryKind.ASKS_HOW, hasHabit: true }),
      ),
    ).toBe(CoachStep.STORY_TALK);
    // ① never shows a course — the same rule the closing sequence follows —
    // and luồng 7 closes after its one thing rather than going back to the
    // coordinator: the reader is on their way to the finished lesson.
    expect(
      advance(
        CoachStep.STORY_TALK,
        { kind: 'text' },
        lesson({ storyKind: CoachStoryKind.ASKS_HOW, hasCourse: true }),
      ),
    ).toBe(CoachStep.END);
  });

  // "User không muốn tiếp tục → dừng, không recommend." Straight to the tail:
  // no card, no commitment offer — mood-end and the rating are the sheet's own
  // and still run once.
  it('stopping ends at once — no card, nothing offered', () => {
    expect(
      advance(
        CoachStep.STORY_TALK,
        { kind: 'text' },
        homeB({ storyKind: CoachStoryKind.STOP, hasCourse: true, storyTold: true }),
      ),
    ).toBe(CoachStep.STORY_TALK);
  });

  // The kind is read on the depth answer too: "làm sao để cải thiện?" typed
  // as the answer to "bạn muốn chia sẻ thêm không?" is the same request.
  it('the depth answer is routed by its kind as well', () => {
    expect(
      advance(
        CoachStep.DEPTH,
        { kind: 'text' },
        homeB({ depthGuess: 'deep', storyKind: CoachStoryKind.ASKS_HOW, hasCourse: true }),
      ),
    ).toBe(CoachStep.COURSE_CARD);
    expect(
      advance(
        CoachStep.DEPTH,
        { kind: 'depth', deep: true },
        homeB({ storyKind: CoachStoryKind.STOP }),
      ),
    ).toBe(CoachStep.STORY_TALK);
  });

  // Words that end a subject, read with no model call — the reader's "thôi"
  // must never be sent to a model to be replied to.
  it('reads a stop in the reader’s own words, in either language', () => {
    expect(saysStop('thôi, mình dừng ở đây')).toBe(true);
    expect(saysStop('không muốn nói nữa')).toBe(true);
    expect(saysStop("that's enough for today")).toBe(true);
    expect(saysStop('stop')).toBe(true);
    expect(saysStop('hôm qua họp nhóm mình lại chen ngang lúc Nam đang nói')).toBe(false);
    expect(saysStop('ừ')).toBe(false);
    expect(saysStop('')).toBe(false);
  });

  // The Home opener goes straight into the conversation (luồng 4): no depth
  // question. "Chỉ ghi lại thôi" still files the line and ends the task.
  it('the opener leads into the conversation; filing it ends the task', () => {
    expect(advance(CoachStep.STORY, { kind: 'text' }, homeB())).toBe(
      CoachStep.STORY_TALK,
    );
    expect(advance(CoachStep.STORY, { kind: 'ack' }, homeB())).toBe(CoachStep.STORY_TALK);
    expect(advance(CoachStep.STORY_TALK, { kind: 'ack' }, homeB())).toBe(CoachStep.STORY_TALK);
  });

  // PARKED: the depth question still reads what a parked session types.
  it('the parked depth question reads what they type — and asks once when unsure', () => {
    expect(advance(CoachStep.STORY, { kind: 'text' }, lesson())).toBe(CoachStep.DEPTH);
    expect(
      advance(CoachStep.DEPTH, { kind: 'text' }, homeB({ depthGuess: 'deep' })),
    ).toBe(CoachStep.STORY_TALK);
    expect(
      advance(CoachStep.DEPTH, { kind: 'text' }, homeB({ depthGuess: 'shallow' })),
    ).toBe(CoachStep.STORY_TALK);
    expect(
      advance(CoachStep.DEPTH, { kind: 'text' }, homeB({ depthGuess: 'unsure' })),
    ).toBe(CoachStep.DEPTH);
    expect(
      advance(
        CoachStep.DEPTH,
        { kind: 'text' },
        homeB({ depthGuess: 'unsure', depthReasked: true }),
      ),
    ).toBe(CoachStep.STORY_TALK);
  });

  it('reads the closing words and the story-length ones with no model call', () => {
    expect(guessDepth('thế thôi')).toBe('shallow');
    expect(guessDepth('ghi lại giúp mình')).toBe('shallow');
    expect(guessDepth('ừ')).toBe('shallow');
    expect(
      guessDepth(
        'Hôm qua họp nhóm mình lại chen ngang lúc Nam đang nói, xong cả buổi thấy khó chịu',
      ),
    ).toBe('deep');
    expect(guessDepth('mình nói với anh ấy rồi')).toBe('unsure');
  });

  // Late at night on a low day used to skip nhịp 2 and draft from the story
  // alone. There is no draft now; the hour only shortens the conversation.
  it('a low day still gets the conversation, just a shorter one', () => {
    expect(
      advance(CoachStep.DEPTH, { kind: 'depth', deep: true }, homeB({ moodLow: true })),
    ).toBe(CoachStep.STORY_TALK);
    expect(
      advance(
        CoachStep.DEPTH,
        { kind: 'depth', deep: true },
        homeB({ moodLow: true, lateNightLow: true }),
      ),
    ).toBe(CoachStep.STORY_TALK);
  });

  // PARKED: sessions still standing on the old beats walk out of them. The
  // draft can still be rejected once; nothing new ever enters these steps.
  it('the retired beats still walk a parked session out', () => {
    expect(advance(CoachStep.TELL_2, { kind: 'text' }, homeB())).toBe(
      CoachStep.TWO_COLS,
    );
    expect(advance(CoachStep.TELL_2, { kind: 'ack' }, homeB())).toBe(CoachStep.STORY_TALK);
    expect(advance(CoachStep.TWO_COLS, { kind: 'text' }, homeB())).toBe(
      CoachStep.NEXT_ACTION,
    );
    expect(advance(CoachStep.TWO_COLS, { kind: 'rejectDraft' }, homeB())).toBe(
      CoachStep.TELL_2,
    );
    expect(
      advance(
        CoachStep.TWO_COLS,
        { kind: 'rejectDraft' },
        homeB({ draftRejected: true }),
      ),
    ).toBeNull();
    expect(advance(CoachStep.NEXT_ACTION, { kind: 'text' }, homeB())).toBe(
      CoachStep.STORY_TALK,
    );
  });

  // A skip is a decline: "Kể chuyện" is not offered again (no carousel of
  // pill → skip → pill), but it spends none of the three runs — nothing ran.
  it('skipping the opener declines the story without spending a run', () => {
    // Declined at Home → the coordinator still has the scene to offer…
    expect(advance(CoachStep.STORY, { kind: 'skip' }, homeB())).toBe(CoachStep.HUB);
    // …and with nothing else to offer the session simply ends.
    expect(
      advance(CoachStep.STORY, { kind: 'skip' }, homeB({ hasHabit: false })),
    ).toBe(CoachStep.STORY_TALK);
  });
});

describe('coach state machine — T2 tình huống', () => {
  const scene = (over: Partial<CoachMachineContext> = {}) =>
    lesson({ hasStage2: true, ...over });

  // RETIRED the same day: the feeling lead-in is gone — a session parked on
  // it still walks out into the scene's own question.
  it('a parked feeling beat walks out into the question', () => {
    expect(advance(CoachStep.SCENE_FEELING, { kind: 'text' }, scene())).toBe(
      CoachStep.TELL_ONCE,
    );
  });

  // Luồng 4 (Home): pick the habit → ONE scene → the answer is judged.
  it('Home picks the habit first, by chip or by name', () => {
    expect(advance(CoachStep.SCENE_PICK, { kind: 'pickNew' }, homeB())).toBe(
      CoachStep.TELL_ONCE,
    );
    expect(
      advance(CoachStep.SCENE_PICK, { kind: 'text' }, homeB({ pickedHabit: true })),
    ).toBe(CoachStep.TELL_ONCE);
    // A name that matches nothing in the kho asks again.
    expect(
      advance(CoachStep.SCENE_PICK, { kind: 'text' }, homeB({ pickedHabit: false })),
    ).toBe(CoachStep.SCENE_PICK);
    expect(advance(CoachStep.SCENE_PICK, { kind: 'ack' }, homeB())).toBeNull();
  });

  // Reactive branching (owner, 2026-09-04): the first line is answered by the
  // other person, not scored. Only the second line closes the beat — and the
  // verdict reads both.
  it('answers the first line before scoring anything', () => {
    expect(
      advance(CoachStep.TELL_ONCE, { kind: 'text' }, homeB({ sceneAwaitingSecondLine: true })),
    ).toBe(CoachStep.SCENE_STAGE2);
    // Without that flag the line is the one to score — the reader is on their
    // second line, or the other person never managed to answer the first and
    // the service scored it straight away.
    expect(
      advance(
        CoachStep.TELL_ONCE,
        { kind: 'text' },
        homeB({ sceneOnTrack: true, hasCourse: true }),
      ),
    ).toBe(CoachStep.COURSE_CARD);
  });

  // Three answers since 2026-09-07, so there are TWO forks: the second choice
  // is made in a situation the first choice created. The service says "another
  // reaction is coming" by leaving the flag set; the graph just follows it.
  it('keeps the scene open while the service says another reaction is coming', () => {
    expect(situationRoundsFor(homeB())).toBe(5);
    expect(
      advance(
        CoachStep.SCENE_STAGE2,
        { kind: 'text' },
        homeB({ sceneAwaitingSecondLine: true }),
      ),
    ).toBe(CoachStep.SCENE_STAGE2);
    // Flag clear — the last answer, or a reaction that never arrived. Scored.
    expect(
      advance(
        CoachStep.SCENE_STAGE2,
        { kind: 'text' },
        homeB({ sceneAwaitingSecondLine: false, sceneOnTrack: false }),
      ),
    ).toBe(CoachStep.SCENE_FIX);
  });

  // The card carries the two ways forward: take the course, or practise again
  // one rung harder. "Harder" is the only one that does not end the session.
  it('the card offers a harder scene as well as the course', () => {
    expect(
      advance(
        CoachStep.COURSE_CARD,
        { kind: 'course', open: false, harder: true },
        homeB({ hasHabit: true }),
      ),
    ).toBe(CoachStep.TELL_ONCE);
    // The run ceiling still holds — an explicit ask does not buy a fourth task.
    expect(
      advance(
        CoachStep.COURSE_CARD,
        { kind: 'course', open: false, harder: true },
        homeB({ hasHabit: true, tasksRun: TASK_RUN_LIMIT }),
      ),
    ).not.toBe(CoachStep.TELL_ONCE);
    // "Đi tới khoá học" still leaves on the spot.
    expect(
      advance(CoachStep.COURSE_CARD, { kind: 'course', open: true }, homeB()),
    ).toBe(CoachStep.END);
  });

  // Đúng hướng: one specific praise, then the card in the same skill set —
  // "không mời tập thêm cảnh nữa trong phiên". No course → the talk goes on.
  it('an answer on track ends on the card, or on one line', () => {
    expect(
      advance(
        CoachStep.SCENE_STAGE2,
        { kind: 'text' },
        homeB({ sceneOnTrack: true, hasCourse: true }),
      ),
    ).toBe(CoachStep.COURSE_CARD);
    expect(
      advance(CoachStep.SCENE_STAGE2, { kind: 'text' }, homeB({ sceneOnTrack: true })),
    ).toBe(CoachStep.STORY_TALK);
  });

  // Chưa đúng: a sample line and why, then ⟨Luyện lại cảnh này⟩ · ⟨Để sau⟩.
  // The same scene, verbatim, at most twice; "chưa làm được thì gợi học thêm
  // là đổi chủ đề" — the wrong branch never shows a course.
  it('an answer off track offers one retry on a fresh scene, then closes', () => {
    expect(
      advance(CoachStep.SCENE_STAGE2, { kind: 'text' }, homeB({ sceneOnTrack: false })),
    ).toBe(CoachStep.SCENE_FIX);
    expect(
      advance(CoachStep.SCENE_FIX, { kind: 'sceneAgain', again: true }, homeB()),
    ).toBe(CoachStep.SCENE_RETRY);
    expect(
      advance(CoachStep.SCENE_FIX, { kind: 'sceneAgain', again: false }, homeB()),
    ).toBe(CoachStep.STORY_TALK);
    expect(
      advance(
        CoachStep.SCENE_FIX,
        { kind: 'sceneAgain', again: true },
        homeB({ sceneRetried: true }),
      ),
    ).toBe(CoachStep.STORY_TALK);
    // The retry walks the same two beats, on a different scene about the same
    // habit ("đưa tình huống tương tự, không lặp lại y nguyên").
    expect(
      advance(
        CoachStep.SCENE_RETRY,
        { kind: 'text' },
        homeB({ sceneAwaitingSecondLine: true }),
      ),
    ).toBe(CoachStep.SCENE_STAGE2);
    expect(
      advance(
        CoachStep.SCENE_STAGE2,
        { kind: 'text' },
        homeB({ sceneRetried: true, sceneOnTrack: true, hasCourse: true }),
      ),
    ).toBe(CoachStep.COURSE_CARD);
    // Off track on the retry: no third try, and no course on this branch.
    expect(
      advance(
        CoachStep.SCENE_STAGE2,
        { kind: 'text' },
        homeB({ sceneRetried: true, sceneOnTrack: false, hasCourse: true }),
      ),
    ).toBe(CoachStep.STORY_TALK);
    expect(uiFor(CoachStep.SCENE_PICK)).toBe(CoachUiKind.CHIPS);
    expect(uiFor(CoachStep.SCENE_FIX)).toBe(CoachUiKind.CHIPS);
    expect(uiFor(CoachStep.SCENE_RETRY)).toBe(CoachUiKind.TEXT);
    expect(requiresAi(CoachStep.SCENE_RETRY)).toBe(true);
  });

  // The lesson door runs the SAME two beats now (owner, 2026-09-04: "cả cửa
  // bài học"), so its scene is no longer a walk through the authored stages.
  it('runs the two beats at the lesson door too', () => {
    expect(
      advance(CoachStep.TELL_ONCE, { kind: 'text' }, scene({ sceneAwaitingSecondLine: true })),
    ).toBe(CoachStep.SCENE_STAGE2);
    expect(
      advance(CoachStep.SCENE_STAGE2, { kind: 'text' }, scene({ sceneOnTrack: true })),
    ).not.toBe(CoachStep.SCENE_STAGE2);
  });

  // "Nhịp 4 — KHÔNG mời nói lại": nothing in the scene asks them to answer the
  // same stage twice, because part c has just said "không phải tốt hơn".
  it('never asks them to say the same thing again', () => {
    expect(advance(CoachStep.TELL_ONCE, { kind: 'sceneAgain', again: true }, scene()))
      .toBeNull();
  });

  it('"Rồi" opens 6b; "Chưa" goes straight to the story', () => {
    expect(
      advance(CoachStep.SCENE_MET, { kind: 'sceneMet', met: true }, scene()),
    ).toBe(CoachStep.SCENE_DID);
    expect(
      advance(CoachStep.SCENE_MET, { kind: 'sceneMet', met: false }, scene()),
    ).toBe(CoachStep.STORY);
    // Mẫu #10 — the telling typed with the "Rồi": 6b is answered, 6d follows.
    expect(advance(CoachStep.SCENE_MET, { kind: 'text' }, scene())).toBe(
      CoachStep.SCENE_CHANGE,
    );
    // T3 already run → the coordinator as usual, and nothing is said about
    // having just missed.
    expect(
      advance(
        CoachStep.SCENE_MET,
        { kind: 'sceneMet', met: false },
        scene({ t3Done: true }),
      ),
    ).toBe(CoachStep.END);
  });

  // 6b → 6c/6d: a real telling earns the mirror and the change question; a
  // dead answer (nothing typed worth keeping, or a question back) skips both.
  it('6b leads to 6d, unless the answer was a dead end', () => {
    expect(advance(CoachStep.SCENE_DID, { kind: 'text' }, homeB())).toBe(
      CoachStep.SCENE_CHANGE,
    );
    expect(
      advance(CoachStep.SCENE_DID, { kind: 'text' }, homeB({ sceneDidDead: true })),
    ).toBe(CoachStep.STORY_TALK);
  });

  it('the occasion hands straight over to the commitment', () => {
    // "Trực tiếp điều hướng sang T4 luôn" (2026-08-28): the coordinator's
    // "Xong rồi. Còn gì bạn muốn nói không?" stood between a reader and the
    // one thing the scene had just earned.
    expect(advance(CoachStep.SCENE_CHANGE, { kind: 'text' }, homeB())).toBe(
      CoachStep.PLAN_ASK,
    );
    // Offered already — then the task simply ends, as before.
    expect(
      advance(CoachStep.SCENE_CHANGE, { kind: 'text' }, homeB({ t4Offered: true })),
    ).toBe(CoachStep.STORY_TALK);
    expect(advance(CoachStep.SCENE_WHEN, { kind: 'text' }, homeB())).toBe(
      CoachStep.STORY_TALK,
    );
  });
});

describe('coach state machine — luồng 5 · the Habit screen', () => {
  const habit = (over: Partial<CoachMachineContext> = {}) =>
    ctx({ entry: CoachEntry.HABIT, tier: null, hasQuiz: true, ...over });

  // "Không hỏi mood ở cửa này": straight to the coordinator, two pills about
  // this one habit — write today, or its quiz. Each disappears once done.
  it('opens on the coordinator with the two habit pills, no mood', () => {
    expect(resolveOpeningStep(habit({ moodAlreadyAskedToday: false }))).toBe(
      CoachStep.HUB,
    );
    expect(eligibleTasks(habit())).toEqual(['checkin', 'quiz']);
    // Today written: the quiz stays first and the Home tasks join it — the
    // pill limit shows two of them, and the box is the story's own way in.
    expect(eligibleTasks(habit({ checkinDone: true }))).toEqual(['quiz', 'T2', 'T3']);
    expect(eligibleTasks(habit({ hasQuiz: false }))).toEqual(['checkin']);
    // Everything about this habit is done: the coordinator offers the two Home
    // tasks instead of closing (owner, 2026-09-04) — unless another habit is
    // still unwritten, which the check-in offer handles first.
    expect(eligibleTasks(habit({ checkinDone: true, quizDone: true }))).toEqual(['T2', 'T3']);
    expect(
      eligibleTasks(habit({ checkinDone: true, quizDone: true, hasNextHabit: true })),
    ).toEqual([]);
    expect(
      eligibleTasks(habit({ checkinDone: true, quizDone: true, t2Done: true, t3Done: true })),
    ).toEqual([]);
    expect(advance(CoachStep.HUB, { kind: 'task', task: 'checkin' }, habit())).toBe(
      CoachStep.CHECKIN_ASK,
    );
    expect(advance(CoachStep.HUB, { kind: 'task', task: 'quiz' }, habit())).toBe(
      CoachStep.QUIZ_IN_CHAT,
    );
    expect(
      advance(CoachStep.HUB, { kind: 'task', task: 'quiz' }, habit({ hasQuiz: false })),
    ).toBeNull();
    // "Hoặc kể luôn chuyện của bạn…" — typing is the story.
    expect(advance(CoachStep.HUB, { kind: 'text' }, habit({ hubRoute: null }))).toBe(
      CoachStep.STORY_TALK,
    );
    expect(taskOf(CoachStep.CHECKIN_TELL)).toBe('checkin');
    expect(taskOf(CoachStep.QUIZ_IN_CHAT)).toBe('quiz');
  });

  // Both answers write. ⟨Có⟩ first asks for one real sentence; ⟨Chưa⟩ writes
  // done:false at once. Then the NEXT unwritten habit is offered — or the
  // sheet closes when there is none.
  it('writes on both answers and offers the next habit, never jumps to it', () => {
    expect(
      advance(CoachStep.CHECKIN_ASK, { kind: 'checkin', done: true }, habit()),
    ).toBe(CoachStep.CHECKIN_TELL);
    expect(
      advance(
        CoachStep.CHECKIN_ASK,
        { kind: 'checkin', done: false },
        habit({ hasNextHabit: true }),
      ),
    ).toBe(CoachStep.CHECKIN_OFFER);
    // Nothing left to write and the two Home tasks still open: the sheet goes
    // to the coordinator rather than closing on "mai mình lại hỏi nhé".
    expect(
      advance(CoachStep.CHECKIN_ASK, { kind: 'checkin', done: false }, habit()),
    ).toBe(CoachStep.HUB);
    expect(
      advance(
        CoachStep.CHECKIN_ASK,
        { kind: 'checkin', done: false },
        habit({ quizDone: true, t2Done: true, t3Done: true }),
      ),
    ).toBe(CoachStep.END);
    expect(
      advance(CoachStep.CHECKIN_TELL, { kind: 'text' }, habit({ hasNextHabit: true })),
    ).toBe(CoachStep.CHECKIN_OFFER);
    expect(advance(CoachStep.CHECKIN_TELL, { kind: 'text' }, habit())).toBe(
      CoachStep.HUB,
    );
    expect(
      advance(CoachStep.CHECKIN_OFFER, { kind: 'invite', accept: true }, habit()),
    ).toBe(CoachStep.CHECKIN_ASK);
    expect(
      advance(CoachStep.CHECKIN_OFFER, { kind: 'invite', accept: false }, habit()),
    ).toBe(CoachStep.END);
    expect(advance(CoachStep.CHECKIN_ASK, { kind: 'text' }, habit())).toBeNull();
  });

  // Three questions, one per turn; the last answer files the attempt and goes
  // on to the offer exactly like a check-in.
  it('asks the quiz one question at a time, then offers the next habit', () => {
    expect(
      advance(CoachStep.QUIZ_IN_CHAT, { kind: 'quizAnswer' }, habit({ quizRemaining: 3 })),
    ).toBe(CoachStep.QUIZ_IN_CHAT);
    expect(
      advance(
        CoachStep.QUIZ_IN_CHAT,
        { kind: 'quizAnswer' },
        habit({ quizRemaining: 1, hasNextHabit: true }),
      ),
    ).toBe(CoachStep.CHECKIN_OFFER);
    expect(
      advance(CoachStep.QUIZ_IN_CHAT, { kind: 'quizAnswer' }, habit({ quizRemaining: 1 })),
    ).toBe(CoachStep.HUB);
    expect(advance(CoachStep.QUIZ_IN_CHAT, { kind: 'text' }, habit())).toBeNull();
    expect(uiFor(CoachStep.CHECKIN_ASK)).toBe(CoachUiKind.CHIPS);
    expect(uiFor(CoachStep.CHECKIN_OFFER)).toBe(CoachUiKind.CHIPS);
    expect(uiFor(CoachStep.QUIZ_IN_CHAT)).toBe(CoachUiKind.CHIPS);
    expect(uiFor(CoachStep.CHECKIN_TELL)).toBe(CoachUiKind.TEXT);
    expect(requiresAi(CoachStep.CHECKIN_TELL)).toBe(true);
  });
});

describe('coach state machine — luồng 2/3 · the lesson door redrawn', () => {
  const talk = (over: Partial<CoachMachineContext> = {}) =>
    lesson({ talkMode: 'talk', ...over });
  const recap = (over: Partial<CoachMachineContext> = {}) =>
    lesson({ talkMode: 'recap', ...over });

  // After a keypoint: no mood, no scene — the talk. After the last one: the recap.
  it('opens on the talk or the recap, never the old scene', () => {
    expect(resolveOpeningStep(talk({ moodAlreadyAskedToday: false }))).toBe(
      CoachStep.TALK_ASK,
    );
    expect(resolveOpeningStep(recap({ moodAlreadyAskedToday: false }))).toBe(
      CoachStep.RECAP_PICK,
    );
    // A client that opens without a keypoint still gets the legacy scene door.
    expect(resolveOpeningStep(lesson())).toBe(CoachStep.TELL_ONCE);
    expect(uiFor(CoachStep.TALK_ASK)).toBe(CoachUiKind.HUB);
    expect(uiFor(CoachStep.QUIZ_RUN)).toBe(CoachUiKind.CHIPS);
    expect(requiresAi(CoachStep.TALK_SUMMARY)).toBe(true);
  });

  // ⟨Bàn luận về bài vừa học⟩ hỏi lại phần nhớ được, CHẤM, rồi MỞ sàn hỏi đáp
  // (owner 2026-09-05) — không mời quiz nữa. ⟨Làm quiz⟩ là lựa chọn riêng ở
  // TALK_ASK. Gõ thẳng vẫn là một câu trả lời đủ nghĩa.
  it('bàn luận → hỏi phần nhớ được → mở sàn hỏi đáp; quiz là nhánh riêng', () => {
    expect(advance(CoachStep.TALK_ASK, { kind: 'pick' }, talk({ pick: 'summary' }))).toBe(
      CoachStep.TALK_SUMMARY,
    );
    expect(advance(CoachStep.TALK_ASK, { kind: 'pick' }, talk({ pick: 'talkQuiz' }))).toBe(
      CoachStep.QUIZ_HANDOFF,
    );
    expect(advance(CoachStep.TALK_ASK, { kind: 'text' }, talk())).toBe(
      CoachStep.QUIZ_HANDOFF,
    );
    expect(advance(CoachStep.TALK_SUMMARY, { kind: 'text' }, talk())).toBe(
      CoachStep.TALK_FREE,
    );
    expect(advance(CoachStep.TALK_ASK, { kind: 'pick' }, talk({ pick: 'nope' }))).toBeNull();
  });

  // Sàn hỏi đáp sau lượt chấm: mỗi câu hỏi được trả lời và tốn một lượt; hết
  // trần thì đóng. Trần do service tính (nó giữ session + config), máy trạng
  // thái chỉ đọc `talkFreeExhausted`.
  it('sàn hỏi đáp mở tới khi hết trần lượt', () => {
    // Còn lượt → ở lại sàn.
    expect(
      advance(CoachStep.TALK_FREE, { kind: 'text' }, talk({ talkFreeExhausted: false })),
    ).toBe(CoachStep.TALK_FREE);
    // Câu cuối của ngân sách → đóng.
    expect(
      advance(CoachStep.TALK_FREE, { kind: 'text' }, talk({ talkFreeExhausted: true })),
    ).toBe(CoachStep.END);
    // Trần = 0 thì lượt chấm là câu cuối, y như hành vi trước 2026-09-05.
    expect(
      advance(CoachStep.TALK_SUMMARY, { kind: 'text' }, talk({ talkFreeExhausted: true })),
    ).toBe(CoachStep.END);
    // Chỉ `text` mới đi tiếp — một cú pick lạc vào sàn không làm gì.
    expect(advance(CoachStep.TALK_FREE, { kind: 'pick' }, talk())).toBeNull();
    // Mỗi câu trên sàn tốn một lần gọi model.
    expect(requiresAi(CoachStep.TALK_FREE)).toBe(true);
  });

  // The quiz runs on its own screen and reports back; declining it goes
  // straight to the closing question. Both closing answers END — no card, no
  // mood, no rating, no reminder after one keypoint.
  it('the quiz hand-off, and the closing question that ends everything', () => {
    expect(
      advance(CoachStep.QUIZ_HANDOFF, { kind: 'pick' }, talk({ pick: 'start' })),
    ).toBe(CoachStep.QUIZ_RUN);
    expect(
      advance(CoachStep.QUIZ_HANDOFF, { kind: 'pick' }, talk({ pick: 'later' })),
    ).toBe(CoachStep.TALK_WHEN);
    expect(advance(CoachStep.QUIZ_RUN, { kind: 'quizDone' }, talk())).toBe(
      CoachStep.TALK_WHEN,
    );
    expect(advance(CoachStep.QUIZ_RUN, { kind: 'text' }, talk())).toBeNull();
    expect(
      advance(CoachStep.TALK_WHEN, { kind: 'pick' }, talk({ pick: 'continue', hasCourse: true })),
    ).toBe(CoachStep.END);
    expect(
      advance(CoachStep.TALK_WHEN, { kind: 'pick' }, talk({ pick: 'later', storyTold: true })),
    ).toBe(CoachStep.END);
  });

  // The recap: a lesson picked → the quiz offer → the in-chat quiz over the
  // course → the ONE lesson-door flow with a card and the full tail.
  it('the recap ends through the card, the mood, the rating — and stops', () => {
    expect(advance(CoachStep.RECAP_PICK, { kind: 'pick' }, recap({ pick: 'lesson-1' }))).toBe(
      CoachStep.RECAP_QUIZ,
    );
    expect(advance(CoachStep.RECAP_PICK, { kind: 'pick' }, recap({ pick: '' }))).toBeNull();
    expect(advance(CoachStep.RECAP_QUIZ, { kind: 'pick' }, recap({ pick: 'try' }))).toBe(
      CoachStep.QUIZ_IN_CHAT,
    );
    expect(
      advance(CoachStep.RECAP_QUIZ, { kind: 'pick' }, recap({ pick: 'later', hasCourse: true })),
    ).toBe(CoachStep.COURSE_CARD);
    expect(
      advance(CoachStep.QUIZ_IN_CHAT, { kind: 'quizAnswer' }, recap({ quizRemaining: 1, hasCourse: true })),
    ).toBe(CoachStep.COURSE_CARD);
    // Từ 2026-09-14 không còn bước RATING giữa đường: hỏi đánh giá chuyển hẳn
    // sang sheet sau ⟨Vẫn đóng⟩, nên đuôi recap đóng thẳng.
    expect(
      advance(CoachStep.QUIZ_IN_CHAT, { kind: 'quizAnswer' }, recap({ quizRemaining: 1 })),
    ).toBe(CoachStep.END);
    expect(
      advance(CoachStep.COURSE_CARD, { kind: 'course', open: false }, recap({ cardShown: true })),
    ).toBe(CoachStep.END);
    expect(
      advance(CoachStep.COURSE_CARD, { kind: 'course', open: false }, recap({ cardShown: true, ratingHidden: true })),
    ).toBe(CoachStep.END);
  });
});

describe('coach state machine — luồng 1 · Onboarding Coach', () => {
  const onboard = (over: Partial<CoachMachineContext> = {}) =>
    homeB({ onboarding: true, viLocale: true, moodAlreadyAskedToday: false, ...over });

  // Once per reader — and never a task. Không còn bước mood nào sau nó.
  it('the first Home session opens on the introduction', () => {
    expect(resolveOpeningStep(onboard())).toBe(CoachStep.ONBOARD_INTRO);
    expect(resolveOpeningStep(homeB({ moodAlreadyAskedToday: false }))).toBe(CoachStep.HUB);
    expect(taskOf(CoachStep.ONBOARD_GOAL)).toBeNull();
    expect(uiFor(CoachStep.ONBOARD_GOAL)).toBe(CoachUiKind.HUB);
    expect(uiFor(CoachStep.ONBOARD_ADDRESS_CONFIRM)).toBe(CoachUiKind.CHIPS);
    expect(requiresAi(CoachStep.ONBOARD_INTRO)).toBe(true);
  });

  // The eight questions in order; the optional four drop out with the toggles,
  // the address drops out of every locale but Vietnamese.
  it('walks the questions in order, skipping what is off', () => {
    expect(advance(CoachStep.ONBOARD_INTRO, { kind: 'pick' }, onboard({ pick: 'start' }))).toBe(
      CoachStep.ONBOARD_ADDRESS,
    );
    expect(advance(CoachStep.ONBOARD_INTRO, { kind: 'pick' }, onboard({ pick: 'start', viLocale: false }))).toBe(
      CoachStep.ONBOARD_BARRIER,
    );
    expect(advance(CoachStep.ONBOARD_ADDRESS, { kind: 'pick' }, onboard({ pick: 'chị' }))).toBe(
      CoachStep.ONBOARD_BARRIER,
    );
    expect(advance(CoachStep.ONBOARD_CURRENT, { kind: 'text' }, onboard())).toBe(CoachStep.ONBOARD_STYLE);
    expect(
      advance(
        CoachStep.ONBOARD_CURRENT,
        { kind: 'text' },
        onboard({ onboardAsk: { style: false, age: false, gender: true, job: true } }),
      ),
    ).toBe(CoachStep.ONBOARD_GENDER);
    expect(
      advance(
        CoachStep.ONBOARD_CURRENT,
        { kind: 'text' },
        onboard({ onboardAsk: { style: false, age: false, gender: false, job: false } }),
      ),
    ).toBe(CoachStep.HUB);
    // Xong onboarding → thẳng bộ điều phối; không còn bước mood ở giữa.
    expect(advance(CoachStep.ONBOARD_JOB, { kind: 'pick' }, onboard({ pick: 'office' }))).toBe(
      CoachStep.HUB,
    );
    expect(
      advance(CoachStep.ONBOARD_JOB, { kind: 'text' }, onboard({ moodAlreadyAskedToday: true })),
    ).toBe(CoachStep.HUB);
    // Owner 2026-09-05 — câu cản trở đứng TRƯỚC câu mục tiêu.
    expect(onboardPosition(CoachStep.ONBOARD_BARRIER, onboard())).toEqual({ step: 2, total: 8 });
    expect(onboardPosition(CoachStep.ONBOARD_GOAL, onboard())).toEqual({ step: 3, total: 8 });
    expect(onboardPosition(CoachStep.ONBOARD_BARRIER, onboard({ viLocale: false }))).toEqual({ step: 1, total: 7 });
  });

  // "Bỏ qua" ends the onboarding wherever it is pressed — except at the one
  // question every later line depends on.
  it('skips out from anywhere except the address', () => {
    expect(advance(CoachStep.ONBOARD_INTRO, { kind: 'pick' }, onboard({ pick: 'skip' }))).toBe(
      CoachStep.HUB,
    );
    expect(advance(CoachStep.ONBOARD_BARRIER, { kind: 'pick' }, onboard({ pick: 'skip' }))).toBe(
      CoachStep.HUB,
    );
    expect(advance(CoachStep.ONBOARD_ADDRESS, { kind: 'pick' }, onboard({ pick: 'skip' }))).toBeNull();
  });

  // "← Câu trước" — one question back, skipping the ones the admin turned off;
  // the address is the floor.
  it('steps back to the previous asked question', () => {
    expect(advance(CoachStep.ONBOARD_GOAL, { kind: 'pick' }, onboard({ pick: 'back' }))).toBe(
      CoachStep.ONBOARD_BARRIER,
    );
    expect(
      advance(
        CoachStep.ONBOARD_GENDER,
        { kind: 'pick' },
        onboard({ pick: 'back', onboardAsk: { style: false, age: false, gender: true, job: true } }),
      ),
    ).toBe(CoachStep.ONBOARD_CURRENT);
    expect(advance(CoachStep.ONBOARD_BARRIER, { kind: 'pick' }, onboard({ pick: 'back' }))).toBe(
      CoachStep.ONBOARD_ADDRESS,
    );
  });

  // "Gọi mình là Mai" — a name, confirmed before it is used.
  it('confirms a typed name, and goes back when it was wrong', () => {
    expect(
      advance(CoachStep.ONBOARD_ADDRESS, { kind: 'text' }, onboard({ onboardNamed: true })),
    ).toBe(CoachStep.ONBOARD_ADDRESS_CONFIRM);
    expect(
      advance(CoachStep.ONBOARD_ADDRESS, { kind: 'text' }, onboard({ onboardNamed: false })),
    ).toBe(CoachStep.ONBOARD_BARRIER);
    expect(
      advance(CoachStep.ONBOARD_ADDRESS_CONFIRM, { kind: 'pick' }, onboard({ pick: 'yes' })),
    ).toBe(CoachStep.ONBOARD_BARRIER);
    expect(
      advance(CoachStep.ONBOARD_ADDRESS_CONFIRM, { kind: 'pick' }, onboard({ pick: 'no' })),
    ).toBe(CoachStep.ONBOARD_ADDRESS);
  });

  // A question typed at the introduction is answered, and the questions begin.
  it('answers a question at the introduction, then begins', () => {
    expect(advance(CoachStep.ONBOARD_INTRO, { kind: 'text' }, onboard())).toBe(
      CoachStep.ONBOARD_ADDRESS,
    );
  });
});

describe('coach state machine — T4 and the closing sequence', () => {
  it('the commitment is offered; declining depends on where it was asked', () => {
    expect(
      advance(CoachStep.PLAN_ASK, { kind: 'planAsk', accept: true }, homeB()),
    ).toBe(CoachStep.PLAN);
    // PARKED (luồng 4 retired the commitment at Home): a session standing on
    // the question still walks out — and Home has no tail, so out is END.
    expect(
      advance(
        CoachStep.PLAN_ASK,
        { kind: 'planAsk', accept: false },
        homeB({ closing: true }),
      ),
    ).toBe(CoachStep.STORY_TALK);
    expect(
      advance(CoachStep.PLAN_ASK, { kind: 'planAsk', accept: false }, homeB()),
    ).toBe(CoachStep.STORY_TALK);
  });

  it('the parked form still leads to the schedule, then out', () => {
    expect(advance(CoachStep.PLAN, { kind: 'plan' }, homeB())).toBe(
      CoachStep.SCHEDULE,
    );
    expect(advance(CoachStep.SCHEDULE, { kind: 'schedule' }, homeB())).toBe(
      CoachStep.STORY_TALK,
    );
    expect(
      advance(CoachStep.SCHEDULE, { kind: 'schedule' }, homeB({ closing: true })),
    ).toBe(CoachStep.STORY_TALK);
  });

  it('① closes on its own line — no card, no mood, no rating', () => {
    expect(
      advance(CoachStep.SCHEDULE, { kind: 'schedule' }, lesson({ closing: true })),
    ).toBe(CoachStep.END);
    expect(advance(CoachStep.HUB, { kind: 'stop' }, lesson())).toBe(CoachStep.END);
  });

  it('the card is the last thing before the end, and shown only once', () => {
    expect(
      advance(CoachStep.HUB, { kind: 'stop' }, homeB({ hasCourse: true, hasDip: true })),
    ).toBe(CoachStep.COURSE_CARD);
    // Save or close → the session ends; no commitment question follows.
    expect(
      advance(
        CoachStep.COURSE_CARD,
        { kind: 'course', open: false },
        homeB({ hasCourse: true, cardShown: true, hasDip: true }),
      ),
    ).toBe(CoachStep.STORY_TALK);
    // "Học ngay" ends the session on the spot — the app navigates to the
    // course itself; there is no LEAVE beat any more.
    expect(
      advance(
        CoachStep.COURSE_CARD,
        { kind: 'course', open: true },
        homeB({ hasCourse: true, cardShown: true }),
      ),
    ).toBe(CoachStep.END);
  });

  // PARKED tail (mood-end → next session): Home no longer enters it (luồng 4),
  // but a session standing in it still walks the arrows. The rating detour that
  // used to sit in the middle is gone — a story told no longer changes where
  // mood-end leads, because the ask moved to the way out.
  it('the parked tail still walks its arrows', () => {
    expect(advance(CoachStep.MOOD_END, { kind: 'moodEnd' }, homeB())).toBe(
      CoachStep.NEXT_SESSION,
    );
    expect(
      advance(CoachStep.MOOD_END, { kind: 'moodEnd' }, homeB({ storyTold: true })),
    ).toBe(CoachStep.NEXT_SESSION);
  });

  it('a new session goes back to the first task; stopping ends', () => {
    expect(
      advance(CoachStep.NEXT_SESSION, { kind: 'nextSession', again: true }, homeB()),
    ).toBe(CoachStep.HUB);
    expect(
      advance(CoachStep.NEXT_SESSION, { kind: 'nextSession', again: false }, homeB()),
    ).toBe(CoachStep.END);
  });

  it('a low mood-end hides "phiên mới" — and refuses it if sent anyway', () => {
    expect(
      advance(
        CoachStep.NEXT_SESSION,
        { kind: 'nextSession', again: true },
        homeB({ moodEndLow: true }),
      ),
    ).toBeNull();
  });
});

describe('coach state machine — guards and rendering', () => {
  it('rejects events that do not belong to the step', () => {
    expect(advance(CoachStep.MOOD, { kind: 'text' }, homeB())).toBeNull();
    expect(advance(CoachStep.STORY, { kind: 'mood' }, homeB())).toBeNull();
    expect(advance(CoachStep.END, { kind: 'text' }, homeB())).toBeNull();
  });

  it('⑥ is not offered anywhere', () => {
    for (const step of Object.values(CoachStep)) {
      expect(isEscapeAvailable(step)).toBe(false);
    }
  });

  it('knows which free-text answers cost a model call', () => {
    expect(requiresAi(CoachStep.TELL_2)).toBe(true);
    expect(requiresAi(CoachStep.TELL_ONCE)).toBe(true);
    // The feeling is acknowledged with a fixed line — no model call.
    expect(requiresAi(CoachStep.SCENE_FEELING)).toBe(false);
    expect(requiresAi(CoachStep.SCENE_STAGE2)).toBe(true);
    // 6b's answer earns the mirror; a telling typed at 6a earns the same one.
    expect(requiresAi(CoachStep.SCENE_DID)).toBe(true);
    expect(requiresAi(CoachStep.SCENE_MET)).toBe(true);
    // 6d's answer goes straight to the coordinator — no reply.
    expect(requiresAi(CoachStep.SCENE_CHANGE)).toBe(false);
    // Written lines, every one of them.
    expect(requiresAi(CoachStep.STORY)).toBe(false);
    expect(requiresAi(CoachStep.DEPTH)).toBe(false);
    expect(requiresAi(CoachStep.SCENE_WHEN)).toBe(false);
    expect(requiresAi(CoachStep.HUB)).toBe(false);
    expect(requiresAi(CoachStep.PLAN)).toBe(false);
  });

  it('maps every live step to the composer the design draws', () => {
    expect(uiFor(CoachStep.MOOD)).toBe(CoachUiKind.CHIPS);
    expect(uiFor(CoachStep.STORY)).toBe(CoachUiKind.TEXT_SKIPPABLE);
    expect(uiFor(CoachStep.DEPTH)).toBe(CoachUiKind.DEPTH);
    expect(uiFor(CoachStep.HUB)).toBe(CoachUiKind.HUB);
    expect(uiFor(CoachStep.SCENE_MET)).toBe(CoachUiKind.CHIPS);
    expect(uiFor(CoachStep.SCENE_STAGE2)).toBe(CoachUiKind.TEXT);
    expect(uiFor(CoachStep.SCENE_WHEN)).toBe(CoachUiKind.TEXT);
    expect(uiFor(CoachStep.TWO_COLS)).toBe(CoachUiKind.TWO_COLS);
    expect(uiFor(CoachStep.PLAN)).toBe(CoachUiKind.PLAN);
    expect(uiFor(CoachStep.SCHEDULE)).toBe(CoachUiKind.SCHEDULE);
    expect(uiFor(CoachStep.COURSE_CARD)).toBe(CoachUiKind.COURSE_CARD);
    expect(uiFor(CoachStep.RATING)).toBe(CoachUiKind.RATING);
    expect(uiFor(CoachStep.NEXT_SESSION)).toBe(CoachUiKind.NEXT_SESSION);
    expect(uiFor(CoachStep.END)).toBe(CoachUiKind.END);
  });

  it('keeps one scene pool for every mood — the third person is a field', () => {
    expect(situationVariantFor(CoachStep.TELL_ONCE, true)).toBe('default');
    expect(situationVariantFor(CoachStep.TELL_ONCE, false)).toBe('default');
    expect(situationVariantFor(CoachStep.RETRY_SCENE, false)).toBe('retry');
  });
});

/**
 * Bug owner gặp 2026-09-04 (sim): bấm ⟨Tóm tắt⟩ ở TALK_ASK ra "Có lỗi ở phía
 * mình". Bản app gửi mọi chip của khung hub bằng `pickTask` — một event `task`
 * — mà TALK_ASK chỉ nhận `pick`, nên advance() trả null và turn() 400.
 *
 * Client đã sửa để gửi `pick`; `turn()` cũng dịch dạng cũ sang `pick` để bản đã
 * cài chạy lại được sau khi deploy API. Spec này khoá cả hai đích của TALK_ASK.
 */
describe('advance · TALK_ASK', () => {
  const talk = (pick: string | null) => ctx({ pick } as Partial<CoachMachineContext>);

  it('⟨Tóm tắt⟩ → TALK_SUMMARY', () => {
    expect(advance(CoachStep.TALK_ASK, { kind: 'pick' }, talk('summary'))).toBe(
      CoachStep.TALK_SUMMARY,
    );
  });

  it('⟨Làm quiz⟩ → QUIZ_HANDOFF', () => {
    expect(advance(CoachStep.TALK_ASK, { kind: 'pick' }, talk('talkQuiz'))).toBe(
      CoachStep.QUIZ_HANDOFF,
    );
  });

  it('gõ chữ → thẳng QUIZ_HANDOFF', () => {
    expect(advance(CoachStep.TALK_ASK, { kind: 'text' }, talk(null))).toBe(
      CoachStep.QUIZ_HANDOFF,
    );
  });

  it('event `task` KHÔNG hợp lệ ở đây — turn() phải dịch trước', () => {
    expect(
      advance(CoachStep.TALK_ASK, { kind: 'task', task: 'T2' }, talk(null)),
    ).toBeNull();
  });
});

describe('chốt chặn hỏi ngược (owner 2026-09-05)', () => {
  it('cảnh KHÔNG chấm câu hỏi meta như thể đó là câu trả lời', () => {
    expect(
      advance(CoachStep.TELL_ONCE, { kind: 'text' }, homeB({ readerAsksBack: true })),
    ).toBe(CoachStep.TELL_ONCE);
  });

  it('trả lời thật thì vẫn đi tiếp như cũ', () => {
    expect(
      advance(CoachStep.TELL_ONCE, { kind: 'text' }, homeB({ readerAsksBack: false })),
    ).not.toBe(CoachStep.TELL_ONCE);
  });

  it('nhánh kể chuyện KHÔNG nằm trong tập bị giữ — hỏi ở đó là nội dung', () => {
    // Không khẳng định qua advance() được: afterStoryLine vốn trả về chính
    // STORY_TALK, nên bị giữ hay không cũng ra cùng một bước.
    expect(holdsOnQuestion(CoachStep.STORY_TALK)).toBe(false);
    expect(holdsOnQuestion(CoachStep.TELL_ONCE)).toBe(true);
  });

  it('asksBack: phân biệt được hỏi ngược với TÊN HABIT chứa "vì sao"', () => {
    expect(asksBack('sao lại hỏi thế?')).toBe(true);
    expect(asksBack('mình không hiểu câu hỏi')).toBe(true);
    expect(asksBack('ý là sao')).toBe(true);
    // Tên habit thật trong kho — nhận nhầm ở đây là khoá user lại giữa luồng.
    expect(asksBack('Giữ tò mò, hay đặt câu hỏi vì sao')).toBe(false);
    expect(asksBack('Xem sai lầm là một bài học')).toBe(false);
    expect(asksBack('mình sẽ nói với Hằng là để mai bàn lại')).toBe(false);
  });
});

/**
 * The predicate the story conversation's exit hangs on.
 *
 * It exists because the graph and the service used to answer "is this line a
 * request for a task?" separately, and disagreed: the service threw the model's
 * reply away whenever a route was detected, while the graph only moved when the
 * reader was ALSO allowed one. In the gap the reader's explicit "luyện tình
 * huống" got no answer at all — reply discarded, step unchanged, the step's
 * fallback line printed instead. Twice in one screen, on the owner's device.
 */
describe('storyTalkLeaves — asking to leave the story, and being allowed to', () => {
  it('leaves for a scene when they ask and may have one', () => {
    expect(storyTalkLeaves(ctx({ hubRoute: 'T2', hasHabit: true }))).toBe(true);
    expect(
      advance(CoachStep.STORY_TALK, { kind: 'text' }, ctx({ hubRoute: 'T2', hasHabit: true })),
    ).not.toBe(CoachStep.STORY_TALK);
  });

  it('leaves for the scene they already did, which wins over a fresh one', () => {
    const asking = ctx({ hubReplayScene: true, hubRoute: 'T2', hasHabit: true });

    expect(storyTalkLeaves(asking)).toBe(true);
    expect(advance(CoachStep.STORY_TALK, { kind: 'text' }, asking)).toBe(CoachStep.TELL_ONCE);
  });

  it('stays when the kho is empty — there is no scene to build', () => {
    expect(storyTalkLeaves(ctx({ hubRoute: 'T2', hasHabit: false }))).toBe(false);
  });

  it("stays when the evening's task budget is spent", () => {
    expect(
      storyTalkLeaves(ctx({ hubRoute: 'T2', hasHabit: true, tasksRun: TASK_RUN_LIMIT })),
    ).toBe(false);
  });

  it('stays for a route the conversation cannot open anyway', () => {
    // T1 and T4 are not reachable from inside the story; a line that merely
    // MENTIONS a reminder must be answered as the story it is, not swallowed.
    expect(storyTalkLeaves(ctx({ hubRoute: 'T1', hasHabit: true }))).toBe(false);
    expect(storyTalkLeaves(ctx({ hubRoute: 'T4', hasHabit: true }))).toBe(false);
  });

  it('stays when nothing was asked for', () => {
    expect(storyTalkLeaves(ctx({ hasHabit: true }))).toBe(false);
    expect(
      advance(CoachStep.STORY_TALK, { kind: 'text' }, ctx({ hasHabit: true })),
    ).toBe(CoachStep.STORY_TALK);
  });
});

/**
 * Leaving a scene, which is meant to be hard.
 *
 * "Bắt buộc user hoàn thành tình huống nếu user bảo là cho tôi tình huống khác
 * thì mới sang tình huống khác" (owner, 2026-09-08). Mid-scene every line is
 * the ANSWER — it is what `sceneFirstLine` files and what the verdict reads —
 * so a request typed there was being graded as though the reader had said it to
 * the person in the scene.
 */
describe('asksForAnotherScene — the one way out of a scene', () => {
  it('recognises the ask in the shapes people type it', () => {
    for (const said of [
      'cho tôi tình huống khác',
      'tình huống khác đi',
      'đổi tình huống',
      'cho mình cảnh mới',
      'thay bài tập khác',
      'give me another scene',
      'a different situation please',
    ]) {
      expect(asksForAnotherScene(said)).toBe(true);
    }
  });

  it('leaves an actual answer alone', () => {
    for (const said of [
      'Tớ nói là để tớ tự chữa trước đã.',
      'Mình sẽ bảo Nam là cảm ơn nhưng tự làm.',
      'không biết nói gì',
      'ngại',
    ]) {
      expect(asksForAnotherScene(said)).toBe(false);
    }
  });

  it('yields to "tình huống cũ", which asks for a specific scene', () => {
    // A line carrying both is asking to go BACK, not to move on — and that
    // request has its own route.
    expect(asksForAnotherScene('cho mình lại tình huống cũ')).toBe(false);
    expect(asksForOldScene('cho mình lại tình huống cũ')).toBe(true);
  });

  it('swaps the scene when asked and allowed', () => {
    const asking = ctx({ sceneSwapAsked: true, hasHabit: true });

    expect(advance(CoachStep.SCENE_STAGE2, { kind: 'text' }, asking)).toBe(
      CoachStep.TELL_ONCE,
    );
    expect(advance(CoachStep.TELL_ONCE, { kind: 'text' }, asking)).toBe(
      CoachStep.TELL_ONCE,
    );
  });

  it('HOLDS the step when the ask cannot be granted, so the line is not scored', () => {
    const spent = ctx({
      sceneSwapAsked: true,
      hasHabit: true,
      tasksRun: TASK_RUN_LIMIT,
    });

    // Not the verdict, not stage two — the same step, and the turn's reply says
    // why. Advancing here would file the request as the scene's answer.
    expect(advance(CoachStep.TELL_ONCE, { kind: 'text' }, spent)).toBe(
      CoachStep.TELL_ONCE,
    );
    expect(advance(CoachStep.SCENE_STAGE2, { kind: 'text' }, spent)).toBe(
      CoachStep.SCENE_STAGE2,
    );
  });

  it('does not touch a scene when nothing was asked', () => {
    const answering = ctx({ hasHabit: true, sceneAwaitingSecondLine: true });

    expect(advance(CoachStep.TELL_ONCE, { kind: 'text' }, answering)).toBe(
      CoachStep.SCENE_STAGE2,
    );
  });
});
