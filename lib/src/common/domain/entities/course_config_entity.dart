part of '../../common.dart';

@freezed
abstract class CourseConfigEntity with _$CourseConfigEntity {
  const factory CourseConfigEntity({
    @JsonKey(fromJson: _boolFromJson) @Default(true) bool enable,
    @JsonKey(name: 'finishOptionalKp', fromJson: _boolFromJson) @Default(true) bool finishOptionalKeypoints,
  }) = _CourseConfigEntity;

  factory CourseConfigEntity.fromJson(Map<String, dynamic> json) => _$CourseConfigEntityFromJson(json);
}

bool _boolFromJson(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
  return false;
}
