part of '../../roleplay.dart';

@LazySingleton(as: IRoleplayRepository)
class RoleplayRepository with RestfulRequestHandlerMixin implements IRoleplayRepository {
  final RoleplayApi _api;
  final RoleplayLocalDataSource _localDataSource;
  final RoleplayFeedbackApi _feedbackApi;

  RoleplayRepository(this._api, this._localDataSource, this._feedbackApi);

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

  @override
  TaskEither<AppException, RoleplayFeedbackEntity> sendFeedbackRoleplay(Map<String, dynamic> body) {
    return callApiCustom<RoleplayFeedbackModel>(
      apiCall: () => _feedbackApi.sendFeedbackRoleplay(body),
    ).map((model) => model.toEntity());
  }
}
