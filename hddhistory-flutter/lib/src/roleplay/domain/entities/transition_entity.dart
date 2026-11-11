part of '../../roleplay.dart';

@freezed
abstract class TransitionEntity with _$TransitionEntity {
  const factory TransitionEntity({
    @Default('') String textColor,
    @Default(BaseMultiLanguage()) BaseMultiLanguage content,
    
    @Default('') String icon,
    @Default('') String backgroundColor,
  }) = _TransitionEntity;

  factory TransitionEntity.fromJson(Map<String, dynamic> json) => _$TransitionEntityFromJson(json);
}
