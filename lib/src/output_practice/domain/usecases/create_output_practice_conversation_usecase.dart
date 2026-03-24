part of '../../output_practice.dart';

@lazySingleton
class CreateOutputPracticeConversationUseCase implements BaseUseCase<OutputPracticeConversationEntity, OutputPracticeConversationEntity> {
  final IOutputPracticeRepository _repository;

  CreateOutputPracticeConversationUseCase(this._repository);

  @override
  TaskEither<AppException, OutputPracticeConversationEntity> call(OutputPracticeConversationEntity params) {
    return _repository.createOutputPracticeConversation(params);
  }
}

