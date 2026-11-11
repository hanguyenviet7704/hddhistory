part of '../../../week_recap.dart';

@lazySingleton
@RestApi()
abstract class WeekRecapApi {
  @factoryMethod
  factory WeekRecapApi(@Named(DIKey.appDio) Dio dio) = _WeekRecapApi;

  @GET(AppEndpoint.coursesUserProgressWeekRecapCurrent)
  Future<BaseResponse<CurrentWeekRecapModel>> getCurrent(
    @Query('tzOffset') int tzOffset,
    @Query('weekOffset') int weekOffset,
  );

  @GET(AppEndpoint.coursesUserProgressWeekRecap)
  Future<BaseResponse<BasePageBreak<WeekRecapSummaryModel>>> getArchive(
    @Query('page') int page,
    @Query('take') int take,
  );

  @GET(AppEndpoint.coursesUserProgressWeekRecapById)
  Future<BaseResponse<WeekRecapModel>> getById(@Path('id') String id);

  @POST(AppEndpoint.coursesUserProgressWeekRecapViewed)
  Future<void> markViewed(@Path('id') String id);

  @POST(AppEndpoint.coursesUserProgressWeekRecapDismissed)
  Future<void> markDismissed(@Path('id') String id);
}
