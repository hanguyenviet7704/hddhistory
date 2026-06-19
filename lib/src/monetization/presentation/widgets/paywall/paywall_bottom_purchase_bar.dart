part of '../../../monetization.dart';

class PaywallBottomPurchaseBar extends StatelessWidget {
  final IapState state;
  final VoidCallback onPurchase;
  final VoidCallback onRetry;

  const PaywallBottomPurchaseBar({
    super.key,
    required this.state,
    required this.onPurchase,
    required this.onRetry,
  });

  static double totalReservedHeight(BuildContext context) => 152.h + MediaQuery.paddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final hasProducts = state.iapProducts.isNotEmpty;
    final isBusy = state.status == MonetizationStatus.loading || state.status == MonetizationStatus.purchasing || state.status == MonetizationStatus.restoring;
    final isFailure = state.status == MonetizationStatus.failure && !hasProducts;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, bottomPadding + 12.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFC7C5FA),
            Color(0xFFA3ABFF),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CountdownStrip(strategy: state.resolvedPaywallStrategy),
          if (state.resolvedPaywallStrategy?.hasSaleCountdown == true) 8.verticalSpace,
          AppText(
            hasProducts ? l10n.monetization.paywallHighlightSubtitle : l10n.monetization.emptyProductsDesc,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppStyle.text12.copyWith(
              fontWeight: FontWeight.w600,
              color: AppCustomColor.textBrand.withValues(alpha: 0.62),
              height: 1.55,
            ),
          ),
          10.verticalSpace,
          _PurchaseButton(
            label: isFailure ? l10n.monetization.retry : l10n.monetization.paywallPrimaryCta,
            busy: state.status == MonetizationStatus.purchasing || state.status == MonetizationStatus.restoring,
            enabled: !isBusy && (hasProducts || isFailure),
            onTap: isFailure ? onRetry : onPurchase,
          ),
        ],
      ),
    );
  }
}
