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
    @Default('') String skillsetId,
  }) = _HabitCourseEntity;

  factory HabitCourseEntity.fromJson(Map<String, dynamic> json) => _$HabitCourseEntityFromJson(json);
}
