part of '../../output_practice.dart';

abstract class IOutputPracticeRepository {
  TaskEither<AppException, BasePageBreak<OutputPracticeMessageEntity>> getAllOutputPracticeMessages(
    PageBreakRequest request,
  );
  TaskEither<AppException, OutputPracticeConversationEntity> getOutputPracticeConversation(String sectionId);
  TaskEither<AppException, OutputPracticeConversationEntity> createOutputPracticeConversation(Map<String, dynamic> body);
  TaskEither<AppException, List<OutputPracticeMessageEntity>> sendOutputPracticeMessage(Map<String, dynamic> body);
}

