part of '../../daily_warm_up.dart';

enum DailyWarmUpStatus { initial, loading, success, entry, question, result, completion, closed, failure }

@freezed
abstract class DailyWarmUpState with _$DailyWarmUpState {
  const factory DailyWarmUpState({
    @Default(DailyWarmUpStatus.initial) DailyWarmUpStatus status,
    DailyWarmUpEntity? entity,
    DailyWarmUpEntity? selectedItem,
    @Default([]) List<QuestionEntity> usableQuestions,
    @Default(0) int currentQuestionIndex,
    @Default([]) List<DailyWarmUpAnswerResultEntity> results,
    DailyWarmUpAnswerResultEntity? latestResult,
    CourseEntity? suggestedCourse,
    @Default(false) bool isCheckingEntry,
    @Default(false) bool isPresenting,
    @Default(false) bool isLoadingCourse,
    @Default(false) bool isRoutingToRoadmap,
    @Default(false) bool hasMarkedShown,
    @Default(false) bool hasTrackedCompleteView,
    @Default('') String shownUserId,
    @Default('') String shownDate,
    @Default(-1) int selectedAnswerIndex,
    @Default({}) Set<int> selectedAnswersIndices,
    @Default([]) List<int> orderedOptionIds,
    @Default({}) Map<int, int> placedOptionIds,
    @Default({}) Set<int> selectedWordIndices,
    String? errorMessage,
  }) = _DailyWarmUpState;

  factory DailyWarmUpState.initial() => const DailyWarmUpState();
}

extension DailyWarmUpStateX on DailyWarmUpState {
  bool get canShowEntry => status == DailyWarmUpStatus.entry && entity != null && usableQuestions.isNotEmpty;

  bool get isQuestionStep => status == DailyWarmUpStatus.question;

  bool get isResultStep => status == DailyWarmUpStatus.result && latestResult != null;

  bool get isCompletionStep => status == DailyWarmUpStatus.completion;

  QuestionEntity? get currentQuestion {
    if (currentQuestionIndex < 0 || currentQuestionIndex >= usableQuestions.length) return null;
    return usableQuestions[currentQuestionIndex];
  }

  bool get isFinalQuestion => usableQuestions.isNotEmpty && currentQuestionIndex >= usableQuestions.length - 1;

  int get answeredCount => results.length;

  int get correctCount => results.where((result) => result.isCorrect).length;

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
}
