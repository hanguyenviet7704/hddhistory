part of '../../progress.dart';

@LazySingleton(as: IProgressRepository)
class ProgressRepository with RestfulRequestHandlerMixin implements IProgressRepository {
  final UserProgressApi _api;
  final ProgressLocalDataSource _localDataSource;

  ProgressRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, UserProgressEntity> getAllUserProgresss(
    UserProgressFilter filter,
  ) {
    return callApiWithTransform<UserProgressModel, UserProgressEntity>(
      apiCall: () => _api.getAllUserProgresss(filter),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async {
        if (data != null) {
          await _localDataSource.cacheUserProgresss([data]);
        }
      },
      onError: () async {
        final cachedModels = await _localDataSource.getCachedUserProgresss();
        if (cachedModels.isNotEmpty) {
          return cachedModels.first.toEntity();
        }
        return null;
      },
      defaultValue: UserProgressEntity(),
    );
  }

  @override
  TaskEither<AppException, LessonResultEntity> getUserProgressLesson(
    UserProgressFilter filter,
  ) {
    return callApiWithTransform<LessonResultModel, LessonResultEntity>(
      apiCall: () => _api.getUserProgressLesson(filter),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async {
        if (data != null) {
          await _localDataSource.cacheLessonResult(data);
        }
      },
      onError: () async {
        final cachedModel = await _localDataSource.getCachedLessonResult();
        return cachedModel?.toEntity();
      },
      defaultValue: LessonResultEntity(),
    );
  }

  @override
  TaskEither<AppException, KeypointResultEntity> getUserProgressKeypoint(
    UserProgressFilter filter,
  ) {
    return callApiWithTransform<KeypointResultModel, KeypointResultEntity>(
      apiCall: () => _api.getUserProgressKeypoint(filter),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async {
        if (data != null) {
          await _localDataSource.cacheKeypointResult(data);
        }
      },
      onError: () async {
        final cachedModel = await _localDataSource.getCachedKeypointResult();
        return cachedModel?.toEntity();
      },
      defaultValue: KeypointResultEntity(),
    );
  }

  @override
  TaskEither<AppException, ExerciseResultEntity> getUserProgressExercise(
    UserProgressFilter filter,
  ) {
    return callApiWithTransform<ExerciseResultModel, ExerciseResultEntity>(
      apiCall: () => _api.getUserProgressExercise(filter),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async {
        if (data != null) {
          await _localDataSource.cacheExerciseResult(data);
        }
      },
      onError: () async {
        final cachedModel = await _localDataSource.getCachedExerciseResult();
        return cachedModel?.toEntity();
      },
      defaultValue: ExerciseResultEntity(),
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
  TaskEither<AppException, UserProgressEntity> updateUserProgressExercise(Map<String, dynamic> body) {
    return callApiWithTransform<UserProgressModel, UserProgressEntity>(
      apiCall: () => _api.updateUserProgressExercise(body),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheUserProgressExercise(data ?? UserProgressModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedUserProgressExercise();
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
