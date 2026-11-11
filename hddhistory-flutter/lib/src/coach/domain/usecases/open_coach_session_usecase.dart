part of '../../coach.dart';

@lazySingleton
class OpenCoachSessionUseCase {
  final ICoachRepository _repository;

  OpenCoachSessionUseCase(this._repository);

  TaskEither<AppException, CoachTurnEntity> call({
    required CoachEntry entry,
    String? lessonId,
    String? habitId,
    String? keypointId,
    String? courseId,
    bool recap = false,
    required String locale,
    required int tzOffsetMinutes,
  }) {
    return _repository.openSession(
      entry: entry,
      lessonId: lessonId,
      habitId: habitId,
      keypointId: keypointId,
      courseId: courseId,
      recap: recap,
      locale: locale,
      tzOffsetMinutes: tzOffsetMinutes,
    );
  }
}
