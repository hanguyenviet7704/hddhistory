part of '../../../daily_warm_up.dart';

@lazySingleton
@RestApi()
abstract class DailyWarmUpApi {
  @factoryMethod
  factory DailyWarmUpApi(@Named(DIKey.appDio) Dio dio) = _DailyWarmUpApi;

  @GET('/daily_warm_ups')
  Future<BaseResponse<BasePageBreak<DailyWarmUpModel>>> getAllDailyWarmUps(
    @Queries() PageBreakRequest request,
  );

  @GET('${'/daily_warm_ups'}/{id}')
  Future<BaseResponse<DailyWarmUpModel>> getDailyWarmUp(@Path('id') String id);

  @POST('/daily_warm_ups')
  Future<BaseResponse<DailyWarmUpModel>> createDailyWarmUp(@Body() Map<String, dynamic> body);

  @PUT('${'/daily_warm_ups'}/{id}')
  Future<BaseResponse<DailyWarmUpModel>> updateDailyWarmUp(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('${'/daily_warm_ups'}/{id}')
  Future<BaseResponse<void>> deleteDailyWarmUp(@Path('id') String id);
}

