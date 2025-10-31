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

  void nextQuestion() {
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
}
