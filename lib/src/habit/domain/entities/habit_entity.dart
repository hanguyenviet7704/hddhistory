part of '../../habit.dart';

enum HabitLibraryStatusEntity {
  @JsonValue('draft')
  draft,
  @JsonValue('published')
  published,
  @JsonValue('unknown')
  unknown,
}

@freezed
abstract class HabitEntity with _$HabitEntity {
  const factory HabitEntity({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default('') String skillsetId,
    @Default(HabitLibraryStatusEntity.unknown) HabitLibraryStatusEntity status,
    /// The habit's own picture. Empty for a habit no editor has given one, and
    /// the icon falls back to the skillset logo then — see [HabitDomainIcon].
    @Default('') String image,
    String? defaultReminderTime,
    @Default(0) int sortOrder,
  }) = _HabitEntity;

  factory HabitEntity.fromJson(Map<String, dynamic> json) => _$HabitEntityFromJson(json);
}
