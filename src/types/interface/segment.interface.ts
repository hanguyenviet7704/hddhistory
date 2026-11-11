/**
 * Audience segments — admin-only. A segment is a name plus criteria; membership
 * is always computed live server-side (never a stored member list), so the
 * shapes here mirror the API's `UpsertSegmentDto` / `SegmentCriteriaDto`
 * exactly. See hddhistory-api `src/modules/segment/`.
 */

export type SegmentDeviceType = "ios" | "android";

/** Mirrors the API's `USER_TYPES` in `segment-match.util.ts`. */
export type SegmentUserType =
  | "pro_lifetime"
  | "pro_subscription"
  | "free_logged_in"
  | "free_guest";

/**
 * Every field optional; unset/empty = no filter on that criterion. All set
 * criteria are AND-ed together server-side.
 */
export interface SegmentCriteria {
  /** ISO date string, or null for an open bound. */
  firstSessionFrom?: string | null;
  firstSessionTo?: string | null;
  lastSessionFrom?: string | null;
  lastSessionTo?: string | null;
  /** Lowercase device-language codes, e.g. "vi". */
  languages?: string[];
  /** Uppercase ISO-3166 alpha-2, e.g. "VN". */
  countries?: string[];
  deviceTypes?: SegmentDeviceType[];
  /** Days since first session (D0, D1, …), inclusive bounds. */
  lifecycleFrom?: number | null;
  lifecycleTo?: number | null;
  /** Explicit Mongo ObjectId allow-list — invalid ids are dropped server-side. */
  userIds?: string[];
  /** Onboarding learning-goal answer ids. */
  userGoals?: number[];
  /** Onboarding category ("topic") ids — ANY match. */
  topicIds?: number[];
  userTypes?: SegmentUserType[];
}

export interface ISegment {
  _id: string;
  name: string;
  criteria?: SegmentCriteria;
  createdAt: string;
  updatedAt: string;
}

export interface SegmentPayload {
  name: string;
  criteria?: SegmentCriteria;
}

/** Minimal shape for pickers (Home banner/popup targeting) — see `SegmentOption`. */
export interface SegmentOption {
  _id: string;
  name: string;
}

/** GET /segments/:id/stats — count is computed live, history is nightly snapshots. */
export interface SegmentStats {
  count: number;
  history: Array<{ date: string; count: number }>;
}

/** GET /segments/overlap?a=&b= */
export interface SegmentOverlap {
  a: { id: string; name: string; count: number };
  b: { id: string; name: string; count: number };
  intersection: number;
}
