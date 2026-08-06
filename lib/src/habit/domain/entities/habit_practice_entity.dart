part of '../../habit.dart';

/// One practice available on a habit: a pointer to authored content, with that
/// content hydrated by the API.
///
/// The content reuses [ExerciseEntity] / [QuestionEntity] from the lesson
/// feature rather than a habit-local copy — the API returns the same
/// `learning_item` document the lesson flow already parses, so a second model
/// would only be a second thing to keep in sync. Only the DATA shape is shared;
/// the habit quiz does not touch the lesson's cubits, which read the currently
/// open lesson through DI singletons and write `user_progress` against it.
@freezed
abstract class HabitPracticeEntity with _$HabitPracticeEntity {
  const factory HabitPracticeEntity({
    @Default('') String id,
    @Default('') String habitId,
    @Default('') String learningItemId,
    @Default(0) int order,

    /// Derived server-side from the learning item's `type`.
    @Default(HabitCheckinMethodEntity.unknown) HabitCheckinMethodEntity method,

    /// Null when the API dropped the row because its content was deleted; the
    /// API filters those out, so this being null means something unexpected.
    ExerciseEntity? learningItem,
  }) = _HabitPracticeEntity;
}

extension HabitPracticeEntityX on HabitPracticeEntity {
  List<QuestionEntity> get questions => learningItem?.questions ?? const [];

  String get title => learningItem?.title.text ?? '';

  /// Only choice questions are playable today (see `HabitQuizPage`), so a
  /// practice whose questions are all drag-drop or speaking would open to an
  /// empty deck. Filtering here keeps that decision in one place.
  List<QuestionEntity> get playableQuestions => questions
      .where(
        (question) =>
            question.type == QuestionTypeEnum.singleChoice ||
            question.type == QuestionTypeEnum.multipleChoice,
      )
      .toList();

  bool get isPlayable => playableQuestions.isNotEmpty;
}
