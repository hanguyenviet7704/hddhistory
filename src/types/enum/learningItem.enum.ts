export enum ExerciseType {
  SINGLE_CHOICE = "single_choice",
  SINGLE_CHOICE_NO_CORRECT_ANSWER = "single_choice_no_correct_answer",
  MULTIPLE_CHOICE = "multiple_choice",
  DRAG_DROP = "drag_drop",
  RECORD = "record",
}

export enum LearningItemType {
  THEORY = "theory",
  EXERCISE = "exercise",
  ROLEPLAY = "roleplay",
  VIDEO = "video",
}

export enum FormDragDropType {
  TextGapFilling = "Text Gap Filling",
  CuesPlacement = "Cues Placement",
  StressPlacement = "Stress Placement",
  ArrangeTheSequence = "Arrange the Sequence",
}

export enum RoleplayContentType {
  CONVERSATION = "conversation",
  LEADING_TEXT = "leading_text",
  TRANSITION = "transition",
  EXERCISE = "exercise",
}

export enum RoleplayConversationPosition {
  LEFT = "left",
  RIGHT = "right",
}
