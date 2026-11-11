part of '../../coach.dart';

@lazySingleton
class CloseCoachSessionUseCase {
  final ICoachRepository _repository;

  CloseCoachSessionUseCase(this._repository);

  TaskEither<AppException, Unit> call(String sessionId) {
    return _repository.closeSession(sessionId);
  }
}
