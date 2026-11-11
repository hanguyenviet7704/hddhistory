import { ImportErrorCode } from './enum/learning-import.enum';

/**
 * Every knob for the import feature in one place.
 *
 * These are the four walls that keep an AI feature from becoming an unbounded
 * bill: premium-only (checked in the service), a monthly count, one job at a
 * time, and a size ceiling per source. They live here rather than inline at the
 * call sites so the numbers can be re-tuned from one file once a month of real
 * usage data exists -- the values below are estimates, not measurements.
 */
export const LEARNING_IMPORT_CONFIG = {
  /**
   * Imports allowed per PREMIUM user per calendar week, reset at 00:00 Monday.
   *
   * A week rather than a month, and five rather than ten: the allowance is only
   * a real constraint if the reader can feel it refill. A monthly bucket spent in
   * the first two days leaves someone locked out for four weeks, which reads as
   * the feature being broken rather than metered — and a month is long enough
   * that "you have some left" stops being information anyone acts on.
   *
   * Calendar week rather than the subscription cycle: it is what we can state in
   * one sentence in the UI ("back to 5 tickets on Monday") without reading a
   * renewal date per user on every quota check. Usage is COUNTED from the job
   * collection rather than kept in a counter field, so there is only ever one
   * source of truth to get wrong.
   */
  quotaPerWeek: 5,

  /**
   * What a reader WITHOUT a subscription gets -- ONCE, for the lifetime of the
   * account. Not per week (product call, 2026-08-12).
   *
   * One, and deliberately not zero. This feature cannot be sold from a
   * screenshot: "turn your own PDF into a lesson" only means something once
   * you've watched it happen to material you chose. One free ticket is that
   * demonstration, at a cost we can carry, and it turns the paywall from a door
   * into an upgrade — the reader who spends it has already seen the thing they
   * would be buying more of.
   *
   * Lifetime rather than weekly because a ticket that comes back every Monday is
   * a free tier, not a demonstration: the reader who only ever wants one lesson a
   * week never has a reason to pay. Spending it is a one-way door, which is why
   * the free reader's quota carries no `resetsAt` -- there is nothing to wait for,
   * and saying "back on Monday" would be false.
   */
  freeQuotaLifetime: 1,

  /**
   * Cap on the PDF we hand to Gemini.
   *
   * 20MB rather than the 50MB the R2 upload endpoint allows: the file rides
   * inline in the generate request, and inline request bodies have their own
   * (smaller) ceiling. Rejecting at 20MB with a clear message beats letting the
   * user wait two minutes for the provider to reject it for us.
   */
  maxPdfBytes: 20 * 1024 * 1024,

  /**
   * Page ceiling, read from the PDF's own metadata.
   *
   * Not a text-extraction step -- see PdfSourceResolver.countPages. The point is
   * cost: a 2000-page PDF costs more in one import than a user's whole monthly
   * allowance is meant to.
   */
  maxPdfPages: 300,

  /**
   * The video-length WINDOW: longer than 10 minutes, shorter than 3 hours
   * (user call, 2026-08-13).
   *
   * The floor is a quality gate, not a cost one: a clip under ten minutes
   * rarely carries enough substance for even a two-keypoint lesson, and
   * rejecting it with a clear sentence beats generating something thin and
   * rejecting it as CONTENT_TOO_SHORT two minutes later.
   *
   * The ceiling was a WAIT cap wearing a cost costume back when generation
   * was single-shot; streaming removed the wait (the reader is on the roadmap
   * in seconds) and the cost is measured, not feared (~1k VND per 2h video).
   * 3h ≈ ~960k input tokens the way the provider watches video — at the edge
   * of its 1M input limit, which is the real reason this does not go higher.
   *
   * Both bounds are enforced only when the duration could be read at all —
   * see `YoutubeSourceResolver.fetchDurationSeconds`.
   */
  minVideoSeconds: 10 * 60,
  maxVideoSeconds: 3 * 60 * 60,

  /**
   * The budget for ONE BODY card, and the number that actually governs how the
   * lesson reads.
   *
   * 38-44 words, the same rule the app's hand-authored courses are written to.
   * Down from ~75, and before that ~150: at those sizes a card had to be scrolled
   * before it could be swiped, which defeats the format.
   *
   * A floor as well as a ceiling, deliberately. The failure mode of a word limit
   * is not long cards, it is clipped ones -- told only "at most 45", a model
   * writes twenty-word stubs that read as lecture notes rather than prose.
   *
   * Stated explicitly rather than implied by dividing the total, because the
   * total is what the model optimises and per-card length is what the reader
   * experiences. "38-44 words" is an instruction; "900 words across twenty
   * cards" is arithmetic the model does loosely.
   */
  targetWordsPerCard: { min: 38, max: 44 },

  /**
   * The takeaway that closes a keypoint.
   *
   * Shorter than a theory card because it does one job -- folding the keypoint
   * into a single flowing thought the reader leaves with -- and it is read at a
   * glance rather than studied. The dedicated short HOOK card is gone
   * (authoring spec, 2026-08-14): every theory card is written at full
   * 38-44-word size, with the arc's opening situation carried at that size too.
   */
  targetWordsPerShortCard: { min: 25, max: 35 },

  /**
   * The line no card crosses, whatever kind it is.
   *
   * One card is one swipeable page. Past this a card has to be scrolled before it
   * can be swiped, and a deck of scrollable pages is a document with extra steps.
   */
  hardWordsPerCard: 45,

  /**
   * What we ask the model for in total.
   *
   * v1 asked for 3500-5000 words, which read fine as an article but could not be
   * shown the way the rest of the app shows learning content -- the reader is a
   * deck of swipeable cards, and that length meant slicing one document into well
   * over a hundred of them.
   *
   * Arithmetic on the card budget rather than a number chosen on its own: 2-6
   * keypoints of 7-11 theory cards (38-44 words each) plus a 25-35 word
   * takeaway puts the honest range around 580 to 3100 words. This asks for the
   * middle and leaves the ends to the material. Kept as its own bound anyway,
   * so a model that ignores the card budget still cannot return a lesson twice
   * the size.
   */
  targetWordCount: { min: 700, max: 2600 },

  /**
   * How many KEYPOINTS the lesson is divided into.
   *
   * A range, not a number, and the model picks within it from the material: a
   * six-minute video with one idea in it and a chapter covering five should not
   * both come out as three keypoints. The bounds are what keeps that judgement
   * from producing something the reader can't show -- one keypoint is a flat
   * lesson again, and seven would make the whole import a sequence of
   * two-card sittings interrupted by six completion screens.
   */
  targetKeypointCount: { min: 2, max: 6 },

  /**
   * THEORY cards inside one keypoint. One card renders as exactly one swipeable
   * page, and the takeaway is NOT in this count -- it lives in its own field and
   * renders as the recap card, so 7-11 here is the authoring spec's "8-12 cards
   * per keypoint, takeaway included".
   *
   * Raised from 3-6 (authoring spec, 2026-08-14): at 38-44 words a six-card
   * keypoint is ~250 words, a sitting finished in a couple of swipes, and the
   * spec sizes a keypoint the way the hand-authored catalogue does. The model
   * picks within the range from the material -- a thin idea sits near 7, a rich
   * one near 11 -- and padding to reach a count is exactly what the prompt
   * forbids.
   */
  targetCardsPerKeypoint: { min: 7, max: 11 },

  /**
   * Reject anything shorter than this after generation.
   *
   * Set below `targetWordCount.min` deliberately: models undershoot a word
   * target routinely and a 500-word summary is still a good summary, so the
   * floor catches the real failure (the source had almost nothing in it) rather
   * than policing the last hundred words.
   *
   * MOVES WITH `targetWordCount`, and has had to three times. It sat at 900
   * while the target was 1200-2000; left there after the target halved it would
   * have rejected almost every lesson. It then dropped to 220 when cards went
   * from ~75 words to 38-44. The 2026-08-14 authoring spec raised the keypoint
   * to 7-11 theory cards plus a takeaway, which puts the smallest legitimate
   * lesson (two keypoints of seven cards each) near 580 words -- 450 stays
   * safely under that while still catching a source with almost nothing in it.
   * A floor above the target is not a floor, it is an outage.
   */
  minAcceptedWordCount: 450,

  // Reading pace used to show "~18 phút" on the lesson card. Rough by nature;
  // it only has to be close enough to set expectations.
  wordsReadPerMinute: 200,
} as const;

/**
 * Failures that DO burn a quota slot.
 *
 * Empty, and that is the decision rather than an oversight: every failure mode
 * leaves the user with no lesson, so charging for any of them means charging for
 * nothing. Our faults (AI_TIMEOUT) obviously shouldn't count, and neither should
 * theirs (a PDF we couldn't read) -- they got no value either way, and a user who
 * loses allowance to a scanned PDF simply stops using the feature.
 *
 * Kept as a named, typed set instead of a hardcoded `false` so that the day
 * someone wants to charge for a category, there is one obvious place to say so.
 */
export const LEARNING_IMPORT_QUOTA_CHARGING_ERRORS: ReadonlySet<ImportErrorCode> =
  new Set<ImportErrorCode>();
