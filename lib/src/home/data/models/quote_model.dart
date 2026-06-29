part of '../../home.dart';

@freezed
abstract class QuoteModel with _$QuoteModel {
  const factory QuoteModel({
    @JsonKey(fromJson: _quoteMultiLanguageFromJson) @Default(BaseMultiLanguage()) BaseMultiLanguage content,
    @Default('') String backgroundColor,
    @Default('') String textColor,
  }) = _QuoteModel;

  factory QuoteModel.fromJson(Map<String, dynamic> json) => _$QuoteModelFromJson(json);
}

extension QuoteModelX on QuoteModel {
  QuoteEntity toEntity() => QuoteEntity(
        content: content,
        backgroundColor: backgroundColor,
        textColor: textColor,
      );
}

BaseMultiLanguage _quoteMultiLanguageFromJson(Object? json) {
  if (json is! Map) return const BaseMultiLanguage();
  return BaseMultiLanguage.fromJson(Map<String, dynamic>.from(json));
}
