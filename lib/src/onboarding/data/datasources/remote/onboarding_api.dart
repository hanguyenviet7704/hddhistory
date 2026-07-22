part of '../../../onboarding.dart';

@lazySingleton
@RestApi()
abstract class OnboardingApi {
  @factoryMethod
  factory OnboardingApi(@Named(DIKey.appDio) Dio dio) = _OnboardingApi;

  @GET(AppEndpoint.onboardingContentConfig)
  Future<BaseResponse<OnboardingContentConfigModel>> getOnboardingConfig();
}
