/**
 * Text judgements the Coach makes about its own output, with no I/O.
 *
 * Pure for the same reason the state machine is: these are rules the product
 * depends on, and a rule that can only be exercised by standing up a database
 * and a model is a rule nobody checks.
 */

/**
 * Fold a line down to what two people typing the same thing would share.
 *
 * Accents come off because readers type without them and models always put them
 * back: "ong ban xoi che" and "ông bán xôi chè" are the same sentence, and a
 * comparison that calls them different is not checking honesty, it is checking
 * keyboards. `đ` is handled by hand — it does not decompose under NFD.
 */
export function fold(value: string): string {
  return value
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/đ/g, 'd');
}

/** Below this there are not enough words to call anything a copy. */
const ECHO_MIN_WORDS = 4;

/** How much of the opening has to be theirs before it stops being a reply. */
const ECHO_SHARE = 0.7;

/**
 * Is this reply just the reader's own sentence handed back?
 *
 * "hôm nay chị tôi không uống trà sữa" answered with "chị tôi không uống trà
 * sữa." is a transcription, and it is what someone gets at the exact moment
 * they decided to tell this thing something. The ban is written in CORE_RULES
 * and again in the ③C prompt, and both kept losing — a model with little to
 * work with reaches for the words in front of it.
 *
 * Decided by counting rather than by a second model call: this one is
 * computable, so spending six seconds and a request on it would be buying an
 * answer that is already free.
 *
 * Only the OPENING is judged. A reply may legitimately quote them later; what
 * reads as parroting is starting with their sentence.
 */
/**
 * Is this line keyboard mash rather than something the reader meant?
 *
 * Owner 2026-09-05: "qqqqq" was answered with "Đúng ý mình đang nghĩ luôn" and
 * a course card. Deliberately narrow — ONE distinct character repeated, in any
 * script — because a false positive tells somebody who did write something
 * that they wrote nothing, which is far worse than letting mash through. Short
 * acknowledgements ("ừ", "ok") are somebody answering and are handled by the
 * prompt, not here.
 */
/**
 * Is the reader asking US something, or saying they did not follow — rather
 * than answering the step's question?
 *
 * Owner 2026-09-05: "trả lời chệch đi 1 cái là AI cứ đi tiếp luôn". The graph
 * advances on `event.kind === 'text'` and never reads the text, so "sao lại
 * hỏi thế?" typed into a scene was scored AS the answer to that scene.
 *
 * Two tiers, because the obvious keywords also live inside habit titles —
 * "Giữ tò mò, hay đặt câu hỏi vì sao" must never be read as a question back:
 *   STRONG  — phrases that can only be a question back, anywhere in the line.
 *   WEAK    — "sao", "tại sao", "nghĩa là"… only at the START, and only on a
 *             short line or one that ends in a question mark.
 *
 * Note the lookahead instead of `\b`: JavaScript's word boundary is ASCII-only,
 * so `là\b` never matches a Vietnamese word ending in a diacritic.
 */
