part of '../../onboard_v2.dart';

/// Onboarding v3 — 11 bước (design.md §6.1). Thanh tiến độ 7 nấc chạy từ
/// p2Name (1) tới p8Reminder (7); p1Intro/p9Loading/p10Result/p11Theme không
/// có header.
enum OnboardV2PageStep {
  p1Intro,
  p2Name,
  p3Age,
  p4Branches,
  p5Problems,
  p6Desire,
  p7How,
  p8Reminder,
  p9Loading,
  p10Result,
  p11Theme,
}

enum OnboardV2AsyncStatus { initial, loading, success, failure }

/// Trạng thái tải `GET /onboarding-taxonomy`. Không còn fallback enum: lỗi thì
/// S4 hiện inline error + Thử lại.
enum OnboardV2TaxonomyStatus { initial, loading, success, failure }

/// Trạng thái gợi ý khoá từ `POST /onboarding-answers`. `fallback` = đã thử và
/// không có kết quả dùng được (S10 hiện màn dự phòng + Thử lại).
enum OnboardV2RecommendStatus { initial, loading, loaded, fallback }

@freezed
abstract class OnboardV2State with _$OnboardV2State {
  const factory OnboardV2State({
    @Default(OnboardV2PageStep.p1Intro) OnboardV2PageStep currentPage,
    @Default(OnboardV2AsyncStatus.initial) OnboardV2AsyncStatus onboardStatus,
    @Default(OnboardV2AsyncStatus.initial) OnboardV2AsyncStatus p3SubmitStatus,
    @Default(OnboardEntity()) OnboardEntity onboardData,

    /// Admin Onboarding Config toggle: open the FULL paywall right after the
    /// onboarding handoff routes into the app.
    @Default(false) bool showPaywallAfterOnboarding,
    @Default('') String name,
    OnboardOptionEntity? selectedAge,

    //* Câu 1/2/3 — taxonomy từ DB (không enum).
    @Default(OnboardingTaxonomyEntity()) OnboardingTaxonomyEntity taxonomy,
    @Default(OnboardV2TaxonomyStatus.initial) OnboardV2TaxonomyStatus taxonomyStatus,
    String? taxonomyErrorMessage,

    /// Mã nhánh theo ĐÚNG thứ tự user chọn — luật câu 2 (§3.2) dựa vào đó.
    @Default([]) List<String> selectedBranchCodes,

    /// Mã gói (= vấn đề) theo thứ tự chọn.
    @Default([]) List<String> selectedPackageCodes,

    /// Mã mong muốn (single-select, == mã gói).
    String? selectedDesireCode,

    /// Đáp án hợp lệ của câu 2 / câu 3, tính lại mỗi khi câu trước đổi
    /// (xem `OnboardV2Cubit._recomputeOptions`).
    @Default([]) List<OnboardingPackageEntity> problemOptions,
    @Default([]) List<OnboardingPackageEntity> desireOptions,

    //* S8 nhắc học theo giờ.
    @Default('21:00') String reminderTime,
    @Default(false) bool reminderEnabled,

    /// Khung giờ nhanh từ config (`reminder.presets`). Rỗng → trang dùng 3
    /// preset l10n mặc định 07:00 / 12:30 / 21:00.
    @Default([]) List<OnboardingReminderPresetEntity> reminderPresets,
    @Default(OnboardV2NotificationStatus.unknown) OnboardV2NotificationStatus notificationStatus,

    //* S9 loading + S10 kết quả.
    DateTime? loadingStartedAt,
    @Default(OnboardV2RecommendStatus.initial) OnboardV2RecommendStatus recommendStatus,
    @Default([]) List<CourseEntity> recommendedCourses,
    @Default({}) Map<String, OnboardingMatchReasonEntity> matchReasons,
    @Default(0) int currentCourseIndex,
    String? recommendErrorMessage,

    /// Khoá user chọn ở S10 (null = "xem kho khoá học"). S11 đọc để bàn giao.
    CourseEntity? chosenCourse,
    String? onboardErrorMessage,
    String? p3ErrorMessage,
  }) = _OnboardV2State;

  factory OnboardV2State.initial() => const OnboardV2State();
}

extension OnboardV2StateX on OnboardV2State {
  bool get canContinueName => name.trim().isNotEmpty;
  bool get canSubmitAge => selectedAge != null && p3SubmitStatus != OnboardV2AsyncStatus.loading;
  bool get canContinueBranches => selectedBranchCodes.isNotEmpty;
  bool get canContinueProblems => selectedPackageCodes.isNotEmpty;
  bool get canContinueDesire => selectedDesireCode?.trim().isNotEmpty ?? false;
  bool get hasRecommendedCourses => recommendedCourses.isNotEmpty;

  CourseEntity? get currentCourse {
    if (recommendedCourses.isEmpty) return null;
    final index = currentCourseIndex.clamp(0, recommendedCourses.length - 1);
    return recommendedCourses[index];
  }

  /// Skillset tương ứng các nhánh đã chọn, theo thứ tự chọn — Home dùng để xếp
  /// skillset. Nhánh chưa gắn `skillsetId` bị bỏ qua.
  List<String> get selectedSkillsetIds => [
    for (final code in selectedBranchCodes)
      if (taxonomy.branchByCode(code)?.skillsetId case final id? when id.isNotEmpty) id,
  ];
}
