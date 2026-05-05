part of '../../onboard_v2.dart';

enum OnboardV2PageStep {
  p1Intro,
  p2Name,
  p3Age,
  p4Skillset,
  p5Demo,
  p6Notification,
  p7Recommendation,
}

enum OnboardV2AsyncStatus { initial, loading, success, failure }

enum OnboardV2RecommendationStatus { initial, loading, loaded, fallback }

enum OnboardV2NavigationStatus { initial, loading, success, failure }

@freezed
abstract class OnboardV2State with _$OnboardV2State {
  const factory OnboardV2State({
    @Default(OnboardV2PageStep.p1Intro) OnboardV2PageStep currentPage,
    @Default(OnboardV2AsyncStatus.initial) OnboardV2AsyncStatus onboardStatus,
    @Default(OnboardV2AsyncStatus.initial) OnboardV2AsyncStatus skillsetStatus,
    @Default(OnboardV2AsyncStatus.initial) OnboardV2AsyncStatus p3SubmitStatus,
    @Default(OnboardV2RecommendationStatus.initial) OnboardV2RecommendationStatus recommendationStatus,
    @Default(OnboardV2NavigationStatus.initial) OnboardV2NavigationStatus navigationStatus,
    @Default(OnboardEntity()) OnboardEntity onboardData,
    @Default([]) List<SkillsetEntity> skillsets,
    @Default('') String name,
    OnboardOptionEntity? selectedAge,
    @Default([]) List<SkillsetEntity> selectedSkillsets,
    CourseEntity? recommendedCourse,
    @Default(OnboardV2NotificationStatus.unknown) OnboardV2NotificationStatus notificationStatus,
    String? onboardErrorMessage,
    String? skillsetErrorMessage,
    String? p3ErrorMessage,
    String? recommendationErrorMessage,
    String? navigationErrorMessage,
  }) = _OnboardV2State;

  factory OnboardV2State.initial() => const OnboardV2State();

  factory OnboardV2State.fromJson(Map<String, dynamic> json) => _$OnboardV2StateFromJson(json);
}

extension OnboardV2StateX on OnboardV2State {
  bool get canContinueName => name.trim().isNotEmpty;
  bool get canSubmitAge => selectedAge != null && p3SubmitStatus != OnboardV2AsyncStatus.loading;
  bool get canContinueSkillsets => selectedSkillsets.isNotEmpty;
  bool get hasRecommendedCourse => recommendedCourse != null && recommendedCourse!.id.isNotEmpty;

  OnboardV2SkillsetSelection get selectedSkillsetSelection => OnboardV2SkillsetSelectionMapper.mapSelected(selectedSkillsets);
}
