part of '../../learning_import.dart';

/// Kinds of block inside a section. Only two, matching what the API generates:
/// v1 produces prose only, and every kind added here is a branch the reader has
/// to grow.
enum LessonBlockTypeEntity {
  @JsonValue('heading')
  heading,
  @JsonValue('paragraph')
  paragraph,
}

@freezed
abstract class LessonBlockEntity with _$LessonBlockEntity {
  const factory LessonBlockEntity({
    @Default(LessonBlockTypeEntity.paragraph) LessonBlockTypeEntity type,
    @Default('') String text,
  }) = _LessonBlockEntity;
}

@freezed
abstract class LessonSectionEntity with _$LessonSectionEntity {
  const factory LessonSectionEntity({
    @Default('') String title,
    @Default(<LessonBlockEntity>[]) List<LessonBlockEntity> blocks,
  }) = _LessonSectionEntity;
}

/// A lesson the user generated from their own material.
///
/// The list screen gets these WITHOUT [sections] (the API leaves the body out of
/// the list response — a page of ten lessons would otherwise ship ~50k words to
/// draw ten cards), so treat an empty `sections` on a card as "not loaded yet",
/// not as "empty lesson".
@freezed
abstract class UserLessonEntity with _$UserLessonEntity {
  const factory UserLessonEntity({
    @Default('') String id,
    @Default('') String title,
    @Default('') String description,
    @Default('') String outputLocale,
    @Default(ImportSourceTypeEntity.unknown) ImportSourceTypeEntity sourceType,

    /// Filename or video title, shown under the title on the card.
    @Default('') String sourceLabel,
    @Default(0) int wordCount,
    @Default(0) int estimatedMinutes,

    /// How far the reader got, as a section index.
    ///
    /// Still a section index even though the reader is one continuous scroll:
    /// the app reports the topmost visible section when it leaves, and restoring
    /// to a section boundary survives a re-render or a font-size change, which a
    /// raw scroll offset would not.
    @Default(0) int stopAtSectionIndex,
    DateTime? createdAt,
    @Default(<LessonSectionEntity>[]) List<LessonSectionEntity> sections,
  }) = _UserLessonEntity;
}

extension UserLessonEntityX on UserLessonEntity {
  bool get hasBody => sections.isNotEmpty;

  /// Reading progress as a 0-100 int, for the card's label.
  ///
  /// Section-granular by nature, so a lesson opened but not finished reads as
  /// e.g. "20% read" rather than anything finer. Good enough to answer "did I
  /// start this?", which is all the card is asking.
  int get readPercent {
    if (sections.isEmpty || stopAtSectionIndex <= 0) return 0;

    return ((stopAtSectionIndex / sections.length) * 100).clamp(0, 100).round();
  }
}
