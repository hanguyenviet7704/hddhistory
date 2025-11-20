part of '../../profile.dart';

@LazySingleton(as: IProfileRepository)
class ProfileRepository with RestfulRequestHandlerMixin implements IProfileRepository {
  final ProfileApi _api;
  final ProfileLocalDataSource _localDataSource;

  ProfileRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, UserEntity> getUser(String id) {
    return callApiWithTransform<UserModel, UserEntity>(
      apiCall: () => _api.getUserProfile(id),
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

  // ==================== HELPER METHODS ====================

  /// Converts UserEntity to JSON Map for API requests
  /// Provides flexibility to customize the request body structure without affecting domain models
  /// Reusable helper to avoid duplication in create/update methods
  Map<String, dynamic> _entityToJson(UserEntity entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'email': entity.email,
      'phone': entity.phone,
      'age': entity.age,
      'gender': entity.gender,
      'status': entity.status.toJsonValue(),
      'language': entity.language,
      'country': entity.country,
      'lastAction': {
        'time': entity.lastAction.time?.toIso8601String(),
        'action': entity.lastAction.action,
      },
      'avatar': entity.avatar,
      'role': entity.role.toJsonValue(),
      'provider': entity.provider,
      'enery': entity.enery,
      'onboarding': entity.onboarding.toJson(),
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }
}
