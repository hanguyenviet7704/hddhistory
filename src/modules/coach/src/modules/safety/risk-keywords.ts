/**
 * The net that never fails.
 *
 * This list exists because the real classifier is a network call, and a network
 * call can be down. It is deliberately SMALL and deliberately unambiguous:
 * every entry is a phrase that means one thing. A broader list would fire on
 * ordinary speech — "I'm dying to leave this job", "kill me now" — and being
 * handed a crisis line for a figure of speech is how someone learns not to talk
 * to this feature honestly.
 *
 * Matching is substring, lowercased, diacritics preserved. That misses
 * misspellings and creative phrasing, which is precisely why it is the FLOOR
 * and not the mechanism: `CoachSafetyService` runs the model classifier in
 * parallel on every turn, and this only has to catch the plainest cases when
 * that call cannot answer.
 */
export const RISK_KEYWORDS: Record<string, string[]> = {
  en: [
    'kill myself',
    'killing myself',
    'end my life',
    'take my own life',
    'want to die',
    'wanna die',
    'better off dead',
    'suicide',
    'suicidal',
    'self-harm',
    'hurt myself',
    'cut myself',
    "don't want to live",
    'do not want to live',
    'no reason to live',
  ],
  vi: [
    'tự tử',
    'tự sát',
    'tự hại',
    'tự làm đau mình',
    'muốn chết',
    'không muốn sống',
    'chán sống',
    'kết thúc tất cả',
    'kết thúc cuộc đời',
    'biến mất khỏi thế giới',
    'chết cho rồi',
    'chết quách',
  ],
  zh: [
    '自杀',
    '自殺',
    '想死',
    '不想活',
    '不想活了',
    '结束生命',
    '結束生命',
    '自残',
    '自殘',
    '伤害自己',
    '傷害自己',
  ],
  ja: [
    '自殺',
    '死にたい',
    '消えたい',
    '生きたくない',
    '自傷',
    '自分を傷つけ',
    'リストカット',
  ],
  ko: [
    '자살',
    '죽고 싶',
    '죽고싶',
    '살기 싫',
    '살기싫',
    '사라지고 싶',
    '자해',
  ],
};

/**
 * Every list at once.
 *
 * Checked in full rather than only the reader's UI locale: someone using the
 * app in English may well write the hardest sentence of their life in their
 * first language, and that is exactly the sentence this must not miss. The
 * whole set is a few hundred substring checks on one short message — the cost
 * is nothing next to what it buys.
 */
const ALL_KEYWORDS: string[] = Object.values(RISK_KEYWORDS).flat();

export function matchesRiskKeyword(text: string): boolean {
  if (!text) return false;

  const haystack = text.toLowerCase();

  return ALL_KEYWORDS.some((keyword) => haystack.includes(keyword));
}
