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

  /// Sale strip geometry from the design: a 64-tall tab whose bottom 18 sits
  /// behind the white card, so only 46 of it is ever visible.
  static double get _stripHeight => 64.h;

  static double get _stripOverlap => 18.h;

  static double get _stripVisibleHeight => _stripHeight - _stripOverlap;

  static double totalReservedHeight(BuildContext context, IapState state) {
    final hasSaleCountdown = state.resolvedPaywallStrategy?.hasSaleCountdown == true;
    return 146.h + (hasSaleCountdown ? _stripVisibleHeight : 0) + MediaQuery.paddingOf(context).bottom;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final hasProducts = state.iapProducts.isNotEmpty;
    final isBusy = state.status == MonetizationStatus.loading || state.status == MonetizationStatus.purchasing || state.status == MonetizationStatus.restoring;
    final isFailure = state.status == MonetizationStatus.failure && !hasProducts;
    final selectedProduct = _selectedProduct;
    final hasSaleCountdown = state.resolvedPaywallStrategy?.hasSaleCountdown == true;

    final card = Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, bottomPadding + 12.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PurchaseButton(
            label: _ctaLabel(isFailure: isFailure, product: selectedProduct),
            busy: state.status == MonetizationStatus.purchasing || state.status == MonetizationStatus.restoring,
            enabled: !isBusy && (hasProducts || isFailure),
            onTap: isFailure ? onRetry : onPurchase,
          ),
          16.verticalSpace,
          _SubscriptionCaption(
            product: selectedProduct,
            fallback: hasProducts ? l10n.monetization.paywallHighlightSubtitle : l10n.monetization.emptyProductsDesc,
          ),
        ],
      ),
    );

    if (!hasSaleCountdown) return card;

    // The strip is laid out first but drawn under the card, which covers its
    // bottom corners — that is what makes it read as a tab behind the sheet.
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: _LimitedTimeOfferStrip(
            strategy: state.resolvedPaywallStrategy,
            height: _stripHeight,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: _stripVisibleHeight),
          child: card,
        ),
      ],
    );
  }

  /// The design puts the selected plan's total on the CTA itself
  /// ("Upgrade to Premium · 399.000đ"), falling back to the bare label when no
  /// plan resolved and to "Retry" when the load failed.
  String _ctaLabel({required bool isFailure, required IapProductEntity? product}) {
    if (isFailure) return l10n.monetization.retry;
    final price = product?.price ?? '';
    if (price.isEmpty) return l10n.monetization.paywallCtaUpgrade;
    return l10n.monetization.paywallCtaUpgradePrice(price: price);
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
  final double height;

  const _LimitedTimeOfferStrip({required this.strategy, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          transform: GradientRotation(100 * math.pi / 180),
          colors: [
            AppCustomColor.paywallSaleStripStart,
            AppCustomColor.paywallSaleStripEnd,
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      // Only the top 46 shows; the rest is behind the card, so the row is
      // pinned to the top instead of centred in the full height.
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt,
                    size: 18.w,
                    color: AppCustomColor.backgroundWhite,
                  ),
                  6.horizontalSpace,
                  Flexible(
                    child: AppText(
                      l10n.monetization.saleCountdownLabel.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      enableFitScaleDown: true,
                      style: AppStyle.text14.copyWith(
                        color: AppCustomColor.backgroundWhite,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
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
            style: _baseStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: AppCustomColor.paywallCtaCaptionStrong,
            ),
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
      fontSize: 13.sp,
      fontWeight: FontWeight.w500,
      color: AppCustomColor.paywallCtaCaption,
      height: 1.5,
    );
  }

  String _periodUnit(IapProductEntity product) {
    final label = product.periodLabel.trim();
    if (label.toLowerCase().startsWith('per ')) return label.substring(4);
    return label;
  }
}
