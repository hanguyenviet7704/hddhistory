part of '../../../learning_streak.dart';

@lazySingleton
@RestApi()
abstract class LearningStreakApi {
  @factoryMethod
  factory LearningStreakApi(@Named(DIKey.appDio) Dio dio) = _LearningStreakApi;

  @GET(AppEndpoint.coursesUserProgressStreak)
  Future<BaseResponse<UserLearningStreakModel>> getUserLearningStreak();

  /// Marks today as a day the user showed up. Idempotent server-side, and
  /// returns the updated streak so the toast can be drawn from this response
  /// without a follow-up GET.
  @POST(AppEndpoint.coursesUserProgressStreakCheckIn)
  Future<BaseResponse<UserLearningStreakModel>> checkInStreak();

  @GET(AppEndpoint.streakConfig)
  Future<BaseResponse<StreakPopupConfigModel>> getStreakPopupConfig();
}
