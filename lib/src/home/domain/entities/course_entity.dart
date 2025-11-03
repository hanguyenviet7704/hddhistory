part of '../../home.dart';

@freezed
abstract class CourseEntity with _$CourseEntity {
  const factory CourseEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default('') String skillsetId,
    @Default(CourseLevel.level1) CourseLevel level,
    @Default(CourseStatus.published) CourseStatus status,
  }) = _CourseEntity;

  factory CourseEntity.fromJson(Map<String, dynamic> json) => _$CourseEntityFromJson(json);
}
