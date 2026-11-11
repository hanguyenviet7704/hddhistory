part of '../../warm_up.dart';

enum WarmUpStatus { initial, loading, intro, question, result, completion, closed, failure }

@freezed
abstract class WarmUpState with _$WarmUpState {
  const factory WarmUpState({
    @Default(WarmUpStatus.initial) WarmUpStatus status,
    @Default(false) bool isDue,
    WarmUpPreviousLessonEntity? previousLesson,
    @Default('') String courseId,
    @Default([]) List<QuestionEntity> usableQuestions,
    @Default(0) int currentQuestionIndex,
    @Default([]) List<DailyWarmUpAnswerResultEntity> results,
    DailyWarmUpAnswerResultEntity? latestResult,
    @Default(false) bool isRoutingToLesson,
    @Default(-1) int selectedAnswerIndex,
    @Default({}) Set<int> selectedAnswersIndices,
    @Default([]) List<int> orderedOptionIds,
    @Default({}) Map<int, int> placedOptionIds,
    @Default({}) Set<int> selectedWordIndices,
    String? errorMessage,
  }) = _WarmUpState;

  factory WarmUpState.initial() => const WarmUpState();
}

extension WarmUpStateX on WarmUpState {
  /// Roadmap CTA swap gate: only show "Let's warm up" when due AND there is at
  /// least one renderable question.
  bool get hasWarmUpAvailable => isDue && usableQuestions.isNotEmpty;

  QuestionEntity? get currentQuestion {
    if (currentQuestionIndex < 0 || currentQuestionIndex >= usableQuestions.length) return null;
    return usableQuestions[currentQuestionIndex];
  }

  bool get isFinalQuestion => usableQuestions.isNotEmpty && currentQuestionIndex >= usableQuestions.length - 1;

  bool get canCheckCurrentQuestion {
    final question = currentQuestion;
    if (question == null || latestResult != null) return false;

    return switch (question.typedPayload) {
      QuestionSingleChoicePayloadEntity() || QuestionSingleChoiceNoCorrectAnswerPayloadEntity() => selectedAnswerIndex >= 0,
      QuestionMultipleChoicePayloadEntity() => selectedAnswersIndices.isNotEmpty,
      QuestionDragAndDropPayloadEntity(:final answers) => placedOptionIds.length == answers.length && answers.isNotEmpty,
      QuestionArrangeTheSequencePayloadEntity(:final answers) => orderedOptionIds.length == answers.length && answers.isNotEmpty,
      QuestionCuesPlacementPayloadEntity() => placedOptionIds.isNotEmpty,
      QuestionStressPlacementPayloadEntity() => selectedWordIndices.isNotEmpty,
      _ => false,
    };
  }

  /// Projects the warm-up question sub-flow into a [DailyWarmUpState] so the
  /// existing daily-warm-up player widgets (progress dots, choice/drag-drop
  /// bodies, result sheet) can be reused as-is without any changes to the
  /// daily_warm_up feature.
  DailyWarmUpState get asDailyWarmUpState => DailyWarmUpState(
    status: switch (status) {
      WarmUpStatus.question => DailyWarmUpStatus.question,
      WarmUpStatus.result => DailyWarmUpStatus.result,
      _ => DailyWarmUpStatus.question,
    },
    usableQuestions: usableQuestions,
    currentQuestionIndex: currentQuestionIndex,
    results: results,
    latestResult: latestResult,
    selectedAnswerIndex: selectedAnswerIndex,
    selectedAnswersIndices: selectedAnswersIndices,
    orderedOptionIds: orderedOptionIds,
    placedOptionIds: placedOptionIds,
    selectedWordIndices: selectedWordIndices,
  );
}
