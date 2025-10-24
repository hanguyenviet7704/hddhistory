part of '../../exercise.dart';

abstract class IExerciseRepository {
  TaskEither<AppException, BasePageBreak<LearningItemEntity>> getAllLearningItems(
    PageBreakRequest request,
  );
  TaskEither<AppException, LearningItemEntity> getLearningItem(String id);
}
