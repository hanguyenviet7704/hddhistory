part of '../../../onboard_branching.dart';

@lazySingleton
@RestApi()
abstract class OnboardBranchingApi {
  @factoryMethod
  factory OnboardBranchingApi(@Named(DIKey.appDio) Dio dio) = _OnboardBranchingApi;

  @GET(AppEndpoint.onboardingsScenarios)
  Future<BaseResponse<OnboardingScenarioBranchingModel>> getOnboardingScenarioBranching(@Path('id') String id);
}
