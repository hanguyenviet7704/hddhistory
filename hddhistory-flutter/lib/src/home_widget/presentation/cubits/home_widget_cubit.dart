part of '../../home_widget.dart';

@lazySingleton
class HomeWidgetCubit extends Cubit<HomeWidgetState> with CubitUseCaseHandlerMixin<HomeWidgetState> {
  final SyncHomeWidgetsUseCase _syncHomeWidgetsUseCase;
  final ClearHomeWidgetsUseCase _clearHomeWidgetsUseCase;

  HomeWidgetCubit(
    this._syncHomeWidgetsUseCase,
    this._clearHomeWidgetsUseCase,
  ) : super(HomeWidgetState.initial());

  Future<void> syncAll({
    required String localeCode,
    DateTime? now,
  }) async {
    await runUseCaseList<HomeWidgetSyncResult>(
      usecase: () => _syncHomeWidgetsUseCase(HomeWidgetSyncParams(localeCode: localeCode, now: now)),
      buildLoadingState: () => state.copyWith(status: HomeWidgetStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: HomeWidgetStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (items) {
        emit(
          state.copyWith(
            status: HomeWidgetStatus.success,
            results: items,
          ),
        );
      },
    );
  }

  Future<void> clearStoredWidgets() async {
    await runUseCase<HomeWidgetSyncResult>(
      usecase: () => _clearHomeWidgetsUseCase(unit),
      buildLoadingState: () => state.copyWith(status: HomeWidgetStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: HomeWidgetStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (item) {
        emit(
          state.copyWith(
            status: HomeWidgetStatus.success,
            results: [item],
          ),
        );
      },
    );
  }
}
