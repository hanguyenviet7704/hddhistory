part of '../../lesson.dart';

abstract class ILessonRepository {
  TaskEither<AppException, BasePageBreak<LearningItemEntity>> getAllLearningItems(
    PageBreakRequest request,
  );
  TaskEither<AppException, LearningItemEntity> getLearningItem(String id);
}
