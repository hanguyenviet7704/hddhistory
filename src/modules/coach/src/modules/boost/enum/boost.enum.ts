/**
 * The four things the app may ask for on top of the conversation.
 *
 * One enum and one table for all four, because their rules are the same shape:
 * how often, how many skips before it goes quiet, and until when it stays
 * hidden. Four separate flags drifted apart in the old build.
 */
export enum CoachBoostKind {
  MOOD_START = 'mood_dau_ngay',
  MOOD_END = 'mood_cuoi_phien',
  RATING = 'danh_gia_coach',
  COURSE_CARD = 'card_course',
}
