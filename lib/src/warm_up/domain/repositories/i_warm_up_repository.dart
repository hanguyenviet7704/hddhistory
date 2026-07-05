part of '../../warm_up.dart';

abstract class IWarmUpRepository {
  TaskEither<AppException, WarmUpForCourseEntity> getWarmUpForCourse(String courseId);
}
