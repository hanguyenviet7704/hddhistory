part of '../../output_practice.dart';

@lazySingleton
class SendOutputPracticeMessageUseCase implements BaseUseCase<Map<String, dynamic>, List<OutputPracticeMessageEntity>> {
  final IOutputPracticeRepository _repository;

  SendOutputPracticeMessageUseCase(this._repository);

  @override
  TaskEither<AppException, List<OutputPracticeMessageEntity>> call(Map<String, dynamic> params) {
    return _repository.sendOutputPracticeMessage(params);
  }
}
