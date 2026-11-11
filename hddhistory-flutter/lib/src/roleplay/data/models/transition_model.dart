part of '../../roleplay.dart';

@freezed
abstract class TransitionModel with _$TransitionModel {
  const factory TransitionModel({
    @Default('') String textColor,
    @Default(BaseMultiLanguage()) BaseMultiLanguage content,

    
    @Default('') String icon,
    @Default('') String backgroundColor,
  }) = _TransitionModel;

  factory TransitionModel.fromJson(Map<String, dynamic> json) => _$TransitionModelFromJson(json);
}

extension TransitionModelExtension on TransitionModel {
  TransitionEntity toEntity() => TransitionEntity(
    icon: icon,
    textColor: textColor,
    backgroundColor: backgroundColor,
    content: content,
  );
}
