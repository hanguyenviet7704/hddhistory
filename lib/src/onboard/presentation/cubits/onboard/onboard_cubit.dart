part of '../../../onboard.dart';

@lazySingleton
class OnboardCubit extends Cubit<OnboardState> with CubitUseCaseHandlerMixin<OnboardState> {
  final GetAllOnboardsUseCase _getAllUseCase;

  OnboardCubit(
    this._getAllUseCase,
  ) : super(OnboardState.initial());

  void loadAllOnboards() async {
    // Prevent multiple simultaneous loads
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
}
