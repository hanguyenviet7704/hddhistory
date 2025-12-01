part of '../../../monetization.dart';

@lazySingleton
final class PaywallCubit extends HydratedCubit<PaywallState> with CubitUseCaseHandlerMixin<PaywallState> {
  PaywallCubit() : super(PaywallState.initial());

  @override
  PaywallState fromJson(Map<String, dynamic> json) => PaywallState.fromJson(json);

  @override
  Map<String, dynamic> toJson(PaywallState state) => state.toJson();

  void reset() => emit(PaywallState.initial());
  void resetPremiumData() {
    List<String> userPremiumIds = state.userPremiumIds;
    emit(PaywallState.initial());
    emit(state.copyWith(userPremiumIds: userPremiumIds));
  }

  void setPaywallSource(String source) => emit(state.copyWith(paywallSource: source));
  void decrementRemainingEnergy() {
    if (state.remainingEnergy == 0) return;
    emit(state.copyWith(remainingEnergy: state.remainingEnergy - 1));
  }


  void setHasShownFeedbackForUser(String userId, {bool shown = true}) {
    if (userId.isEmpty) return;
    if (shown) {
      if (state.hasShownPaywallFeedbackUserIds.contains(userId)) return;
      emit(state.copyWith(hasShownPaywallFeedbackUserIds: [...state.hasShownPaywallFeedbackUserIds, userId]));
    } else {
      if (state.hasShownPaywallFeedbackUserIds.contains(userId)) {
        emit(state.copyWith(hasShownPaywallFeedbackUserIds: state.hasShownPaywallFeedbackUserIds.where((id) => id != userId).toList()));
      }
    }
    emit(state);
  }

  bool hasShownFeedbackForUser(String userId) => userId.isNotEmpty && (state.hasShownPaywallFeedbackUserIds.contains(userId));

  void incrementRemainingEnergy() => emit(state.copyWith(remainingEnergy: state.remainingEnergy + 1));
  void bonusEnergyRegisterSuccess() => emit(state.copyWith(remainingEnergy: state.remainingEnergy + 10));
  void setActiveSubscriptions(List<ActiveProduct> activeSubscriptions) => emit(state.copyWith(activeSubscriptions: activeSubscriptions));
  void fakeInfiniteEnergy() => emit(state.copyWith(remainingEnergy: 99999999999));

  void reactiveFakePremium(String userId) {
    if (!state.userPremiumIds.contains(userId)) return;
    fakeInfiniteEnergy();
  }

  void addUserPremiumId(String id) {
    if (!state.isThisDeviceFakePremium) return;
    if (state.userPremiumIds.contains(id)) return;
    emit(state.copyWith(userPremiumIds: [...state.userPremiumIds, id]));
  }

  Future<void> showFeedbackPaywallDialog() async {
    final userId = AppDI.injector.get<UserCubit>().state.auth.user.id;
    if (hasShownFeedbackForUser(userId)) {
      return;
    }
    if (userId.isNotEmpty) setHasShownFeedbackForUser(userId);
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> showFeedbackDialog() async {
    if (AppService.instance.firebaseRemoteConfigService.appFunctionModel.showFeedback == false) return;
    if (state.hasShowFeedback) return;
    emit(state.copyWith(hasShowFeedback: true));
  }
}
