part of '../../output_practice.dart';

@lazySingleton
class UpdateOutputPracticeConversationUseCase implements BaseUseCase<OutputPracticeConversationEntity, OutputPracticeConversationEntity> {
  final IOutputPracticeRepository _repository;

  UpdateOutputPracticeConversationUseCase(this._repository);

  @override
  TaskEither<AppException, OutputPracticeConversationEntity> call(OutputPracticeConversationEntity params) {
    return _repository.updateOutputPracticeConversation(params);
  }
}

