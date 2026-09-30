/**
 * Which coach task spent the money.
 *
 * Named after the task, not the model: the point of the breakdown is to answer
 * "which STEP of the flow is expensive", and the same task can move between
 * models (the meaning-question gate already runs on a different one).
 */
export enum CoachAiCallKind {
  /** T3's conversational reply — the most-run call in the product. */
  REFLECT = 'reflect',
  /** The two-column draft at T3 nhịp 3. */
  DRAFT_TWO_COLS = 'draft_two_cols',
  /** T3's story conversation — one reply plus the kind of line it answered. */
  TALK_STORY = 'talk_story',
  /** Luồng 4 — judging the answer to the Home scene: on track, or a sample line and why. */
  JUDGE_SCENE = 'judge_scene',
  /** Luồng 5 — the in-chat quiz: why a wrong answer was wrong, and the closing summary. */
  QUIZ_FEEDBACK = 'quiz_feedback',
  /** After a session ends: what this conversation adds to what the Coach knows about the reader. */
  EXTRACT_MEMORY = 'extract_memory',
  /** Luồng 2/3 — the talk after a keypoint: summary, reply, quiz feedback, recap line. */
  LESSON_TALK = 'lesson_talk',
  /** Đối chiếu ngầm: which habit the story is about. */
  MATCH_HABIT = 'match_habit',
  /** Câu chốt at the end of a session. */
  CLOSING_LINE = 'closing_line',
  /** Luồng 4 — the other person's push-back mid-scene, plus how the line sat. */
  REACT_SCENE = 'react_scene',
  /** Luồng 5 — writing a quiz about one keypoint, stored and reused. */
  MAKE_QUIZ = 'make_quiz',
  /** Pha một của một cảnh: đúng những gì người đọc thấy khi nó mở ra. */
  GENERATE_SITUATION = 'generate_situation',
  /**
   * Pha hai: chặng hai, bài học, nước đi — viết khi người đọc đang đọc cảnh.
   *
   * Tên RIÊNG chứ không gộp vào pha một, dù cùng viết một cảnh. Tách hai pha
   * ra là để pha một nhanh lên, và gộp sổ thì trung bình của chúng trộn vào
   * nhau đúng chỗ cần đọc — không còn biết pha một có nhanh lên thật không.
   */
  COMPLETE_SITUATION = 'complete_situation',
  /** The critic pass over a freshly written scene. */
  CRITIQUE_SITUATION = 'critique_situation',
  /** The banned-question gate — runs on the lite model. */
  CLASSIFY_QUESTION = 'classify_question',
  /** Scoring what the reader said in a scene. */
  SCORE_SCENE = 'score_scene',
  /** The self-harm / crisis gate — runs on the lite model, on every free text. */
  CLASSIFY_RISK = 'classify_risk',
  /** Speech to text for voice input. */
  TRANSCRIBE = 'transcribe',
}
