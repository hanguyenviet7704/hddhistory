part of '../../home.dart';

@freezed
abstract class SuggestedCourseModel with _$SuggestedCourseModel {
  const factory SuggestedCourseModel({
    @Default('') String courseId,
    @JsonKey(fromJson: _suggestedCourseMultiLanguageFromJson) @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @JsonKey(fromJson: _suggestedCourseMultiLanguageFromJson) @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default('') String categoryId,
    @Default(0) int numberOfLesson,
    @Default(false) bool isNew,
    DateTime? publishAt,
    int? newDurationDays,
    // Editorial fields set per course in admin. Nullable on purpose: the "New
    // today" card hides each half when the content team left it blank.
    String? author,
    int? viewCount,

    /// When the course was created — the "New today" card picks the latest.
    /// Null from an older API/cache; the card then falls back to its
    /// day-seeded rotation.
    DateTime? createdAt,
  }) = _SuggestedCourseModel;

  factory SuggestedCourseModel.fromJson(Map<String, dynamic> json) => _$SuggestedCourseModelFromJson(json);
}

extension SuggestedCourseModelX on SuggestedCourseModel {
  SuggestedCourseEntity toEntity() => SuggestedCourseEntity(
    id: courseId,
    title: title,
    description: description,
    image: image,
    categoryId: categoryId,
    numberOfLesson: numberOfLesson,
    isNew: isNew,
    publishAt: publishAt,
    newDurationDays: newDurationDays,
    author: author,
    viewCount: viewCount,
    createdAt: createdAt,
  );
}

BaseMultiLanguage _suggestedCourseMultiLanguageFromJson(Object? json) {
  if (json is! Map) return const BaseMultiLanguage();
  return BaseMultiLanguage.fromJson(Map<String, dynamic>.from(json));
}
