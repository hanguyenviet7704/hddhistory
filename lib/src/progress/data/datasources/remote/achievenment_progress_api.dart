part of '../../../progress.dart';

@lazySingleton
@RestApi()
abstract class AchievenmentProgressApi {
  @factoryMethod
  factory AchievenmentProgressApi(@Named(DIKey.appDio) Dio dio) = _AchievenmentProgressApi;

  @GET(AppEndpoint.coursesUserProgressAchievements)
  Future<BaseResponseList<AchievenmentResponseModel>> getAllAchievenmentResponses(@Queries() UserProgressFilter filter);

  @GET(AppEndpoint.coursesUserProgressBadgeProgress)
  Future<BaseResponseList<CourseLevelProgressModel>> getCourseLevelProgress(@Path('courseId') String courseId);
}
