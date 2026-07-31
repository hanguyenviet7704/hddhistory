part of '../../progress.dart';

@LazySingleton(as: IAchievenmentProgressRepository)
class AchievenmentProgressRepository with RestfulRequestHandlerMixin implements IAchievenmentProgressRepository {
  final AchievenmentProgressApi _api;
  final AchievenmentProgressLocalDataSource _localDataSource;

  AchievenmentProgressRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, List<AchievenmentResponseEntity>> getAllAchievenmentResponses() {
    return callApiListWithTransform<AchievenmentResponseModel, AchievenmentResponseEntity>(
      apiCall: () => _api.getAllAchievenmentResponses(),
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
  Future<List<AchievenmentResponseEntity>> getCachedAchievenmentResponses() async {
    final cachedModels = await _localDataSource.getCachedAchievenmentResponses();
    return cachedModels.map((model) => model.toEntity()).toList();
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
