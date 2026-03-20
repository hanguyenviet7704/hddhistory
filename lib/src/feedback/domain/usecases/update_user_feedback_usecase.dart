part of '../../feedback.dart';

@lazySingleton
class UpdateUserFeedbackUseCase implements BaseUseCase<UserFeedbackSubmissionEntity, Unit> {
  final IFeedbackRepository _repository;

  UpdateUserFeedbackUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(UserFeedbackSubmissionEntity params) {
    return _repository.updateUserFeedback(params);
  }
}
