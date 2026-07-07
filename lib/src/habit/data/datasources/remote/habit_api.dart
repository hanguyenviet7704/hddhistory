part of '../../../habit.dart';

@lazySingleton
@RestApi()
abstract class HabitApi {
  @factoryMethod
  factory HabitApi(@Named(DIKey.appDio) Dio dio) = _HabitApi;

  @GET(AppEndpoint.habits)
  Future<BaseResponse<List<HabitModel>>> getHabits(
    @Query('skillsetId') String? skillsetId,
    @Query('lessonId') String? lessonId,
  );

  @GET(AppEndpoint.userHabits)
  Future<BaseResponse<List<UserHabitModel>>> getUserHabits(@Query('state') String? state);

  @GET(AppEndpoint.userHabitsSummary)
  Future<BaseResponse<UserHabitSummaryModel>> getUserHabitsSummary();

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
}
