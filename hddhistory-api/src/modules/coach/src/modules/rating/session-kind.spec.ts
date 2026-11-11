import { CoachSessionKind } from './enum/rating.enum';
import { sessionKindOf } from './session-kind';
import { CoachStep } from '../../shared/coach.enum';

describe('sessionKindOf', () => {
  const cases: [CoachStep, CoachSessionKind][] = [
    // Onboarding — every question of luồng 1.
    [CoachStep.ONBOARD_INTRO, CoachSessionKind.ONBOARD],
    [CoachStep.ONBOARD_ADDRESS, CoachSessionKind.ONBOARD],
    [CoachStep.ONBOARD_JOB, CoachSessionKind.ONBOARD],

    // The scene: its beats, both rehearsal doors, and the score at its tail.
    [CoachStep.SCENE_FEELING, CoachSessionKind.SCENE],
    [CoachStep.SCENE_STAGE2, CoachSessionKind.SCENE],
    [CoachStep.SCENE_SCORE, CoachSessionKind.SCENE],
    [CoachStep.TELL_ONCE, CoachSessionKind.SCENE],
    [CoachStep.TELL_ONCE_B, CoachSessionKind.SCENE],
    [CoachStep.PRACTICE_ANSWER, CoachSessionKind.SCENE],
    [CoachStep.RETRY_SCENE, CoachSessionKind.SCENE],

    // Recap and the lesson talk that ends in one.
    [CoachStep.RECAP_PICK, CoachSessionKind.RECAP],
    [CoachStep.RECAP_QUIZ, CoachSessionKind.RECAP],
    [CoachStep.QUIZ_IN_CHAT, CoachSessionKind.RECAP],
    [CoachStep.QUIZ_RUN, CoachSessionKind.RECAP],
    [CoachStep.TALK_SUMMARY, CoachSessionKind.RECAP],
    [CoachStep.TALK_FREE, CoachSessionKind.RECAP],

    // Telling today's story, and everything the story leads into.
    [CoachStep.STORY, CoachSessionKind.STORY],
    [CoachStep.DEPTH, CoachSessionKind.STORY],
    [CoachStep.STORY_TALK, CoachSessionKind.STORY],
    [CoachStep.TWO_COLS, CoachSessionKind.STORY],
    [CoachStep.BARRIER, CoachSessionKind.STORY],
    [CoachStep.INTENT_TELL, CoachSessionKind.STORY],
    [CoachStep.CHECKIN_TELL, CoachSessionKind.STORY],
    [CoachStep.PLAN, CoachSessionKind.STORY],
    [CoachStep.SCHEDULE, CoachSessionKind.STORY],

    // Nothing chosen yet — the hub and the beats around it.
    [CoachStep.HUB, CoachSessionKind.HUB],
    [CoachStep.MOOD, CoachSessionKind.HUB],
    [CoachStep.INVITE, CoachSessionKind.HUB],
    [CoachStep.END, CoachSessionKind.HUB],
    [CoachStep.COURSE_CARD, CoachSessionKind.HUB],
  ];

  it.each(cases)('%s → %s', (step, kind) => {
    expect(sessionKindOf(step)).toBe(kind);
  });

  it('a retired step nobody mapped falls back to "chưa chọn gì" rather than throwing', () => {
    expect(sessionKindOf('somethingRetired' as CoachStep)).toBe(CoachSessionKind.HUB);
  });

  it('null is the same fallback — a session with no step is not a story', () => {
    expect(sessionKindOf(null)).toBe(CoachSessionKind.HUB);
  });

  it('every step in the enum maps to something', () => {
    for (const step of Object.values(CoachStep)) {
      expect(Object.values(CoachSessionKind)).toContain(sessionKindOf(step));
    }
  });
});
