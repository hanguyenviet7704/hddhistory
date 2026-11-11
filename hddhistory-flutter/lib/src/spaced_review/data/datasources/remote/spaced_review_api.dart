part of '../../../spaced_review.dart';

@lazySingleton
@RestApi()
abstract class SpacedReviewApi {
  @factoryMethod
  factory SpacedReviewApi(@Named(DIKey.appDio) Dio dio) = _SpacedReviewApi;

  @GET(AppEndpoint.spacedReviewToday)
  Future<BaseResponse<SpacedReviewTodayModel>> getToday();

  @POST(AppEndpoint.spacedReviewAnswers)
  Future<void> submitAnswers(@Body() Map<String, dynamic> body);
}
