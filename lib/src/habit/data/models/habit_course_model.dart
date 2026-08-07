part of '../../habit.dart';

/// One course on the habit detail's "Read more on this" rail — the wire shape
/// of `GET /habits/:id/courses` (card summary, most-relevant course first).
@freezed
abstract class HabitCourseModel with _$HabitCourseModel {
  const factory HabitCourseModel({
    String? id,
    BaseMultiLanguage? title,
    String? image,
    String? author,
    int? viewCount,
    String? skillsetId,
  }) = _HabitCourseModel;

  factory HabitCourseModel.fromJson(Map<String, dynamic> json) => _$HabitCourseModelFromJson(json);
}

extension HabitCourseModelX on HabitCourseModel {
  HabitCourseEntity toEntity() => HabitCourseEntity(
    id: id ?? '',
    title: title ?? const BaseMultiLanguage(),
    image: image ?? '',
    author: author ?? '',
    // Kept nullable rather than defaulted to 0: the chip is hidden for "unset"
    // and for zero alike, and collapsing them would claim a reach of nothing.
    viewCount: viewCount,
    skillsetId: skillsetId ?? '',
  );
}
