part of '../../../monetization.dart';

/// Legacy wrapper retained for older call sites while the paywall now renders
/// the purchase surface through [PaywallBottomPurchaseBar].
class PaywallHighlightPackageInfo extends StatelessWidget {
  const PaywallHighlightPackageInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IapCubit, IapState>(
      builder: (context, state) {
        return PaywallBottomPurchaseBar(
          state: state,
          onPurchase: () {
            final product = state.selectedProduct;
            AppService.instance.appTrackingService.trackPremiumPurchase(
              productId: product.productId,
              price: product.price,
            );
            context.read<IapCubit>().purchaseProduct();
          },
          onRetry: () => context.read<IapCubit>().loadIapProducts(forceRetry: true),
        );
      },
    );
  }
}
