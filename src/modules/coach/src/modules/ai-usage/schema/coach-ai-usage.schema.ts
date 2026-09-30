import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { CoachAiCallKind } from '../coach-ai-usage.enum';

/**
 * One row per AI call the coach makes, with what it cost.
 *
 * A row per call rather than a daily counter: the useful questions are "which
 * step is expensive" and "did the retry path double our bill", and a counter
 * cannot be re-cut by kind or model after the fact. Volume is one row per model
 * call, which is the same order as `coach_sessions` × a handful.
 *
 * Nothing here identifies a person. The call site that would know the reader is
 * four services away from the HTTP request, and threading a user id through ten
 * signatures to make a cost report slightly more granular is not a trade worth
 * making — cost per session and per user are read as averages instead, dividing
 * by the session counts that already exist.
 */
@Schema({ collection: 'coach_ai_usages' })
export class CoachAiUsage extends AbstractDocument {
  @Prop({ type: String, enum: CoachAiCallKind, required: true, index: true })
  kind: CoachAiCallKind;

  /** The alias actually called, so a model swap is visible in the numbers. */
  @Prop({ type: String, required: true })
  model: string;

  @Prop({ type: Number, default: 0, min: 0 })
  inputTokens: number;

  @Prop({ type: Number, default: 0, min: 0 })
  outputTokens: number;

  /**
   * Cost in đồng, computed at write time from the price list in force THEN.
   *
   * Stored rather than derived on read so a later price change does not silently
   * rewrite history: last month's bill was last month's rate, and a report that
   * shifts every time the constants move is a report nobody can reconcile.
   *
   * FRACTIONAL on purpose. The cheapest calls are also the most frequent — the
   * safety gate costs about 0.13 đồng and runs on every free-text turn — so a
   * value rounded here would be 0 for most rows and the total would be missing
   * every one of them. Rounding happens on the sum, at the report.
   */
  @Prop({ type: Number, default: 0, min: 0 })
  costVnd: number;

  /**
   * False when the call did not produce a usable answer.
   *
   * This used to mean only "the provider answered but the answer was unusable
   * — blocked, no text part, malformed JSON", because those are the failures
   * that cost money and a plain log cannot price them.
   *
   * That was too narrow, and the narrowness hid the failure that matters most
   * to a reader. A timeout and a 429/503 never reach the billing block at all,
   * so they were recorded NOWHERE — and every one of them is a turn that
   * answered the reader with silence (`runAi` catches `CoachAiError` and
   * returns `{ reply: null }`). The report said `failedCalls: 0` over 8,955
   * calls while turns were dying, which is worse than saying nothing.
   *
   * So every path records now. `errorCode` says which kind, and the unbilled
   * ones carry `costVnd: 0` — a failure that cost nothing is still a failure
   * somebody watched happen.
   */
  @Prop({ type: Boolean, default: true })
  ok: boolean;

  /**
   * Why the call failed, or null when it did not.
   *
   * The HTTP status as a string for a provider refusal ('429', '503', '500'),
   * or one of the named shapes the code itself decides: 'timeout' (our own
   * abort), 'blocked' (promptFeedback), 'no_text' (billed, no text part),
   * 'malformed' (billed, unparseable JSON), 'no_key'.
   *
   * Kept as a loose string rather than an enum on purpose: the interesting
   * value here is whichever status the provider invents next, and an enum would
   * quietly file it as "other" exactly when somebody needs to see it.
   */
  @Prop({ type: String, default: null })
  errorCode: string | null;

  /**
   * Round-trip milliseconds, provider time only.
   *
   * Recorded for failures too — a timeout's latency IS the timeout, and the
   * whole point of watching this number is to catch the ceiling being hit.
   */
  @Prop({ type: Number, default: 0, min: 0 })
  latencyMs: number;

  /**
   * Server-side calendar day, `YYYY-MM-DD`.
   *
   * The spend report is a finance question, not a per-reader one, so this is
   * deliberately server time — unlike every user-facing date in this feature,
   * which is the reader's own.
   */
  @Prop({ type: String, required: true, index: true })
  serverDate: string;
}

export const CoachAiUsageSchema = SchemaFactory.createForClass(CoachAiUsage);

// The only query the report makes: a date window, then grouped in memory.
CoachAiUsageSchema.index({ serverDate: 1, kind: 1 });
