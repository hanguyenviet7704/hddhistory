part of '../../warm_up.dart';

@lazySingleton
class WarmUpCubit extends Cubit<WarmUpState> with CubitUseCaseHandlerMixin<WarmUpState> {
  final CheckWarmUpForCourseUseCase _checkUseCase;

  WarmUpCubit(this._checkUseCase) : super(WarmUpState.initial());

  /// Called when the roadmap loads a course. Silently resolves whether a
  /// return-refresher is due; failures never block the roadmap — they just
  /// leave the floating CTA in its normal "start/continue lesson" state.
  Future<void> check(String courseId) async {
    final normalizedCourseId = courseId.trim();
    if (normalizedCourseId.isEmpty) {
      emit(state.copyWith(status: WarmUpStatus.closed, isDue: false, previousLesson: null, courseId: ''));
      return;
    }

    await runUseCase<WarmUpForCourseEntity>(
      usecase: () => _checkUseCase(normalizedCourseId),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: WarmUpStatus.closed,
            isDue: false,
            previousLesson: null,
            courseId: normalizedCourseId,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (entity) {
        emit(
          state.copyWith(
            status: WarmUpStatus.closed,
            isDue: entity.isDue,
            previousLesson: entity.previousLesson,
            usableQuestions: entity.usableQuestions,
            courseId: normalizedCourseId,
            errorMessage: null,
          ),
        );
      },
    );
  }

  void openIntro() {
    if (!state.hasWarmUpAvailable) return;
    emit(state.copyWith(status: WarmUpStatus.intro));
  }

  void startWarmUp() {
    if (!state.hasWarmUpAvailable) return;
    emit(_clearCurrentAnswer(state.copyWith(status: WarmUpStatus.question, currentQuestionIndex: 0, results: const [], latestResult: null)));
  }

  void closeFlow() {
    // Closing CONSUMES the offer (isDue: false): whether the user finished,
    // skipped, or X-ed out, the roadmap CTA must revert to the normal
    // Continue/Start-lesson button — the refresher is offered once per return,
    // not looped.
    emit(state.copyWith(status: WarmUpStatus.closed, isRoutingToLesson: false, isDue: false));
  }

  /// Closes the flow AND asks the roadmap page to open today's lesson.
  /// The lesson/paywall must be launched from the ROADMAP's context (it has
  /// the full provider tree and stays alive), not from a warm-up page that is
  /// being popped — otherwise dismissing the paywall lands the user back on a
  /// dead-end completion screen. The roadmap's WarmUpCubit listener picks this
  /// flag up and triggers the start-lesson action. Also consumes the offer
  /// (isDue: false) so the CTA reverts to Continue.
  void closeFlowAndRouteToLesson() {
    emit(state.copyWith(status: WarmUpStatus.closed, isRoutingToLesson: true, isDue: false));
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
        status: WarmUpStatus.result,
        latestResult: result,
        results: [...state.results, result],
      ),
    );
    return result;
  }

  void continueFromResult() {
    if (state.latestResult == null) return;

    if (state.isFinalQuestion) {
      emit(_clearCurrentAnswer(state.copyWith(status: WarmUpStatus.completion, latestResult: null)));
      return;
    }

    emit(
      _clearCurrentAnswer(
        state.copyWith(
          status: WarmUpStatus.question,
          currentQuestionIndex: state.currentQuestionIndex + 1,
          latestResult: null,
        ),
      ),
    );
  }

  void setRoutingToLesson(bool value) => emit(state.copyWith(isRoutingToLesson: value));

  WarmUpState _clearCurrentAnswer(WarmUpState input) {
    return input.copyWith(
      selectedAnswerIndex: -1,
      selectedAnswersIndices: const {},
      orderedOptionIds: const [],
      placedOptionIds: const {},
      selectedWordIndices: const {},
    );
  }
}
