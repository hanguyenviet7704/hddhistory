part of '../../roleplay.dart';

@freezed
abstract class HintModel with _$HintModel {
  const factory HintModel({
    @Default('') String icon,
    @Default('') String textColor,
    @Default('') String backgroundColor,
    @Default(BaseMultiLanguage()) BaseMultiLanguage content,
  }) = _HintModel;

  factory HintModel.fromJson(Map<String, dynamic> json) => _$HintModelFromJson(json);
}

extension HintModelExtension on HintModel {
  HintEntity toEntity() => HintEntity(
    icon: icon,
    textColor: textColor, 
    backgroundColor: backgroundColor,
    content: content,
  );
}
