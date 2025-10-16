part of '../base.dart';

mixin CubitUseCaseHandlerMixin<State> on Cubit<State> {
  // ==================== OLD USE CASE HANDLERS ====================

  Future<void> executeUseCase<T>({
    required TaskEither<AppException, BaseResponse<T>> Function() usecase,
    State Function(State currentState, {required bool isLoading})? setLoadingState,
    Function(BaseResponse<T>)? onSuccess,
    Function(AppException)? onFailure,
  }) async {
    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: true));
    }
    final Either<AppException, BaseResponse<T>> response = await usecase().run();
    response.fold(
      (failure) => onFailure?.call(failure),
      (success) => onSuccess?.call(success),
    );

    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: false));
    }
  }

  Future<void> executeEmptyUseCase({
    required TaskEither<AppException, BaseResponse> Function() usecase,
    State Function(State currentState, {required bool isLoading})? setLoadingState,
    Function(BaseResponse)? onSuccess,
    Function(AppException)? onFailure,
  }) async {
    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: true));
    }
    final Either<AppException, BaseResponse> response = await usecase().run();
    response.fold(
      (failure) => onFailure?.call(failure),
      (success) => onSuccess?.call(success),
    );
    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: false));
    }
  }

  Future<void> executeListUseCase<T>({
    required TaskEither<AppException, BaseResponseList<T>> Function() usecase,
    State Function(State currentState, {required bool isLoading})? setLoadingState,
    Function(BaseResponseList<T>)? onSuccess,
    Function(AppException)? onFailure,
  }) async {
    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: true));
    }
    final Either<AppException, BaseResponseList<T>> response = await usecase().run();
    response.fold(
      (failure) => onFailure?.call(failure),
      (success) => onSuccess?.call(success),
    );
    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: false));
    }
  }

  Future<void> executePageBreakUseCase<T>({
    required TaskEither<AppException, BaseResponse<BasePageBreak<T>>> Function() usecase,
    required BasePageBreak<T> currentPageData,
    required bool isInit,
    required State Function(State currentState, {required BasePageBreak<T> mergedPageBreakData}) setPageBreakState,
    Function(BaseResponse<BasePageBreak<T>>)? onSuccess,
    Function(AppException)? onFailure,
    State Function(State currentState, {required bool isLoading})? setLoadingState,
  }) async {
    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: true));
    }
    final Either<AppException, BaseResponse<BasePageBreak<T>>> response = await usecase().run();
    response.fold(
      (failure) => onFailure?.call(failure),
      (success) {
        List<T> currentData = isInit ? [] : currentPageData.data;
        final mergedPageBreak = BasePageBreak<T>(
          currentPage: success.data!.currentPage,
          lastPage: success.data!.lastPage,
          perPage: success.data!.perPage,
          total: success.data!.total,
          data: [...currentData, ...success.data!.data],
        );
        emit(setPageBreakState(state, mergedPageBreakData: mergedPageBreak));
        onSuccess?.call(success);
      },
    );
    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: false));
    }
  }

  Future<void> executeCustomUseCase<T>({
    required TaskEither<AppException, T> Function() usecase,
    State Function(State currentState, {required bool isLoading})? setLoadingState,
    Function(T)? onSuccess,
    Function(AppException)? onFailure,
  }) async {
    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: true));
    }
    final Either<AppException, T> response = await usecase().run();
    response.fold(
      (failure) => onFailure?.call(failure),
      (success) => onSuccess?.call(success),
    );
    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: false));
    }
  }

  // ==================== NEW SIMPLIFIED USE CASE HANDLERS ====================

  /// Execute use case with status-based state pattern (loading → success/failure)
  ///
  /// Use this when your state follows a status enum pattern (loading, success, failure)
  /// and you want to handle entity results without BaseResponse wrapper.
  ///
  /// [usecase] - The use case that returns `TaskEither<AppException, T>`
  /// [buildLoadingState] - Function to build loading state
  /// [buildFailureState] - Function to build failure state with error message
  /// [buildSuccessState] - Function to build success state with result data
  /// [setLoadingState] - Optional function to control loading state separately
  Future<void> runUseCase<T>({
    required TaskEither<AppException, T> Function() usecase,
    required State Function() buildLoadingState,
    required State Function(String errorMessage) buildFailureState,
    required State Function(T data) buildSuccessState,
    State Function(State currentState, {required bool isLoading})? setLoadingState,
  }) async {
    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: true));
    } else {
      emit(buildLoadingState());
    }

    final result = await usecase().run();

    result.fold(
      (exception) => emit(buildFailureState(exception.message ?? 'Unknown error')),
      (data) => emit(buildSuccessState(data)),
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
  /// [buildLoadingState] - Function to build loading state
  /// [buildFailureState] - Function to build failure state with error message
  /// [buildSuccessState] - Function to build success state with list data
  /// [setLoadingState] - Optional function to control loading state separately
  Future<void> runUseCaseList<T>({
    required TaskEither<AppException, List<T>> Function() usecase,
    required State Function() buildLoadingState,
    required State Function(String errorMessage) buildFailureState,
    required State Function(List<T> data) buildSuccessState,
    State Function(State currentState, {required bool isLoading})? setLoadingState,
  }) async {
    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: true));
    } else {
      emit(buildLoadingState());
    }

    final result = await usecase().run();

    result.fold(
      (exception) => emit(buildFailureState(exception.message ?? 'Unknown error')),
      (data) => emit(buildSuccessState(data)),
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
  /// [buildLoadingState] - Function to build loading state
  /// [buildFailureState] - Function to build failure state with error message
  /// [buildSuccessState] - Function to build success state (no data parameter)
  /// [setLoadingState] - Optional function to control loading state separately
  Future<void> runUseCaseVoid({
    required TaskEither<AppException, Unit> Function() usecase,
    required State Function() buildLoadingState,
    required State Function(String errorMessage) buildFailureState,
    required State Function() buildSuccessState,
    State Function(State currentState, {required bool isLoading})? setLoadingState,
  }) async {
    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: true));
    } else {
      emit(buildLoadingState());
    }

    final result = await usecase().run();

    result.fold(
      (exception) => emit(buildFailureState(exception.message ?? 'Unknown error')),
      (_) => emit(buildSuccessState()),
    );

    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: false));
    }
  }

  /// Execute use case with custom success handler for complex state updates
  ///
  /// Use when you need to perform additional logic before emitting success state
  /// (e.g., merging with existing state, updating collections)
  ///
  /// [usecase] - The use case that returns `TaskEither<AppException, T>`
  /// [buildLoadingState] - Function to build loading state
  /// [buildFailureState] - Function to build failure state with error message
  /// [onSuccess] - Custom handler that receives data and current state, emits manually
  /// [setLoadingState] - Optional function to control loading state separately
  Future<void> runUseCaseWithCustomSuccess<T>({
    required TaskEither<AppException, T> Function() usecase,
    required State Function() buildLoadingState,
    required State Function(String errorMessage) buildFailureState,
    required void Function(T data, State currentState) onSuccess,
    State Function(State currentState, {required bool isLoading})? setLoadingState,
  }) async {
    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: true));
    } else {
      emit(buildLoadingState());
    }

    final result = await usecase().run();

    result.fold(
      (exception) => emit(buildFailureState(exception.message ?? 'Unknown error')),
      (data) => onSuccess(data, state),
    );

    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: false));
    }
  }

  /// Execute use case with custom success handler for list results
  ///
  /// Similar to runUseCaseWithCustomSuccess but for list results
  ///
  /// [usecase] - The use case that returns `TaskEither<AppException, List<T>>`
  /// [buildLoadingState] - Function to build loading state
  /// [buildFailureState] - Function to build failure state with error message
  /// [onSuccess] - Custom handler that receives list data and current state, emits manually
  /// [setLoadingState] - Optional function to control loading state separately
  Future<void> runUseCaseListWithCustomSuccess<T>({
    required TaskEither<AppException, List<T>> Function() usecase,
    required State Function() buildLoadingState,
    required State Function(String errorMessage) buildFailureState,
    required void Function(List<T> data, State currentState) onSuccess,
    State Function(State currentState, {required bool isLoading})? setLoadingState,
  }) async {
    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: true));
    } else {
      emit(buildLoadingState());
    }

    final result = await usecase().run();

    result.fold(
      (exception) => emit(buildFailureState(exception.message ?? 'Unknown error')),
      (data) => onSuccess(data, state),
    );

    if (setLoadingState != null) {
      emit(setLoadingState(state, isLoading: false));
    }
  }
}
