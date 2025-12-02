part of '../../../monetization.dart';

class PaywallCubit extends Cubit<PaywallState> {
  PaywallCubit() : super(PaywallState.initial());

  void showAllPlans() {
    emit(state.copyWith(isShowAllPlans: true));
  }

  void showPurchaseSuccess() {
    emit(state.copyWith(isShowPurchaseSuccess: true));
  }
}
