part of '../../lesson.dart';

@lazySingleton
class GetKeypointAccessUseCase {
  final ILessonRepository _repository;

  GetKeypointAccessUseCase(this._repository);

  TaskEither<AppException, KeypointAccessEntity> call(String keypointId) => _repository.getKeypointAccess(keypointId);
}

@lazySingleton
class ClaimKeypointAccessUseCase {
  final ILessonRepository _repository;

  ClaimKeypointAccessUseCase(this._repository);

  /// Spends today's free ticket on [keypointId]. Idempotent for the same keypoint
  /// — the reader already holds that ticket, so they get it again.
  TaskEither<AppException, KeypointClaimEntity> call(String keypointId) => _repository.claimKeypointAccess(keypointId);
}
