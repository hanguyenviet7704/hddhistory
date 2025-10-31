part of '../../../lesson.dart';

@lazySingleton
class LessonCubit extends Cubit<LessonState> with CubitUseCaseHandlerMixin<LessonState> {
  final GetAllLearningItemsUseCase _getAllLearningItemUseCase;
  final GetLearningItemUseCase _getLearningItemUseCase;

  LessonCubit(
    this._getAllLearningItemUseCase,
    this._getLearningItemUseCase,
  ) : super(LessonState.initial());

  void setCurrentLearningItem() {
    if (state.currentLearningItem.id.isEmpty) return;

    switch (state.currentLearningItem.type) {
      case LearningItemType.theory:
        AppDI.injector.get<TheoryCubit>()
          ..reset()
          ..setCurrentLearningItem(state.currentLearningItem);
        TheoryRoute().go(AppConfig.instance.context!);
        break;
      case LearningItemType.exercise:
        AppDI.injector.get<ExerciseCubit>()
          ..reset()
          ..setCurrentLearningItem(state.currentLearningItem);
        ExerciseRoute().go(AppConfig.instance.context!);
        break;
    }
  }

  void setCurrentLessonIndex(int index) => emit(state.copyWith(currentLessonIndex: index));

  void nextLearningItem() {
    if (state.currentLearningItemIndex >= state.pageData.items.length - 1) return;
    emit(state.copyWith(currentLearningItemIndex: state.currentLearningItemIndex + 1));
    loadLearningItem(state.currentLearningItem.id);
  }

  void previousLearningItem() {
    if (state.currentLearningItemIndex <= 0) return;
    emit(state.copyWith(currentLearningItemIndex: state.currentLearningItemIndex - 1));
    loadLearningItem(state.currentLearningItem.id);
  }

  void loadAllLearningItems({
    bool isInit = false,
  }) async {
    // Prevent multiple simultaneous loads
    if (!isInit && state.status == LessonStatus.loading) return;

    // Prevent loading if already on last page (unless it's init)
    if (!isInit && state.pageData.isLastPage) return;

    PageBreakRequest pageRequest;
    pageRequest = isInit ? const PageBreakRequest() : PageBreakRequest(page: state.pageData.nextPage);

    await runUseCasePageBreak<LearningItemEntity>(
      usecase: () => _getAllLearningItemUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: LessonStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: LessonStatus.failure, errorMessage: error));
      },
      onSuccess: (pageData) {
        emit(state.copyWith(status: LessonStatus.success, pageData: pageData, currentLearningItemIndex: 0));
        loadLearningItem(pageData.items.first.id);
      },
    );
  }

  void loadLearningItem(String id) async {
    await runUseCase<LearningItemEntity>(
      usecase: () => _getLearningItemUseCase(id),
      buildLoadingState: () => state.copyWith(status: LessonStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: LessonStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(state.copyWith(status: LessonStatus.success));
        setCurrentLearningItem();
      },
    );
  }
}
