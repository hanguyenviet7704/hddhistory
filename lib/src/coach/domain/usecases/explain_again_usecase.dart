part of '../../coach.dart';

@lazySingleton
class ExplainAgainUseCase {
  final ICoachRepository _repository;

  ExplainAgainUseCase(this._repository);

  TaskEither<AppException, Unit> call(String keypointId) {
    return _repository.explainAgain(keypointId);
  }
}
