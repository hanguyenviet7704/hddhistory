part of '../../output_practice.dart';

enum OutputPracticeActionKind { option, summaryDecision }

enum OutputPracticeSummaryAction {
  endPractice(1),
  startANewConversation(2)
  ;

  const OutputPracticeSummaryAction(this.value);

  final int value;
}

class OutputPracticeActionChipVm {
  const OutputPracticeActionChipVm({
    required this.id,
    required this.kind,
    required this.value,
    required this.label,
    this.summaryAction,
  });

  final String id;
  final OutputPracticeActionKind kind;
  final int value;
  final String label;
  final OutputPracticeSummaryAction? summaryAction;

  factory OutputPracticeActionChipVm.option(OutputPracticeAiReplyOptionEntity option) {
    return OutputPracticeActionChipVm(
      id: 'option_${option.value}',
      kind: OutputPracticeActionKind.option,
      value: option.value,
      label: option.label,
    );
  }

  factory OutputPracticeActionChipVm.summary(OutputPracticeSummaryAction action) {
    return OutputPracticeActionChipVm(
      id: 'summary_${action.value}',
      kind: OutputPracticeActionKind.summaryDecision,
      value: action.value,
      label: '',
      summaryAction: action,
    );
  }
}
