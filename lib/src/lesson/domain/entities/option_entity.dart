part of '../../lesson.dart';

/// A unified model representing question options across different question types.
///
/// Since Dart does not support union types, this model consolidates multiple
/// API response structures into a single type with optional fields.
///
/// **Field usage by question type:**
///
/// | Question Type                          | Used Fields            |
/// |----------------------------------------|------------------------|
/// | `singleChoice` / `multipleChoice`      | `value`, `isCorrect`   |
/// | `dragAndDrop`                          | `id`, `text`           |
/// | `record`                               | None                   |
@freezed
abstract class OptionEntity with _$OptionEntity {
  const factory OptionEntity({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage text,
    @Default(BaseMultiLanguage()) BaseMultiLanguage value,
    @Default(false) bool isCorrect,
  }) = _OptionEntity;

  factory OptionEntity.fromJson(Map<String, dynamic> json) => _$OptionEntityFromJson(json);
}

extension OptionEntityX on OptionEntity {
  String get labelText {
    if (text.text.isNotEmpty) return text.text;
    return value.text;
  }

  OptionEntity withFallbackLabel(String fallback) {
    final fallbackBase = BaseMultiLanguage(en: fallback, vi: fallback, zh: fallback);
    return OptionEntity(
      id: id,
      text: text.text.isNotEmpty ? text : fallbackBase,
      value: value.text.isNotEmpty ? value : fallbackBase,
      isCorrect: isCorrect,
    );
  }
}
