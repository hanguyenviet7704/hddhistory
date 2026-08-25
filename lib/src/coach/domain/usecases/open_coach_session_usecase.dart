part of '../../coach.dart';

@lazySingleton
class OpenCoachSessionUseCase {
  final ICoachRepository _repository;

  OpenCoachSessionUseCase(this._repository);

  TaskEither<AppException, CoachTurnEntity> call({
    required CoachEntry entry,
    String? lessonId,
    String? habitId,
    required String locale,
    required int tzOffsetMinutes,
  }) {
    return _repository.openSession(
      entry: entry,
      lessonId: lessonId,
      habitId: habitId,
      locale: locale,
      tzOffsetMinutes: tzOffsetMinutes,
    );
  }
}
