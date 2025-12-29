part of '../../achievenment.dart';

@freezed
abstract class AchievenmentResponseEntity with _$AchievenmentResponseEntity {
  const factory AchievenmentResponseEntity({
    @Default('') String id,
    @Default('') String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _AchievenmentResponseEntity;

  factory AchievenmentResponseEntity.fromJson(Map<String, dynamic> json) => _$AchievenmentResponseEntityFromJson(json);
}

