part of '../../../lesson.dart';

@lazySingleton
class LessonCubit extends Cubit<LessonState> with CubitUseCaseHandlerMixin<LessonState> {
  final GetAllLearningItemsUseCase _getAllLearningItemUseCase;
  final GetLearningItemUseCase _getLearningItemUseCase;

  LessonCubit(
    this._getAllLearningItemUseCase,
    this._getLearningItemUseCase,
  ) : super(LessonState.initial());

  void setCurrentLearningItem(LearningItemEntity learningItem) {
    if (learningItem.id.isEmpty) return;

    switch (learningItem.type) {
      case LearningItemType.theory:
        AppDI.injector.get<TheoryCubit>()
          ..reset()
          ..setCurrentLearningItem(learningItem);
        break;
      case LearningItemType.exercise:
        AppDI.injector.get<ExerciseCubit>()
          ..reset()
          ..setCurrentLearningItem(learningItem);
        break;
    }
  }

  void setCurrentLessonIndex(int index) => emit(state.copyWith(currentLessonIndex: index));

  void addSubQuestion(QuestionEntity question) => emit(state.copyWith(subQuestions: [...state.subQuestions, question]));

  void reviewDone() {
    if (state.subQuestions.isEmpty) return;
    
    LearningItemEntity learningItem = state.pageData.items.firstWhere((item) => item.type == LearningItemType.exercise, orElse: () => LearningItemEntity());
    learningItem = learningItem.copyWith(questions: state.subQuestions, type: LearningItemType.exercise);
    AppDI.injector.get<ExerciseCubit>().setSubQuestions(learningItem);
    LessonRoute().go(AppConfig.instance.context!);
  }

  void nextLearningItem() {
    if (state.currentLearningItemIndex >= state.pageData.items.length - 1) {
      if (state.subQuestions.isNotEmpty) {
        ReviewTimeRoute().go(AppConfig.instance.context!);
        return;
      }

      LessonCompleteRoute(
        type: 'lesson',
        keypointTitle: state.currentLearningItem.title.en,
        progress: 1.0,
      ).go(AppConfig.instance.context!);
      return;
    }

    final currentProgress = (state.currentLearningItemIndex + 1) / state.pageData.items.length;
    LessonCompleteRoute(
      type: 'keypoint',
      keypointTitle: state.currentLearningItem.title.en,
      progress: currentProgress,
    ).go(AppConfig.instance.context!);
  }

  void continueToNextLearningItem() {
    if (state.currentLearningItemIndex >= state.pageData.items.length - 1) {
      return;
    }
    emit(state.copyWith(currentLearningItemIndex: state.currentLearningItemIndex + 1));
    loadLearningItem(state.currentLearningItem.id);
    LessonRoute().go(AppConfig.instance.context!);
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
        setCurrentLearningItem(item);
        updatePageBreakItem(
          currentPageData: state.pageData,
          updatedItem: item,
          getId: (item) => item.id,
          onSuccess: (pageData) {
            emit(state.copyWith(pageData: pageData));
          },
        );
      },
    );
  }
}
