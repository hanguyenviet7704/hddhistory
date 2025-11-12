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
    @Default(CoursePublishStatus.published) CoursePublishStatus status,
  }) = _CourseEntity;

  factory CourseEntity.fromJson(Map<String, dynamic> json) => _$CourseEntityFromJson(json);
}

extension CourseEntityExtension on CourseEntity {
  CourseEntity get withSkillset {
    List<SkillsetEntity> skillsets = AppDI.injector.get<HomeCubit>().state.skillsets;
    SkillsetEntity skillset = skillsets.firstWhere((skillset) => skillset.id == skillsetId, orElse: () => SkillsetEntity());
    return copyWith(skillset: skillset);
  }
}