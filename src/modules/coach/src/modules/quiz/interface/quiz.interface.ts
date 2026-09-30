/**
 * Luồng 5 — the in-chat quiz, GENERATED from what the keypoint teaches rather
 * than taken from the authored exercises.
 *
 * The catalogue's exercises are written for the deck: five kinds, drag-and-drop
 * and recordings among them, and a chat can only ask one of those kinds. So the
 * Coach writes its own single-choice questions from the keypoint's own material
 * and keeps them (owner, 2026-09-04: "gen lại quizz từ keypoint sau đó lưu vào
 * csdl để lần sau lấy ra"). Each set is three questions about one keypoint in
 * one language; a reader never sees the same set twice while an unseen one
 * exists.
 */
export interface ICoachQuizQuestion {
  question: string;
  options: string[];
  correctIndex: number;
  explanation?: string | null;
}

export interface ICoachQuizSet {
  keypointId: string;
  locale: string;
  questions: ICoachQuizQuestion[];
  /** Bumped every time the set is served, so a stale set can be spotted later. */
  servedCount?: number;
}

/** One reader has seen one set — the row that keeps the next quiz fresh. */
export interface ICoachQuizSeen {
  userId: string;
  setId: string;
  keypointId: string;
}
