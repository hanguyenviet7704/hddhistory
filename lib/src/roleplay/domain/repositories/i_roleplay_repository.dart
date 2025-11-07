part of '../../roleplay.dart';

abstract class IRoleplayRepository {
  TaskEither<AppException, BasePageBreak<LearningItemEntity>> getAllLearningItems(
    PageBreakRequest request,
  );
  TaskEither<AppException, LearningItemEntity> getLearningItem(String id);
}
