part of '../../common.dart';

@freezed
abstract class PaywallConfigEntity with _$PaywallConfigEntity {
  const factory PaywallConfigEntity({
    @Default(false) bool enableLessonLock,
    @Default(0) int lessonLock,
  }) = _PaywallConfigEntity;

  factory PaywallConfigEntity.fromJson(Map<String, dynamic> json) => _$PaywallConfigEntityFromJson(json);
}
