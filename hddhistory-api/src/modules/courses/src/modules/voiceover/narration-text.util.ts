import { LearningItemType } from '../learning-item/enum/learning-item.enum';

/**
 * Strips everything a TTS voice would NAME instead of read: emoji/pictographs
 * ("biểu tượng cảm xúc..."), quotation marks ("dấu nháy"), markdown leftovers
 * and list/arrow glyphs. Ordinary sentence punctuation stays — commas, dots,
 * dashes and question marks are what give the voice its phrasing.
 *
 * Applied to narration text BEFORE hashing (see VoiceoverService.stripHtml),
 * so cleaning a card's text changes its segment hash and the next dub run
 * re-synthesises exactly the affected cards.
 */
export function sanitizeForNarration(text: string): string {
  return (
    String(text || '')
      // Emoji & pictographs, incl. variation selectors, ZWJ, keycaps, arrows,
      // technical/geometric glyphs (▶ ⏰ ►), dingbats (✓ ✨ ❌).
      .replace(
        /[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{2190}-\u{21FF}\u{2300}-\u{23FF}\u{25A0}-\u{25FF}\u{FE00}-\u{FE0F}\u{200D}\u{20E3}\u{2122}\u{2139}]/gu,
        ' ',
      )
      // Quote marks in every flavour — never read aloud, the words carry on.
      .replace(/[«»„‟“”‘’‹›❝❞"]/g, ' ')
      // ASCII apostrophe only when NOT joining two letters (keep don't, l'eau).
      .replace(/(?<!\p{L})'|'(?!\p{L})/gu, ' ')
      // Markup leftovers and bullets that survive HTML stripping.
      .replace(/[*_`~^|#•◦]/g, ' ')
      .replace(/[ \t]+/g, ' ')
      .replace(/[ \t]*\n[ \t]*/g, '\n')
      // A glyph often leaves an orphaned space before punctuation: "thử ngay ."
      .replace(/ +([,.!?;:])/g, '$1')
      .trim()
  );
}

/**
 * The spoken "up next" line for a keypoint — what background listening plays
 * between two keypoints, right before the next one's narration starts.
 *
 * One fixed phrase per language rather than admin copy: it is chrome, and a
 * transition that changed wording per campaign would make the catalogue's
 * clips permanently inconsistent (each clip is synthesised once and cached by
 * hash). Empty when the title has nothing to say in that language — a
 * transition that announces an empty name is worse than no announcement.
 */
export function nextUpNarrationText(lang: string, title: string): string {
  const clean = sanitizeForNarration(title).trim();
  if (!clean) return '';

  switch (lang) {
    case 'vi':
      return `Tiếp theo: ${clean}.`;
    case 'zh':
      return `接下来：${clean}。`;
    case 'ja':
      return `次は、${clean}。`;
    case 'ko':
      return `다음은 ${clean}입니다.`;
    default:
      return `Up next: ${clean}.`;
  }
}

/**
 * Lesson content is rich text/HTML; a TTS voice should read the words, not the
 * markup. Strip tags, decode the few common entities, collapse whitespace —
 * then drop the glyphs the voice would NAME instead of read (emoji, quote
 * marks, bullets): [sanitizeForNarration].
 *
 * Runs BEFORE hashing, so cleaning a card's text changes its hash and the next
 * dub run re-synthesises exactly the affected cards.
 */
export function stripNarrationHtml(html: string): string {
  const text = String(html || '')
    .replace(/<\s*(br|\/p|\/div|\/li|\/h[1-6])\s*\/?>/gi, '\n')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>')
    .replace(/&#39;|&apos;/gi, "'")
    .replace(/&quot;/gi, '"')
    .replace(/[ \t]+/g, ' ')
    .replace(/\n{3,}/g, '\n\n')
    .replace(/[ \t]*\n[ \t]*/g, '\n')
    .trim();

  return sanitizeForNarration(text);
}

/**
 * The words of one block list (a theory document's blocks, or an exercise
 * question's) for one language. Blocks with no text for that language (image,
 * video, audio) contribute nothing.
 */
export function readNarrationBlocks(blocks: any[], lang: string): string {
  const parts: string[] = [];
  for (const block of blocks ?? []) {
    const content = block?.data?.content?.[lang];
    if (typeof content === 'string' && content.trim()) {
      parts.push(stripNarrationHtml(content));
    }
  }

  return parts.filter(Boolean).join('\n\n').trim();
}

/**
 * One narration string per CARD, in the order the app pages through them.
 *
 * A card is one entry of a theory's `documents`, or one entry of an exercise's
 * `questions` — the same units the app's swipe screen shows one at a time.
 * Dubbing per card is what makes narration land exactly on the page being read.
 *
 * An exercise card is dubbed from the QUESTION only — never the options: the
 * reader hears what is asked and then answers it, and reading the options aloud
 * would give away the shape of the answer.
 *
 * Entries can be empty strings — an image-only card still occupies an index, so
 * segment index N always means card N. This walk (items in `index` order,
 * theory documents then exercise questions) is mirrored exactly by
 * `KeypointCardCubit._buildCardList` in the app; change one and the other plays
 * a neighbour's clip.
 *
 * Lives here rather than on `VoiceoverService` because the version-aware read
 * path has to re-derive these exact strings from a TAG's frozen learning items
 * to find its clips — and "exact" is load-bearing: any drift between the two
 * callers would silently unmatch the whole catalogue's hashes.
 */
export function buildNarrationSegments(items: any[], lang: string): string[] {
  const segments: string[] = [];
  for (const item of items) {
    if (item.type === LearningItemType.EXERCISE) {
      for (const question of item.questions ?? []) {
        segments.push(readNarrationBlocks(question?.document, lang));
      }
      continue;
    }
    for (const tdoc of item.documents ?? []) {
      segments.push(readNarrationBlocks(tdoc?.document, lang));
    }
  }

  return segments;
}

/**
 * The keypoint's whole narration for one language — stored (and hashed) so the
 * coverage report can answer "is this dub current?" with one compare.
 */
export function buildNarrationText(items: any[], lang: string): string {
  return buildNarrationSegments(items, lang).filter(Boolean).join('\n\n');
}
