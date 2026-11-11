import { AsyncLocalStorage } from 'node:async_hooks';

/**
 * How long one reader-facing coach request may spend on the provider, all
 * calls together.
 *
 * The number comes from the OTHER end of the wire. The app's Dio client gives
 * up at 30s (`RECEIVE_TIMEOUT` in every flavour's env), and the server had no
 * matching ceiling at all: each provider call carried its own 15s timeout and
 * the retries stacked on top of each other. A STORY_TALK turn that hit every
 * retry it is allowed — reply, echo rewrite, banned-question gate, regenerate,
 * gate again — could spend 57 seconds, and a scene generation that hit all four
 * of its rewrites could spend 60. Both are past the point where the app has
 * stopped listening, so the work was finished, billed, and thrown away, while
 * the reader saw the three dots die.
 *
 * 20s leaves ten seconds of the app's budget for everything that is not the
 * provider: the database reads around the turn, the response, a slow phone on
 * a slow network. A turn that cannot be answered inside 20s is not going to be
 * answered inside 30 either — better to send the fallback while somebody is
 * still there to read it.
 */
export const COACH_REQUEST_BUDGET_MS = 20_000;

interface CoachDeadline {
  deadlineAt: number;
}

const storage = new AsyncLocalStorage<CoachDeadline>();

/**
 * Run one reader-facing request under a shared time budget.
 *
 * `AsyncLocalStorage` rather than a `deadline` parameter threaded through the
 * call chain: the provider call sits four services below the controller, behind
 * some twenty method signatures that have nothing to do with time. And rather
 * than a `Scope.REQUEST` provider, which Nest bubbles UP the whole dependency
 * graph — this codebase has been bitten by that twice already and both scars
 * are commented (`notification-campaign.service.ts`, `week-recap.service.ts`).
 */
export function withCoachDeadline<T>(
  budgetMs: number,
  run: () => Promise<T>,
): Promise<T> {
  return storage.run({ deadlineAt: Date.now() + budgetMs }, run);
}

/**
 * Run something OUTSIDE the current budget.
 *
 * The trap this exists for: an async context follows a promise nobody awaited
 * just as faithfully as one somebody did. Coach deliberately starts work off
 * the reader's clock mid-turn — the next quiz is written now so tomorrow's is
 * waiting (40s of its own), and the session's memory is extracted after the
 * reply has gone out. Both are launched from inside a turn, so both would
 * inherit that turn's remaining milliseconds and be killed by a ceiling meant
 * for somebody who is watching. Background work has to say so explicitly.
 */
export function detachedFromCoachDeadline<T>(run: () => T): T {
  return storage.exit(run);
}

/**
 * Milliseconds left in the current budget, or null when there is no budget.
 *
 * Null is the honest answer for everything that is not a reader-facing request
 * — the admin's scene import, the schedulers, the background work above — and
 * it means "use your own timeout", not "you have no time".
 */
export function coachTimeLeftMs(): number | null {
  const store = storage.getStore();
  if (!store) return null;

  return Math.max(0, store.deadlineAt - Date.now());
}
