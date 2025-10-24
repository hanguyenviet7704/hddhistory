part of '../../exercise.dart';

abstract class IExerciseRepository {
  TaskEither<AppException, BasePageBreak<LearningItemEntity>> getAllLearningItems(
    PageBreakRequest request,
  );
  TaskEither<AppException, LearningItemEntity> getLearningItem(String id);
  TaskEither<AppException, LearningItemEntity> createLearningItem(LearningItemEntity entity);
  TaskEither<AppException, LearningItemEntity> updateLearningItem(LearningItemEntity entity);
  TaskEither<AppException, Unit> deleteLearningItem(String id);
}
