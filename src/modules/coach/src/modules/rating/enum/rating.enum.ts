/**
 * Dead since the 👍/👎 toast was removed (2026-09-14).
 *
 * Kept because every row written before that date carries one, and the admin
 * queue still renders those rows. Nothing writes it any more — the chips say
 * whether the reader was pleased, which is why the toast could go.
 */
export enum CoachRatingThumb {
  UP = 'up',
  DOWN = 'down',
}

/**
 * What the reader was DOING when they closed the Coach.
 *
 * The rating sheet asks a different question for each: somebody who left in the
 * middle of a scene has an opinion about the scene, and somebody who left at the
 * hub has not met the Coach at all yet. Reading those as one number is how "the
 * Coach is disliked" gets said about a product nobody started.
 *
 * Derived from the session's step at exit — see `sessionKindOf`.
 */
export enum CoachSessionKind {
  /** Kể chuyện hôm nay, and everything the story leads into. */
  STORY = 'story',
  /** Luyện tập tình huống — the scene and its rehearsal. */
  SCENE = 'scene',
  /** Tổng kết / ôn tập — the recap, its quiz, and the lesson talk. */
  RECAP = 'recap',
  /** Luồng 1 — the first session's questions. */
  ONBOARD = 'onboard',
  /** Chưa chọn gì — closed at the hub, having started nothing. */
  HUB = 'hub',
}

/**
 * What the conversation was like — praise and complaint in ONE list.
 *
 * Since the thumb went away this list carries the sentiment by itself: a reader
 * who ticks "hiểu đúng chuyện mình kể" has said the Coach did well without
 * anybody having to ask them a yes/no question first. `POSITIVE_RATING_CHIPS`
 * is what separates the two halves; everything outside it puts the row in front
 * of a person.
 */
export enum CoachRatingChip {
  /** "Coach hiểu đúng chuyện mình kể" */
  UNDERSTOOD_ME = 'understood_me',
  /** "Câu hỏi đúng chỗ" */
  RIGHT_QUESTIONS = 'right_questions',
  /** "Chưa giúp được gì" */
  NOT_HELPFUL = 'not_helpful',
  /** "Áp đặt suy nghĩ của tôi". The safety valve: routes to a human. */
  IMPOSED_THINKING = 'imposed_thinking',
  /** "Hỏi quá nhiều" */
  TOO_MANY_QUESTIONS = 'too_many_questions',
  /** "Không hiểu ý tôi" */
  MISSED_THE_POINT = 'missed_the_point',
  /** "Trả lời chung chung" */
  TOO_GENERIC = 'too_generic',
  /** "Giọng điệu không phù hợp" */
  VOICE_MISMATCH = 'voice_mismatch',
  /** "Khác" — opens the free box; the words land in `note`. */
  OTHER = 'other',
  /** Kept for rows written before the chip set was redrawn (design v2). */
  TOO_LONG = 'too_long',
  /** Kept for rows written before the chip set was redrawn (2026-08-26). */
  FELT_JUDGED = 'felt_judged',
  /** Kept for rows written before the chip set was redrawn (2026-08-26). */
  PUSHED_TOO_HARD = 'pushed_too_hard',

  // ---- Luyện tập tình huống (2026-09-14) ----
  /** "Tình huống giống đời thật" */
  SCENE_REALISTIC = 'scene_realistic',
  /** "Gợi ý trả lời dùng được" */
  SCENE_USEFUL = 'scene_useful',
  /** "Tình huống không giống đời mình" */
  SCENE_UNREALISTIC = 'scene_unrealistic',
  /** "Câu gợi ý nghe không tự nhiên" */
  SCENE_UNNATURAL = 'scene_unnatural',

  // ---- Tổng kết / ôn tập ----
  /** "Tóm đúng ý mình" */
  RECAP_ACCURATE = 'recap_accurate',
  /** "Câu hỏi ôn đúng trọng tâm" */
  RECAP_ON_POINT = 'recap_on_point',
  /** "Tóm sai hoặc thiếu ý" */
  RECAP_WRONG = 'recap_wrong',
  /** "Câu hỏi quá dễ / quá khó" */
  RECAP_BAD_LEVEL = 'recap_bad_level',

