part of '../../course.dart';

@LazySingleton(as: ICourseLessonRepository)
class CourseLessonRepository with RestfulRequestHandlerMixin implements ICourseLessonRepository {
  final CourseLessonApi _api;
  final CourseLessonLocalDataSource _localDataSource;

  CourseLessonRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, LessonEntity> getLesson(String id) {
    return callApiWithTransform<LessonModel, LessonEntity>(
      apiCall: () => _api.getLesson(id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheLesson(data ?? LessonModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedLesson(id);
        return cachedModel?.toEntity();
      },
      defaultValue: LessonEntity(),
    );
  }

  @override
  TaskEither<AppException, BasePageBreak<LessonEntity>> getAllLessons(
    PageBreakRequest request,
  ) {
    return callApiPageBreak<LessonModel, LessonEntity>(
      apiCall: () => _api.getAllLessons(request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async {
        await _localDataSource.cacheLessons(pageData.items);
      },
      onError: () async {
        final cachedModels = await _localDataSource.getCachedLessons();
        if (cachedModels.isNotEmpty) {
          return BasePageBreak<LessonEntity>(
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

