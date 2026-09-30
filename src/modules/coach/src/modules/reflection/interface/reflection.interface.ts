/**
 * ⑤ "ĐỜI THẬT" — the reader's own account of doing the thing, in the world.
 *
 * The ONLY record in this feature that counts as "actually happened". Nothing
 * else does: not a situation answered well, not a plan made, not a streak. A
 * row exists here if and only if the reader told us, in their own sentence,
 * that an occasion came and they acted on it.
 */
export interface ICoachEvidence {
  userId: string;
  planId: string;
  habitId?: string | null;
  content: string;
}

/**
 * ⑦ "vấn đề thật của tôi là …" — the sentence the reader writes after pulling
 * their own lines across the two columns.
 *
 * Never edited, never paraphrased, never summarised back at them. It goes on
 * the weekly recap verbatim, which is the whole reason the ⑦ flow exists.
 */
export interface ICoachProblemStatement {
  userId: string;
  sessionId: string;
  habitId?: string | null;
  content: string;
  /**
   * Which line of the product this sentence came from.
   *
   * The weekly recap's "chữ của chính bạn" reads only `PROBLEM_STATEMENT` —
   * a twenty-second jot is the reader's words too, but it is not the sentence
   * they arrived at after pulling their own story apart, and showing the two
   * side by side would flatten the difference.
   */
  kind: CoachStatementKind;
  /** BARRIER only: the commitment the barrier was about. */
  planId?: string | null;
  /** ⑦ only: how much of the model's draft the reader had to move or delete. */
  draftProposedCount?: number;
  draftKeptCount?: number;
}

export enum CoachStatementKind {
  /** ⑦ — "vấn đề thật của tôi là …", after the two columns. */
  PROBLEM_STATEMENT = 'problem_statement',
  /** ⑥ — the twenty-second way out. Not a telling, and it starts nothing. */
  QUICK_NOTE = 'quick_note',
  /**
   * ②A "có dịp mà chưa làm" — what stopped them, in their words, tied to the
   * commitment it was about (`planId`). The most valuable row in the feature:
   * it is how a commitment learns it was too big.
   */
  BARRIER = 'barrier',
  /**
   * 6b — "Hôm đó bạn làm gì?": a real occurrence that already happened,
   * in their words. NOT a câu kể — it counts toward nothing: "không tính vào
   * chuỗi luyện tập của habit" (doc 20 mẫu v2, 2026-08-28).
   */
  LAN_DA_QUA = 'lan_da_qua',
}

/**
 * What the reader answered to a short situation.
 *
 * `situationId` is the join that makes ⑤ "ĐỔI THAY" possible: two answers to
 * the SAME situation, three weeks apart, is the only honest way to show someone
 * they changed. That is why situations are cached rather than generated fresh
 * each time.
 */
export interface ICoachSituationAnswer {
  userId: string;
  sessionId: string;
  situationId: string;
  habitId?: string | null;
  variant: string;
  content: string;
  /** The question it answered, frozen — the catalogue may not keep it. */
  promptSnapshot?: string | null;
  /** 1 the first answer to this scene, 2 the one after "nói lại". */
  round?: number;
}
