export enum OutputPracticeConversationStatus {
  ACTIVE = 'active',
  SELECT_OPTION_PENDING = 'select_option_pending',
  SUMMARY_DECISION_PENDING = 'summary_decision_pending',
  CONVERSATION_LIMIT_IN_MONTH = 'conversation_limit_in_month',
  FINISHED = 'finished',
}

export enum OutputPracticeSummaryDecisionValue {
  STOP_PRACTICING_HERE = 1,
  START_A_NEW_PRACTICE = 2,
}
