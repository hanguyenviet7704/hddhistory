part of '../../onboarding.dart';

@freezed
abstract class OnboardingMatchReasonEntity with _$OnboardingMatchReasonEntity {
  const factory OnboardingMatchReasonEntity({
    @Default(false) bool desire,
    @Default([]) List<String> labelCodes,
    @Default([]) List<String> packageCodes,
  }) = _OnboardingMatchReasonEntity;
}

/// Response of `POST /api/v1/onboarding-answers` — the 3 recommended courses
/// plus, keyed by course id, why each one was recommended.
@freezed
abstract class OnboardingRecommendationEntity with _$OnboardingRecommendationEntity {
  const factory OnboardingRecommendationEntity({
    @Default([]) List<CourseEntity> courses,
    @Default({}) Map<String, OnboardingMatchReasonEntity> matchReasons,
  }) = _OnboardingRecommendationEntity;
}

/// Body của POST /onboarding-answers. Mọi field optional; null không gửi.
class OnboardingAnswersRequest {
  const OnboardingAnswersRequest({
    this.branchCodes,
    this.packageCodes,
    this.desireCode,
    this.reminderEnabled,
    this.reminderTime,
    this.chosenCourseId,
    this.ageKey,
    this.completed,
  });

  final List<String>? branchCodes;
  final List<String>? packageCodes;
  final String? desireCode;
  final bool? reminderEnabled;
  final String? reminderTime;
  final String? chosenCourseId;
  final String? ageKey;
  final bool? completed;

  Map<String, dynamic> toJson() => {
    if (branchCodes != null) 'branchCodes': branchCodes,
    if (packageCodes != null) 'packageCodes': packageCodes,
    if (desireCode != null) 'desireCode': desireCode,
    if (reminderEnabled != null) 'reminderEnabled': reminderEnabled,
    if (reminderTime != null) 'reminderTime': reminderTime,
    if (chosenCourseId != null) 'chosenCourseId': chosenCourseId,
    if (ageKey != null) 'ageKey': ageKey,
    if (completed != null) 'completed': completed,
  };
}
