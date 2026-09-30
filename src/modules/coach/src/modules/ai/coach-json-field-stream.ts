/**
 * Reads ONE string field out of JSON that is still arriving.
 *
 * Every coach call asks the provider for `responseMimeType: 'application/json'`
 * against a schema, so what streams back is not prose — it is a JSON document
 * being typed out character by character. `JSON.parse` cannot help until the
 * last brace lands, which is exactly the wait streaming exists to remove.
 *
 * What saves us is `propertyOrdering` on every response schema: the field the
 * reader actually reads (`reply`, or a scene's `prompt`) is declared FIRST, so
 * it is complete long before the rest of the document — a scene's other nine
 * fields, both third-person tellings included, are several thousand tokens the
 * reader does not see yet.
 *
 * So this walks the raw buffer, finds that one field, and decodes its string
 * value as it grows — unescaping as JSON would, and stopping short whenever the
 * buffer ends mid-escape, because `"\` might become `\"` or `\\` and guessing
 * would corrupt the text on screen.
 *
 * Deliberately NOT a JSON parser. It knows one shape — a top-level string field
 * — and anything it does not understand it simply does not emit, which leaves
 * the caller with the complete answer it was going to parse anyway.
 */

const ESCAPES: Record<string, string> = {
  '"': '"',
  '\\': '\\',
  '/': '/',
  b: '\b',
  f: '\f',
  n: '\n',
  r: '\r',
  t: '\t',
};

export class CoachJsonFieldStream {
  /** Everything the provider has sent so far. */
  private raw = '';

  /** Where in `raw` the field's value begins, or -1 while still looking. */
  private valueStart = -1;

  /** How far into the value we have decoded and handed out. */
  private cursor = -1;

  private closed = false;

  constructor(private readonly field: string) {}

  /** True once the field's closing quote has been seen. */
  get isClosed(): boolean {
    return this.closed;
  }

  /** True once the field has been located and can start producing text. */
  get isOpen(): boolean {
    return this.valueStart >= 0;
  }

  /**
   * Feeds the next piece of the document; returns whatever new text of the
   * field is now certain.
   *
   * Empty string is the normal answer for most chunks — the opening brace, the
   * field name itself, and every byte after the field has closed all produce
   * nothing.
   */
  push(chunk: string): string {
    if (this.closed) return '';

    this.raw += chunk;

    if (this.valueStart < 0) {
      const at = this.findValueStart();
      if (at < 0) return '';
      this.valueStart = at;
      this.cursor = at;
    }

    return this.decodeFromCursor();
  }

  /**
   * Where the field's value starts, or -1.
   *
   * Matches `"field"` followed by a colon and the opening quote, allowing the
   * whitespace a pretty-printer inserts. Anchored on the quoted KEY rather than
   * on a bare word, so a field named `reply` is not found inside a sentence
   * that happens to contain the word.
   */
  private findValueStart(): number {
    const pattern = new RegExp(`"${this.field}"\\s*:\\s*"`);
    const found = pattern.exec(this.raw);

    return found ? found.index + found[0].length : -1;
  }

  /**
   * Decodes as much of the value as is unambiguous, and stops.
   *
   * Stops rather than guesses in three places, all of them a buffer that ended
   * mid-symbol: a lone trailing backslash, a `\u` with fewer than four hex
   * digits behind it, and the closing quote (which ends the field for good).
   */
  private decodeFromCursor(): string {
    let out = '';
    let index = this.cursor;

    while (index < this.raw.length) {
      const char = this.raw[index];

      if (char === '"') {
        this.closed = true;
        this.cursor = index;

        return out;
      }

      if (char !== '\\') {
        out += char;
        index += 1;
        continue;
      }

      // An escape needs at least one more character to mean anything.
      if (index + 1 >= this.raw.length) break;

      const marker = this.raw[index + 1];

      if (marker === 'u') {
        // \uXXXX — four hex digits, all or nothing.
        if (index + 6 > this.raw.length) break;
        const hex = this.raw.slice(index + 2, index + 6);
        if (!/^[0-9a-fA-F]{4}$/.test(hex)) break;
        out += String.fromCharCode(Number.parseInt(hex, 16));
        index += 6;
        continue;
      }

      const mapped = ESCAPES[marker];
      // An escape the schema should never produce: leave it, and let the
      // caller's own parse of the finished document be the authority.
      if (mapped === undefined) break;

      out += mapped;
      index += 2;
    }

    this.cursor = index;

    return out;
  }
}
