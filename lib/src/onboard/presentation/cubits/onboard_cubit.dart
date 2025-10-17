part of '../../onboard.dart';

@lazySingleton
class OnboardCubit extends Cubit<OnboardState> with CubitUseCaseHandlerMixin<OnboardState> {
  final GetAllOnboardsUseCase _getAllUseCase;
  final GetOnboardUseCase _getUseCase;
  final CreateOnboardUseCase _createUseCase;
  final UpdateOnboardUseCase _updateUseCase;
  final DeleteOnboardUseCase _deleteUseCase;

  OnboardCubit(
    this._getAllUseCase,
    this._getUseCase,
    this._createUseCase,
    this._updateUseCase,
    this._deleteUseCase,
  ) : super(OnboardState.initial());

  void loadAllOnboards() async {
    // Prevent multiple simultaneous loads
    if (state.status == OnboardStatus.loading) return;

    await runUseCase<OnboardEntity>(
      usecase: () => _getAllUseCase(),
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
      },
    );
  }

  void loadOnboard(String id) async {
    await runUseCase<OnboardEntity>(
      usecase: () => _getUseCase(id),
      buildLoadingState: () => state.copyWith(status: OnboardStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: OnboardStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (item) {
        emit(
          state.copyWith(
            status: OnboardStatus.success,
            selectedItem: item,
          ),
        );
      },
    );
  }

  void createOnboard(OnboardEntity entity) async {
    await runUseCase<OnboardEntity>(
      usecase: () => _createUseCase(entity),
      buildLoadingState: () => state.copyWith(status: OnboardStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: OnboardStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (newItem) {
        emit(
          state.copyWith(
            status: OnboardStatus.success,
            onboardData: newItem,
          ),
        );
      },
    );
  }

  void updateOnboard(OnboardEntity entity) async {
    await runUseCase<OnboardEntity>(
      usecase: () => _updateUseCase(entity),
      buildLoadingState: () => state.copyWith(status: OnboardStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: OnboardStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (updatedItem) {
        emit(
          state.copyWith(
            status: OnboardStatus.success,
            onboardData: updatedItem,
            selectedItem: updatedItem,
          ),
        );
      },
    );
  }

  void deleteOnboard(String id) async {
    await runUseCase<Unit>(
      usecase: () => _deleteUseCase(id),
      buildLoadingState: () => state.copyWith(status: OnboardStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: OnboardStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (_) {
        emit(
          state.copyWith(
            status: OnboardStatus.success,
          ),
        );
      },
    );
  }
}
