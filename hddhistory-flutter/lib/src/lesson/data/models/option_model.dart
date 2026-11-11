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
/// | `singleChoiceNoCorrectAnswer`          | `value`, `documentGroupId` |
/// | `dragAndDrop`                          | `id`, `text`           |
/// | `record`                               | None                   |

@freezed
abstract class OptionModel with _$OptionModel {
  const factory OptionModel({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage text,
    @Default(BaseMultiLanguage()) BaseMultiLanguage value,
    @Default(false) bool isCorrect,
    @Default('') String documentGroupId,
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

  QuestionChoiceOptionEntity toChoiceOptionEntity() {
    final pickedValue = value.text.isNotEmpty ? value : text;
    return QuestionChoiceOptionEntity(
      value: pickedValue,
      isCorrect: isCorrect,
    );
  }

  QuestionNoCorrectChoiceOptionEntity toNoCorrectChoiceOptionEntity() {
    final pickedValue = value.text.isNotEmpty ? value : text;
    return QuestionNoCorrectChoiceOptionEntity(
      value: pickedValue,
      documentGroupId: documentGroupId,
    );
  }

  QuestionDragDropOptionEntity toDragDropOptionEntity() {
    final pickedText = text.text.isNotEmpty ? text : value;
    return QuestionDragDropOptionEntity(
      id: id,
      text: pickedText,
    );
  }
}
