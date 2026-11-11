/**
 * Streams text out, always holding the LAST sentence back.
 *
 * This is what lets the Coach stream at all.
 *
 * Seven gates may still replace a reply after the model has finished writing
 * it, and the one that actually fires — 53 times in the week of 2026-09-09,
 * against 636 gated replies, so 8.3% — is the banned-question gate. Its whole
 * job is to catch a question the design forbids ("what did that mean to you?"),
 * and by construction that question is the reply's CLOSING sentence. Stream the
 * reply naively and the forbidden question is on the reader's screen a second
 * before the gate decides it may not be; there is no taking it back.
 *
 * So the last sentence never goes out on its own. Every sentence that has text
 * after it is, by definition, not the closing one, and can be released the
 * moment the next one starts. What is left at the end is exactly the sentence
 * the gate needs to judge — released by `flush()` once it has.
 *
 * The cost is one sentence of lag at the very end of a reply, against a saving
 * of several seconds at the start of it.
 */

/**
 * Sentence ends, across the five locales the app ships.
 *
 * The CJK forms are separate characters rather than the ASCII ones, and zh/ja
 * write without spaces — so a terminator is a boundary on its own there, while
 * in vi/en/ko a period may be an abbreviation or a decimal point. Requiring
 * whitespace after the ASCII forms is what keeps "3.5 phút" from being read as
 * two sentences; the CJK forms need no such guard.
 */
const SENTENCE_END_SOURCE = '([.!?…](?=\\s)|[。！？])';

/**
 * A FRESH regex per scan, never a shared one.
 *
 * A module-level `/g/` regex carries `lastIndex` between calls, so two holds
 * running at once — two readers mid-turn, which is the normal case on a server
 * — would each resume scanning where the other stopped and silently release
 * the wrong text. Building it here costs nothing worth measuring.
 */
function sentenceEnds(): RegExp {
  return new RegExp(SENTENCE_END_SOURCE, 'g');
}

export class CoachSentenceHold {
  private buffer = '';

  /**
   * Takes more text; returns what is safe to show now.
   *
   * Safe means "provably not part of the closing sentence": everything up to
   * and including the last terminator that has something after it.
   */
  push(text: string): string {
    this.buffer += text;

    const cut = this.lastSafeCut();
    if (cut <= 0) return '';

    const out = this.buffer.slice(0, cut);
    this.buffer = this.buffer.slice(cut);

    return out;
  }

  /** What is still being held — the closing sentence, gate pending. */
  get pending(): string {
    return this.buffer;
  }

  /** Releases the held sentence. The gate has spoken. */
  flush(): string {
    const out = this.buffer;
    this.buffer = '';

    return out;
  }

  /**
   * Index just past the last terminator that is NOT the end of the text.
   *
   * The "not the end" part is the whole subtlety. With `"Rồi sao. Bạn kể tiếp"`
   * the first sentence is safe, because a second one has started. With
   * `"Rồi sao. Bạn kể tiếp."` the second is now complete — and might be the
   * last thing the model writes, so it stays held. Only when a third begins
   * does it become releasable.
   */
  private lastSafeCut(): number {
    const pattern = sentenceEnds();
    let cut = 0;

    for (;;) {
      const found = pattern.exec(this.buffer);
      if (!found) break;

      const after = found.index + found[0].length;
      // Text after this terminator? Then the sentence it ends is not the last.
      if (this.buffer.slice(after).trim().length > 0) cut = after;
    }

    return cut;
  }
}
