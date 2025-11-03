part of '../../blocs.dart';

@freezed
abstract class PaywallState with _$PaywallState {
  const factory PaywallState({
    @Default(false) bool isLoading,
    @Default(10) int remainingEnergy,
    @Default([]) List<ActiveProduct> activeSubscriptions,
    @Default([]) List<String> userPremiumIds,
    @Default('') String paywallSource,
    @Default([]) List<String> hasShownPaywallFeedbackUserIds,
    @Default(false) bool hasShowFeedback,
  }) = _PaywallState;

  factory PaywallState.initial() =>  PaywallState(remainingEnergy: (F.appFlavor == Flavor.dev || kDebugMode) ? 3636 : 10);

  factory PaywallState.fromJson(Map<String, dynamic> json) => _$PaywallStateFromJson(json);
}

extension PaywallStateExtension on PaywallState {
  String get remainingEnergyString => remainingEnergy > 100000 ? '∞' : '$remainingEnergy';

  bool get isThisDeviceFakePremium => remainingEnergy > 100000;

  bool get isPremiumUser => remainingEnergy > 100000 || activeSubscriptions.isNotEmpty;

  bool hasShownFeedbackForUser(String userId) => hasShownPaywallFeedbackUserIds.contains(userId);
}
