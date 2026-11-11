/**
 * Whether to ask this reader to rate the Coach on the way out.
 *
 * A pure function on purpose: it is the one piece of the rating flow a person
 * in admin can change without a deploy, so it has to be readable on its own and
 * testable without a database. The service around it supplies the row and the
 * clock; nothing here reaches for either.
 */

/** The admin-facing knobs, each with a neutral value that switches it off. */
export interface RatingAskConfig {
  /** The master switch. */
  ratingAskEnabled: boolean;
  /** Days to wait after an answer. 0 turns the wait off. */
  ratingAskMinDays: number;
  /** Days to wait after ⟨Để sau⟩. 0 turns the wait off. */
  ratingAskSnoozeDays: number;
  /** Ask on every Nth exit. 1 means every exit. */
  ratingAskEveryNthExit: number;
  /** Percentage of otherwise-eligible exits that get asked. 100 asks them all. */
  ratingAskProbability: number;
  /** Asks per reader before the question retires. 0 means no ceiling. */
  ratingAskMaxPerUser: number;
}

/** What this reader has done with the question so far. */
export interface RatingAskState {
  ratingAskedAt?: Date | null;
  ratingSnoozedAt?: Date | null;
  ratingAskCount: number;
  exitCount: number;
}

const DAY_MS = 24 * 60 * 60 * 1000;

const daysSince = (from: Date | null | undefined, now: Date): number | null => {
  if (!from) return null;

  return (now.getTime() - new Date(from).getTime()) / DAY_MS;
};

/**
 * Every gate must pass.
 *
 * AND rather than a mode picker so no knob can sit on the screen doing nothing:
 * an admin who only wants a day-cooldown leaves the rest at their neutral
 * values, and every number they can see is a number that still means something.
 *
 * `roll` is injected so the probability gate is testable; callers pass
 * `Math.random`.
 */
export function shouldAskRating(params: {
  config: RatingAskConfig;
  state: RatingAskState;
  now: Date;
  roll: () => number;
}): boolean {
  const { config, state, now, roll } = params;

  if (!config.ratingAskEnabled) return false;

  // The ceiling is the reader's own answer — somebody asked their last time is
  // never asked again, whatever the other knobs say.
  if (config.ratingAskMaxPerUser > 0 && state.ratingAskCount >= config.ratingAskMaxPerUser) {
    return false;
  }

  const sinceAnswer = daysSince(state.ratingAskedAt, now);
  if (config.ratingAskMinDays > 0 && sinceAnswer !== null && sinceAnswer < config.ratingAskMinDays) {
    return false;
  }

  const sinceSnooze = daysSince(state.ratingSnoozedAt, now);
  if (
    config.ratingAskSnoozeDays > 0 &&
    sinceSnooze !== null &&
    sinceSnooze < config.ratingAskSnoozeDays
  ) {
    return false;
  }

  // The exit about to happen, not the ones already counted: a reader with two
  // exits on file is leaving for the third time, and N=3 means this is the one.
  const nth = config.ratingAskEveryNthExit;
  if (nth > 1 && (state.exitCount + 1) % nth !== 0) return false;

  // Compared as a fraction so 0 closes the gate and 100 opens it, without the
  // caller having to know which end is exclusive.
  const probability = config.ratingAskProbability;
  if (probability <= 0) return false;
  if (probability < 100 && roll() >= probability / 100) return false;

  return true;
}
