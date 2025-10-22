part of '../../profile.dart';

enum ProfileStatus { initial, loading, success, failure }

@freezed
abstract class ProfileState with _$ProfileState {
  const factory ProfileState({
    @Default(false) bool isLoading,
    @Default(ProfileStatus.initial) ProfileStatus status,
    @Default(AuthEntity()) AuthEntity auth,
    @Default(Profile()) Profile profile,
    @Default(true) bool isFirstTimeUserRunApp,
    @Default(true) bool isFirstTimeUserAccessApp,
    @Default(true) bool isFirstTimeUserAccessPictureStudy,
    @Default(false) bool isAppShowRegisterRecommend,
    @Default(true) bool isGuest,
    @Default('') String guestProfileId,
  }) = _ProfileState;

  factory ProfileState.initial() => ProfileState();
  factory ProfileState.fromJson(Map<String, dynamic> json) => _$ProfileStateFromJson(json);
}


extension ProfileStateExtension on ProfileState {
  UserEntity get user => auth.user;
  String get accessToken => auth.token.accessToken;
  String get refreshToken => auth.token.refreshToken;

  bool get isGuestOrNotLogin => isGuest || auth.user.id.isEmpty;
  String get paymentStatus {
    if (profile.activeSubscriptions.isEmpty) return 'free';
    return switch (profile.activeSubscriptions.last.subscriptionPlan.externalPlanId) {
      String _ when profile.activeSubscriptions.last.subscriptionPlan.externalPlanId.contains('monthly') => 'monthly',
      String _ when profile.activeSubscriptions.last.subscriptionPlan.externalPlanId.contains('yearly') => 'yearly',
      _ => 'free',
    };
  }
}
