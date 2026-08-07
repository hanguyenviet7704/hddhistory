part of '../../habit.dart';

/// A course that teaches this habit's keypoints — rendered on the habit
/// detail's "Read more on this" rail and opened into its roadmap on tap.
@freezed
abstract class HabitCourseEntity with _$HabitCourseEntity {
  const factory HabitCourseEntity({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default('') String image,
    @Default('') String author,
    /// Curated reach figure. Null when the admin left it blank; the card hides
    /// the chip for null and for zero alike.
    int? viewCount,
    @Default('') String skillsetId,
  }) = _HabitCourseEntity;

  factory HabitCourseEntity.fromJson(Map<String, dynamic> json) => _$HabitCourseEntityFromJson(json);
}
