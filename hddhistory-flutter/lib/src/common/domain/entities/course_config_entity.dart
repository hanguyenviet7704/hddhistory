part of '../../common.dart';

@freezed
abstract class CourseConfigEntity with _$CourseConfigEntity {
  const factory CourseConfigEntity({
    @DefaultBool() @Default(true) bool enable,
    @JsonKey(name: 'enableFinishOptionalKp') @DefaultBool() @Default(true) bool enableFinishOptionalKeypoints,
    @DefaultBool() @Default(false) bool enablePremiumUnlimitedPractice,
  }) = _CourseConfigEntity;

  factory CourseConfigEntity.fromJson(Map<String, dynamic> json) => _$CourseConfigEntityFromJson(json);
}
