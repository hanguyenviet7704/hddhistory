part of '../../course.dart';

@freezed
abstract class CourseEntity with _$CourseEntity {
  const factory CourseEntity({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default('') String skillsetId,
    @Default(SkillsetEntity()) SkillsetEntity skillset,
    @Default(0) int numberOfLesson,
    @Default(0) int numberOfLessonPassed,
    @Default([]) List<OnboardingSymptom> onboardingSymptoms,
    @Default(CoursePublishStatus.published) CoursePublishStatus status,
    @Default(false) bool isNew,
    DateTime? publishAt,
    int? newDurationDays,

    /// Author credit for course cards. Null when unset in admin.
    String? author,

    /// Curated reach figure, raw (6300 renders as "6.3k"). Null when unset.
    int? viewCount,
  }) = _CourseEntity;

  factory CourseEntity.fromJson(Map<String, dynamic> json) => _$CourseEntityFromJson(json);
}


extension CourseEntityExtension on CourseEntity {
  CourseEntity get withSkillset {
    List<SkillsetEntity> skillsets = AppDI.injector.get<HomeCubit>().state.skillsets;
    SkillsetEntity skillset = skillsets.firstWhere(
      (skillset) => skillset.id == skillsetId,
      orElse: () => SkillsetEntity(),
    );
    return copyWith(skillset: skillset);
  }

  /// Completion percentage (0–100) for "Continue learning" cards.
  double get completionPercentage =>
      numberOfLesson > 0 ? (numberOfLessonPassed / numberOfLesson * 100).clamp(0, 100) : 0;

  String get trackingName => title.en;

  String get trackingNameOrText => title.en.isNotEmpty ? title.en : title.text;

  /// Effective "Coming soon" state, computed at read time: a coming-soon course
  /// stays upcoming only until its scheduled [publishAt]; after that it's live.
  bool get isComingSoonNow {
    if (status != CoursePublishStatus.comingSoon) return false;
    final at = publishAt;
    if (at == null) return true;
    return DateTime.now().isBefore(at);
  }

  /// Effective "New course" state: the manual [isNew] flag, or a scheduled
  /// course within its new-course window ([publishAt] … +[newDurationDays]).
  bool get isNewNow {
    if (isComingSoonNow) return false;
    if (isNew) return true;
    final at = publishAt;
    final days = newDurationDays ?? 0;
    if (at == null || days <= 0) return false;
    final now = DateTime.now();
    return !now.isBefore(at) && now.isBefore(at.add(Duration(days: days)));
  }
}
