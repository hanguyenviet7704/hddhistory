part of '../../home.dart';

@freezed
abstract class QuoteEntity with _$QuoteEntity {
  const factory QuoteEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage content,
    @Default('') String backgroundColor,
    @Default('') String textColor,
  }) = _QuoteEntity;

  factory QuoteEntity.fromJson(Map<String, dynamic> json) => _$QuoteEntityFromJson(json);
}

extension QuoteEntityX on QuoteEntity {
  Color get resolvedBackgroundColor => _parseHexColor(backgroundColor, AppCustomColor.brandPrimary50);
  Color get resolvedTextColor => _parseHexColor(textColor, AppCustomColor.textPrimary);

  Color _parseHexColor(String hex, Color fallback) {
    try {
      final cleaned = hex.replaceAll('#', '');
      if (cleaned.length == 6) return Color(int.parse('0xFF$cleaned'));
      if (cleaned.length == 8) return Color(int.parse('0x$cleaned'));
    } catch (_) {}
    return fallback;
  }
}
