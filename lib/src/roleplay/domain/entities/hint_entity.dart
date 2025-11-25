part of '../../roleplay.dart';

@freezed
abstract class HintEntity with _$HintEntity {
  const factory HintEntity({
    @Default('') String icon,
    @Default('') String textColor,
    @Default('') String backgroundColor,
    @Default(BaseMultiLanguage()) BaseMultiLanguage content,
  }) = _HintEntity;

  factory HintEntity.fromJson(Map<String, dynamic> json) => _$HintEntityFromJson(json);
}
