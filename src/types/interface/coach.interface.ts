/** One crisis line. `country` narrows a locale; absent = that locale's fallback. */
export interface CoachHotline {
  locale: string;
  country?: string | null;
  label: string;
  number: string;
}

export interface CoachConfig {
  enabled: boolean;
  hotlines: CoachHotline[];
}

export type CoachSituationVariant =
  | "default"
  | "third_person"
  | "after_done"
  | "after_missed"
  | "after_none"
  | "practice";

export interface CoachSituation {
  _id: string;
  habitId: string;
  locale: string;
  variant: CoachSituationVariant;
  prompt: string;
  /** `generated` = the model's first guess. `edited` = a person fixed it, and generation will never overwrite it again. */
  source: "generated" | "edited";
  createdAt?: string;
  updatedAt?: string;
}

export type CoachRatingChip =
  | "imposed_thinking"
  | "felt_judged"
  | "missed_the_point"
  | "pushed_too_hard";

export interface CoachRating {
  _id: string;
  userId: string;
  sessionId: string;
  thumb: "up" | "down";
  chips: CoachRatingChip[];
  needsReview: boolean;
  createdAt?: string;
}
