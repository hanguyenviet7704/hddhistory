part of '../../../monetization.dart';

@lazySingleton
class PaywallCubit extends Cubit<PaywallState> {
  PaywallCubit() : super(PaywallState.initial());

  void showAllPlans() {
    emit(state.copyWith(isShowAllPlans: true));
  }

  void showPurchaseSuccess() {
    emit(state.copyWith(isShowPurchaseSuccess: true));
  }

  void hideAllPlans() {
    emit(state.copyWith(isShowAllPlans: false));
  }

  void hidePurchaseSuccess() {
    emit(state.copyWith(isShowPurchaseSuccess: false));
  }
}
