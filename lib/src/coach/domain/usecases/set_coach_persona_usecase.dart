part of '../../coach.dart';

@lazySingleton
class SetCoachPersonaUseCase {
  final ICoachRepository _repository;

  SetCoachPersonaUseCase(this._repository);

  TaskEither<AppException, Unit> call({
    required String sessionId,
    required String persona,
  }) {
    return _repository.setPersona(sessionId: sessionId, persona: persona);
  }
}
