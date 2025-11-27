part of '../../../roleplay.dart';

@lazySingleton
class RoleplayFeedbackApi {
  final Dio _dio;

  RoleplayFeedbackApi(@Named(DIKey.aiDio) this._dio);

  Future<RoleplayFeedbackModel> sendFeedbackRoleplay(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      AppEndpoint.feedbackRoleplay,
      data: body,
      options: Options(
        headers: const {"Content-Type": "application/json"},
        responseType: ResponseType.json,
      ),
    );
    return RoleplayFeedbackModel.fromJson(response.data ?? {});
  }
}
