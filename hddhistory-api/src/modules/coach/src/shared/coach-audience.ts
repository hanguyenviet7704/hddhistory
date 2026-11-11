/**
 * Who the scene is for, at the only grain the cache can afford.
 *
 * Scenes are cached per (habit, locale, variant, audience, goal) — see
 * `coach_situations` — because ⑤ "ĐỔI THAY" compares two answers to the SAME
 * scene weeks apart, so personalisation has to live in the cache KEY, never in
 * per-user generation. Age band and learning goal are the two onboarding
 * answers that are both stable per person and actually change what an ordinary
 * day looks like: a "cuộc họp chốt phương án" scene handed to a 15-year-old is
 * the exact miss this exists to prevent.
 */
export type CoachAudience =
  | 'teen'
  | 'young_adult'
  | 'adult'
  | 'midlife'
  | 'unknown';

/** Words that mean "under N" in the five locales the app ships. */
const UNDER_WORDS = /dưới|under|below|未満|以下|미만|이하/i;

/**
 * Bucket the stored age answer.
 *
 * `user.age` holds the LABEL of whatever option the onboarding config offered
 * ("13–17", "Dưới 18", "25-34 tuổi", "45+") — admin-authored, per-locale, free
 * to change — so this parses numbers out of the text rather than matching a
 * closed list a config edit would silently break.
 */
export function coachAudienceFromAge(age?: string | null): CoachAudience {
  if (!age) return 'unknown';

  const numbers = (age.match(/\d+/g) ?? []).map(Number).filter(Number.isFinite);
  if (!numbers.length) return 'unknown';

  // "Dưới 18" names the bound it sits below, not a member of the range.
  const lower = UNDER_WORDS.test(age) ? Math.min(...numbers) - 1 : Math.min(...numbers);

  if (lower < 18) return 'teen';
  if (lower < 25) return 'young_adult';
  if (lower < 45) return 'adult';

  return 'midlife';
}

/**
 * What the scene generator is told about the reader. English, like the rest of
 * the generation prompt; null adds no line at all.
 */
export const COACH_AUDIENCE_HINT: Record<CoachAudience, string | null> = {
  teen: 'The reader is a teenager still in school. Set scenes in class, study groups, clubs, family, chats with friends — never offices, staff meetings or work deadlines.',
  young_adult:
    'The reader is a young adult (18–24). Scenes fit university, part-time work, a first job, roommates, early-career moments.',
  adult:
    'The reader is a working adult (25–44). Scenes fit workplaces, meetings, colleagues, family life.',
  midlife:
    'The reader is an adult over 45. Scenes fit long careers, family, community — avoid campus settings.',
  unknown: null,
};
