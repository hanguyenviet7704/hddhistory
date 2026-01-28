part of '../../feedback.dart';

@lazySingleton
class GetUserFeedbacksUseCase implements UseCaseWithoutParams<UserFeedbackEntity> {
  final IFeedbackRepository _repository;

  GetUserFeedbacksUseCase(this._repository);

  @override
  TaskEither<AppException, UserFeedbackEntity> call() {
    return _repository.getUserFeedbacks();
  }
}