const ASKS_BACK_STRONG =
  /(kh[ôo]ng\s*hi[ểe]u|ch[ưu]a\s*hi[ểe]u|kho[ảa]n\s*[đd][ãa]|[đd][ợo]i\s*[đd][ãa]|[ýy]\s*l[àa]\s*sao|[ýy]\s*b[ạa]n\s*l[àa]\s*g[ìi]|h[ỏo]i\s*l[ạa]i|what do you mean|i (don'?t|do not) (get|understand)|hold on|say that again)/i;

const ASKS_BACK_HEAD =
  /^(sao\s*(l[ạa]i|v[ậa]y|th[ếe])?|t[ạa]i\s*sao|v[ìi]\s*sao|ngh[ĩi]a\s*l[àa]|th[ếe]\s*n[àa]o|nh[ưu]\s*th[ếe]\s*n[àa]o|why|what)(?=$|[\s,.:;!?…])/i;

/** Longest line still short enough that a leading "tại sao" reads as a question. */
const ASKS_BACK_SHORT = 40;

export function asksBack(text: string): boolean {
  const said = (text ?? '').trim();
  if (!said) return false;
  if (ASKS_BACK_STRONG.test(said)) return true;
  if (!ASKS_BACK_HEAD.test(said)) return false;

  return said.endsWith('?') || said.length <= ASKS_BACK_SHORT;
}

export function looksLikeNoise(text: string): boolean {
  const stripped = (text ?? '').replace(/[\s\p{P}\p{S}]/gu, '');
  if (stripped.length < 3) return false;

  return new Set(stripped.toLowerCase()).size === 1;
}

export function looksLikeEcho(reply: string, input: string): boolean {
  const said = fold(input);
  const opening = fold(reply).split(/[.!?…\n]/)[0] ?? '';
  const words = opening.split(/\s+/).filter((w) => w.length >= 2);

  if (words.length < ECHO_MIN_WORDS) return false;

  const shared = words.filter((w) => said.includes(w)).length;

  return shared / words.length >= ECHO_SHARE;
}

/**
 * The Vietnamese fixed lines are written to "bạn". A reader who asked to be
 * «anh» / «chị» / «em» / a name gets that word instead — the second-person
 * "bạn" only, never the noun ("bạn bè", "người bạn", "bạn thân"…). Other
 * languages have no such choice and pass through untouched.
 */
export function addressVi(text: string, address?: string | null): string {
  const to = address?.trim();
  if (!text || !to || to === 'bạn') return text;
  const cap = to.charAt(0).toUpperCase() + to.slice(1);
  // "ấy" is not a noun the way the others are — "bạn ấy" is Vietnamese for
  // he/she, so the "bạn" in it is the person being TALKED ABOUT, not the reader.
  // It only started mattering when this began running over scene prose (the
  // model writes about a third person; a fixed line never does), and without it
  // a scene saying "bạn ấy nói…" came out as "Hà ấy nói…".
  const nounAfter = /^\s+(bè|thân|trai|gái|cùng|học|đồng|đời|cũ|mới|ấy|thân thiết)(?![\p{L}])/u;
  const nounBefore = /(người|cô|anh|chị|ông|bà|thằng|đứa|tụi|các|nhóm|mấy|những|đám|bọn)\s*$/u;

  return text.replace(/(^|[^\p{L}])([Bb])ạn(?![\p{L}])/gu, (match, pre: string, b: string, offset: number) => {
    const after = text.slice(offset + match.length);
    const before = text.slice(0, offset + pre.length);
    if (nounAfter.test(after) || nounBefore.test(before)) return match;

    return pre + (b === 'B' ? cap : to);
  });
}

/**
 * A scene split into the prose and its closing question.
 *
 * The app shows the two as separate bubbles, and the question carries the
 * weight — it is the line being answered. Lifted out of the session service so
 * it can be tested: it is pure text work, and the way it breaks is invisible
 * until somebody reads a bubble on a device.
 *
 * Returns `question: null` when the scene has none to split out (an old row
 * that ends on a statement), and the caller then shows the whole thing as prose.
 */
export function splitScene(prompt: string): {
  setup: string;
  question: string | null;
} {
  const text = (prompt ?? '').trim();
  // The closing quote belongs to the sentence it closes. Without that last
  // class a scene ending its quoted line mid-prose — "…chữa luôn mấy câu sai
  // với tớ đi.' Bạn nói gì với Nam?" — broke at the full stop INSIDE the quote
  // and the orphaned ' opened the question, so the reader got a bubble starting
  // "' Bạn nói gì với Nam?" (owner on-device 2026-09-08). Scenes quote people
  // constantly, so this is the ordinary shape rather than an edge case.
  const sentences = text.match(/[^.!?。！？…]+[.!?。！？…]*['"”’»)\]]*/g) ?? [text];

  // The LAST question wins: a scene may quote somebody asking something on the
  // way to its own closing question.
  let cut = -1;
  for (let index = sentences.length - 1; index >= 0; index -= 1) {
    if (/[?？]/.test(sentences[index])) {
      cut = index;
      break;
    }
  }
  if (cut <= 0) return { setup: text, question: null };

  const setup = sentences.slice(0, cut).join('').trim();
  const question = sentences.slice(cut).join('').trim();

  return setup && question
    ? { setup, question }
    : { setup: text, question: null };
}
