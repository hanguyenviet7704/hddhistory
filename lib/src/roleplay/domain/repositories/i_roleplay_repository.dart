part of '../../roleplay.dart';

abstract class IRoleplayRepository {
  TaskEither<AppException, LearningItemEntity> getLearningItem(String id);
  TaskEither<AppException, RoleplayFeedbackEntity> sendFeedbackRoleplay(Map<String, dynamic> body);
}
