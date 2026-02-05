part of '../../lesson.dart';

/// A unified model representing answer data across different question types.
///
/// Since Dart does not support union types, this model consolidates multiple
/// API response structures into a single type with optional fields.
///
/// **Field usage by question type:**
///
/// | Question Type                     | Used Fields             |
/// |-----------------------------------|-------------------------|
/// | `singleChoice` / `multipleChoice` | None                    |
/// | `dragAndDrop`                     | `id`, `correctAnswer`   |
/// | `record`                          | `record`, `review`      |
@freezed
abstract class AnswerEntity with _$AnswerEntity {
  const factory AnswerEntity({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage correctAnswer,
    @Default('') String record,
    @Default('') String review,
  }) = _AnswerEntity;

  factory AnswerEntity.fromJson(Map<String, dynamic> json) => _$AnswerEntityFromJson(json);
}

