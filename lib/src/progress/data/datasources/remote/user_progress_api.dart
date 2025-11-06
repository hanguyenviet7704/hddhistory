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

  @PUT(AppEndpoint.coursesUserProgressLesson)
  Future<BaseResponse<UserProgressModel>> updateUserProgressLesson(@Path('lessonId') String lessonId);

  @PUT(AppEndpoint.coursesUserProgressKeypoint)
  Future<BaseResponse<UserProgressModel>> updateUserProgressKeypoint(@Path('keypointId') String keypointId);

  @PUT(AppEndpoint.coursesUserProgressExercise)
  Future<BaseResponse<UserProgressModel>> updateUserProgressExercise(@Path('exerciseId') String exerciseId);

  @GET(AppEndpoint.coursesUserProgressMyCourses)
  Future<BaseResponse<BasePageBreak<CourseModel>>> getUserProgressMyCourses(
    @Queries() PageBreakRequest request,
  );
}
