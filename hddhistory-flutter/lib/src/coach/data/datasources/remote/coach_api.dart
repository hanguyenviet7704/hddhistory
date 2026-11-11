part of '../../../coach.dart';

@lazySingleton
@RestApi()
abstract class CoachApi {
  @factoryMethod
  factory CoachApi(@Named(DIKey.appDio) Dio dio) = _CoachApi;

  @GET(AppEndpoint.coachBubble)
  Future<BaseResponse<CoachBubbleModel>> getBubble(
    @Query('entry') String entry,
    @Query('lessonId') String? lessonId,
    @Query('tzOffsetMinutes') int tzOffsetMinutes,
  );

  @POST(AppEndpoint.coachSessions)
  Future<BaseResponse<CoachTurnModel>> openSession(@Body() Map<String, dynamic> body);

  @POST(AppEndpoint.coachSessionTurns)
  Future<BaseResponse<CoachTurnModel>> sendTurn(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST(AppEndpoint.coachSessionClose)
  Future<void> closeSession(@Path('id') String id);

  /// Luồng 6 — the plea at ⟨Đóng⟩ was answered: `{"stayed": bool}`.
  @POST(AppEndpoint.coachSessionExit)
  Future<void> exitSession(@Path('id') String id, @Body() Map<String, dynamic> body);

  /// The voice, changed from the header at any step. Not a turn.
  @PATCH(AppEndpoint.coachSessionPersona)
  Future<void> setPersona(@Path('id') String id, @Body() Map<String, dynamic> body);

  @POST(AppEndpoint.coachExplainAgain)
  Future<void> explainAgain(@Body() Map<String, dynamic> body);

  @POST(AppEndpoint.coachTranscribe)
  Future<BaseResponse<CoachTranscriptModel>> transcribe(@Body() Map<String, dynamic> body);
}
