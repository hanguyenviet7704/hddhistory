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
  TaskEither<AppException, BasePageBreak<OnboardEntity>> getAllOnboards(
    PageBreakRequest request,
  ) {
    return callApiPageBreak<OnboardModel, OnboardEntity>(
      apiCall: () => _api.getAllOnboards(request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async {
        // Cache only the items from the current page
        await _localDataSource.cacheOnboards(pageData.items);
      },
      onError: () async {
        final cachedModels = await _localDataSource.getCachedOnboards();
        if (cachedModels.isNotEmpty) {
          return BasePageBreak<OnboardEntity>(
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
  TaskEither<AppException, OnboardEntity> createOnboard(
    OnboardEntity entity,
  ) {
    return callApiWithTransform<OnboardModel, OnboardEntity>(
      apiCall: () => _api.createOnboard(_entityToJson(entity)),
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
      apiCall: () => _api.updateOnboard(entity.id, _entityToJson(entity)),
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

  /// Converts OnboardEntity to JSON Map for API requests
  /// Provides flexibility to customize the request body structure without affecting domain models
  /// Reusable helper to avoid duplication in create/update methods
  Map<String, dynamic> _entityToJson(OnboardEntity entity) {
    return {
      'id': entity.id,
      'isNativeEnglishSpeaker': entity.isNativeEnglishSpeaker,
      'comfortableLearningTime': entity.comfortableLearningTime,
      'dailyLearningGoal': entity.dailyLearningGoal,
      'timeToBecomeSkilled': entity.timeToBecomeSkilled,
      'topicsWantToMaster': entity.topicsWantToMaster
          .map(
            (e) => {
              'isNativeEnglishSpeaker': e.isNativeEnglishSpeaker,
              'comfortableLearningTime': e.comfortableLearningTime,
              'dailyLearningGoal': e.dailyLearningGoal,
              'timeToBecomeSkilled': e.timeToBecomeSkilled,
            },
          )
          .toList(),
      'seemLikeYou': entity.seemLikeYou
          .map(
            (e) => {
              'isNativeEnglishSpeaker': e.isNativeEnglishSpeaker,
              'comfortableLearningTime': e.comfortableLearningTime,
              'dailyLearningGoal': e.dailyLearningGoal,
              'timeToBecomeSkilled': e.timeToBecomeSkilled,
            },
          )
          .toList(),
      'strugglesWhenSpeaking': entity.strugglesWhenSpeaking
          .map(
            (e) => {
              'isNativeEnglishSpeaker': e.isNativeEnglishSpeaker,
              'comfortableLearningTime': e.comfortableLearningTime,
              'dailyLearningGoal': e.dailyLearningGoal,
              'timeToBecomeSkilled': e.timeToBecomeSkilled,
            },
          )
          .toList(),
    };
  }
}
