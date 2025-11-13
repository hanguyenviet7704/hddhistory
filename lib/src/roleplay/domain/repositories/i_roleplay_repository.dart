part of '../../roleplay.dart';

abstract class IRoleplayRepository {
  TaskEither<AppException, LearningItemEntity> getLearningItem(String id);
}
