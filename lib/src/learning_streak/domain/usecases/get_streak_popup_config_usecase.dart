part of '../../learning_streak.dart';

@lazySingleton
class GetStreakPopupConfigUseCase {
  final ILearningStreakRepository _repository;

  GetStreakPopupConfigUseCase(this._repository);

  TaskEither<AppException, StreakPopupConfigEntity> call() {
    return _repository.getStreakPopupConfig();
  }
}
