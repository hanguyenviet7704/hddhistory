part of '../../feedback.dart';

@lazySingleton
class UpdateUserFeedbackUseCase implements UseCaseWithParams<UserFeedbackEntity, Unit> {
  final IFeedbackRepository _repository;

  UpdateUserFeedbackUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(UserFeedbackEntity params) {
    return _repository.updateUserFeedback(params);
  }
}

