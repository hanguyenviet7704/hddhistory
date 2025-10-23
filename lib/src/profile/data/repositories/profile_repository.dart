part of '../../profile.dart';

@LazySingleton(as: IProfileRepository)
class ProfileRepository with RestfulRequestHandlerMixin implements IProfileRepository {
  final ProfileApi _api;
  final ProfileLocalDataSource _localDataSource;

  ProfileRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, UserEntity> getUser(String id) {
    return callApiWithTransform<UserModel, UserEntity>(
      apiCall: () => _api.getUser(id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheUser(data ?? UserModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedUser(id);
        return cachedModel?.toEntity();
      },
      defaultValue: UserEntity(),
    );
  }

  @override
  TaskEither<AppException, BasePageBreak<UserEntity>> getAllUsers(
    PageBreakRequest request,
  ) {
    return callApiPageBreak<UserModel, UserEntity>(
      apiCall: () => _api.getAllUsers(request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async {
        // Cache only the items from the current page
        await _localDataSource.cacheUsers(pageData.items);
      },
      onError: () async {
        final cachedModels = await _localDataSource.getCachedUsers();
        if (cachedModels.isNotEmpty) {
          return BasePageBreak<UserEntity>(
            currentPage: 1,
            totalPages: 1,
            itemsPerPage: cachedModels.length,
            items: cachedModels.map((model) => model.toEntity()).toList(),
          );
        }
        return null;
      },
    );
  }

  @override
  TaskEither<AppException, UserEntity> createUser(
    UserEntity entity,
  ) {
    return callApiWithTransform<UserModel, UserEntity>(
      apiCall: () => _api.createUser(_entityToJson(entity)),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheUser(data ?? UserModel()),
      defaultValue: UserEntity(),
    );
  }

  @override
  TaskEither<AppException, UserEntity> updateUser(
    UserEntity entity,
  ) {
    return callApiWithTransform<UserModel, UserEntity>(
      apiCall: () => _api.updateUser(entity.id, _entityToJson(entity)),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheUser(data ?? UserModel()),
      defaultValue: UserEntity(),
    );
  }

  @override
  TaskEither<AppException, Unit> deleteUser(String id) {
    return executeApiAction(
      apiCall: () => _api.deleteUser(id),
      onSuccess: () async => await _localDataSource.deleteCachedUser(id),
    );
  }

  // ==================== HELPER METHODS ====================

  /// Converts UserEntity to JSON Map for API requests
  /// Provides flexibility to customize the request body structure without affecting domain models
  /// Reusable helper to avoid duplication in create/update methods
  Map<String, dynamic> _entityToJson(UserEntity entity) {
    return {
      'id': entity.id,
      'name': entity.name,
    };
  }
}
