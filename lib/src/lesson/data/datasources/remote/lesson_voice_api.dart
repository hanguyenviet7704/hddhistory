part of '../../../lesson.dart';

@lazySingleton
@RestApi()
abstract class LessonVoiceApi {
  @factoryMethod
  factory LessonVoiceApi(@Named(DIKey.aiDio) Dio dio) = _LessonVoiceApi;

  @POST(AppEndpoint.voiceFeedback)
  Future<BaseResponse<VoiceFeedbackModel>> sendVoiceFeedback(@Body() Map<String, dynamic> body);
}

@lazySingleton
class LessonVoiceAIApi {
  final Dio _dio;

  LessonVoiceAIApi(@Named(DIKey.aiDio) this._dio);

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

  Future<VoiceScoreModel> sendScoreRecord(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      AppEndpoint.feedbackRoleplay,
      data: body,
      options: Options(
        headers: const {"Content-Type": "application/json"},
        responseType: ResponseType.json,
      ),
    );
    return VoiceScoreModel.fromJson(response.data ?? {});
  }
}
