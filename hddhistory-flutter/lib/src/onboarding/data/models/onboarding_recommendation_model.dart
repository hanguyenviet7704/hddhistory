part of '../../onboarding.dart';

@freezed
abstract class OnboardingMatchReasonModel with _$OnboardingMatchReasonModel {
  const factory OnboardingMatchReasonModel({
    @Default(false) bool desire,
    @Default([]) List<String> labelCodes,
    @Default([]) List<String> packageCodes,
  }) = _OnboardingMatchReasonModel;

  factory OnboardingMatchReasonModel.fromJson(Map<String, dynamic> json) => _$OnboardingMatchReasonModelFromJson(json);
}

@freezed
abstract class OnboardingRecommendedCourseModel with _$OnboardingRecommendedCourseModel {
  const factory OnboardingRecommendedCourseModel({
    @JsonKey(name: '_id') @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default('') String categoryId,
    @Default(0) int numberOfLesson,
    @Default(OnboardingMatchReasonModel()) OnboardingMatchReasonModel matchReason,
  }) = _OnboardingRecommendedCourseModel;

  factory OnboardingRecommendedCourseModel.fromJson(Map<String, dynamic> json) => _$OnboardingRecommendedCourseModelFromJson(json);
}

@freezed
abstract class OnboardingRecommendationModel with _$OnboardingRecommendationModel {
  const factory OnboardingRecommendationModel({
    @Default([]) List<OnboardingRecommendedCourseModel> recommendations,
  }) = _OnboardingRecommendationModel;

  factory OnboardingRecommendationModel.fromJson(Map<String, dynamic> json) => _$OnboardingRecommendationModelFromJson(json);
}

extension OnboardingRecommendationModelX on OnboardingRecommendationModel {
  OnboardingRecommendationEntity toEntity() => OnboardingRecommendationEntity(
    courses: [
      for (final c in recommendations)
        CourseEntity(
          id: c.id,
          title: c.title,
          description: c.description,
          image: c.image,
          categoryId: c.categoryId,
          numberOfLesson: c.numberOfLesson,
        ),
    ],
    matchReasons: {
      for (final c in recommendations)
        c.id: OnboardingMatchReasonEntity(
          desire: c.matchReason.desire,
          labelCodes: c.matchReason.labelCodes,
          packageCodes: c.matchReason.packageCodes,
        ),
    },
  );
}
