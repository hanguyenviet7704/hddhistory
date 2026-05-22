part of '../../in_app_survey.dart';

@lazySingleton
class InAppSurveyCubit extends Cubit<InAppSurveyState> with CubitUseCaseHandlerMixin<InAppSurveyState> {
  final GetInAppSurveyConfigUseCase _getConfigUseCase;
  final CreateInAppSurveyResponseUseCase _createResponseUseCase;

  InAppSurveyCubit(
    this._getConfigUseCase,
    this._createResponseUseCase,
  ) : super(InAppSurveyState.initial());

  Future<void> loadInAppSurveyConfig() async {
    await runUseCase<InAppSurveyConfigEntity>(
      usecase: () => _getConfigUseCase(unit),
      buildLoadingState: () => state.copyWith(
        status: InAppSurveyStatus.loading,
        errorMessage: null,
      ),
      onFailure: (error) {
        emit(
          _resetDraft(
            state.copyWith(
              status: InAppSurveyStatus.failure,
              config: null,
              errorMessage: error,
            ),
          ),
        );
      },
      onSuccess: (config) {
        emit(
          _resetDraft(
            state.copyWith(
              status: InAppSurveyStatus.success,
              step: config.hasUsableConfig ? InAppSurveyStep.entry : InAppSurveyStep.hidden,
              config: config,
              errorMessage: null,
            ),
          ),
        );
      },
    );
  }

  void openSurvey() {
    if (!state.isEntryVisible) return;
    emit(
      _resetDraft(
        state.copyWith(
          step: InAppSurveyStep.rating,
          errorMessage: null,
        ),
      ),
    );
    _trackPopupView(InAppSurveyStep.rating);
  }

  void closeSurvey() {
    if (state.step != InAppSurveyStep.entry && state.step != InAppSurveyStep.hidden) {
      _trackPopupClose(state.step);
    }
    emit(_resetDraft(state.copyWith(step: state.hasUsableConfig ? InAppSurveyStep.entry : InAppSurveyStep.hidden)));
  }

  void selectBranch(int index) {
    if (state.step != InAppSurveyStep.rating) return;
    final branches = state.config?.branches;
    if (branches == null || index < 0 || index >= branches.length) return;
    final branch = branches[index];
    if (!branch.isUsableForSurvey) return;

    emit(
      state.copyWith(
        step: InAppSurveyStep.closedQuestion,
        selectedBranchIndex: index,
        selectedOptionIds: const [],
        feedback: '',
        errorMessage: null,
      ),
    );
    _trackEmojiClick(branch);
    _trackClosedQuestionView(branch);
  }

  void toggleOption(String optionId) {
    if (state.step != InAppSurveyStep.closedQuestion || optionId.trim().isEmpty) return;
    final branch = state.selectedBranch;
    if (branch == null) return;
    final hasOption = branch.closedQuestion.options.any((option) => option.id == optionId);
    if (!hasOption) return;

    final current = state.selectedOptionIds;
    final next = switch (branch.closedQuestion.type) {
      InAppSurveyClosedQuestionType.singleChoice => [optionId],
      InAppSurveyClosedQuestionType.multipleChoice => current.contains(optionId) ? current.where((id) => id != optionId).toList() : [...current, optionId],
    };

    emit(state.copyWith(selectedOptionIds: next, errorMessage: null));
    _trackClosedOptionClick(branch, next);
  }

  void continueToOpenFeedback() {
    if (!state.canContinueClosedQuestion) return;
    final branch = state.selectedBranch;
    if (branch == null) return;
    _trackClosedContinueClick(branch, state.selectedOptionIds);
    emit(state.copyWith(step: InAppSurveyStep.openFeedback, errorMessage: null));
    _trackOpenQuestionView(branch, state.selectedOptionIds);
  }

  void updateFeedback(String value) {
    if (state.step != InAppSurveyStep.openFeedback) return;
    emit(state.copyWith(feedback: value));
  }

  Future<void> submitSurveyResponse() async {
    if (!state.canSubmit) return;
    final branch = state.selectedBranch;
    if (branch == null) return;

    final response = InAppSurveyResponseEntity(
      branchId: branch.id,
      selectedOptionIds: state.selectedOptionIds,
      feedback: state.trimmedFeedback,
    );

    emit(state.copyWith(isSubmitting: true, errorMessage: null));
    _trackSendClick(branch, response);
    final result = await _createResponseUseCase(response).run();

    result.fold(
      (exception) {
        _trackSendFailure(branch, response, exception);
        emit(
          state.copyWith(
            status: InAppSurveyStatus.failure,
            isSubmitting: false,
            errorMessage: exception.message ?? 'Unknown error',
          ),
        );
      },
      (_) {
        _trackSendSuccess(branch, response);
        emit(
          _resetDraft(
            state.copyWith(
              status: InAppSurveyStatus.success,
              isSubmitting: false,
              step: state.hasUsableConfig ? InAppSurveyStep.entry : InAppSurveyStep.hidden,
              errorMessage: null,
            ),
          ),
        );
      },
    );
  }

  InAppSurveyState _resetDraft(InAppSurveyState current) {
    return current.copyWith(
      selectedBranchIndex: null,
      selectedOptionIds: const [],
      feedback: '',
      isSubmitting: false,
    );
  }
}
