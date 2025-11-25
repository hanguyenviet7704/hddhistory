part of '../../lesson.dart';

@lazySingleton
class SendVoiceFeedbackUseCase implements UseCaseWithParams<VoiceFeedbackRequest, VoiceFeedbackEntity> {
  final ILessonRepository _repository;

  SendVoiceFeedbackUseCase(this._repository);

  @override
  TaskEither<AppException, VoiceFeedbackEntity> call(VoiceFeedbackRequest params) {
    return _repository.sendVoiceFeedback(params);
  }
}
