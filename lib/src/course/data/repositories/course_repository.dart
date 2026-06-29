part of '../../course.dart';

@LazySingleton(as: ICourseRepository)
class CourseRepository with RestfulRequestHandlerMixin implements ICourseRepository {
  final CourseApi _api;
  final CourseLocalDataSource _localDataSource;

  CourseRepository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, CourseEntity> getCourse(String id) {
    return callApiWithTransform<CourseModel, CourseEntity>(
      apiCall: () => _api.getCourse(id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheCourse(data ?? CourseModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedCourse(id);
        return cachedModel?.toEntity();
      },
      defaultValue: CourseEntity(),
    );
  }

  @override
  TaskEither<AppException, BasePageBreak<CourseEntity>> getAllCourses(
    PageBreakRequest<CourseFilterRequest> request,
  ) {
    return callApiPageBreak<CourseModel, CourseEntity>(
      apiCall: () => _api.getAllCourses(request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async {
        await _localDataSource.cacheCourses(pageData.items);
      },
      onError: () async {
        if (request.filter?.hasFilters ?? false) return null;
        final cachedModels = await _localDataSource.getCachedCourses();
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

  @override
  TaskEither<AppException, RoadmapEntity> getRoadmap(String id) {
    return callApiWithTransform<RoadmapModel, RoadmapEntity>(
      apiCall: () => _api.getRoadmap(id),
      transform: (model) => model.toEntity(),
      defaultValue: RoadmapEntity(),
    );
  }

  @override
  TaskEither<AppException, List<String>> getSearchHistory() {
    return callApiWithTransform<List<SearchHistoryModel>, List<String>>(
      apiCall: () => _api.getSearchHistory(),
      transform: (models) => models.map((m) => m.query).where((q) => q.isNotEmpty).toList(),
      defaultValue: const [],
    );
  }

  @override
  TaskEither<AppException, Unit> saveSearchQuery(String query) {
    return executeApiAction(
      apiCall: () => _api.saveSearchQuery({'query': query}),
      enableErrorMessages: false,
    );
  }

  @override
  TaskEither<AppException, Unit> clearSearchHistory() {
    return executeApiAction(
      apiCall: () => _api.clearSearchHistory(),
    );
  }

  @override
  TaskEither<AppException, List<CourseEntity>> getRecentCourses() {
    return callApiWithTransform<List<CourseModel>, List<CourseEntity>>(
      apiCall: () => _api.getRecentlyViewedCourses(),
      transform: (models) => models.map((m) => m.toEntity()).toList(),
      defaultValue: const [],
    );
  }

  @override
  TaskEither<AppException, Unit> recordCourseView(String courseId) {
    return executeApiAction(
      apiCall: () => _api.recordCourseView({'courseId': courseId}),
      enableErrorMessages: false,
    );
  }

  @override
  TaskEither<AppException, Unit> clearRecentCourses() {
    return executeApiAction(
      apiCall: () => _api.clearRecentlyViewed(),
    );
  }
}
