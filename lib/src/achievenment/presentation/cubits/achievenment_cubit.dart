

part of '../../achievenment.dart';

@lazySingleton
class AchievenmentCubit extends Cubit<AchievenmentState>
    with CubitUseCaseHandlerMixin<AchievenmentState> {
  final GetAchievenmentResponseUseCase _getUseCase;
  

  AchievenmentCubit(
    this._getUseCase,
    
  ) : super(AchievenmentState.initial());

  void loadAchievenmentResponse(String id) async {
    await runUseCase<AchievenmentResponseEntity>(
      usecase: () => _getUseCase(id),
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
          selectedItem: item,
        ));
      },
    );
  }

  
}


