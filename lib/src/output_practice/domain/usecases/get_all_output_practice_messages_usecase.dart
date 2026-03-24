part of '../../output_practice.dart';

@lazySingleton
class GetAllOutputPracticeMessagesUseCase
    implements BaseUseCase<PageBreakRequest, BasePageBreak<OutputPracticeMessageEntity>> {
  final IOutputPracticeRepository _repository;

  GetAllOutputPracticeMessagesUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<OutputPracticeMessageEntity>> call(PageBreakRequest params) {
    return _repository.getAllOutputPracticeMessages(params);
  }
}
