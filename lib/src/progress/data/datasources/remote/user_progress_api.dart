part of '../../../progress.dart';

@lazySingleton
@RestApi()
abstract class UserProgressApi {
  @factoryMethod
  factory UserProgressApi(@Named(DIKey.appDio) Dio dio) = _UserProgressApi;

  @GET(AppEndpoint.coursesUserProgress)
  Future<BaseResponse<UserProgressModel>> getAllUserProgresss(@Queries() UserProgressFilter filter);

  @GET(AppEndpoint.coursesUserProgress)
  Future<BaseResponse<LessonResultModel>> getUserProgressLesson(@Queries() UserProgressFilter filter);

  @GET(AppEndpoint.coursesUserProgress)
  Future<BaseResponse<KeypointResultModel>> getUserProgressKeypoint(@Queries() UserProgressFilter filter);

  @GET(AppEndpoint.coursesUserProgress)
  Future<BaseResponse<ExerciseResultModel>> getUserProgressExercise(@Queries() UserProgressFilter filter);

  @PUT(AppEndpoint.coursesUserProgressLesson)
  Future<BaseResponse<UserProgressModel>> updateUserProgressLesson(@Path('lessonId') String lessonId, @Body() Map<String, dynamic> body);

  @PUT(AppEndpoint.coursesUserProgressKeypoint)
  Future<BaseResponse<UserProgressModel>> updateUserProgressKeypoint(@Body() Map<String, dynamic> body);

  @PUT(AppEndpoint.coursesUserProgressExercise)
  Future<BaseResponse<UserProgressModel>> updateUserProgressExercise(@Body() Map<String, dynamic> body);

  @GET(AppEndpoint.coursesUserProgressMyCourses)
  Future<BaseResponse<BasePageBreak<CourseModel>>> getUserProgressMyCourses(
    @Queries() PageBreakRequest request,
  );
}
