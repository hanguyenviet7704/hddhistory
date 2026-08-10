part of '../../onboard_v2.dart';

enum OnboardV2PageStep {
  p1Intro,
  p2Name,
  p3Age,
  p4Notification,
  p5PathSelection,
  p6PathMap,
  p7Symptoms,
  p8CoursePicker,
  p9Theme,
}

enum OnboardV2AsyncStatus { initial, loading, success, failure }

enum OnboardV2CourseStatus { initial, loading, loaded, fallback }

enum OnboardV2NavigationStatus { initial, loading, success, failure }

@freezed
abstract class OnboardV2State with _$OnboardV2State {
  const factory OnboardV2State({
    @Default(OnboardV2PageStep.p1Intro) OnboardV2PageStep currentPage,
    @Default(OnboardV2AsyncStatus.initial) OnboardV2AsyncStatus onboardStatus,
    @Default(OnboardV2AsyncStatus.initial) OnboardV2AsyncStatus p3SubmitStatus,
    @Default(OnboardV2CourseStatus.initial) OnboardV2CourseStatus courseStatus,
    @Default(OnboardV2NavigationStatus.initial) OnboardV2NavigationStatus navigationStatus,
    @Default(OnboardEntity()) OnboardEntity onboardData,

    /// Admin Onboarding Config toggle: open the FULL paywall right after the
    /// onboarding handoff routes into the app.
    @Default(false) bool showPaywallAfterOnboarding,
    @Default('') String name,
    OnboardOptionEntity? selectedAge,
    @Default([]) List<OnboardingPath> selectedPaths,
    @Default([]) List<OnboardingSymptom> availableSymptoms,
    @Default([]) List<OnboardingSymptom> selectedSymptoms,
    @Default([]) List<CourseEntity> recommendedCourses,
    @Default(0) int currentCourseIndex,
    @Default(OnboardV2NotificationStatus.unknown) OnboardV2NotificationStatus notificationStatus,
    String? onboardErrorMessage,
    String? p3ErrorMessage,
    String? courseErrorMessage,
    String? navigationErrorMessage,
    // P8 -> P9 handoff (see [OnboardV2Cubit.goToThemeWithSelectedCourse] /
    // [OnboardV2Cubit.goToThemeAsBrowse]): stashes which action P9's
    // "Start Explore" CTA should perform once the user has picked their study
    // theme. Exactly one of the two is meaningful for a given visit to P9 —
    // a non-null [pendingHandoffCourse] always wins over the browse flag.
    CourseEntity? pendingHandoffCourse,
    @Default(false) bool pendingHandoffIsBrowse,
  }) = _OnboardV2State;

  factory OnboardV2State.initial() => const OnboardV2State();

  factory OnboardV2State.fromJson(Map<String, dynamic> json) => _$OnboardV2StateFromJson(json);
}

extension OnboardV2StateX on OnboardV2State {
  bool get canContinueName => name.trim().isNotEmpty;
  bool get canSubmitAge => selectedAge != null && p3SubmitStatus != OnboardV2AsyncStatus.loading;
  bool get canContinuePaths => selectedPaths.isNotEmpty;
  bool get canContinueSymptoms => selectedSymptoms.isNotEmpty;
  bool get hasRecommendedCourses => recommendedCourses.isNotEmpty;

  CourseEntity? get currentCourse {
    if (recommendedCourses.isEmpty) return null;
    final index = currentCourseIndex.clamp(0, recommendedCourses.length - 1);
    return recommendedCourses[index];
  }
}
