

part of '../../learning_streak.dart';

@lazySingleton
class LearningStreakCubit extends Cubit<LearningStreakState>
    with CubitUseCaseHandlerMixin<LearningStreakState> {
  final GetUserLearningStreakUseCase _getUseCase;

  LearningStreakCubit(
    this._getUseCase,
  ) : super(LearningStreakState.initial());

  void loadUserLearningStreak() async {
    await runUseCase<UserLearningStreakEntity>(
      usecase: () => _getUseCase(),
      buildLoadingState: () => state.copyWith(status: LearningStreakStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: LearningStreakStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (item) {
        emit(state.copyWith(
          status: LearningStreakStatus.success,
          selectedItem: item,
        ));
      },
    );
  }
}


