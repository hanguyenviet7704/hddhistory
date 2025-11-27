part of '../../../roleplay.dart';

@lazySingleton
@RestApi()
abstract class RoleplayFeedbackApi {
  @factoryMethod
  factory RoleplayFeedbackApi(@Named(DIKey.aiDio) Dio dio) = _RoleplayFeedbackApi;

  @POST(AppEndpoint.feedbackRoleplay)
  Future<BaseResponse<RoleplayFeedbackModel>> sendFeedbackRoleplay(@Body() Map<String, dynamic> body);
}
