/**
 * The kinds of reader-written text the coach keeps.
 *
 * Six kinds out of four collections: `coach_problem_statements` holds three of
 * them under its own `kind`, and `dip` lives on the session because it is a
 * field of one, not a record of its own.
 *
 * Everything here was TYPED BY A PERSON. Nothing the model generated appears —
 * that boundary is the same one `CoachReflectionService` states, and this screen
 * is the reason it matters: it is a window onto users' own words.
 */
export enum CoachContentKind {
  /** Câu kể — the only proof a habit happened out in the real world. */
  EVIDENCE = 'evidence',
  /** "Vấn đề thật của tôi là…", written after the two columns. */
  PROBLEM_STATEMENT = 'problem_statement',
  /** Ghi nhanh — the shallow branch, kept as-is and starting nothing. */
  QUICK_NOTE = 'quick_note',
  /** Rào cản — what stopped them. The row that teaches a commitment it was too big. */
  BARRIER = 'barrier',
  /** Câu trả lời tình huống — practice, which never counts as having done it. */
  SITUATION_ANSWER = 'situation_answer',
  /** Dịp — the real-life occasion they typed, which a commitment is anchored to. */
  DIP = 'dip',
}
