/**
 * What a coach AI call costs, in code rather than config.
 *
 * Same choice `LearningImportRunnerService` made and for the same reason: the
 * number only changes when Google changes its price list, which is a deploy-shaped
 * event, not an operator-shaped one. The tradeoff is real — a price change makes
 * every row written before the deploy cheaper or dearer than reality — which is
 * why the rate used is STORED on each row (see the schema) instead of being
 * re-applied at read time.
 */

/** USD per million tokens, per model. Gemini pricing as of 2026-08. */
const MODEL_PRICES: Record<string, { input: number; output: number }> = {
  'gemini-flash-latest': { input: 0.075, output: 0.3 },
  // The classifier model: ~3x cheaper, which is the whole reason the risk and
  // meaning-question gates run on it instead of the conversational model.
  'gemini-flash-lite-latest': { input: 0.025, output: 0.1 },
};

/**
 * Charged when the model is one nothing here has a price for.
 *
 * The conversational model's rate, not zero: an unpriced model is almost always
 * a NEW alias Google shifted us onto, and reporting it as free would quietly
 * understate the bill exactly when somebody needs to notice it. Overstating a
 * cheap model is the safer error.
 */
const FALLBACK_PRICE = MODEL_PRICES['gemini-flash-latest'];

export const USD_TO_VND = 26_000;

export function priceFor(model: string): { input: number; output: number } {
  return MODEL_PRICES[model] ?? FALLBACK_PRICE;
}

/** Whether this model has a real price or is being charged at the fallback. */
export function isPricedModel(model: string): boolean {
  return Boolean(MODEL_PRICES[model]);
}

/**
 * Exact cost in đồng, deliberately NOT rounded.
 *
 * The import feature rounds, and can afford to: it prices one big call per job.
 * Here the cheapest calls are the most frequent — the safety gate runs on every
 * free-text turn and costs about 0.13 đồng — so rounding per call would store 0
 * for each of them and understate the bill by every gate call ever made.
 * Rounding happens once, at the edge, on sums (see `CoachAiUsageService`).
 */
export function estimateCostVnd(usage: {
  model: string;
  inputTokens: number;
  outputTokens: number;
}): number {
  const price = priceFor(usage.model);
  const usd =
    (usage.inputTokens / 1_000_000) * price.input +
    (usage.outputTokens / 1_000_000) * price.output;

  return usd * USD_TO_VND;
}
