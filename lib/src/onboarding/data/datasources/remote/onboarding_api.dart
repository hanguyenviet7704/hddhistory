part of '../../../onboarding.dart';

@lazySingleton
@RestApi()
abstract class OnboardingApi {
  @factoryMethod
  factory OnboardingApi(@Named(DIKey.appDio) Dio dio) = _OnboardingApi;

  @GET(AppEndpoint.onboardingContentConfig)
  Future<BaseResponse<OnboardingContentConfigModel>> getOnboardingConfig();

  @GET(AppEndpoint.onboardingTaxonomy)
  Future<BaseResponse<OnboardingTaxonomyModel>> getTaxonomy();

  @POST(AppEndpoint.onboardingAnswers)
  Future<BaseResponse<OnboardingRecommendationModel>> submitAnswers(@Body() Map<String, dynamic> body);
}
