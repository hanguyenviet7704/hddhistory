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
  /** Who the scene was written for — the age band and onboarding goal keys. */
  audience?: string;
  goalKey?: string;
  /** Position in the habit's pool (0-based); the pool holds at most a few per key. */
  slot?: number;
  prompt: string;
  /** Two tappable opener suggestions shown with the scene. */
  samples?: string[];
  /** The scene script: 2–4 ordered probe intents the Coach walks after the first answer. */
  beats?: string[];
  /** What the other person SAYS at each beat, index-aligned with `beats`. "" = probe. */
  beatLines?: string[];
  /** Who those lines belong to, as the scene names them. */
  counterpart?: string | null;
  /** Difficulty band 1–5, from the skill's own ladder. */
  level?: number | null;
  /** The lesson this scene lands, woven into the closing reply. */
  takeaway?: string | null;
  /** The concrete move this scene teaches — pre-fills the reminder. */
  goodMove?: string | null;
  /** `generated` = the model's first guess. `edited` = a person fixed it, and generation will never overwrite it again. */
  source: "generated" | "edited";
  createdAt?: string;
  updatedAt?: string;
}

/** The editable fields of a scene — its prose, its openers, and its script. */
export interface CoachSituationUpdate {
  prompt: string;
  samples?: string[];
  beats?: string[];
  beatLines?: string[];
  counterpart?: string;
  level?: number;
  takeaway?: string;
  goodMove?: string;
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

/** Loại chữ do user tự viết mà Coach giữ lại. Sáu loại, bốn collection. */
export type CoachContentKind =
  | "evidence"
  | "problem_statement"
  | "quick_note"
  | "barrier"
  | "situation_answer"
  | "dip";

export interface CoachContentRow {
  id: string;
  kind: CoachContentKind;
  userId: string;
  /** Nguyên văn chữ user viết. Không bao giờ là câu Coach sinh ra. */
  content: string;
  habitId: string | null;
  sessionId: string | null;
  createdAt: string;
  /** Phụ trợ theo từng loại: planId, round, variant, số dòng nháp bị kéo… */
  meta: Record<string, unknown>;
}

export interface CoachContentPage {
  rows: CoachContentRow[];
  total: number;
  /**
   * Mỗi nguồn bị chặn ở `limit` rồi mới trộn, nên true nghĩa là còn dữ liệu
   * chưa hiện — thu hẹp khoảng ngày hoặc lọc theo loại.
   */
  truncated: boolean;
  limit: number;
}

export interface CoachAiUsageGroup {
  key: string;
  calls: number;
  /** Lệnh gọi vẫn bị tính tiền nhưng trả về thứ không dùng được. */
  failedCalls: number;
  inputTokens: number;
  outputTokens: number;
  costVnd: number;
}

export interface CoachAiUsageSummary {
  range: { from: string; to: string };
  totals: {
    calls: number;
    failedCalls: number;
    inputTokens: number;
    outputTokens: number;
    costVnd: number;
    avgLatencyMs: number;
  };
  /** Tiền theo BƯỚC của luồng — đắt nhất lên đầu. */
  byKind: CoachAiUsageGroup[];
  byModel: CoachAiUsageGroup[];
  /** Tăng dần theo ngày, khỏi phải sắp lại ở client. */
  daily: CoachAiUsageGroup[];
  sessions: {
    count: number;
    users: number;
    costPerSessionVnd: number | null;
    costPerUserVnd: number | null;
  };
  pricing: {
    usdToVnd: number;
    models: {
      model: string;
      usdPerMillionInput: number;
      usdPerMillionOutput: number;
      /** false = model chưa có trong bảng giá, đang bị tính theo giá dự phòng. */
      priced: boolean;
    }[];
  };
}
