part of '../../roleplay.dart';

@LazySingleton(as: IRoleplayRepository)
class RoleplayRepository with RestfulRequestHandlerMixin implements IRoleplayRepository {
  final RoleplayApi _api;
  final RoleplayLocalDataSource _localDataSource;

  RoleplayRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, LearningItemEntity> getLearningItem(String id) {
    return callApiWithTransform<LearningItemModel, LearningItemEntity>(
      apiCall: () => _api.getLearningItem(id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheLearningItem(data ?? LearningItemModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedLearningItem(id);
        return cachedModel?.toEntity();
      },
      defaultValue: LearningItemEntity(),
    );
  }

}