  // ---- Onboarding ----
  /** "Câu hỏi dễ trả lời" */
  ONBOARD_EASY = 'onboard_easy',
  /** "Hỏi riêng tư quá" */
  ONBOARD_TOO_PERSONAL = 'onboard_too_personal',
  /** "Chưa hiểu Coach để làm gì" */
  ONBOARD_UNCLEAR = 'onboard_unclear',

  // ---- Chưa chọn gì: why they never started ----
  /** "Không biết chọn gì" */
  HUB_UNSURE = 'hub_unsure',
  /** "Không có mục nào hợp" */
  HUB_NOTHING_FITS = 'hub_nothing_fits',
  /** "Chỉ ghé xem thử" */
  HUB_JUST_LOOKING = 'hub_just_looking',
  /** "Đang bận, để sau" */
  HUB_BUSY = 'hub_busy',
}

/**
 * The chips offered for each kind, in the order the sheet draws them.
 *
 * Server-side and not the client's business to invent: the row that comes back
 * has to be readable against the question that was actually asked, and a client
 * one version behind must not be able to file a chip this kind never offered.
 */
export const RATING_CHIPS_BY_KIND: Record<CoachSessionKind, CoachRatingChip[]> = {
  [CoachSessionKind.STORY]: [
    CoachRatingChip.UNDERSTOOD_ME,
    CoachRatingChip.RIGHT_QUESTIONS,
    CoachRatingChip.TOO_LONG,
    CoachRatingChip.IMPOSED_THINKING,
    CoachRatingChip.NOT_HELPFUL,
  ],
  [CoachSessionKind.SCENE]: [
    CoachRatingChip.SCENE_REALISTIC,
    CoachRatingChip.SCENE_USEFUL,
    CoachRatingChip.SCENE_UNREALISTIC,
    CoachRatingChip.SCENE_UNNATURAL,
    CoachRatingChip.NOT_HELPFUL,
  ],
  [CoachSessionKind.RECAP]: [
    CoachRatingChip.RECAP_ACCURATE,
    CoachRatingChip.RECAP_ON_POINT,
    CoachRatingChip.RECAP_WRONG,
    CoachRatingChip.RECAP_BAD_LEVEL,
    CoachRatingChip.NOT_HELPFUL,
  ],
  [CoachSessionKind.ONBOARD]: [
    CoachRatingChip.ONBOARD_EASY,
    CoachRatingChip.TOO_MANY_QUESTIONS,
    CoachRatingChip.ONBOARD_TOO_PERSONAL,
    CoachRatingChip.ONBOARD_UNCLEAR,
  ],
  // No praise chip on purpose: somebody who closed the hub has not met the
  // Coach yet, so "Coach hiểu đúng chuyện mình kể" would be asking them to
  // rate something they never saw. This kind asks why they never started.
  [CoachSessionKind.HUB]: [
    CoachRatingChip.HUB_UNSURE,
    CoachRatingChip.HUB_NOTHING_FITS,
    CoachRatingChip.HUB_JUST_LOOKING,
    CoachRatingChip.HUB_BUSY,
  ],
};

/**
 * The chips that are praise.
 *
 * A row made only of these needs nobody: it is the reader saying the Coach did
 * its job. Every other chip — and any free text at all, whatever it sits beside
 * — sends the row to the queue a person reads.
 */
export const POSITIVE_RATING_CHIPS: ReadonlySet<CoachRatingChip> = new Set([
  CoachRatingChip.UNDERSTOOD_ME,
  CoachRatingChip.RIGHT_QUESTIONS,
  CoachRatingChip.SCENE_REALISTIC,
  CoachRatingChip.SCENE_USEFUL,
  CoachRatingChip.RECAP_ACCURATE,
  CoachRatingChip.RECAP_ON_POINT,
  CoachRatingChip.ONBOARD_EASY,
  // The hub's four are neither praise nor complaint — they are reasons for not
  // starting. Left OUT so they land in the queue: "không có mục nào hợp" is the
  // most actionable sentence on this screen and must not be filed as applause.
]);

/**
 * Where the row came from.
 *
 * A thumb-down on the rating toast is somebody judging the Coach's last turn.
 * A row filed on the way out is somebody who stopped mid-conversation and told
 * us why on the way through the door — the same chips, a different question.
 * Reading them as one number would say the Coach is disliked twice as often as
 * it is, so they are separable from the day the second one exists.
 */
export enum CoachRatingSource {
  RATING = 'rating',
  EXIT = 'exit',
}
