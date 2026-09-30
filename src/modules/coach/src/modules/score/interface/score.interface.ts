/**
 * One rubric criterion as it was scored — the key, the number, and the clause
 * that earned it.
 *
 * The key is stored, never the label: labels are editable per locale on the
 * habit, and a reader's history has to survive an editor rewording a criterion.
 */
export interface ICoachScoreCriterion {
  key: string;
  score: number;
  note?: string | null;
}

/**
 * Tầng 4 — the rubric read on one finished scene.
 *
 * The FIRST durable record in this feature that says anything evaluative about
 * a reader, added on the product owner's call (2026-08-27). Deliberately kept
 * apart from `coach_evidence`, which still means only "they told us they did the
 * thing in real life": practising a scene well is not the same as living it, and
 * merging the two would quietly redefine the one number the recap trusts.
 */
export interface ICoachSceneScore {
  userId: string;
  habitId: string;
  /** The scene practised. Null only if it was deleted between answer and score. */
  situationId?: string | null;
  /** Difficulty of the scene that was scored — the ladder needs it to promote. */
  level: number;
  criteria: ICoachScoreCriterion[];
  /** Mean of the criteria, 0–10, one decimal. Stored so trends need no recompute. */
  overall: number;
  /** The three sentences shown on the card, kept for the weekly recap. */
  strength?: string | null;
  improve?: string | null;
  tip?: string | null;
  /** Was this the reader's second attempt at the same scene? */
  retry: boolean;
}
