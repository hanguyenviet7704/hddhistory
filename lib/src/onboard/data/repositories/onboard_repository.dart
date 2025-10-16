part of '../../onboard.dart';

@LazySingleton(as: IOnboardRepository)
class OnboardRepository with RestfulRequestHandlerMixin implements IOnboardRepository {
  final OnboardApi _api;
  final OnboardLocalDataSource _localDataSource;

  OnboardRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, OnboardEntity> getOnboard(String id) {
    return callApiWithTransform<OnboardModel, OnboardEntity>(
      apiCall: () => _api.getOnboard(id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheOnboard(data ?? OnboardModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedOnboard(id);
        return cachedModel?.toEntity();
      },
      defaultValue: OnboardEntity(),
    );
  }

  @override
  TaskEither<AppException, List<OnboardEntity>> getAllOnboards() {
    return callApiListWithTransform<OnboardModel, OnboardEntity>(
      apiCall: () => _api.getAllOnboards(),
      transform: (model) => model.toEntity(),
      onSuccess: (models) async => await _localDataSource.cacheOnboards(models),
      onError: () async {
        final cachedModels = await _localDataSource.getCachedOnboards();
        if (cachedModels.isNotEmpty) {
          return cachedModels.map((model) => model.toEntity()).toList();
        }
        return null;
      },
    );
  }

  @override
  TaskEither<AppException, OnboardEntity> createOnboard(
    OnboardEntity entity,
  ) {
    return callApiWithTransform<OnboardModel, OnboardEntity>(
      apiCall: () => _api.createOnboard(_entityToModel(entity)),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheOnboard(data ?? OnboardModel()),
      defaultValue: OnboardEntity(),
    );
  }

  @override
  TaskEither<AppException, OnboardEntity> updateOnboard(
    OnboardEntity entity,
  ) {
    return callApiWithTransform<OnboardModel, OnboardEntity>(
      apiCall: () => _api.updateOnboard(entity.id, _entityToModel(entity)),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheOnboard(data ?? OnboardModel()),
      defaultValue: OnboardEntity(),
    );
  }

  @override
  TaskEither<AppException, Unit> deleteOnboard(String id) {
    return executeApiAction(
      apiCall: () => _api.deleteOnboard(id),
      onSuccess: () async => await _localDataSource.deleteCachedOnboard(id),
    );
  }

  // ==================== HELPER METHODS ====================

  /// Converts OnboardEntity to OnboardModel
  /// Reusable helper to avoid duplication in create/update methods
  OnboardModel _entityToModel(OnboardEntity entity) {
    return OnboardModel(
      id: entity.id,
      isNativeEnglishSpeaker: entity.isNativeEnglishSpeaker,
      comfortableLearningTime: entity.comfortableLearningTime,
      dailyLearningGoal: entity.dailyLearningGoal,
      timeToBecomeSkilled: entity.timeToBecomeSkilled,
      topicsWantToMaster: entity.topicsWantToMaster
          .map(
            (e) => OnboardOptionModel(
              isNativeEnglishSpeaker: e.isNativeEnglishSpeaker,
              comfortableLearningTime: e.comfortableLearningTime,
              dailyLearningGoal: e.dailyLearningGoal,
              timeToBecomeSkilled: e.timeToBecomeSkilled,
            ),
          )
          .toList(),
      seemLikeYou: entity.seemLikeYou
          .map(
            (e) => OnboardOptionModel(
              isNativeEnglishSpeaker: e.isNativeEnglishSpeaker,
              comfortableLearningTime: e.comfortableLearningTime,
              dailyLearningGoal: e.dailyLearningGoal,
              timeToBecomeSkilled: e.timeToBecomeSkilled,
            ),
          )
          .toList(),
      strugglesWhenSpeaking: entity.strugglesWhenSpeaking
          .map(
            (e) => OnboardOptionModel(
              isNativeEnglishSpeaker: e.isNativeEnglishSpeaker,
              comfortableLearningTime: e.comfortableLearningTime,
              dailyLearningGoal: e.dailyLearningGoal,
              timeToBecomeSkilled: e.timeToBecomeSkilled,
            ),
          )
          .toList(),
    );
  }
}
