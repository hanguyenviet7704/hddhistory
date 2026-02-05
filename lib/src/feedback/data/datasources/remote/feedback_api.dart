part of '../../../feedback.dart';

@lazySingleton
@RestApi()
abstract class FeedbackApi {
  @factoryMethod
  factory FeedbackApi(@Named(DIKey.appDio) Dio dio) = _FeedbackApi;

  @GET(AppEndpoint.coursesFeedbacksOfUser)
  Future<BaseResponse<UserFeedbackModel>> getUserFeedbacks();

  @PUT(AppEndpoint.coursesFeedbacks)
  Future<BaseResponse> updateUserFeedback(@Body() Map<String, dynamic> body);
}
