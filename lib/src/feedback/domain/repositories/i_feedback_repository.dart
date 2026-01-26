part of '../../feedback.dart';

abstract class IFeedbackRepository {
  TaskEither<AppException, UserFeedbackEntity> getUserFeedbacks();
  TaskEither<AppException, Unit> updateUserFeedback(UserFeedbackEntity entity);
}

