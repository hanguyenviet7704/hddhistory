part of '../../course.dart';

enum CourseHandoffRouteIntent {
  course,
  courseRoadmap,
}

class CourseHandoffHelper {
  const CourseHandoffHelper();

  Future<CourseHandoffRouteIntent> prepareRecommendedCourse({
    required CourseEntity course,
    Future<void> Function()? initializeHomeData,
    void Function(String courseId)? selectCourseFromCourseId,
    void Function(String courseId)? loadRoadmap,
  }) async {
    final courseId = course.id.trim();
    if (courseId.isEmpty) return CourseHandoffRouteIntent.course;

    try {
      await (initializeHomeData ?? _initializeHomeData)();
      (selectCourseFromCourseId ?? _selectCourseFromCourseId)(courseId);
      (loadRoadmap ?? _loadRoadmap)(courseId);
      return CourseHandoffRouteIntent.courseRoadmap;
    } catch (error) {
      LogDev.warning('[CourseHandoffHelper] prepareRecommendedCourse failed: $error');
      return CourseHandoffRouteIntent.course;
    }
  }

  Future<CourseHandoffRouteIntent> prepareCourseCatalog({
    Future<void> Function()? initializeHomeData,
  }) async {
    try {
      await (initializeHomeData ?? _initializeHomeData)();
    } catch (error) {
      LogDev.warning('[CourseHandoffHelper] prepareCourseCatalog failed: $error');
    }
    return CourseHandoffRouteIntent.course;
  }

  Future<void> _initializeHomeData() {
    return AppDI.injector.get<HomeCubit>().initializeData(isInit: true);
  }

  void _selectCourseFromCourseId(String courseId) {
    AppDI.injector.get<HomeCubit>().selectCourseFromCourseId(courseId);
  }

  void _loadRoadmap(String courseId) {
    AppDI.injector.get<CourseRoadmapCubit>().loadRoadmap(courseId: courseId);
  }
}
