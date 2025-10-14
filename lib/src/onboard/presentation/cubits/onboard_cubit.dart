part of '../../onboard.dart';

@lazySingleton
class OnboardCubit extends Cubit<OnboardState> {
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
  ) : super(const OnboardState());

  Future<void> loadAllOnboards() async {
    emit(state.copyWith(status: OnboardStatus.loading));

    final result = await _getAllUseCase().run();

    result.fold(
      (exception) => emit(
        state.copyWith(
          status: OnboardStatus.failure,
          errorMessage: exception.message,
        ),
      ),
      (items) => emit(
        state.copyWith(
          status: OnboardStatus.success,
          items: items,
        ),
      ),
    );
  }

  Future<void> loadOnboard(String id) async {
    emit(state.copyWith(status: OnboardStatus.loading));

    final result = await _getUseCase(id).run();

    result.fold(
      (exception) => emit(
        state.copyWith(
          status: OnboardStatus.failure,
          errorMessage: exception.message,
        ),
      ),
      (item) => emit(
        state.copyWith(
          status: OnboardStatus.success,
          selectedItem: item,
        ),
      ),
    );
  }

  Future<void> createOnboard(OnboardEntity entity) async {
    emit(state.copyWith(status: OnboardStatus.loading));

    final result = await _createUseCase(entity).run();

    result.fold(
      (exception) => emit(
        state.copyWith(
          status: OnboardStatus.failure,
          errorMessage: exception.message,
        ),
      ),
      (newItem) {
        final updatedItems = [...state.items, newItem];
        emit(
          state.copyWith(
            status: OnboardStatus.success,
            items: updatedItems,
          ),
        );
      },
    );
  }

  Future<void> updateOnboard(OnboardEntity entity) async {
    emit(state.copyWith(status: OnboardStatus.loading));

    final result = await _updateUseCase(entity).run();

    result.fold(
      (exception) => emit(
        state.copyWith(
          status: OnboardStatus.failure,
          errorMessage: exception.message,
        ),
      ),
      (updatedItem) {
        final updatedItems = state.items
            .map((item) => item.id == updatedItem.id ? updatedItem : item)
            .toList();
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

  Future<void> deleteOnboard(String id) async {
    emit(state.copyWith(status: OnboardStatus.loading));

    final result = await _deleteUseCase(id).run();

    result.fold(
      (exception) => emit(
        state.copyWith(
          status: OnboardStatus.failure,
          errorMessage: exception.message,
        ),
      ),
      (_) {
        final updatedItems = state.items.where((item) => item.id != id).toList();
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
