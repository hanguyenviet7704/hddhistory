part of '../../../exercise.dart';

@lazySingleton
class ExerciseCubit extends Cubit<ExerciseState> with CubitUseCaseHandlerMixin<ExerciseState> {
  final GetAllLearningItemsUseCase _getAllLearningItemUseCase;
  final GetLearningItemUseCase _getLearningItemUseCase;

  ExerciseCubit(
    this._getAllLearningItemUseCase,
    this._getLearningItemUseCase,
  ) : super(ExerciseState.initial());

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
        emit(state.copyWith(currentQuestion: dragAndDropLesson));
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
        emit(state.copyWith(status: ExerciseStatus.success, currentLearningItem: item));
        QuestionEntity arrangeTheSequense = item.questions[2];
        emit(state.copyWith(currentQuestion: arrangeTheSequense));
        AppDI.injector.get<ArrangeTheSequenceCubit>().initializeQuestion(arrangeTheSequense);
      },
    );
  }
}
