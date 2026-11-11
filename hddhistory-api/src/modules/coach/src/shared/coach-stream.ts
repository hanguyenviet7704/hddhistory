import { AsyncLocalStorage } from 'node:async_hooks';

/**
 * Where a turn's text goes while it is still being written.
 *
 * A PREVIEW channel, and nothing more. The REST response stays the source of
 * truth for the whole turn — the reply, the chips, the scene, the step the
 * machine moved to — exactly as it is today. What goes through here is the
 * prose, early, so the reader has something to read during the four to thirteen
 * seconds the model takes; when the real response lands the client replaces the
 * preview with it.
 *
 * Three things fall out of that, all of them good:
 *
 * - An app that knows nothing about this keeps working unchanged. Build 1.6.3 is
 *   on the store right now speaking plain REST, and it must not care.
 * - A socket that will not connect costs the reader the effect, never the answer.
 * - The gates keep their veto. Nothing streamed here is authoritative, so a
 *   reply the banned-question gate throws away is corrected by the response that
 *   follows — and `CoachSentenceHold` has already kept the forbidden sentence
 *   itself off the screen.
 */
export interface CoachStreamSink {
  /** Text the reader may see now. Never the sentence still under judgement. */
  push(delta: string): void;
}

const storage = new AsyncLocalStorage<CoachStreamSink>();

/**
 * Runs a turn with a preview channel open.
 *
 * Same mechanism as the time budget next door, for the same reason: the model
 * call sits four services below the controller, and neither a `sink` parameter
 * on twenty signatures nor a request-scoped provider is worth what it costs.
 * See the note in `coach-deadline.ts`.
 */
export function withCoachStream<T>(
  sink: CoachStreamSink,
  run: () => Promise<T>,
): Promise<T> {
  return storage.run(sink, run);
}

/** The open channel, or null when nobody is watching this call. */
export function coachStreamSink(): CoachStreamSink | null {
  return storage.getStore() ?? null;
}
