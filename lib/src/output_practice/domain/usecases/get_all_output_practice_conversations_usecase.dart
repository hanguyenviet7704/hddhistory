part of '../../output_practice.dart';

@lazySingleton
class GetAllOutputPracticeConversationsUseCase implements BaseUseCase<PageBreakRequest, BasePageBreak<OutputPracticeConversationEntity>> {
  final IOutputPracticeRepository _repository;

  GetAllOutputPracticeConversationsUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<OutputPracticeConversationEntity>> call(PageBreakRequest params) {
    return _repository.getAllOutputPracticeConversations(params);
  }
}

