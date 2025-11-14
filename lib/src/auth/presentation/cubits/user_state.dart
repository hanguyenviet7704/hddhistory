part of '../../auth.dart';

@freezed
abstract class UserState with _$UserState {
  const factory UserState({
    @Default(false) bool isLoading,
    @Default(AuthEntity()) AuthEntity auth,
    @Default(Profile()) Profile profile,
    @Default(true) bool isFirstTimeUserRunApp,
    @Default(true) bool isFirstTimeUserAccessApp,
    @Default('') String guestProfileId,
  }) = _UserState;

  factory UserState.initial() => UserState();
  factory UserState.fromJson(Map<String, dynamic> json) => _$UserStateFromJson(json);
}

extension UserStateExtension on UserState {
  UserEntity get user => auth.user;
  String get accessToken => auth.token.accessToken;
  String get refreshToken => auth.token.refreshToken;

  String get paymentStatus {
    if (profile.activeSubscriptions.isEmpty) return 'free';
    return switch (profile.activeSubscriptions.last.subscriptionPlan.externalPlanId) {
      String _ when profile.activeSubscriptions.last.subscriptionPlan.externalPlanId.contains('monthly') => 'monthly',
      String _ when profile.activeSubscriptions.last.subscriptionPlan.externalPlanId.contains('yearly') => 'yearly',
      _ => 'free',
    };
  }
}
