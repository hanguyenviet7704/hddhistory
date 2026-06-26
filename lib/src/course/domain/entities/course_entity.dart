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
    @Default([]) List<OnboardingSymptom> onboardingSymptoms,
    @Default(CoursePublishStatus.published) CoursePublishStatus status,
    @Default(false) bool isNew,
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

  String get trackingName => title.en;

  String get trackingNameOrText => title.en.isNotEmpty ? title.en : title.text;
}
