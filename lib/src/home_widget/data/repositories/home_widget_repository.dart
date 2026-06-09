part of '../../home_widget.dart';

@LazySingleton(as: IHomeWidgetRepository)
class HomeWidgetRepository with RestfulRequestHandlerMixin implements IHomeWidgetRepository {
  final HomeWidgetApi _api;
  final HomeWidgetLocalDataSource _localDataSource;
  

  HomeWidgetRepository(
    this._api,
    this._localDataSource,
  );

  @override
  TaskEither<AppException, HomeWidgetEntity> getHomeWidget(String id) {
    return callApiWithTransform<HomeWidgetModel, HomeWidgetEntity>(
      apiCall: () => _api.getHomeWidget(id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheHomeWidget(data ?? HomeWidgetModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedHomeWidget(id);
        return cachedModel?.toEntity();
      },
      defaultValue: HomeWidgetEntity(),
    );
  }

  

  // ==================== HELPER METHODS ====================

  /// Converts HomeWidgetEntity to JSON Map for API requests
  /// Provides flexibility to customize the request body structure without affecting domain models
  /// Reusable helper to avoid duplication in create/update methods
  Map<String, dynamic> _entityToJson(HomeWidgetEntity entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      // TODO: Add more fields as needed
    };
  }
  

  TaskEither<AppException, T> _missingDataSourceTask<T>(String operation) {
    
    return TaskEither.left(
      AppException.unexpected('$operation is not implemented. Please provide a remote or local data source.'),
    );
  }
}

