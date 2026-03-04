part of '../../../learning_streak.dart';

@lazySingleton
@RestApi()
abstract class LearningStreakApi {
  @factoryMethod
  factory LearningStreakApi(@Named(DIKey.appDio) Dio dio) = _LearningStreakApi;

  @GET('/learning_streaks')
  Future<BaseResponse<BasePageBreak<UserLearningStreakModel>>> getAllUserLearningStreaks(
    @Queries() PageBreakRequest request,
  );

  @GET('${'/learning_streaks'}/{id}')
  Future<BaseResponse<UserLearningStreakModel>> getUserLearningStreak(@Path('id') String id);

  @POST('/learning_streaks')
  Future<BaseResponse<UserLearningStreakModel>> createUserLearningStreak(@Body() Map<String, dynamic> body);

  @PUT('${'/learning_streaks'}/{id}')
  Future<BaseResponse<UserLearningStreakModel>> updateUserLearningStreak(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('${'/learning_streaks'}/{id}')
  Future<BaseResponse<void>> deleteUserLearningStreak(@Path('id') String id);
}

