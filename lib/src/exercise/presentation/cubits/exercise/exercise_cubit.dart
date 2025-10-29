part of '../../../exercise.dart';

@lazySingleton
class ExerciseCubit extends Cubit<ExerciseState> with CubitUseCaseHandlerMixin<ExerciseState> {
  final GetAllLearningItemsUseCase _getAllLearningItemUseCase;
  final GetLearningItemUseCase _getLearningItemUseCase;

  ExerciseCubit(
    this._getAllLearningItemUseCase,
    this._getLearningItemUseCase,
  ) : super(ExerciseState.initial());

  void nextQuestion() {
    if (state.currentQuestionIndex >= state.currentLearningItem.questions.length - 1) return;
    emit(state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1));
    setQuestionData(state.currentQuestion);
  }

  void previousQuestion() {
    if (state.currentQuestionIndex <= 0) return;
    emit(state.copyWith(currentQuestionIndex: state.currentQuestionIndex - 1));
    setQuestionData(state.currentQuestion);
  }

  void nextSubQuestion() {
    if (state.currentSubQuestionIndex >= state.currentLearningItem.subQuestions.length - 1) return;
    emit(state.copyWith(currentSubQuestionIndex: state.currentSubQuestionIndex + 1));
    setQuestionData(state.currentSubQuestion);
  }

  void previousSubQuestion() {
    if (state.currentSubQuestionIndex <= 0) return;
    emit(state.copyWith(currentSubQuestionIndex: state.currentSubQuestionIndex - 1));
    setQuestionData(state.currentSubQuestion);
  }

  void loadAllLearningItems({
    bool isInit = false,
  }) async {
    // Prevent multiple simultaneous loads
    if (!isInit && state.status == ExerciseStatus.loading) return;

    // Prevent loading if already on last page (unless it's init)
    if (!isInit && state.pageData.isLastPage) return;

    PageBreakRequest pageRequest;
    pageRequest = isInit ? const PageBreakRequest() : PageBreakRequest(page: state.pageData.nextPage);

    await runUseCasePageBreak<LearningItemEntity>(
      usecase: () => _getAllLearningItemUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: ExerciseStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ExerciseStatus.failure, errorMessage: error));
      },
      onSuccess: (pageData) {
        emit(state.copyWith(status: ExerciseStatus.success, pageData: pageData));
        QuestionEntity dragAndDropLesson = pageData.items[1].questions[2];
        emit(state.copyWith(currentQuestionIndex: 2));
        AppDI.injector.get<DragAndDropCubit>().loadQuestion(dragAndDropLesson);
        loadLearningItem('68f9e14727faeb3760987e14');
      },
    );
  }

  void loadLearningItem(String id) async {
    await runUseCase<LearningItemEntity>(
      usecase: () => _getLearningItemUseCase(id),
      buildLoadingState: () => state.copyWith(status: ExerciseStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ExerciseStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(state.copyWith(status: ExerciseStatus.success, currentLearningItem: item, currentQuestionIndex: 0));
        setQuestionData(state.currentQuestion);
      },
    );
  }

  void setQuestionData(QuestionEntity question) {
    switch (question.type) {
      case QuestionTypeEnum.singleChoice:
        AppDI.injector.get<ChoiceCubit>()
          ..reset()
          ..loadQuestion(question);
        break;
      case QuestionTypeEnum.multipleChoice:
        AppDI.injector.get<ChoiceCubit>()
          ..reset()
          ..loadQuestion(question);
        break;
      case QuestionTypeEnum.cuesPlacement:
        AppDI.injector.get<CuesPlacementCubit>().loadQuestion(question);
        break;
      case QuestionTypeEnum.dragAndDrop:
        AppDI.injector.get<DragAndDropCubit>().loadQuestion(question);
        break;
      case QuestionTypeEnum.arrangeTheSequence:
        AppDI.injector.get<ArrangeTheSequenceCubit>().loadQuestion(question);
        break;
      case QuestionTypeEnum.stressPlacement:
        AppDI.injector.get<MarkStressWordCubit>().loadQuestion(question);
        break;
      case QuestionTypeEnum.speaking:
        AppDI.injector.get<SpeakingCubit>().loadQuestion(question);
        break;
    }
  }
}
