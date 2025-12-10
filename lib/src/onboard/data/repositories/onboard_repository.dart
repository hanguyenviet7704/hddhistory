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
  TaskEither<AppException, OnboardEntity> getAllOnboards() {
    return callApiWithTransform<OnboardModel, OnboardEntity>(
      apiCall: () => _api.getAllOnboard(),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheOnboard(data ?? OnboardModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedOnboard('');
        return cachedModel?.toEntity();
      },
      defaultValue: OnboardEntity(),
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
      'age': entity.age
          .map(
            (e) => {
              'id': e.id,
              'icon': e.icon,
              'label': e.label.toJson(),
              'title': e.title.toJson(),
            },
          )
          .toList(),
      'gender': entity.gender
          .map(
            (e) => {
              'id': e.id,
              'icon': e.icon,
              'label': e.label.toJson(),
              'title': e.title.toJson(),
            },
          )
          .toList(),
      'skillsetWantToMaster': entity.skillsetWantToMaster
          .map(
            (e) => {
              'id': e.id,
              'icon': e.icon,
              'label': e.label.toJson(),
              'title': e.title.toJson(),
            },
          )
          .toList(),
      'learningGoal': entity.learningGoal
          .map(
            (e) => {
              'id': e.id,
              'icon': e.icon,
              'label': e.label.toJson(),
              'title': e.title.toJson(),
            },
          )
          .toList(),
      'learningStruggles': entity.learningStruggles
          .map(
            (e) => {
              'id': e.id,
              'icon': e.icon,
              'label': e.label.toJson(),
              'title': e.title.toJson(),
            },
          )
          .toList(),
      'comfortableLearningTime': entity.comfortableLearningTime
          .map(
            (e) => {
              'id': e.id,
              'icon': e.icon,
              'label': e.label.toJson(),
              'title': e.title.toJson(),
            },
          )
          .toList(),
      'dailyLearningGoal': entity.dailyLearningGoal
          .map(
            (e) => {
              'id': e.id,
              'icon': e.icon,
              'label': e.label.toJson(),
              'title': e.title.toJson(),
            },
          )
          .toList(),
      'intro': entity.intro
          .map(
            (e) => {
              'id': e.id,
              'image': e.image,
              'title': e.title.toJson(),
              'content': e.content.toJson(),
            },
          )
          .toList(),
      'welcome': entity.welcome
          .map(
            (e) => {
              'content': e.content.toJson(),
              'image': e.image,
            },
          )
          .toList(),
      'motivationOne': entity.motivationOne
          .map(
            (e) => {
              'content': e.content.toJson(),
              'image': e.image,
            },
          )
          .toList(),
      'motivationTwo': entity.motivationTwo
          .map(
            (e) => {
              'content': e.content.toJson(),
              'image': e.image,
            },
          )
          .toList(),
      'motivationThree': entity.motivationThree
          .map(
            (e) => {
              'content': e.content.toJson(),
              'image': e.image,
            },
          )
          .toList(),
      'loading': entity.loading
          .map(
            (e) => {
              'content': e.content.toJson(),
              'image': e.image,
            },
          )
          .toList(),
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }
}
