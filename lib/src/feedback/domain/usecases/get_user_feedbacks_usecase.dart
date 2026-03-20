part of '../../feedback.dart';

@lazySingleton
class GetUserFeedbacksUseCase implements BaseUseCase<Unit, UserFeedbackEntity> {
  final IFeedbackRepository _repository;

  GetUserFeedbacksUseCase(this._repository);

  @override
  TaskEither<AppException, UserFeedbackEntity> call(Unit _) {
    return _repository.getUserFeedbacks();
  }
}
