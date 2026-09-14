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
  /** Model Gemini cho các call hội thoại. Rỗng = dùng env của server. */
  geminiModel?: string | null;
  /** Model riêng cho việc VIẾT CẢNH (1 call/lượt luyện). Rỗng = theo geminiModel. */
  geminiSceneModel?: string | null;
  /** Onboarding Coach (luồng 1): bốn câu tuỳ chọn ở phiên Home đầu tiên. */
  onboardAskStyle?: boolean;
  onboardAskAge?: boolean;
  onboardAskGender?: boolean;
  onboardAskJob?: boolean;
  /**
   * Luồng 6 — tần suất hiện popup đánh giá sau ⟨Vẫn đóng⟩.
   *
   * Mọi cổng phải qua hết thì mới hỏi; mỗi cổng có một giá trị trung tính để
   * tắt riêng nó, nên không knob nào nằm trên màn hình mà vô tác dụng.
   */
  ratingAskEnabled?: boolean;
  /** Số ngày chờ với người ĐÃ gửi đánh giá. 0 = tắt cổng này. */
  ratingAskMinDays?: number;
  /** Số ngày chờ với người bấm ⟨Để sau⟩. 0 = tắt cổng này. */
  ratingAskSnoozeDays?: number;
  /** Cứ N lần thoát mới hỏi. 1 = mọi lần thoát. */
  ratingAskEveryNthExit?: number;
  /** Phần trăm số lần đã qua các cổng trên mà thực sự được hỏi. 100 = hỏi hết. */
  ratingAskProbability?: number;
  /** Hỏi tối đa M lần mỗi người rồi thôi hẳn. 0 = không giới hạn. */
  ratingAskMaxPerUser?: number;
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

/**
 * User đang làm gì lúc đóng Coach. Popup hỏi một câu khác cho mỗi loại, nên
 * đọc chê mà không biết loại thì không biết chê cái gì.
 *
 * Hàng ghi trước 2026-09-14 không có field này và KHÔNG được đoán ngược.
 */
export type CoachSessionKind =
  | "story"
  | "scene"
  | "recap"
  | "onboard"
  | "hub";

export type CoachRatingChip =
  /** Bộ "kể chuyện" — cũng là bộ dùng chung trước khi tách theo loại. */
  | "understood_me"
  | "right_questions"
  | "not_helpful"
  | "imposed_thinking"
  /** Bộ "luyện tập tình huống". */
  | "scene_realistic"
  | "scene_useful"
  | "scene_unrealistic"
  | "scene_unnatural"
  /** Bộ "tổng kết / ôn tập". */
  | "recap_accurate"
  | "recap_on_point"
  | "recap_wrong"
  | "recap_bad_level"
  /** Bộ "onboarding". */
  | "onboard_easy"
  | "onboard_too_personal"
  | "onboard_unclear"
  /** Bộ "chưa chọn gì" — lý do không bắt đầu, không phải khen hay chê. */
  | "hub_unsure"
  | "hub_nothing_fits"
  | "hub_just_looking"
  | "hub_busy"
  | "too_many_questions"
  | "missed_the_point"
  | "too_generic"
  | "voice_mismatch"
  | "other"
  /** Ba loại dưới là chip đời cũ, chỉ còn trong hàng đã lưu. */
  | "too_long"
  | "felt_judged"
  | "pushed_too_hard";

/** Hai chip mang nghĩa khen — mọi chip khác đẩy hàng vào hàng đợi người đọc. */
export const POSITIVE_RATING_CHIPS: CoachRatingChip[] = [
  "understood_me",
  "right_questions",
  "scene_realistic",
  "scene_useful",
  "recap_accurate",
  "recap_on_point",
  "onboard_easy",
  // Bốn chip của loại "chưa chọn gì" cố tình không nằm đây: chúng là lý do
  // không bắt đầu, và "không có mục nào hợp" phải vào hàng đợi người đọc.
];

/**
 * Hàng đến từ đâu: `exit` là popup đánh giá sau ⟨Vẫn đóng⟩ — đường duy nhất
 * còn lại. `rating` là toast 👍/👎 đã bỏ ngày 2026-09-14; chỉ còn trong hàng
 * cũ. Hàng ghi trước khi có field này đọc thiếu thì hiểu là `rating`.
 */
export type CoachRatingSource = "rating" | "exit";

export interface CoachRating {
  _id: string;
  userId: string;
  sessionId: string;
  /** Null từ 2026-09-14 — chip đã mang nghĩa khen/chê, không cần thumb nữa. */
  thumb?: "up" | "down" | null;
  chips: CoachRatingChip[];
  note?: string | null;
  source?: CoachRatingSource;
  /** Null ở hàng cũ — admin hiện "Không rõ loại" chứ không đoán. */
  sessionKind?: CoachSessionKind | null;
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
  /** Chỉ có khi lọc đúng một user — phần đầu của trang dòng thời gian. */
  user?: { userId: string; name: string | null; email: string | null };
}

/** Một user và dấu vết họ để lại, cho danh sách "Theo user". */
export interface CoachContentUserRow {
  userId: string;
  /** Null khi tài khoản không còn: chữ họ viết sống lâu hơn tài khoản. */
  name: string | null;
  email: string | null;
  anonymous: boolean;
  firstAt: string;
  lastAt: string;
  total: number;
  /** Đủ sáu loại, kể cả loại bằng 0, để bảng có cột cố định. */
  byKind: Record<CoachContentKind, number>;
}

export interface CoachContentUserPage {
  rows: CoachContentUserRow[];
  total: number;
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

/**
 * Lời Coach đến từ đâu.
 *
 * `transcript` — đọc nguyên văn từ phiên còn trong hạn lưu.
 * `derived` — phiên đã bị xoá, hội thoại được dựng lại quanh những gì user để
 * lại: chữ user là thật, còn lời Coach chỉ có với câu hỏi tình huống.
 */
export type CoachThreadSource = "transcript" | "derived";

export interface CoachThreadMessage {
  at: string;
  role: "coach" | "user";
  /** Null = câu cố định, admin tự điền theo `kind` và đánh dấu tái dựng. */
  text: string | null;
  kind?: CoachContentKind;
  step?: string | null;
  derived?: boolean;
  meta?: Record<string, unknown>;
}

export interface CoachThreadSession {
  /** Null cho khối "ngoài phiên" — câu kể viết ở màn habit. */
  sessionId: string | null;
  entry: string | null;
  habitId: string | null;
  startedAt: string;
  endedAt: string;
  source: CoachThreadSource;
  messages: CoachThreadMessage[];
}

export interface CoachThreadPage {
  user: { userId: string; name: string | null; email: string | null };
  sessions: CoachThreadSession[];
  truncated: boolean;
  limit: number;
}
