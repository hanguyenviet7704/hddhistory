part of '../../output_practice.dart';

@lazySingleton
class GetOutputPracticeConversationUseCase implements BaseUseCase<String, OutputPracticeConversationEntity> {
  final IOutputPracticeRepository _repository;

  GetOutputPracticeConversationUseCase(this._repository);

  @override
  TaskEither<AppException, OutputPracticeConversationEntity> call(String params) {
    return _repository.getOutputPracticeConversation(params);
  }
}

