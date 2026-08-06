part of '../../../habit.dart';

@lazySingleton
@RestApi()
abstract class HabitApi {
  @factoryMethod
  factory HabitApi(@Named(DIKey.appDio) Dio dio) = _HabitApi;

  @GET(AppEndpoint.habits)
  Future<BaseResponse<List<HabitModel>>> getHabits(
    @Query('skillsetId') String? skillsetId,
    @Query('keypointId') String? keypointId,
  );

  @GET(AppEndpoint.userHabits)
  Future<BaseResponse<List<UserHabitModel>>> getUserHabits(@Query('state') String? state);

  @GET(AppEndpoint.userHabitsSummary)
  Future<BaseResponse<UserHabitSummaryModel>> getUserHabitsSummary();

  /// Combined Habit-tab bootstrap: config + habits + summary in one round
  /// trip — replaces the three calls above on the tab's initial load.
  @GET(AppEndpoint.userHabitsScreen)
  Future<BaseResponse<HabitScreenModel>> getHabitScreen(@Query('state') String? state);

  @POST(AppEndpoint.userHabits)
  Future<BaseResponse<UserHabitModel>> adoptHabit(@Body() Map<String, dynamic> body);

  @PATCH(AppEndpoint.userHabitsById)
  Future<BaseResponse<UserHabitModel>> updateUserHabit(@Path('id') String id, @Body() Map<String, dynamic> body);

  @DELETE(AppEndpoint.userHabitsById)
  Future<void> removeUserHabit(@Path('id') String id);

  @POST(AppEndpoint.userHabitsCheckIn)
  Future<BaseResponse<UserHabitModel>> checkIn(@Path('id') String id, @Body() Map<String, dynamic> body);

  @GET(AppEndpoint.userHabitsCheckins)
  Future<BaseResponse<List<HabitCheckinModel>>> getCheckins(@Path('id') String id);

  @GET(AppEndpoint.habitConfig)
  Future<BaseResponse<dynamic>> getHabitConfig();

  @GET(AppEndpoint.reanchorReasons)
  Future<BaseResponse<List<ReanchorReasonModel>>> getReanchorReasons(@Query('courseId') String courseId);

  @GET(AppEndpoint.habitPractices)
  Future<BaseResponse<List<HabitPracticeModel>>> getHabitPractices(@Query('habitId') String habitId);

  /// Finishing a practice also files the day's check-in server-side, so the
  /// response carries the refreshed user habit — never call checkIn as well.
  @POST(AppEndpoint.habitPracticeAttempts)
  Future<BaseResponse<HabitPracticeAttemptResultModel>> submitPracticeAttempt(@Body() Map<String, dynamic> body);
}
