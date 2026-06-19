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

  static double totalReservedHeight(BuildContext context, IapState state) {
    final hasSaleCountdown = state.resolvedPaywallStrategy?.hasSaleCountdown == true;
    return (hasSaleCountdown ? 186.h : 138.h) + MediaQuery.paddingOf(context).bottom;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final hasProducts = state.iapProducts.isNotEmpty;
    final isBusy = state.status == MonetizationStatus.loading || state.status == MonetizationStatus.purchasing || state.status == MonetizationStatus.restoring;
    final isFailure = state.status == MonetizationStatus.failure && !hasProducts;
    final selectedProduct = _selectedProduct;
    final hasSaleCountdown = state.resolvedPaywallStrategy?.hasSaleCountdown == true;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          transform: GradientRotation(70.65 * math.pi / 180),
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
          if (hasSaleCountdown) _LimitedTimeOfferStrip(strategy: state.resolvedPaywallStrategy),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, bottomPadding + 12.h),
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PurchaseButton(
                  label: isFailure ? l10n.monetization.retry : l10n.monetization.paywallTitle,
                  busy: state.status == MonetizationStatus.purchasing || state.status == MonetizationStatus.restoring,
                  enabled: !isBusy && (hasProducts || isFailure),
                  onTap: isFailure ? onRetry : onPurchase,
                ),
                12.verticalSpace,
                _SubscriptionCaption(
                  product: selectedProduct,
                  fallback: hasProducts ? l10n.monetization.paywallHighlightSubtitle : l10n.monetization.emptyProductsDesc,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IapProductEntity? get _selectedProduct {
    for (final product in state.iapProducts) {
      if (product.id == state.selectedProductId) return product;
    }
    return state.iapProducts.firstOrNull;
  }
}

class _LimitedTimeOfferStrip extends StatelessWidget {
  final ResolvedPaywallStrategyEntity? strategy;

  const _LimitedTimeOfferStrip({required this.strategy});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt,
                  size: 16.w,
                  color: AppCustomColor.textBrand,
                ),
                4.horizontalSpace,
                AppText(
                  l10n.monetization.saleCountdownLabel.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  enableFitScaleDown: true,
                  style: AppStyle.text14.copyWith(
                    color: AppCustomColor.textBrand,
                    fontWeight: FontWeight.w700,
                    height: 1.75,
                  ),
                ),
              ],
            ),
            12.horizontalSpace,
            _CountdownStrip(strategy: strategy, compact: true),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionCaption extends StatelessWidget {
  final IapProductEntity? product;
  final String fallback;

  const _SubscriptionCaption({
    required this.product,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final product = this.product;
    if (product == null) {
      return AppText(
        fallback,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: _baseStyle,
      );
    }
    final priceText = '${product.pricePerPeriodString} /${_periodUnit(product)}';
    final caption = l10n.monetization.paywallSubscriptionCaption(price: priceText);
    final captionParts = caption.split(priceText);
    if (captionParts.length != 2) {
      return AppText(
        caption,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: _baseStyle,
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: captionParts.first),
          TextSpan(
            text: priceText,
            style: _baseStyle.copyWith(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: captionParts.last),
        ],
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: _baseStyle,
    );
  }

  TextStyle get _baseStyle {
    return AppStyle.text14.copyWith(
      fontWeight: FontWeight.w600,
      color: AppCustomColor.textBrand.withValues(alpha: 0.5),
      height: 1.75,
    );
  }

  String _periodUnit(IapProductEntity product) {
    final label = product.periodLabel.trim();
    if (label.toLowerCase().startsWith('per ')) return label.substring(4);
    return label;
  }
}
