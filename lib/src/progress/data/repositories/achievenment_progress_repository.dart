part of '../../progress.dart';

@LazySingleton(as: IAchievenmentProgressRepository)
class AchievenmentProgressRepository with RestfulRequestHandlerMixin implements IAchievenmentProgressRepository {
  final AchievenmentProgressApi _api;
  final AchievenmentProgressLocalDataSource _localDataSource;

  AchievenmentProgressRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, List<AchievenmentResponseEntity>> getAllAchievenmentResponses(
    UserProgressFilter filter,
  ) {
    return callApiListWithTransform<AchievenmentResponseModel, AchievenmentResponseEntity>(
      apiCall: () => _api.getAllAchievenmentResponses(filter),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async {
        await _localDataSource.cacheAchievenmentResponses(data);
      },
      onError: () async {
        final cachedModels = await _localDataSource.getCachedAchievenmentResponses();
        if (cachedModels.isNotEmpty) {
          return cachedModels.map((model) => model.toEntity()).toList();
        }
        return null;
      },
    );
  }

  @override
  TaskEither<AppException, List<CourseLevelProgressEntity>> getCourseLevelProgress(String courseId) {
    return callApiListWithTransform<CourseLevelProgressModel, CourseLevelProgressEntity>(
      apiCall: () => _api.getCourseLevelProgress(courseId),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async {
        await _localDataSource.cacheCourseLevelProgress(courseId, data);
      },
      onError: () async {
        final cachedModels = await _localDataSource.getCachedCourseLevelProgress(courseId);
        if (cachedModels.isNotEmpty) {
          return cachedModels.map((model) => model.toEntity()).toList();
        }
        return null;
      },
    );
  }
}
