part of '../../../lesson.dart';

@lazySingleton
class ExerciseCubit extends Cubit<ExerciseState> with CubitUseCaseHandlerMixin<ExerciseState> {
  final GetLearningItemUseCase _getLearningItemUseCase;

  ExerciseCubit(
    this._getLearningItemUseCase,
  ) : super(ExerciseState.initial());

  void reset() => emit(ExerciseState.initial());

  void setCurrentLearningItem(LearningItemEntity learningItem) {
    emit(state.copyWith(currentLearningItem: learningItem));
    setQuestionData(learningItem.questions.first);
  }

  //* Exercise Page Flow
  void setSubQuestions(LearningItemEntity learningItem) {
    reset();
    setCurrentLearningItem(learningItem);
  }

  void setRoleplayQuestions(LearningItemEntity learningItem) {
    reset();
    setCurrentLearningItem(learningItem);
  }

  void nextQuestion() {
    AppDI.injector.get<LessonCubit>().setIsShowResultOverlay(false);
    // setQuestionPoint(state.currentQuestion);

    if (state.currentQuestionIndex >= state.currentLearningItem.questions.length - 1) {
      AppDI.injector.get<LessonCubit>().nextLearningItem();
      return;
    }
    emit(state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1));
    setQuestionData(state.currentQuestion);
  }

  void previousQuestion() {
    if (state.currentQuestionIndex <= 0) return;
    emit(state.copyWith(currentQuestionIndex: state.currentQuestionIndex - 1));
    setQuestionData(state.currentQuestion);
  }

  void addSubQuestionToLessonCubit() {
    List<QuestionEntity> subQuestions = List<QuestionEntity>.from(state.currentLearningItem.subQuestions);
    if (subQuestions.isEmpty) return;

    QuestionEntity newQuestion = subQuestions.firstWhere((value) => value.mainQuestion == state.currentQuestion.id, orElse: () => QuestionEntity());
    if (newQuestion.id == 0) return;
    AppDI.injector.get<LessonCubit>().addSubQuestion(newQuestion);
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
    AppDI.injector.get<LessonCubit>().setCurrentLessonIndex(state.currentQuestionIndex);
    switch (question.type) {
      case QuestionTypeEnum.singleChoice:
        AppDI.injector.get<ChoiceCubit>()
          ..reset()
          ..setQuestion(question);
        break;
      case QuestionTypeEnum.multipleChoice:
        AppDI.injector.get<ChoiceCubit>()
          ..reset()
          ..setQuestion(question);
        break;
      case QuestionTypeEnum.cuesPlacement:
        AppDI.injector.get<CuesPlacementCubit>()
          ..reset()
          ..setQuestion(question);
        break;
      case QuestionTypeEnum.dragAndDrop:
        AppDI.injector.get<DragAndDropCubit>()
          ..reset()
          ..setQuestion(question);
        break;
      case QuestionTypeEnum.arrangeTheSequence:
        AppDI.injector.get<ArrangeTheSequenceCubit>()
          ..reset()
          ..setQuestion(question);
        break;
      case QuestionTypeEnum.stressPlacement:
        AppDI.injector.get<MarkStressWordCubit>()
          ..reset()
          ..setQuestion(question);
        break;
      case QuestionTypeEnum.speaking:
        AppDI.injector.get<SpeakingCubit>()
          ..reset()
          ..setQuestion(question);
        break;
    }
  }

  //* Roleplay Page Flow
  void setQuestionPoint(QuestionEntity question) {
    if (state.currentLearningItem.type != LearningItemType.roleplay) return;
    KeypointEntity point = question.keypoint.copyWith(isUseRoleplayModule: true);

    switch (question.type) {
      case QuestionTypeEnum.multipleChoice || QuestionTypeEnum.singleChoice:
        int score = AppDI.injector.get<ChoiceCubit>().pointCalculation();
        point = point.copyWith(point: score);
        break;
      case QuestionTypeEnum.cuesPlacement:
        int score = AppDI.injector.get<CuesPlacementCubit>().pointCalculation();
        point = point.copyWith(point: score);
        break;
      case QuestionTypeEnum.dragAndDrop:
        int score = AppDI.injector.get<DragAndDropCubit>().pointCalculation();
        point = point.copyWith(point: score);
        break;
      case QuestionTypeEnum.arrangeTheSequence:
        int score = AppDI.injector.get<ArrangeTheSequenceCubit>().pointCalculation();
        point = point.copyWith(point: score);
        break;
      case QuestionTypeEnum.stressPlacement:
        int score = AppDI.injector.get<MarkStressWordCubit>().pointCalculation();
        point = point.copyWith(point: score);
        break;
      case QuestionTypeEnum.speaking:
        int score = AppDI.injector.get<SpeakingCubit>().pointCalculation();
        point = point.copyWith(point: score);
        break;
    }
    
    AppDI.injector.get<RoleplayPointCubit>().setPoint(point);
  }
}
