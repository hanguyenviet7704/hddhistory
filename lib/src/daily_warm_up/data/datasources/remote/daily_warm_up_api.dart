part of '../../../daily_warm_up.dart';

@lazySingleton
@RestApi()
abstract class DailyWarmUpApi {
  @factoryMethod
  factory DailyWarmUpApi(@Named(DIKey.appDio) Dio dio) = _DailyWarmUpApi;

  @GET(AppEndpoint.dailyWarmUp)
  Future<BaseResponse<DailyWarmUpModel>> getDailyWarmUp();
}

