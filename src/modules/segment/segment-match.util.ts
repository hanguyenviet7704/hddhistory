/**
 * Segment membership, as a pure function over one viewer's facts.
 *
 * Two consumers with very different budgets share these rules: the Home
 * banner/popup serve path evaluates ONE user per request (this file), while
 * the admin's member COUNT compiles the same criteria into a Mongo filter
 * (`segment.service.ts`). Keeping the rules in data-shaped criteria + one
 * matcher is what keeps those two answers from drifting.
 */

/** The four audience buckets of the segment spec, mutually exclusive. */
export const USER_TYPES = [
  'pro_lifetime',
  'pro_subscription',
  'free_logged_in',
  'free_guest',
] as const;

export type UserType = (typeof USER_TYPES)[number];

/**
 * Every criterion is optional, and an unset criterion filters nothing — a
 * segment with empty criteria is "everyone". Set criteria AND together.
 */
export interface SegmentCriteriaShape {
  /** First contact with the server (user.createdAt). */
  firstSessionFrom?: Date | null;
  firstSessionTo?: Date | null;
  /** Most recent contact (user.lastAction.time, falling back to updatedAt). */
  lastSessionFrom?: Date | null;
  lastSessionTo?: Date | null;
  /** App language codes, lowercase (vi, en, …). */
  languages?: string[];
  /** ISO-3166 alpha-2, uppercase. */
  countries?: string[];
  /** 'ios' | 'android' — from the devices' pushPlatform. */
  deviceTypes?: string[];
  /** Lifecycle stage in DAYS since first session: D0..D30+ inclusive bounds. */
  lifecycleFrom?: number | null;
  lifecycleTo?: number | null;
  /** Explicit user-id allow-list. */
  userIds?: string[];
  /** onboarding.learningGoal answer ids. */
  userGoals?: number[];
  /** onboarding.skillsetWantToMaster ids ("chủ đề" ≈ skillset), ANY match. */
  topicIds?: number[];
  /** Audience buckets — see USER_TYPES. */
  userTypes?: string[];
}

/** One viewer, reduced to exactly what the criteria can ask about. */
export interface ViewerFacts {
  userId: string;
  firstSessionAt?: Date | null;
  lastSessionAt?: Date | null;
  language: string;
  country: string;
  deviceTypes: string[];
  userType: UserType;
  learningGoal?: number | null;
  topicIds: number[];
}

/** Whole days since the first session — the D of "D0, D1, … D30". */
export function lifecycleDayOf(
  firstSessionAt: Date | null | undefined,
  now: Date,
): number | null {
  if (!firstSessionAt) return null;
  const ms = now.getTime() - new Date(firstSessionAt).getTime();
  if (ms < 0) return null;

  return Math.floor(ms / 86_400_000);
}

function inDateRange(
  value: Date | null | undefined,
  from?: Date | null,
  to?: Date | null,
): boolean {
  if (!from && !to) return true;
  // A bounded criterion excludes a viewer the fact is unknown for — the admin
  // asked for "people who X", and someone we cannot place is not provably one.
  if (!value) return false;
  const at = new Date(value).getTime();
  if (from && at < new Date(from).getTime()) return false;
  if (to && at > new Date(to).getTime()) return false;

  return true;
}

function listMatches(list: string[] | undefined, value: string): boolean {
  if (!list || list.length === 0) return true;

  return Boolean(value) && list.includes(value);
}

/** Whether this viewer belongs to a segment with these criteria. */
export function matchesCriteria(
  criteria: SegmentCriteriaShape | null | undefined,
  facts: ViewerFacts,
  now = new Date(),
): boolean {
  if (!criteria) return true;

  if (
    !inDateRange(
      facts.firstSessionAt,
      criteria.firstSessionFrom,
      criteria.firstSessionTo,
    )
  ) {
    return false;
  }
  if (
    !inDateRange(
      facts.lastSessionAt,
      criteria.lastSessionFrom,
      criteria.lastSessionTo,
    )
  ) {
    return false;
  }

  if (!listMatches(criteria.languages, facts.language)) return false;
  if (!listMatches(criteria.countries, facts.country)) return false;

  if (criteria.deviceTypes && criteria.deviceTypes.length > 0) {
    const owned = facts.deviceTypes.some(type =>
      criteria.deviceTypes.includes(type),
    );
    if (!owned) return false;
  }

  const lifecycleBounded =
    criteria.lifecycleFrom != null || criteria.lifecycleTo != null;
  if (lifecycleBounded) {
    const day = lifecycleDayOf(facts.firstSessionAt, now);
    if (day == null) return false;
    if (criteria.lifecycleFrom != null && day < criteria.lifecycleFrom) {
      return false;
    }
    if (criteria.lifecycleTo != null && day > criteria.lifecycleTo) {
      return false;
    }
  }

  if (criteria.userIds && criteria.userIds.length > 0) {
    if (!criteria.userIds.includes(facts.userId)) return false;
  }

  if (criteria.userGoals && criteria.userGoals.length > 0) {
    if (
      facts.learningGoal == null ||
      !criteria.userGoals.includes(facts.learningGoal)
    ) {
      return false;
    }
  }

  if (criteria.topicIds && criteria.topicIds.length > 0) {
    const follows = facts.topicIds.some(id => criteria.topicIds.includes(id));
    if (!follows) return false;
  }

  if (criteria.userTypes && criteria.userTypes.length > 0) {
    if (!criteria.userTypes.includes(facts.userType)) return false;
  }

  return true;
}
