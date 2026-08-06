part of '../../habit.dart';

/// One practice available on a habit: a pointer to authored content, with that
/// content hydrated by the API.
///
/// The content reuses [LearningItemEntity] / [QuestionEntity] from the course
/// and lesson features rather than a habit-local copy — the API returns the same
/// `learning_item` document the lesson flow already parses, so a second model
/// would only be a second thing to keep in sync. Only the DATA shape is shared;
/// the habit quiz does not touch the lesson's cubits, which read the currently
/// open lesson through DI singletons and write `user_progress` against it.
///
/// It must be [LearningItemEntity] — hydrated through `LearningItemModel` — and
/// NOT `ExerciseEntity.fromJson`. The wire writes the whole drag-drop family as
/// `type: 'drag_drop'` plus a `form` discriminator, and `QuestionEntity`'s
/// generated decoder throws `ArgumentError` on a `type` outside its own enum
/// (`drag_and_drop` / `arrange_the_sequence`). Parsing the raw document into
/// entities therefore blew up the ENTIRE practices response the moment a text-gap
/// or arrange question existed — the whole list came back empty and the quiz row
/// silently disappeared. `QuestionModel` is the tolerant layer that maps
/// `(type, form)` onto those entity values.
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
    LearningItemEntity? learningItem,
  }) = _HabitPracticeEntity;
}

extension HabitPracticeEntityX on HabitPracticeEntity {
  List<QuestionEntity> get questions => learningItem?.mainQuestions ?? const [];

  String get title => learningItem?.title.text ?? '';

  /// The four types the design's quiz deck covers — its own data is
  /// `QUIZ_TYPES = { single, multi, dnd, arr }`. Anything else (speaking,
  /// cues/stress placement) is dropped rather than rendered: those need a
  /// microphone or a lesson-only renderer, and a card the reader cannot answer
  /// would wedge the deck, since swiping on is gated on grading.
  List<QuestionEntity> get playableQuestions => questions
      .where(
        (question) => switch (question.type) {
          QuestionTypeEnum.singleChoice ||
          QuestionTypeEnum.multipleChoice ||
          QuestionTypeEnum.dragAndDrop ||
          QuestionTypeEnum.arrangeTheSequence => true,
          _ => false,
        },
      )
      .toList();

  bool get isPlayable => playableQuestions.isNotEmpty;
}
