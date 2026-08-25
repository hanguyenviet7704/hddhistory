part of '../../coach.dart';

@lazySingleton
class SendCoachTurnUseCase {
  final ICoachRepository _repository;

  SendCoachTurnUseCase(this._repository);

  TaskEither<AppException, CoachTurnEntity> call({
    required String sessionId,
    required Map<String, dynamic> payload,
  }) {
    return _repository.sendTurn(sessionId: sessionId, payload: payload);
  }
}
