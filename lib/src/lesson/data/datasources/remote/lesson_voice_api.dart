part of '../../../lesson.dart';

@lazySingleton
@RestApi()
abstract class LessonVoiceApi {
  @factoryMethod
  factory LessonVoiceApi(@Named(DIKey.aiDio) Dio dio) = _LessonVoiceApi;

  @POST(AppEndpoint.voiceFeedback)
  Future<BaseResponse<VoiceFeedbackModel>> sendVoiceFeedback(@Body() Map<String, dynamic> body);

  @POST(AppEndpoint.scoreRecord)
  Future<BaseResponse<VoiceFeedbackModel>> sendScoreRecord(@Body() Map<String, dynamic> body);
}

@lazySingleton
class LessonVoiceStreamApi {
  final Dio _dio;

  LessonVoiceStreamApi(@Named(DIKey.aiDio) this._dio);

  Future<ResponseBody> sendVoiceFeedbackStream(Map<String, dynamic> body) async {
    final response = await _dio.post<ResponseBody>(
      AppEndpoint.voiceFeedbackStream,
      data: body,
      options: Options(
        headers: const {
          "Accept": "text/event-stream",
          "Content-Type": "application/json",
        },
        responseType: ResponseType.stream,
      ),
    );
    return response.data!;
  }
}
