part of '../../../onboard.dart';

@lazySingleton
@RestApi()
abstract class OnboardApi {
  @factoryMethod
  factory OnboardApi(@Named(DIKey.appDio) Dio dio) = _OnboardApi;

  @GET(AppEndpoint.onboardings)
  Future<BaseResponse<OnboardModel>> getAllOnboard();
}
