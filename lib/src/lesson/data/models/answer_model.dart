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
abstract class AnswerModel with _$AnswerModel {
  const factory AnswerModel({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage correctAnswer,
    @Default('') String record,
    @Default('') String review,
  }) = _AnswerModel;

  factory AnswerModel.fromJson(Map<String, dynamic> json) => _$AnswerModelFromJson(json);
}

extension AnswerModelExtension on AnswerModel {
  AnswerEntity toEntity() => AnswerEntity(
    id: id,
    correctAnswer: correctAnswer,
    record: record,
    review: review,
  );

  QuestionDragDropAnswerEntity toDragDropAnswerEntity() => QuestionDragDropAnswerEntity(
    id: id,
    correctAnswer: correctAnswer,
  );
}
