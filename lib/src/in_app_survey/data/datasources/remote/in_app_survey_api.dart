part of '../../../in_app_survey.dart';

@lazySingleton
@RestApi()
abstract class InAppSurveyApi {
  @factoryMethod
  factory InAppSurveyApi(@Named(DIKey.appDio) Dio dio) = _InAppSurveyApi;

  @GET(AppEndpoint.inAppSurveyConfigs)
  Future<BaseResponse<InAppSurveyConfigModel>> getInAppSurveyConfig();

  @POST(AppEndpoint.inAppSurveyResponses)
  Future<BaseResponse<void>> createInAppSurveyResponse(@Body() Map<String, dynamic> body);
}

