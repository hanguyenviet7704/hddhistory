part of '../../setting.dart';

@lazySingleton
class SettingCubit extends Cubit<SettingState> with CubitUseCaseHandlerMixin<SettingState> {
  final GetSettingUseCase _getUseCase;

  SettingCubit(
    this._getUseCase,
  ) : super(SettingState.initial());

  void loadSetting(String id) async {
    await runUseCase<SettingEntity>(
      usecase: () => _getUseCase(id),
      buildLoadingState: () => state.copyWith(status: SettingStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: SettingStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (item) {
        emit(
          state.copyWith(
            status: SettingStatus.success,
            selectedItem: item,
          ),
        );
      },
    );
  }
}
