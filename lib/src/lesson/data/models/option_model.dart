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
abstract class OptionModel with _$OptionModel {
  const factory OptionModel({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage text,
    @Default(BaseMultiLanguage()) BaseMultiLanguage value,
    @Default(false) bool isCorrect,
  }) = _OptionModel;

  factory OptionModel.fromJson(Map<String, dynamic> json) => _$OptionModelFromJson(json);
}

extension OptionModelExtension on OptionModel {
  OptionEntity toEntity() => OptionEntity(
    id: id,
    text: text,
    value: value,
    isCorrect: isCorrect,
  );
}
