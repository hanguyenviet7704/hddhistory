part of '../../home.dart';

@freezed
abstract class SuggestedCourseModel with _$SuggestedCourseModel {
  const factory SuggestedCourseModel({
    @Default('') String courseId,
    @JsonKey(fromJson: _suggestedCourseMultiLanguageFromJson) @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @JsonKey(fromJson: _suggestedCourseMultiLanguageFromJson) @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default('') String thumbnailUrl,
    @Default('') String skillsetId,
    @Default(0) int numberOfLesson,
    @Default(false) bool isNew,
    DateTime? publishAt,
    int? newDurationDays,
  }) = _SuggestedCourseModel;

  factory SuggestedCourseModel.fromJson(Map<String, dynamic> json) => _$SuggestedCourseModelFromJson(json);
}

extension SuggestedCourseModelX on SuggestedCourseModel {
  SuggestedCourseEntity toEntity() => SuggestedCourseEntity(
        id: courseId,
        title: title,
        description: description,
        image: image,
        thumbnailUrl: thumbnailUrl,
        skillsetId: skillsetId,
        numberOfLesson: numberOfLesson,
        isNew: isNew,
        publishAt: publishAt,
        newDurationDays: newDurationDays,
      );
}

BaseMultiLanguage _suggestedCourseMultiLanguageFromJson(Object? json) {
  if (json is! Map) return const BaseMultiLanguage();
  return BaseMultiLanguage.fromJson(Map<String, dynamic>.from(json));
}
