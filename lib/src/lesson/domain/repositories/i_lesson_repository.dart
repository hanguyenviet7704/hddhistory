part of '../../lesson.dart';

abstract class ILessonRepository {
  TaskEither<AppException, BasePageBreak<LearningItemEntity>> getAllLearningItems(
    PageBreakRequest request,
  );
  TaskEither<AppException, LearningItemEntity> getLearningItem(String id);
  TaskEither<AppException, VoiceFeedbackEntity> sendVoiceFeedback(VoiceFeedbackRequest request);
  TaskEither<AppException, ResponseBody> sendVoiceFeedbackStream(VoiceFeedbackRequest request);
  TaskEither<AppException, VoiceFeedbackEntity> sendScoreRecord(ScoreRecordRequest request);
}
