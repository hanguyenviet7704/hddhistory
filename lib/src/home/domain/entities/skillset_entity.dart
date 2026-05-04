part of '../../home.dart';

@freezed
abstract class SkillsetEntity with _$SkillsetEntity {
  const factory SkillsetEntity({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default([]) List<CourseEntity> courses,
    SkillsetOnboardingIntroduce? onboardingIntroduce,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _SkillsetEntity;

  factory SkillsetEntity.fromJson(Map<String, dynamic> json) => _$SkillsetEntityFromJson(json);
}

enum SkillsetOnboardingIntroduce {
  myFeelingsFeelLoud('MY_FEELINGS_FEEL_LOUD'),
  myThoughtsCircle('MY_THOUGHTS_CIRCLE'),
  imBusyAllDay('IM_BUSY_ALL_DAY'),
  iTalkToMany('I_TALK_TO_MANY'),
  whatILearnFades('WHAT_I_LEARN_FADES'),
  nothingFeelsNew('NOTHING_FEELS_NEW'),
  ;

  const SkillsetOnboardingIntroduce(this.name);

  final String name;

  String get title => switch (this) {
    myFeelingsFeelLoud => l10n.onboarding.onboardingIntroduceMyFeelings,
    myThoughtsCircle => l10n.onboarding.onboardingIntroduceMyThoughts,
    imBusyAllDay => l10n.onboarding.onboardingIntroduceBusyAllDay,
    iTalkToMany => l10n.onboarding.onboardingIntroduceTalkToMany,
    whatILearnFades => l10n.onboarding.onboardingIntroduceLearnFades,
    nothingFeelsNew => l10n.onboarding.onboardingIntroduceNothingNew,
  };
  
  String get image => switch (this) {
    myFeelingsFeelLoud => AppAsset.icons.app.icHeart.path,
    myThoughtsCircle => AppAsset.icons.app.icCompass.path,
    imBusyAllDay => AppAsset.icons.app.icDirectHit.path,
    iTalkToMany => AppAsset.icons.app.icSpeechBallon.path,
    whatILearnFades => AppAsset.icons.app.icBook.path,
    nothingFeelsNew => AppAsset.icons.app.icWorldMap.path,
  };

  String get imageDisable => switch (this) {
    myFeelingsFeelLoud => AppAsset.icons.app.icHeartDisable.path,
    myThoughtsCircle => AppAsset.icons.app.icCompassDisable.path,
    imBusyAllDay => AppAsset.icons.app.icDirectHitDisable.path,
    iTalkToMany => AppAsset.icons.app.icSpeechBallonDisable.path,
    whatILearnFades => AppAsset.icons.app.icBookDisable.path,
    nothingFeelsNew => AppAsset.icons.app.icWorldMapDisable.path,
  };
}

extension SkillsetEntityExtension on SkillsetEntity {
  List<CourseEntity> get coursesWithSkillset => courses.map((course) => course.copyWith(skillset: copyWith(courses: []))).toList();

  String get trackingName => title.en;
}

extension SkillsetListExtension on List<SkillsetEntity> {
  SkillsetEntity? skillsetFromIndex(int index) => elementAtOrNull(index);

  SkillsetEntity resolveSkillsetByCourseId(String courseId, {SkillsetEntity? fallback}) {
    if (courseId.isEmpty) return fallback ?? const SkillsetEntity();
    return firstWhere(
      (skillset) => skillset.courses.any((course) => course.id == courseId),
      orElse: () => fallback ?? const SkillsetEntity(),
    );
  }

  CourseEntity resolveCourseByCourseId(
    String courseId, {
    CourseEntity? fallback,
    SkillsetEntity? skillsetFallback,
  }) {
    if (courseId.isEmpty) return fallback ?? const CourseEntity();
    final skillset = resolveSkillsetByCourseId(courseId, fallback: skillsetFallback);
    return skillset.courses.firstWhere(
      (course) => course.id == courseId,
      orElse: () => fallback ?? const CourseEntity(),
    );
  }
}
