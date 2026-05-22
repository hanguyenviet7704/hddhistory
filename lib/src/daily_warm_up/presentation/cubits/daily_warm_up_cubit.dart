

part of '../../daily_warm_up.dart';

@lazySingleton
class DailyWarmUpCubit extends Cubit<DailyWarmUpState>
    with CubitUseCaseHandlerMixin<DailyWarmUpState> {
  final GetDailyWarmUpUseCase _getUseCase;
  

  DailyWarmUpCubit(
    this._getUseCase,
    
  ) : super(DailyWarmUpState.initial());

  void loadDailyWarmUp(String id) async {
    await runUseCase<DailyWarmUpEntity>(
      usecase: () => _getUseCase(id),
      buildLoadingState: () => state.copyWith(status: DailyWarmUpStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: DailyWarmUpStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (item) {
        emit(state.copyWith(
          status: DailyWarmUpStatus.success,
          selectedItem: item,
        ));
      },
    );
  }

  
}


