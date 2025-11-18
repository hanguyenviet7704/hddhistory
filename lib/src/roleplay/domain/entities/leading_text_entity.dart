part of '../../roleplay.dart';

@freezed
abstract class LeadingTextEntity with _$LeadingTextEntity {
  const factory LeadingTextEntity({
    @Default('') String backgroundColor,
    @Default('') String textColor,
    @Default(BaseMultiLanguage()) BaseMultiLanguage content,
    @Default('') String audio,
  }) = _LeadingTextEntity;

  factory LeadingTextEntity.fromJson(Map<String, dynamic> json) => _$LeadingTextEntityFromJson(json);
}
