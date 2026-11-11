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
    Map<String, dynamic> params,
  ) {
    Map<String, dynamic> body = params;
    String userId = body['id'] as String;
    body.remove('id');
    return callApiWithTransform<UserModel, UserEntity>(
      apiCall: () => _api.updateUser(userId, body),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheUser(data ?? UserModel()),
      defaultValue: UserEntity(),
    );
  }
}
