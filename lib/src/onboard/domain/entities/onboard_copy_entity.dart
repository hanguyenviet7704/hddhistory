part of '../../onboard.dart';

@freezed
abstract class OnboardCopyEntity with _$OnboardCopyEntity {
  const factory OnboardCopyEntity({
    @Default('') String key,
    @Default(BaseMultiLanguage()) BaseMultiLanguage value,
  }) = _OnboardCopyEntity;

  factory OnboardCopyEntity.fromJson(Map<String, dynamic> json) => _$OnboardCopyEntityFromJson(json);
}
