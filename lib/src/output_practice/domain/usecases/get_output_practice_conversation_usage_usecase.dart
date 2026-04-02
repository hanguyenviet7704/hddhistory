part of '../../output_practice.dart';

@lazySingleton
class GetOutputPracticeConversationUsageUseCase implements BaseUseCase<String, OutputPracticeConversationUsageEntity> {
  final IOutputPracticeRepository _repository;

  GetOutputPracticeConversationUsageUseCase(this._repository);

  @override
  TaskEither<AppException, OutputPracticeConversationUsageEntity> call(String params) {
    return _repository.getOutputPracticeConversationUsage(params);
  }
}
