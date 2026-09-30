import { CoachSessionKind } from './enum/rating.enum';
import { CoachStep } from '../../shared/coach.enum';

/**
 * Steps that belong to telling today's story, and to everything the story leads
 * into — the two columns, the barrier, the commitment and its reminder.
 *
 * Listed rather than matched by prefix because these names have no shared one:
 * `twoCols`, `barrier` and `plan` are the same conversation to a reader and
 * nothing in their spelling says so.
 */
const STORY_STEPS: ReadonlySet<string> = new Set([
  CoachStep.STORY,
  CoachStep.DEPTH,
  CoachStep.STORY_TALK,
  CoachStep.TELL,
  CoachStep.TELL_2,
  CoachStep.TWO_COLS,
  CoachStep.REDRAFT,
  CoachStep.BARRIER,
  CoachStep.SHRINK_ASK,
  CoachStep.SHRINK,
  CoachStep.CONTEXT_ASK,
  CoachStep.CONTEXT_EDIT,
  CoachStep.INTENT,
  CoachStep.INTENT_TELL,
  CoachStep.CHECKIN,
  CoachStep.CHECKIN_ASK,
  CoachStep.CHECKIN_TELL,
  CoachStep.CHECKIN_OFFER,
  CoachStep.FREE,
  CoachStep.JOT,
  CoachStep.NEXT_ACTION,
  CoachStep.PLAN_ASK,
  CoachStep.PLAN,
  CoachStep.SCHEDULE,
  CoachStep.LOOP,
]);

/**
 * What the reader was doing when they closed the Coach.
 *
 * Five buckets over ~70 steps, because the rating sheet asks its question per
 * bucket and a reader cannot tell `sceneStage2` from `sceneMet`. The prefixes do
 * the work where the enum already groups by name; `STORY_STEPS` covers the one
 * flow whose steps are named after their own beats.
 *
 * The default is HUB — "chưa chọn gì" — and that is deliberate for a step this
 * function does not recognise: a retired step from a parked session says nothing
 * about what the reader was doing, and guessing STORY would put words in their
 * mouth. Falling back to "started nothing" understates rather than invents.
 */
export function sessionKindOf(step: CoachStep | string | null | undefined): CoachSessionKind {
  if (!step) return CoachSessionKind.HUB;

  const name = String(step);

  if (name.startsWith('onboard')) return CoachSessionKind.ONBOARD;
  if (name.startsWith('scene') || name.startsWith('tellOnce')) return CoachSessionKind.SCENE;
  if (name === CoachStep.PRACTICE_ANSWER || name === CoachStep.RETRY_SCENE) {
    return CoachSessionKind.SCENE;
  }
  if (name.startsWith('recap') || name.startsWith('quiz') || name.startsWith('talk')) {
    return CoachSessionKind.RECAP;
  }
  if (STORY_STEPS.has(name)) return CoachSessionKind.STORY;

  return CoachSessionKind.HUB;
}
