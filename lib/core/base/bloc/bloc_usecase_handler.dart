part of '../base.dart';

mixin BlocUseCaseHandlerMixin<Event, State> on BlocBase<State> {
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
}
