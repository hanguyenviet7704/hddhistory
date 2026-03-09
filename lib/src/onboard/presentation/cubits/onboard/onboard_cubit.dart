part of '../../../onboard.dart';

@lazySingleton
class OnboardCubit extends Cubit<OnboardState> with CubitUseCaseHandlerMixin<OnboardState> {
  final GetAllOnboardsUseCase _getAllUseCase;
  final GetUserByDeviceIdUseCase _getUserByDeviceIdUseCase;

  OnboardCubit(
    this._getAllUseCase,
    this._getUserByDeviceIdUseCase,
  ) : super(OnboardState.initial());

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

  void loadUserByDeviceId(String deviceId) async {
    await runUseCase<UserEntity>(
      usecase: () => _getUserByDeviceIdUseCase(deviceId),
      buildLoadingState: () => state.copyWith(status: OnboardStatus.loading),
      onFailure: (error) => emit(state.copyWith(status: OnboardStatus.failure, errorMessage: error)),
      onSuccess: (user) => emit(state.copyWith(status: OnboardStatus.success, userByDeviceId: user)),
    );
  }
}
