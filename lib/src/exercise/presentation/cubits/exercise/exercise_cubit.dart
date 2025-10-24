part of '../../../exercise.dart';

@lazySingleton
class ExerciseCubit extends Cubit<ExerciseState> with CubitUseCaseHandlerMixin<ExerciseState> {
  final GetAllLearningItemsUseCase _getAllUseCase;
  final GetLearningItemUseCase _getUseCase;

  ExerciseCubit(
    this._getAllUseCase,
    this._getUseCase,
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
      usecase: () => _getAllUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: ExerciseStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ExerciseStatus.failure, errorMessage: error));
      },
      onSuccess: (pageData) {
        emit(state.copyWith(status: ExerciseStatus.success, pageData: pageData));
        QuestionEntity singleChoiceQuestion = pageData.items.firstWhere((item) => item.questions.first.type == QuestionTypeEnum.singleChoice).questions.first;
        emit(state.copyWith(currentQuestion: singleChoiceQuestion));
        AppDI.injector.get<ChoiceCubit>().loadQuestionData(singleChoiceQuestion);
      },
    );
  }

  void loadLearningItem(String id) async {
    await runUseCase<LearningItemEntity>(
      usecase: () => _getUseCase(id),
      buildLoadingState: () => state.copyWith(status: ExerciseStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ExerciseStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(state.copyWith(status: ExerciseStatus.success, currentLearningItem: item));
      },
    );
  }
}
