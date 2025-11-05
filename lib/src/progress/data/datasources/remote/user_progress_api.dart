part of '../../../progress.dart';

@lazySingleton
@RestApi()
abstract class UserProgressApi {
  @factoryMethod
  factory UserProgressApi(@Named(DIKey.appDio) Dio dio) = _UserProgressApi;

  @GET(AppEndpoint.coursesUserProgress)
  Future<BaseResponse<BasePageBreak<UserProgressModel>>> getAllUserProgresss(
    @Queries() PageBreakRequest request,
  );

  @GET(AppEndpoint.coursesUserProgressLesson)
  Future<BaseResponse<UserProgressModel>> getUserProgressLesson(@Path('lessonId') String lessonId);

  @GET(AppEndpoint.coursesUserProgressKeypoint)
  Future<BaseResponse<UserProgressModel>> getUserProgressKeypoint(@Path('keypointId') String keypointId);

  @GET(AppEndpoint.coursesUserProgressExercise)
  Future<BaseResponse<UserProgressModel>> getUserProgressExercise(@Path('exerciseId') String exerciseId);

  @GET(AppEndpoint.coursesUserProgressMyCourses)
  Future<BaseResponse<BasePageBreak<CourseModel>>> getUserProgressMyCourses(
    @Queries() PageBreakRequest request,
  );
}
