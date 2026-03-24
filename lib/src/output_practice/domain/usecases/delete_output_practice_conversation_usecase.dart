part of '../../output_practice.dart';

@lazySingleton
class DeleteOutputPracticeConversationUseCase implements BaseUseCase<String, Unit> {
  final IOutputPracticeRepository _repository;

  DeleteOutputPracticeConversationUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(String params) {
    return _repository.deleteOutputPracticeConversation(params);
  }
}

