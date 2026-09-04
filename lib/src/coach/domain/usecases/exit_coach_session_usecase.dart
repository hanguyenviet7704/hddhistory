part of '../../coach.dart';

/// Luồng 6 — the plea's answer. Staying resets the run of declines; closing
/// anyway lengthens it, and after two the plea stops for good.
@lazySingleton
class ExitCoachSessionUseCase {
  final ICoachRepository _repository;

  ExitCoachSessionUseCase(this._repository);

  TaskEither<AppException, Unit> call(String sessionId, {required bool stayed}) {
    return _repository.exitSession(sessionId, stayed: stayed);
  }
}
