import { CommunityLocale } from '../../../interface/community.interface';

// The rules are THREE fixed lists, not free-form sections, because the sheet
// draws each one differently: a green "Nên" block, a red "Không" block, and
// tappable starter lines under "Chưa biết nói gì? Hãy thử:". A generic
// `sections[]` could hold the words but not tell the sheet which is which.

/**
 * "Hướng dẫn & nội quy nhóm" (design `S-03c`), one row per language.
 *
 * Authored in the panel rather than shipped in the app's translation files.
 * The rules are the thing most likely to be reworded after an incident, and a
 * wording fix must not wait for a release — nor be written five times in YAML
 * and regenerated before anyone can read it.
 *
 * Per LOCALE and not per room: one room ships today, and a second one would
 * far sooner share the house rules than need its own.
 */
export interface ICommunityChatGuide {
  locale: CommunityLocale;
  title: string;
  /** The line under the title — the room's promise, in one sentence. */
  intro: string;
  /** "Nên" — what this room is for. */
  dos: string[];
  /** "Không" — what gets a line taken down. */
  donts: string[];
  /** "Chưa biết nói gì? Hãy thử:" — openers for a reader with nothing to say. */
  starters: string[];
}
