part of '../../../course.dart';

@lazySingleton
@RestApi()
abstract class CourseLessonApi {
  @factoryMethod
  factory CourseLessonApi(@Named(DIKey.appDio) Dio dio) = _CourseLessonApi;

  @GET(AppEndpoint.coursesLessons)
  Future<BaseResponse<BasePageBreak<LessonModel>>> getAllCourseLessons(
    @Queries() PageBreakRequest request,
  );

  @GET(AppEndpoint.coursesLessonsById)
  Future<BaseResponse<LessonModel>> getCourseLesson(@Path('id') String id);
}
