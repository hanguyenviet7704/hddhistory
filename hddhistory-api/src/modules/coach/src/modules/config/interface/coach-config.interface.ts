/**
 * One crisis line, for one audience.
 *
 * `country` narrows a locale: Chinese readers in different territories do not
 * share a number, and "the Vietnamese line" is useless to a Vietnamese speaker
 * living abroad. Null country = the fallback for that locale.
 */
export interface ICoachHotline {
  locale: string;
  country?: string | null;
  label: string;
  number: string;
}

export interface ICoachConfig {
  configKey: string;
  /** Master switch. Off = the bubble never renders and the endpoints 403. */
  enabled: boolean;
  hotlines: ICoachHotline[];
  /**
   * Gemini model for the Coach's conversational calls, editable from admin so
   * a model swap needs no env change and no deploy. Null/empty = fall back to
   * the GEMINI_MODEL env, then the code default.
   */
  geminiModel?: string | null;
  /**
   * Model for scene WRITING only — once per practice, the most
   * multi-constraint prompt in the coach, so it can afford a stronger model
   * than the every-turn replies. Null/empty = geminiModel, then the
   * GEMINI_SCENE_MODEL env, then the conversational model.
   */
  geminiSceneModel?: string | null;
  /**
   * Comma-separated, best first: where a call goes when its own model answers
   * 429/503. Null/empty = the GEMINI_FALLBACK_MODELS env, then the built-in
   * pair; `off` stops the hopping altogether.
   */
  geminiFallbackModels?: string | null;
  /** Luồng 1 — the four optional onboarding questions. */
  onboardAskStyle: boolean;
  onboardAskAge: boolean;
  onboardAskGender: boolean;
  onboardAskJob: boolean;
  /** Luồng 2 — follow-up questions allowed after the grading turn; 0 disables. */
  talkFreeMaxTurns: number;
  /**
   * Luồng 6 — how often the rating sheet may follow ⟨Vẫn đóng⟩.
   *
   * Every gate must pass, and each has a neutral value that switches it off, so
   * no number on the admin screen is ever quietly inert. See `shouldAskRating`.
   */
  ratingAskEnabled: boolean;
  ratingAskMinDays: number;
  ratingAskSnoozeDays: number;
  ratingAskEveryNthExit: number;
  ratingAskProbability: number;
  ratingAskMaxPerUser: number;
}
