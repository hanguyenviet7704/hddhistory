part of '../../output_practice.dart';

@lazySingleton
class CreateOutputPracticeConversationUseCase
    implements BaseUseCase<Map<String, dynamic>, OutputPracticeConversationEntity> {
  final IOutputPracticeRepository _repository;

  CreateOutputPracticeConversationUseCase(this._repository);

  @override
  TaskEither<AppException, OutputPracticeConversationEntity> call(Map<String, dynamic> params) {
    return _repository.createOutputPracticeConversation(params);
  }
}

