part of '../../achievenment.dart';

@lazySingleton
class AchievenmentCubit extends Cubit<AchievenmentState>
    with CubitUseCaseHandlerMixin<AchievenmentState> {
  final GetAchievenmentResponseUseCase _getAchievenmentResponseUseCase;

  AchievenmentCubit(
    this._getAchievenmentResponseUseCase,
  ) : super(AchievenmentState.initial());

  void loadAchievenmentResponse(String id) async {
    await runUseCase<AchievenmentResponseEntity>(
      usecase: () => _getAchievenmentResponseUseCase(id),
      buildLoadingState: () => state.copyWith(status: AchievenmentStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: AchievenmentStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (item) {
        emit(state.copyWith(
          status: AchievenmentStatus.success,
          selectedAchievenmentResponse: item,
        ));
      },
    );
  }
}


