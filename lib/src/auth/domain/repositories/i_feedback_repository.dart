part of 'repositories.dart';

abstract interface class IFeedbackRepository {
  TaskEither<AppException, BaseResponse> createFeedback(Map<String, dynamic> data);
  TaskEither<AppException, BaseResponse> createFeedbackPaywall(Map<String, dynamic> data);
}
