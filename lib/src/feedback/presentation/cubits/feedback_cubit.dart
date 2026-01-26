part of '../../feedback.dart';

@lazySingleton
class FeedbackCubit extends Cubit<FeedbackState>
    with CubitUseCaseHandlerMixin<FeedbackState> {
  final GetUserFeedbacksUseCase _getUserFeedbacksUseCase;
  final UpdateUserFeedbackUseCase _updateUserFeedbackUseCase;

  FeedbackCubit(
    this._getUserFeedbacksUseCase,
    this._updateUserFeedbackUseCase,
  ) : super(FeedbackState.initial());

  void loadUserFeedbacks() async {
    await runUseCase<UserFeedbackEntity>(
      usecase: () => _getUserFeedbacksUseCase(),
      buildLoadingState: () => state.copyWith(status: FeedbackStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: FeedbackStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (item) {
        emit(state.copyWith(
          status: FeedbackStatus.success,
          userFeedback: item,
        ));
      },
    );
  }

  void updateUserFeedback(UserFeedbackEntity entity) async {
    await runUseCase<Unit>(
      usecase: () => _updateUserFeedbackUseCase(entity),
      buildLoadingState: () => state.copyWith(status: FeedbackStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: FeedbackStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (_) {
        emit(state.copyWith(
          status: FeedbackStatus.success,
          userFeedback: entity,
        ));
      },
    );
  }
}


