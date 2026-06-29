part of '../../home.dart';

@freezed
abstract class SuggestedCourseEntity with _$SuggestedCourseEntity {
  const factory SuggestedCourseEntity({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default('') String skillsetId,
    @Default(0) int numberOfLesson,
  }) = _SuggestedCourseEntity;

  factory SuggestedCourseEntity.fromJson(Map<String, dynamic> json) => _$SuggestedCourseEntityFromJson(json);
}
