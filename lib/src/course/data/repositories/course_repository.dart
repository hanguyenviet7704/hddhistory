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
    PageBreakRequest request,
  ) {
    return callApiPageBreak<CourseModel, CourseEntity>(
      apiCall: () => _api.getAllCourses(request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async {
        await _localDataSource.cacheCourses(pageData.items);
      },
      onError: () async {
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
}
