part of '../../in_app_survey.dart';

enum InAppSurveyStatus { initial, loading, success, failure }

enum InAppSurveyStep { hidden, entry, rating, closedQuestion, openFeedback }

@freezed
abstract class InAppSurveyState with _$InAppSurveyState {
  const factory InAppSurveyState({
    @Default(InAppSurveyStatus.initial) InAppSurveyStatus status,
    @Default(InAppSurveyStep.hidden) InAppSurveyStep step,
    InAppSurveyConfigEntity? config,
    int? selectedBranchIndex,
    @Default([]) List<String> selectedOptionIds,
    @Default('') String feedback,
    @Default(false) bool isSubmitting,
    String? errorMessage,
  }) = _InAppSurveyState;

  factory InAppSurveyState.initial() => const InAppSurveyState();

  factory InAppSurveyState.fromJson(Map<String, dynamic> json) => _$InAppSurveyStateFromJson(json);
}

extension InAppSurveyStateExtension on InAppSurveyState {
  bool get hasUsableConfig => config?.hasUsableConfig ?? false;

  bool get isEntryVisible => hasUsableConfig && step == InAppSurveyStep.entry;

  InAppSurveyBranchEntity? get selectedBranch {
    final index = selectedBranchIndex;
    final branches = config?.branches;
    if (index == null || branches == null || index < 0 || index >= branches.length) return null;
    final branch = branches[index];
    if (!branch.isUsableForSurvey) return null;
    return branch;
  }

  bool get canContinueClosedQuestion => selectedBranch != null && selectedOptionIds.isNotEmpty;

  bool get canSubmit => step == InAppSurveyStep.openFeedback && canContinueClosedQuestion && !isSubmitting;

  String get trimmedFeedback => feedback.trim();
}

extension InAppSurveyStepExtension on InAppSurveyStep {
  String get trackingName {
    return switch (this) {
      InAppSurveyStep.hidden => 'hidden',
      InAppSurveyStep.entry => 'p1',
      InAppSurveyStep.rating => 'p2',
      InAppSurveyStep.closedQuestion => 'p3',
      InAppSurveyStep.openFeedback => 'p4',
    };
  }
}
