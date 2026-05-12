part of '../../onboard_v2.dart';

@freezed
abstract class OnboardV2Entity with _$OnboardV2Entity {
  const factory OnboardV2Entity({
    @Default('') String id,
    @Default('') String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _OnboardV2Entity;

  factory OnboardV2Entity.fromJson(Map<String, dynamic> json) => _$OnboardV2EntityFromJson(json);
}
