part of '../../spaced_review.dart';

enum SpacedReviewStatus { initial, loading, ready, question, result, completion, failure }

@freezed
abstract class SpacedReviewState with _$SpacedReviewState {
  const factory SpacedReviewState({
    @Default(SpacedReviewStatus.initial) SpacedReviewStatus status,
    @Default(0) int dueCount,
    @Default([]) List<SpacedReviewKeypointEntity> keypoints,
    DateTime? nextDueAt,
    // The session's questions flattened in play order, and — index for index —
    // the keypoint each one belongs to, so a result can be credited back.
    @Default([]) List<QuestionEntity> usableQuestions,
    @Default([]) List<String> questionKeypointIds,
    @Default(0) int currentQuestionIndex,
    @Default([]) List<DailyWarmUpAnswerResultEntity> results,
    DailyWarmUpAnswerResultEntity? latestResult,
    @Default(-1) int selectedAnswerIndex,
    @Default({}) Set<int> selectedAnswersIndices,
    @Default([]) List<int> orderedOptionIds,
    @Default({}) Map<int, int> placedOptionIds,
    @Default({}) Set<int> selectedWordIndices,
    String? errorMessage,
  }) = _SpacedReviewState;

  factory SpacedReviewState.initial() => const SpacedReviewState();
}

extension SpacedReviewStateX on SpacedReviewState {
  /// Home card gate: something is due AND at least one question can render.
  bool get hasReviewAvailable => usableQuestions.isNotEmpty;

  /// Keypoints that actually made it into the session (some may have had no
  /// renderable question and were dropped).
  int get sessionKeypointCount => questionKeypointIds.toSet().length;

  bool get isInSession => status == SpacedReviewStatus.question || status == SpacedReviewStatus.result;

  QuestionEntity? get currentQuestion {
    if (currentQuestionIndex < 0 || currentQuestionIndex >= usableQuestions.length) return null;
    return usableQuestions[currentQuestionIndex];
  }

  bool get isFinalQuestion => usableQuestions.isNotEmpty && currentQuestionIndex >= usableQuestions.length - 1;

  /// Neutral (no-correct-answer) questions count as remembered: there was
  /// nothing to get wrong.
  int get correctCount => results.where((result) => result.type != DailyWarmUpAnswerResultType.incorrect).length;

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

  /// Per-keypoint outcome of the questions answered so far. A keypoint is only
  /// reported once EVERY one of its questions has an answer — quitting halfway
  /// through a keypoint leaves its schedule untouched rather than grading it on
  /// half the evidence.
  List<SpacedReviewResultEntity> get answeredKeypointResults {
    final answered = <String, int>{};
    final wrong = <String>{};
    for (var i = 0; i < results.length && i < questionKeypointIds.length; i++) {
      final keypointId = questionKeypointIds[i];
      answered[keypointId] = (answered[keypointId] ?? 0) + 1;
      if (results[i].type == DailyWarmUpAnswerResultType.incorrect) wrong.add(keypointId);
    }

    final total = <String, int>{};
    for (final keypointId in questionKeypointIds) {
      total[keypointId] = (total[keypointId] ?? 0) + 1;
    }

    return [
      for (final entry in answered.entries)
        if (entry.value >= (total[entry.key] ?? 0)) SpacedReviewResultEntity(keypointId: entry.key, correct: !wrong.contains(entry.key)),
    ];
  }

  /// Projects the session into a [DailyWarmUpState] so the daily-warm-up
  /// player widgets (progress dots, answer bodies, result sheet) are reused
  /// as-is — the same trick `WarmUpState.asDailyWarmUpState` uses.
  DailyWarmUpState get asDailyWarmUpState => DailyWarmUpState(
    status: switch (status) {
      SpacedReviewStatus.result => DailyWarmUpStatus.result,
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
