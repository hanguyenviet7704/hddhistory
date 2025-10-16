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
    await runUseCaseList<OnboardEntity>(
      usecase: _getAllUseCase.call,
      buildLoadingState: () => state.copyWith(status: OnboardStatus.loading),
      buildFailureState: (error) => state.copyWith(
        status: OnboardStatus.failure,
        errorMessage: error,
      ),
      buildSuccessState: (items) => state.copyWith(
        status: OnboardStatus.success,
        items: items,
      ),
    );
  }

  void loadOnboard(String id) async {
    await runUseCase<OnboardEntity>(
      usecase: () => _getUseCase(id),
      buildLoadingState: () => state.copyWith(status: OnboardStatus.loading),
      buildFailureState: (error) => state.copyWith(
        status: OnboardStatus.failure,
        errorMessage: error,
      ),
      buildSuccessState: (item) => state.copyWith(
        status: OnboardStatus.success,
        selectedItem: item,
      ),
    );
  }

  void createOnboard(OnboardEntity entity) async {
    await runUseCaseWithCustomSuccess<OnboardEntity>(
      usecase: () => _createUseCase(entity),
      buildLoadingState: () => state.copyWith(status: OnboardStatus.loading),
      buildFailureState: (error) => state.copyWith(
        status: OnboardStatus.failure,
        errorMessage: error,
      ),
      onSuccess: (newItem, currentState) {
        final updatedItems = [...currentState.items, newItem];
        emit(
          state.copyWith(
            status: OnboardStatus.success,
            items: updatedItems,
          ),
        );
      },
    );
  }

  void updateOnboard(OnboardEntity entity) async {
    await runUseCaseWithCustomSuccess<OnboardEntity>(
      usecase: () => _updateUseCase(entity),
      buildLoadingState: () => state.copyWith(status: OnboardStatus.loading),
      buildFailureState: (error) => state.copyWith(
        status: OnboardStatus.failure,
        errorMessage: error,
      ),
      onSuccess: (updatedItem, currentState) {
        final updatedItems = currentState.items.map((item) => item.id == updatedItem.id ? updatedItem : item).toList();
        emit(
          state.copyWith(
            status: OnboardStatus.success,
            items: updatedItems,
            selectedItem: updatedItem,
          ),
        );
      },
    );
  }

  void deleteOnboard(String id) async {
    await runUseCaseWithCustomSuccess<Unit>(
      usecase: () => _deleteUseCase(id),
      buildLoadingState: () => state.copyWith(status: OnboardStatus.loading),
      buildFailureState: (error) => state.copyWith(
        status: OnboardStatus.failure,
        errorMessage: error,
      ),
      onSuccess: (_, currentState) {
        final updatedItems = currentState.items.where((item) => item.id != id).toList();
        emit(
          state.copyWith(
            status: OnboardStatus.success,
            items: updatedItems,
          ),
        );
      },
    );
  }
}
