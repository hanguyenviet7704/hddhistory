part of '../../../onboard.dart';

@lazySingleton
class OnboardCubit extends Cubit<OnboardState> with CubitUseCaseHandlerMixin<OnboardState> {
  final GetAllOnboardsUseCase _getAllUseCase;
  final GetUserByDeviceIdUseCase _getUserByDeviceIdUseCase;
  final IDeviceInfoService _deviceInfoService;

  OnboardCubit(
    this._getAllUseCase,
    this._getUserByDeviceIdUseCase,
    this._deviceInfoService,
  ) : super(OnboardState.initial());

  static const _emptyUser = UserEntity();

  void loadAllOnboards() async {
    if (state.status == OnboardStatus.loading) return;

    await runUseCase<OnboardEntity>(
      usecase: () => _getAllUseCase(unit),
      buildLoadingState: () => state.copyWith(status: OnboardStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: OnboardStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (onboardData) {
        emit(
          state.copyWith(
            status: OnboardStatus.success,
            onboardData: onboardData,
          ),
        );

        AppDI.injector.get<DataCollectCubit>().setOnboardData(onboardData);
        AppDI.injector.get<IntroCubit>().setIntros(onboardData.intro);
      },
    );
  }

  Future<void> loadUserByDeviceId() async {
    if (state.deviceCheckStatus == OnboardDeviceCheckStatus.loading) return;

    emit(
      state.copyWith(
        deviceCheckStatus: OnboardDeviceCheckStatus.loading,
        userByDeviceId: _emptyUser,
        deviceCheckErrorMessage: null,
      ),
    );

    final deviceId = await _deviceInfoService.deviceToken;
    if (deviceId.isEmpty) {
      emit(
        state.copyWith(
          deviceCheckStatus: OnboardDeviceCheckStatus.success,
          userByDeviceId: _emptyUser,
          deviceCheckErrorMessage: null,
        ),
      );
      return;
    }

    final result = await _getUserByDeviceIdUseCase(deviceId).run();

    result.fold(
      (exception) {
        if (_isRecoverableDeviceMiss(exception)) {
          emit(
            state.copyWith(
              deviceCheckStatus: OnboardDeviceCheckStatus.success,
              userByDeviceId: _emptyUser,
              deviceCheckErrorMessage: null,
            ),
          );
          return;
        }

        emit(
          state.copyWith(
            deviceCheckStatus: OnboardDeviceCheckStatus.failure,
            userByDeviceId: _emptyUser,
            deviceCheckErrorMessage: exception.displayMessage,
          ),
        );
      },
      (user) => emit(
        state.copyWith(
          deviceCheckStatus: OnboardDeviceCheckStatus.success,
          userByDeviceId: user,
          deviceCheckErrorMessage: null,
        ),
      ),
    );
  }

  bool _isRecoverableDeviceMiss(AppException exception) {
    return switch (exception) {
      NotFoundException() => true,
      FromDioException(error: final error) => error.response?.statusCode == 404,
      _ => false,
    };
  }
}
