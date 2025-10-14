part of '../../onboard.dart';

@freezed
abstract class OnboardEntity with _$OnboardEntity {
  const factory OnboardEntity({
    @Default('') String id,
    @Default('') String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _OnboardEntity;

  factory OnboardEntity.fromJson(Map<String, dynamic> json) => _$OnboardEntityFromJson(json);
}
