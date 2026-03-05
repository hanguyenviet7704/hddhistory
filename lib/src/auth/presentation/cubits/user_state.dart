part of '../../auth.dart';

enum UserStatus { initial, loading, success, failure }

@freezed
abstract class UserState with _$UserState {
  const factory UserState({
    @Default(UserStatus.initial) UserStatus status,
    @Default(AuthEntity()) AuthEntity auth,
    @Default(true) bool isAppEventConfigured,
    @Default(true) bool isUserPassOnboarding,
    @Default(true) bool isFirstTimeUserAccessLessonList,
    @Default(true) bool isFirstTimeUserChooseCourse,
    @Default(true) bool isFirstTimeLessonNavigationGuide,
    @Default(null) DateTime? lastStreakCountedDate,
  }) = _UserState;

  factory UserState.initial() => UserState();
  factory UserState.fromJson(Map<String, dynamic> json) => _$UserStateFromJson(json);
}

extension UserStateExtension on UserState {
  UserEntity get user => auth.user;
  String get accessToken => auth.token.accessToken;
  String get refreshToken => auth.token.refreshToken;
  DateTime? get lastStreakCountedUtcDay {
    if (lastStreakCountedDate == null) return null;
    final value = lastStreakCountedDate!.toUtc();
    return DateTime.utc(value.year, value.month, value.day);
  }

  bool isSameStreakCountedUtcDay(DateTime utcDate) {
    final previousDay = lastStreakCountedUtcDay;
    if (previousDay == null) return false;
    final normalized = DateTime.utc(utcDate.year, utcDate.month, utcDate.day);
    return previousDay == normalized;
  }

  // String get paymentStatus {
  //   if (profile.activeSubscriptions.isEmpty) return 'free';
  //   return switch (profile.activeSubscriptions.last.subscriptionPlan.externalPlanId) {
  //     String _ when profile.activeSubscriptions.last.subscriptionPlan.externalPlanId.contains('monthly') => 'monthly',
  //     String _ when profile.activeSubscriptions.last.subscriptionPlan.externalPlanId.contains('yearly') => 'yearly',
  //     _ => 'free',
  //   };
  // }
}
