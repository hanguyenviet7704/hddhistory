part of '../../home.dart';

@freezed
abstract class SuggestedCourseEntity with _$SuggestedCourseEntity {
  const factory SuggestedCourseEntity({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default('') String skillsetId,
    @Default(0) int numberOfLesson,
    @Default(false) bool isNew,
    DateTime? publishAt,
    int? newDurationDays,
  }) = _SuggestedCourseEntity;

  factory SuggestedCourseEntity.fromJson(Map<String, dynamic> json) => _$SuggestedCourseEntityFromJson(json);
}

extension SuggestedCourseEntityX on SuggestedCourseEntity {
  /// Effective "New course" state for a recommended card. Suggested courses are
  /// always published, so there's no coming-soon case — a course is "new" via
  /// the manual [isNew] flag or while inside its scheduled new-course window
  /// ([publishAt] … +[newDurationDays]). Defaults to false when the backend
  /// sends no new-ness data, so the badge stays hidden rather than showing on
  /// every card.
  bool get isNewNow {
    if (isNew) return true;
    final at = publishAt;
    final days = newDurationDays ?? 0;
    if (at == null || days <= 0) return false;
    final now = DateTime.now();
    return !now.isBefore(at) && now.isBefore(at.add(Duration(days: days)));
  }
}
