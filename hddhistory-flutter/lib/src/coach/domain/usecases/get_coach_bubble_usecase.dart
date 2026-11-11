part of '../../coach.dart';

@lazySingleton
class GetCoachBubbleUseCase {
  final ICoachRepository _repository;

  GetCoachBubbleUseCase(this._repository);

  TaskEither<AppException, CoachBubbleEntity> call({
    required CoachEntry entry,
    String? lessonId,
    required int tzOffsetMinutes,
  }) {
    return _repository.getBubble(
      entry: entry,
      lessonId: lessonId,
      tzOffsetMinutes: tzOffsetMinutes,
    );
  }
}
