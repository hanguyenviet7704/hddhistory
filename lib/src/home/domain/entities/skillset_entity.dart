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
