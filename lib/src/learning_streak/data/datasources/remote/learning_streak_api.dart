part of '../../../learning_streak.dart';

@lazySingleton
@RestApi()
abstract class LearningStreakApi {
  @factoryMethod
  factory LearningStreakApi(@Named(DIKey.appDio) Dio dio) = _LearningStreakApi;

  @GET(AppEndpoint.coursesUserProgressStreak)
  Future<BaseResponse<UserLearningStreakModel>> getUserLearningStreak();

  @GET(AppEndpoint.streakConfig)
  Future<BaseResponse<StreakPopupConfigModel>> getStreakPopupConfig();
}
