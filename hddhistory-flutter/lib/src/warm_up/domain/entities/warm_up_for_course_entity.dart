part of '../../warm_up.dart';

@freezed
abstract class WarmUpForCourseEntity with _$WarmUpForCourseEntity {
  const factory WarmUpForCourseEntity({
    @Default(false) bool isDue,
    WarmUpPreviousLessonEntity? previousLesson,
  }) = _WarmUpForCourseEntity;

  factory WarmUpForCourseEntity.fromJson(Map<String, dynamic> json) => _$WarmUpForCourseEntityFromJson(json);
}

extension WarmUpForCourseEntityX on WarmUpForCourseEntity {
  /// Only questions the shared daily-warm-up player can actually render.
  List<QuestionEntity> get usableQuestions {
    final lesson = previousLesson;
    if (lesson == null) return const [];
    return filterUsableDailyWarmUpQuestions(lesson.questions);
  }

  /// The single source of truth for "should the return-refresher CTA show".
  bool get hasWarmUpAvailable => isDue && usableQuestions.isNotEmpty;
}
