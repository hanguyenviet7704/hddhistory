part of '../../onboard.dart';

@freezed
abstract class OnboardCopyModel with _$OnboardCopyModel {
  const factory OnboardCopyModel({
    @Default('') String key,
    @Default(BaseMultiLanguage()) BaseMultiLanguage value,
  }) = _OnboardCopyModel;

  factory OnboardCopyModel.fromJson(Map<String, dynamic> json) => _$OnboardCopyModelFromJson(json);
}

extension OnboardCopyModelExtension on OnboardCopyModel {
  OnboardCopyEntity toEntity() => OnboardCopyEntity(key: key, value: value);
}
