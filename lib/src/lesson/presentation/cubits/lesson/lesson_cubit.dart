part of '../../../lesson.dart';

@lazySingleton
class LessonCubit extends Cubit<LessonState> with CubitUseCaseHandlerMixin<LessonState> {
  final GetAllLearningItemsUseCase _getAllLearningItemUseCase;
  final GetLearningItemUseCase _getLearningItemUseCase;
  final ProgressCubit _progressCubit;
  final RoleplayCubit _roleplayCubit;
  final ExerciseCubit _exerciseCubit;
  final TheoryCubit _theoryCubit;

  LessonCubit(
    this._getAllLearningItemUseCase,
    this._getLearningItemUseCase,
    this._progressCubit,
    this._roleplayCubit,
    this._exerciseCubit,
    this._theoryCubit,
  ) : super(LessonState.initial());

  void reset() => emit(LessonState.initial());

  //* Roleplay Page Flow
  void setLearningItemFromRoleplay(LearningItemEntity learningItem) {
    emit(state.copyWith(pageData: state.pageData.copyWith(items: [learningItem]), currentLearningItemIndex: 0));
    setCurrentLearningItem(learningItem);
  }

  void setRoleplayDataToExerciseCubit(LearningItemEntity learningItem) {
    emit(state.copyWith(pageData: state.pageData.copyWith(items: [learningItem])));
    _exerciseCubit.setRoleplayQuestions(learningItem);
  }

  //* Lesson Page Flow
  void setCurrentLearningItem(LearningItemEntity learningItem) {
    if (learningItem.id.isEmpty) return;

    switch (learningItem.type) {
      case LearningItemType.theory:
        _theoryCubit
          ..reset()
          ..setCurrentLearningItem(learningItem);
        break;
      case LearningItemType.exercise || LearningItemType.roleplay:
        _exerciseCubit
          ..reset()
          ..setCurrentLearningItem(learningItem);
        break;
    }
  }

  void nextLearningItem() {
    if (state.currentLearningItemIndex >= state.pageData.items.length - 1) {
      if (state.currentLearningItem.type == LearningItemType.roleplay) {
        AppConfig.instance.context!.back();
        _roleplayCubit.goToNextSection();
        return;
      }

      if (state.subQuestions.isNotEmpty) {
        ReviewTimeRoute().go(AppConfig.instance.context!);
        return;
      }

      _updateUserProgressKeypoint();
      KeypointCompleteRoute().go(AppConfig.instance.context!);
      return;
    }

    emit(state.copyWith(currentLearningItemIndex: state.currentLearningItemIndex + 1));
    setCurrentLearningItem(state.currentLearningItem);
    preloadNextLearningItem();
  }

  void _updateUserProgressKeypoint() {
    UpdateUserProgressKeypointData keypointData = UpdateUserProgressKeypointData(
      keypointId: state.currentLearningItem.keypointId,
      averageScore: 0.0,
      passed: true,
      reviews: '',
    );

    UpdateUserProgressKeypointParams keypointParams = UpdateUserProgressKeypointParams(keypoints: [keypointData]);
    _progressCubit.updateUserProgressKeypoint(LessonType.lesson, keypointParams);
  }

  void previousLearningItem() {
    if (state.currentLearningItemIndex <= 0) return;
    emit(state.copyWith(currentLearningItemIndex: state.currentLearningItemIndex - 1));
    setCurrentLearningItem(state.currentLearningItem);
  }

  void setCurrentLessonIndex(int index) => emit(state.copyWith(currentLessonIndex: index));

  void addSubQuestion(QuestionEntity question) => emit(state.copyWith(subQuestions: [...state.subQuestions, question]));

  void reviewDone() {
    if (state.subQuestions.isEmpty) {
      _updateUserProgressKeypoint();
      return;
    }

    LearningItemEntity learningItem = state.pageData.items.firstWhere((item) => item.type == LearningItemType.exercise, orElse: () => LearningItemEntity());
    learningItem = learningItem.copyWith(
      mainQuestions: state.subQuestions,
      type: LearningItemType.exercise,
      subQuestions: [],
      isPlayingSubQuestions: true,
    );
    _exerciseCubit.setSubQuestions(learningItem);
    List<LearningItemEntity> items = List<LearningItemEntity>.from(state.pageData.items);
    items.add(learningItem);
    emit(
      state.copyWith(
        pageData: state.pageData.copyWith(items: items),
        currentLearningItemIndex: items.length - 1,
        subQuestions: [],
      ),
    );
    LessonRoute().go(AppConfig.instance.context!);
  }

  void loadAllLearningItems({
    bool isInit = false,
    String? keypointId,
  }) async {
    // Prevent multiple simultaneous loads
    if (!isInit && state.status == LessonStatus.loading) return;

    // Prevent loading if already on last page (unless it's init)
    if (!isInit && state.pageData.isLastPage) return;

    LearningItemFilter filter = LearningItemFilter(keypointId: keypointId);

    PageBreakRequest<LearningItemFilter> pageRequest = isInit
        ? PageBreakRequest<LearningItemFilter>(filter: filter, orderBy: 'index', order: PageBreakOrder.asc)
        : PageBreakRequest<LearningItemFilter>(
            page: state.pageData.nextPage,
            filter: filter,
            orderBy: 'index',
            order: PageBreakOrder.asc,
          );

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
        if (pageData.items.isEmpty) return;
        loadLearningItem(
          pageData.items.first.id,
          onSuccess: (item) => setCurrentLearningItem(item),
        );
        preloadNextLearningItem();
      },
    );
  }

  void preloadNextLearningItem() {
    if (state.pageData.items.length <= state.currentLearningItemIndex + 1) return;
    loadLearningItem(state.pageData.items[state.currentLearningItemIndex + 1].id);
  }

  void loadLearningItem(String id, {void Function(LearningItemEntity)? onSuccess}) async {
    await runUseCase<LearningItemEntity>(
      usecase: () => _getLearningItemUseCase(id),
      // buildLoadingState: () => state.copyWith(status: LessonStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: LessonStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(state.copyWith(status: LessonStatus.success));
        updatePageBreakItem(
          currentPageData: state.pageData,
          updatedItem: item,
          getId: (item) => item.id,
          onSuccess: (pageData) {
            emit(state.copyWith(pageData: pageData));
          },
        );
        onSuccess?.call(item);
      },
    );
  }
}
