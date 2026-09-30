/**
 * Which speech engine dubs a course's Vietnamese.
 *
 * Only `vi` has a choice: the other four locales have no Vbee equivalent worth
 * paying for and stay on Edge unconditionally. The value lives on the COURSE
 * (`course.voiceoverViProvider`) rather than in config, because the product
 * rule is "only the courses editorial nominated get the paid voice" — a global
 * switch would let one catalogue-wide re-dub spend the balance on all of them.
 */
export enum VoiceoverProvider {
  /** Free Microsoft Edge neural voices. The default, and every other locale. */
  EDGE = 'edge',
  /** Paid Vbee, billed per character. Opted into per course, in admin. */
  VBEE = 'vbee',
}

/** The one locale [VoiceoverProvider] applies to. */
export const VBEE_LANG = 'vi';
