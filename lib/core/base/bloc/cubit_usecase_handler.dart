part of '../base.dart';

mixin CubitUseCaseHandlerMixin<State> on Cubit<State> {
  /// Execute use case with status-based state pattern (loading → success/failure)
  ///
  /// Use this when your state follows a status enum pattern (loading, success, failure)
  /// and you want to handle entity results without BaseResponse wrapper.
  ///
  /// [usecase] - The use case that returns `TaskEither<AppException, T>`
  /// [buildLoadingState] - Optional function to build loading state when not using [setLoadingState]
  /// [onFailure] - Callback when use case fails, receives error message, should emit state
  /// [onSuccess] - Callback when use case succeeds, receives result data, should emit state
  /// [setLoadingState] - Optional function to control loading state separately
  Future<void> runUseCase<T>({
    required TaskEither<AppException, T> Function() usecase,
    State Function()? buildLoadingState,
    required void Function(String errorMessage) onFailure,
    required void Function(T data) onSuccess,
    State Function(State currentState, {required bool isLoading})? setLoadingState,
  }) async {
    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: true));
    } else if (buildLoadingState != null) {
      emit(buildLoadingState());
    }

    final result = await usecase().run();

    result.fold(
      (exception) => onFailure(exception.message ?? 'Unknown error'),
      (data) => onSuccess(data),
    );

    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: false));
    }
  }

  /// Execute use case returning a list with status-based state pattern
  ///
  /// Similar to runUseCase but specifically for list results
  ///
  /// [usecase] - The use case that returns `TaskEither<AppException, List<T>>`
  /// [buildLoadingState] - Optional function to build loading state when not using [setLoadingState]
  /// [onFailure] - Callback when use case fails, receives error message, should emit state
  /// [onSuccess] - Callback when use case succeeds, receives list data, should emit state
  /// [setLoadingState] - Optional function to control loading state separately
  Future<void> runUseCaseList<T>({
    required TaskEither<AppException, List<T>> Function() usecase,
    State Function()? buildLoadingState,
    required void Function(String errorMessage) onFailure,
    required void Function(List<T> data) onSuccess,
    State Function(State currentState, {required bool isLoading})? setLoadingState,
  }) async {
    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: true));
    } else if (buildLoadingState != null) {
      emit(buildLoadingState());
    }

    final result = await usecase().run();

    result.fold(
      (exception) => onFailure(exception.message ?? 'Unknown error'),
      (data) => onSuccess(data),
    );

    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: false));
    }
  }

  /// Execute use case returning Unit/void with status-based state pattern
  ///
  /// Use for delete/update operations that don't return data
  ///
  /// [usecase] - The use case that returns `TaskEither<AppException, Unit>`
  /// [buildLoadingState] - Optional function to build loading state when not using [setLoadingState]
  /// [onFailure] - Callback when use case fails, receives error message, should emit state
  /// [onSuccess] - Callback when use case succeeds, should emit state
  /// [setLoadingState] - Optional function to control loading state separately
  Future<void> runUseCaseVoid({
    required TaskEither<AppException, Unit> Function() usecase,
    State Function()? buildLoadingState,
    required void Function(String errorMessage) onFailure,
    required void Function() onSuccess,
    State Function(State currentState, {required bool isLoading})? setLoadingState,
  }) async {
    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: true));
    } else if (buildLoadingState != null) {
      emit(buildLoadingState());
    }

    final result = await usecase().run();

    result.fold(
      (exception) => onFailure(exception.message ?? 'Unknown error'),
      (_) => onSuccess(),
    );

    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: false));
    }
  }

  /// Execute use case with pagination support (BasePageBreak)
  ///
  /// Use this for paginated list APIs. Handles automatic merging of pages.
  ///
  /// [usecase] - The use case that returns `TaskEither<AppException, BasePageBreak<T>>`
  /// [currentPageData] - The current page data from state
  /// [isInit] - Whether this is initial load (true) or loading more (false)
  /// [buildLoadingState] - Optional function to build loading state when not using [setLoadingState]
  /// [onFailure] - Callback when use case fails, receives error message, should emit state
  /// [onSuccess] - Callback when use case succeeds, receives merged page data, should emit state
  /// [setLoadingState] - Optional function to control loading state separately
  Future<void> runUseCasePageBreak<T>({
    required TaskEither<AppException, BasePageBreak<T>> Function() usecase,
    required BasePageBreak<T> currentPageData,
    required bool isInit,
    State Function()? buildLoadingState,
    required void Function(String errorMessage) onFailure,
    required void Function(BasePageBreak<T> mergedPageData) onSuccess,
    State Function(State currentState, {required bool isLoading})? setLoadingState,
  }) async {
    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: true));
    } else if (buildLoadingState != null) {
      emit(buildLoadingState());
    }

    final result = await usecase().run();

    result.fold(
      (exception) => onFailure(exception.message ?? 'Unknown error'),
      (pageData) {
        // Merge with existing data if not init
        final List<T> existingItems = isInit ? [] : currentPageData.items;
        final mergedPageBreak = BasePageBreak<T>(
          currentPage: pageData.currentPage,
          totalPages: pageData.totalPages,
          itemsPerPage: pageData.itemsPerPage,
          items: [...existingItems, ...pageData.items],
        );
        onSuccess(mergedPageBreak);
      },
    );

    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: false));
    }
  }

  /// Update a single item in BasePageBreak list by ID
  ///
  /// Finds and replaces an item in the BasePageBreak items list with matching ID.
  /// If no matching item found, returns the original BasePageBreak unchanged.
  ///
  /// Example:
  /// ```dart
  /// final updatedPageData = updatePageBreakItem(
  ///   currentPageData: state.lessonsPageData,
  ///   updatedItem: completedLesson,
  ///   getId: (lesson) => lesson.id,
  /// );
  /// emit(state.copyWith(lessonsPageData: updatedPageData));
  /// ```
  ///
  /// [currentPageData] - Current page data from state
  /// [updatedItem] - New item to replace the old one
  /// [getId] - Function to extract ID from item for comparison
  void updatePageBreakItem<T, ID>({
    required BasePageBreak<T> currentPageData,
    required T updatedItem,
    required ID Function(T item) getId,
    required void Function(BasePageBreak<T> updatedPageData) onSuccess,
  }) {
    final updatedId = getId(updatedItem);
    final updatedItems = currentPageData.items.map((item) {
      return getId(item) == updatedId ? updatedItem : item;
    }).toList();

    onSuccess(
      BasePageBreak<T>(
        currentPage: currentPageData.currentPage,
        totalPages: currentPageData.totalPages,
        itemsPerPage: currentPageData.itemsPerPage,
        items: updatedItems,
      ),
    );
  }
}
