part of '../../home.dart';

@freezed
abstract class SkillsetEntity with _$SkillsetEntity {
  const factory SkillsetEntity({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default([]) List<CourseEntity> courses,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _SkillsetEntity;

  factory SkillsetEntity.fromJson(Map<String, dynamic> json) => _$SkillsetEntityFromJson(json);
}

extension SkillsetEntityExtension on SkillsetEntity {
  List<CourseEntity> get coursesWithSkillset => courses.map((course) => course.copyWith(skillset: copyWith(courses: []))).toList();
}