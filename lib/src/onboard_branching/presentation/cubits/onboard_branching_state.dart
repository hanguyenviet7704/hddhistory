part of '../../onboard_branching.dart';

enum OnboardBranchingStatus { initial, loading, ready, failure }

enum OnboardBranchingStage {
  welcome,
  content,
  loading,
  recommendation,
}

enum OnboardBranchingFallbackReason {
  none,
  scenarioUnavailable,
  entrySceneMissing,
  scenesEmpty,
  sceneCycleDetected,
  unknownContentType,
  missingPayload,
  branchNextSceneNotFound,
}

extension OnboardBranchingFallbackReasonExtension on OnboardBranchingFallbackReason {
  String get trackingReason {
    return switch (this) {
      OnboardBranchingFallbackReason.none => 'none',
      OnboardBranchingFallbackReason.scenarioUnavailable => 'scenario_unavailable',
      OnboardBranchingFallbackReason.entrySceneMissing => 'entry_scene_missing',
      OnboardBranchingFallbackReason.scenesEmpty => 'scenes_empty',
      OnboardBranchingFallbackReason.sceneCycleDetected => 'scene_cycle_detected',
      OnboardBranchingFallbackReason.unknownContentType => 'unknown_content_type',
      OnboardBranchingFallbackReason.missingPayload => 'missing_payload',
      OnboardBranchingFallbackReason.branchNextSceneNotFound => 'branch_next_scene_not_found',
    };
  }
}

@freezed
abstract class OnboardBranchingState with _$OnboardBranchingState {
  const factory OnboardBranchingState({
    @Default(OnboardBranchingStatus.initial) OnboardBranchingStatus status,
    @Default(OnboardBranchingStage.welcome) OnboardBranchingStage stage,
    @Default(OnboardingScenarioBranchingEntity()) OnboardingScenarioBranchingEntity onboardScenarioData,
    @Default('') String userName,
    @Default('') String currentSceneId,
    @Default(0) int currentContentIndex,
    @Default([]) List<String> visitedSceneIds,
    @Default([]) List<OnboardingScenarioBranchOptionEntity> selectedBranchOptions,
    @Default([]) List<OnboardOptionEntity> selectedFixedOptions,
    OnboardingScenarioBranchOptionEntity? selectedCurrentBranchOption,
    OnboardOptionEntity? selectedCurrentFixedOption,
    OnboardingScenarioPersonOptionEntity? selectedPersonAdmireOption,
    @Default(false) bool isPersonAdmireDetailVisible,
    @Default(false) bool isAnonymousLoginAttempted,
    @Default(false) bool isAnonymousLoggedIn,
    @Default(false) bool shouldSkipLegacyAnonymousLogin,
    @Default(false) bool isOnboardingTransitionActive,
    @Default(false) bool isRecommendationInitialized,
    @Default('') String recommendedCourseId,
    @Default(0) double recommendedProgressPercent,
    @Default(CourseEntity()) CourseEntity recommendedCourse,
    @Default(false) bool isTryNowLoading,
    String? p7ErrorMessage,
    @Default(OnboardBranchingFallbackReason.none) OnboardBranchingFallbackReason fallbackReason,
    String? errorMessage,
  }) = _OnboardBranchingState;

  factory OnboardBranchingState.initial() => OnboardBranchingState();

  factory OnboardBranchingState.fromJson(Map<String, dynamic> json) => _$OnboardBranchingStateFromJson(json);
}

extension OnboardBranchingStateExtension on OnboardBranchingState {
  bool get isOnWelcome => stage == OnboardBranchingStage.welcome;
  bool get isOnContent => stage == OnboardBranchingStage.content;
  bool get isOnLoading => stage == OnboardBranchingStage.loading;
  bool get isOnRecommendation => stage == OnboardBranchingStage.recommendation;

  OnboardingScenarioSceneEntity get currentScene => onboardScenarioData.getSceneById(currentSceneId);

  bool get hasCurrentScene => currentScene.id.isNotEmpty;

  bool get hasCurrentContent {
    return currentScene.contents.isNotEmpty && currentContentIndex >= 0 && currentContentIndex < currentScene.contents.length;
  }

  OnboardingScenarioContentItemEntity get currentContent {
    if (!hasCurrentContent) return const OnboardingScenarioContentItemEntity();
    return currentScene.contents[currentContentIndex];
  }

  String get currentContentType {
    return currentContent.type.name;
  }

  List<String> get recommendedCourseIds {
    return selectedBranchOptions.expand((option) => option.courses).map((courseId) => courseId.trim()).where((courseId) => courseId.isNotEmpty).toSet().toList();
  }

  String get recommendedCourseCandidateId {
    final courseIds = recommendedCourseIds;
    return courseIds.isEmpty ? '' : courseIds.last;
  }

  bool get canContinueCurrentContent {
    if (!hasCurrentContent) return false;

    return switch (currentContent.type) {
      OnboardingContentType.branch => selectedCurrentBranchOption != null,
      OnboardingContentType.fixed => selectedCurrentFixedOption != null,
      OnboardingContentType.personAdmire => isPersonAdmireDetailVisible || selectedPersonAdmireOption != null,
      OnboardingContentType.activation => true,
      OnboardingContentType.fact => true,
      OnboardingContentType.unknown => false,
    };
  }
}
