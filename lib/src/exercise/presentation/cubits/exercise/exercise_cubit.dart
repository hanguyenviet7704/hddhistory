part of '../../../exercise.dart';

@lazySingleton
class ExerciseCubit extends Cubit<ExerciseState> with CubitUseCaseHandlerMixin<ExerciseState> {
  final GetAllLearningItemsUseCase _getAllUseCase;
  final GetLearningItemUseCase _getUseCase;
  final CreateLearningItemUseCase _createUseCase;
  final UpdateLearningItemUseCase _updateUseCase;
  final DeleteLearningItemUseCase _deleteUseCase;

  ExerciseCubit(
    this._getAllUseCase,
    this._getUseCase,
    this._createUseCase,
    this._updateUseCase,
    this._deleteUseCase,
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
        emit(state.copyWith(
          status: ExerciseStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (pageData) {
        emit(state.copyWith(
          status: ExerciseStatus.success,
          pageData: pageData,
        ));
      },
    );
  }

  void loadLearningItem(String id) async {
    await runUseCase<LearningItemEntity>(
      usecase: () => _getUseCase(id),
      buildLoadingState: () => state.copyWith(status: ExerciseStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: ExerciseStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (item) {
        emit(state.copyWith(
          status: ExerciseStatus.success,
          selectedItem: item,
        ));
      },
    );
  }

  void createLearningItem(LearningItemEntity entity) async {
    await runUseCase<LearningItemEntity>(
      usecase: () => _createUseCase(entity),
      buildLoadingState: () => state.copyWith(status: ExerciseStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: ExerciseStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (newItem) {
        final updatedItems = [...state.pageData.items, newItem];
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: ExerciseStatus.success,
          pageData: updatedPageData,
        ));
      },
    );
  }

  void updateLearningItem(LearningItemEntity entity) async {
    await runUseCase<LearningItemEntity>(
      usecase: () => _updateUseCase(entity),
      buildLoadingState: () => state.copyWith(status: ExerciseStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: ExerciseStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (updatedItem) {
        final updatedItems = state.pageData.items.map((item) => item.id == updatedItem.id ? updatedItem : item).toList();
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: ExerciseStatus.success,
          pageData: updatedPageData,
          selectedItem: updatedItem,
        ));
      },
    );
  }

  void deleteLearningItem(String id) async {
    await runUseCase<Unit>(
      usecase: () => _deleteUseCase(id),
      buildLoadingState: () => state.copyWith(status: ExerciseStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: ExerciseStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (_) {
        final updatedItems = state.pageData.items.where((item) => item.id != id).toList();
        final updatedPageData = state.pageData.copyWith(items: updatedItems);
        emit(state.copyWith(
          status: ExerciseStatus.success,
          pageData: updatedPageData,
        ));
      },
    );
  }
}

