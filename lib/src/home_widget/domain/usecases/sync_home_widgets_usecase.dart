part of '../../home_widget.dart';

@lazySingleton
class SyncHomeWidgetsUseCase implements BaseUseCase<HomeWidgetSyncParams, List<HomeWidgetSyncResult>> {
  final IHomeWidgetRepository _repository;

  SyncHomeWidgetsUseCase(this._repository);

  @override
  TaskEither<AppException, List<HomeWidgetSyncResult>> call(HomeWidgetSyncParams params) {
    return _repository.syncAll(params);
  }
}

@lazySingleton
class ClearHomeWidgetsUseCase implements BaseUseCase<Unit, HomeWidgetSyncResult> {
  final IHomeWidgetRepository _repository;

  ClearHomeWidgetsUseCase(this._repository);

  @override
  TaskEither<AppException, HomeWidgetSyncResult> call(Unit params) {
    return _repository.clearStoredWidgets();
  }
}
