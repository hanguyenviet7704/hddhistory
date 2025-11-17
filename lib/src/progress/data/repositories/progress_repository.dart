part of '../../progress.dart';

@LazySingleton(as: IProgressRepository)
class ProgressRepository with RestfulRequestHandlerMixin implements IProgressRepository {
  final UserProgressApi _api;
  final ProgressLocalDataSource _localDataSource;

  ProgressRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, BasePageBreak<UserProgressEntity>> getAllUserProgresss(
    PageBreakRequest request,
  ) {
    return callApiPageBreak<UserProgressModel, UserProgressEntity>(
      apiCall: () => _api.getAllUserProgresss(request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async {
        await _localDataSource.cacheUserProgresss(pageData.items);
      },
      onError: () async {
        final cachedModels = await _localDataSource.getCachedUserProgresss();
        if (cachedModels.isNotEmpty) {
          return BasePageBreak<UserProgressEntity>(
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
  TaskEither<AppException, UserProgressEntity> updateUserProgressLesson(String lessonId, Map<String, dynamic> body) {
    return callApiWithTransform<UserProgressModel, UserProgressEntity>(
      apiCall: () => _api.updateUserProgressLesson(lessonId, body),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheUserProgressLesson(lessonId, data ?? UserProgressModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedUserProgressLesson(lessonId);
        return cachedModel?.toEntity();
      },
      defaultValue: UserProgressEntity(),
    );
  }

  @override
  TaskEither<AppException, UserProgressEntity> updateUserProgressKeypoint(Map<String, dynamic> body) {
    return callApiWithTransform<UserProgressModel, UserProgressEntity>(
      apiCall: () => _api.updateUserProgressKeypoint(body),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheUserProgressKeypoint(data ?? UserProgressModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedUserProgressKeypoint();
        return cachedModel?.toEntity();
      },
      defaultValue: UserProgressEntity(),
    );
  }

  @override
  TaskEither<AppException, UserProgressEntity> updateUserProgressExercise(String exerciseId, Map<String, dynamic> body) {
    return callApiWithTransform<UserProgressModel, UserProgressEntity>(
      apiCall: () => _api.updateUserProgressExercise(exerciseId, body),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheUserProgressExercise(exerciseId, data ?? UserProgressModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedUserProgressExercise(exerciseId);
        return cachedModel?.toEntity();
      },
      defaultValue: UserProgressEntity(),
    );
  }

  @override
  TaskEither<AppException, BasePageBreak<CourseEntity>> getUserProgressMyCourses(
    PageBreakRequest request,
  ) {
    return callApiPageBreak<CourseModel, CourseEntity>(
      apiCall: () => _api.getUserProgressMyCourses(request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async {
        await _localDataSource.cacheUserProgressMyCourses(pageData.items);
      },
      onError: () async {
        final cachedModels = await _localDataSource.getCachedUserProgressMyCourses();
        if (cachedModels.isNotEmpty) {
          return BasePageBreak<CourseEntity>(
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
}
