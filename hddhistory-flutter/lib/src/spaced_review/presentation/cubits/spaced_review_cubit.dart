part of '../../spaced_review.dart';

@lazySingleton
class SpacedReviewCubit extends Cubit<SpacedReviewState> with CubitUseCaseHandlerMixin<SpacedReviewState> {
  final GetSpacedReviewTodayUseCase _getTodayUseCase;
  final SubmitSpacedReviewUseCase _submitUseCase;

  SpacedReviewCubit(this._getTodayUseCase, this._submitUseCase) : super(SpacedReviewState.initial());

  /// Called whenever Home becomes active. What is due changes with the clock,
  /// not with anything the app does, so this always refetches — except while a
  /// session is running, where a refetch would swap the questions mid-play.
  Future<void> refresh() async {
    if (state.isInSession || state.status == SpacedReviewStatus.loading || state.status == SpacedReviewStatus.completion) return;

    emit(state.copyWith(status: SpacedReviewStatus.loading));
    await runUseCase<SpacedReviewTodayEntity>(
      usecase: () => _getTodayUseCase(unit),
      onFailure: (error) => emit(state.copyWith(status: SpacedReviewStatus.failure, errorMessage: error)),
      onSuccess: (today) {
        final questions = <QuestionEntity>[];
        final keypointIds = <String>[];
        for (final keypoint in today.keypoints) {
          for (final question in filterUsableDailyWarmUpQuestions(keypoint.questions)) {
            questions.add(question);
            keypointIds.add(keypoint.keypointId);
          }
        }
        emit(
          _clearSession(
            state.copyWith(
              status: SpacedReviewStatus.ready,
              dueCount: today.dueCount,
              keypoints: today.keypoints,
              nextDueAt: today.nextDueAt,
              usableQuestions: questions,
              questionKeypointIds: keypointIds,
              errorMessage: null,
            ),
          ),
        );
      },
    );
  }

  void start() {
    if (!state.hasReviewAvailable) return;
    emit(_clearSession(state.copyWith(status: SpacedReviewStatus.question)));
  }

  /// Leaving mid-session still credits every keypoint that was fully answered,
  /// then reloads so the Home card reflects what is left.
  Future<void> closeFlow() async {
    await _submitAnswered();
    emit(_clearSession(state.copyWith(status: SpacedReviewStatus.ready)));
    await refresh();
  }

  void selectChoiceAnswer(int index) {
    final question = state.currentQuestion;
    if (question == null || state.latestResult != null) return;

    if (question.typedPayload is QuestionMultipleChoicePayloadEntity) {
      final selected = Set<int>.from(state.selectedAnswersIndices);
      if (selected.contains(index)) {
        selected.remove(index);
      } else {
        selected.add(index);
      }
      emit(state.copyWith(selectedAnswersIndices: selected));
      return;
    }

    emit(state.copyWith(selectedAnswerIndex: index));
  }

  void setOrderedOptionIds(List<int> optionIds) {
    if (state.latestResult != null) return;
    emit(state.copyWith(orderedOptionIds: List<int>.from(optionIds)));
  }

  void placeOption({required int slotIndex, required int optionId}) {
    if (state.latestResult != null) return;
    final placed = Map<int, int>.from(state.placedOptionIds);
    placed.removeWhere((key, value) => key == slotIndex || value == optionId);
    placed[slotIndex] = optionId;
    emit(state.copyWith(placedOptionIds: placed));
  }

  void removePlacedOption(int slotIndex) {
    if (state.latestResult != null) return;
    final placed = Map<int, int>.from(state.placedOptionIds)..remove(slotIndex);
    emit(state.copyWith(placedOptionIds: placed));
  }

  void toggleWordIndex(int index) {
    if (state.latestResult != null) return;
    final selected = Set<int>.from(state.selectedWordIndices);
    if (selected.contains(index)) {
      selected.remove(index);
    } else {
      selected.add(index);
    }
    emit(state.copyWith(selectedWordIndices: selected));
  }

  DailyWarmUpAnswerResultEntity? checkCurrentQuestion() {
    final question = state.currentQuestion;
    if (question == null || !state.canCheckCurrentQuestion) return null;

    final result = evaluateDailyWarmUpQuestion(
      question,
      questionIndex: state.currentQuestionIndex,
      selectedAnswerIndex: state.selectedAnswerIndex,
      selectedAnswersIndices: state.selectedAnswersIndices,
      orderedOptionIds: state.orderedOptionIds,
      placedOptionIds: state.placedOptionIds,
      selectedWordIndices: state.selectedWordIndices,
    );
    emit(
      state.copyWith(
        status: SpacedReviewStatus.result,
        latestResult: result,
        results: [...state.results, result],
      ),
    );
    return result;
  }

  Future<void> continueFromResult() async {
    if (state.latestResult == null) return;

    if (state.isFinalQuestion) {
      // Show the completion screen straight away; the schedule update is
      // fire-and-forget from the reader's point of view.
      emit(_clearAnswer(state.copyWith(status: SpacedReviewStatus.completion, latestResult: null)));
      await _submitAnswered();
      return;
    }

    emit(
      _clearAnswer(
        state.copyWith(
          status: SpacedReviewStatus.question,
          currentQuestionIndex: state.currentQuestionIndex + 1,
          latestResult: null,
        ),
      ),
    );
  }

  /// Back to Home from the completion screen: drop the finished session and
  /// fetch whatever is still due (usually nothing until tomorrow).
  Future<void> finish() async {
    emit(_clearSession(state.copyWith(status: SpacedReviewStatus.ready)));
    await refresh();
  }

  Future<void> _submitAnswered() async {
    final answered = state.answeredKeypointResults;
    if (answered.isEmpty) return;
    await runUseCaseVoid(
      usecase: () => _submitUseCase(answered),
      // A lost submit only means those keypoints come back again next time —
      // never worth interrupting the reader for.
      onFailure: (_) {},
      onSuccess: () {},
    );
  }

  SpacedReviewState _clearSession(SpacedReviewState input) {
    return _clearAnswer(input.copyWith(currentQuestionIndex: 0, results: const [], latestResult: null));
  }

  SpacedReviewState _clearAnswer(SpacedReviewState input) {
    return input.copyWith(
      selectedAnswerIndex: -1,
      selectedAnswersIndices: const {},
      orderedOptionIds: const [],
      placedOptionIds: const {},
      selectedWordIndices: const {},
    );
  }
}
