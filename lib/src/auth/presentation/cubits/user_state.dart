part of '../../auth.dart';

enum UserStatus { initial, loading, success, failure }

@freezed
abstract class UserState with _$UserState {
  const factory UserState({
    @Default(UserStatus.initial) UserStatus status,
    @Default(AuthEntity()) AuthEntity auth,
    @Default(true) bool isAppEventConfigured,
    @Default(true) bool isUserPassOnboarding,
    @Default(false) bool hasCompletedFirstTimeNotificationGate,
    @Default(false) bool hasCompletedCourseEntryNotificationGate,
    @Default(false) bool hasPendingFirstTimePaywallAfterAuth,
    @Default(true) bool isFirstTimeUserAccessLessonList,
    @Default(true) bool isFirstTimeUserChooseCourse,
    @Default(true) bool isFirstTimeLessonNavigationGuide,
    @Default([]) List<String> onboardingCategoryOrder,
  }) = _UserState;

  factory UserState.initial() => UserState();
  factory UserState.fromJson(Map<String, dynamic> json) => _$UserStateFromJson(json);
}

extension UserStateExtension on UserState {
  UserEntity get user => auth.user;
  String get accessToken => auth.token.accessToken;
  String get refreshToken => auth.token.refreshToken;

  // String get paymentStatus {
  //   if (profile.activeSubscriptions.isEmpty) return 'free';
  //   return switch (profile.activeSubscriptions.last.subscriptionPlan.externalPlanId) {
  //     String _ when profile.activeSubscriptions.last.subscriptionPlan.externalPlanId.contains('monthly') => 'monthly',
  //     String _ when profile.activeSubscriptions.last.subscriptionPlan.externalPlanId.contains('yearly') => 'yearly',
  //     _ => 'free',
  //   };
  // }
}
