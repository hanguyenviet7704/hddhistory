part of '../../output_practice.dart';

abstract class IOutputPracticeRepository {
  TaskEither<AppException, BasePageBreak<OutputPracticeConversationEntity>> getAllOutputPracticeConversations(
    PageBreakRequest request,
  );
  TaskEither<AppException, OutputPracticeConversationEntity> getOutputPracticeConversation(String id);
  TaskEither<AppException, OutputPracticeConversationEntity> createOutputPracticeConversation(OutputPracticeConversationEntity entity);
  TaskEither<AppException, OutputPracticeConversationEntity> updateOutputPracticeConversation(OutputPracticeConversationEntity entity);
  TaskEither<AppException, Unit> deleteOutputPracticeConversation(String id);
  
}

