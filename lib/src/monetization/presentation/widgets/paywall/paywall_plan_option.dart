part of '../../../monetization.dart';

/// Reusable inline plan option tile for the paywall.
class PaywallPlanOption extends StatelessWidget {
  final IapProductEntity product;
  final bool selected;
  final VoidCallback? onTap;

  const PaywallPlanOption({
    super.key,
    required this.product,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            constraints: BoxConstraints(minHeight: 84.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: selected ? AppCustomColor.backgroundWhite : const Color(0xFFF2F1FE),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: selected ? const Color(0xFF4B44CA) : AppCustomColor.borderDefault,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RadioIndicator(selected: selected),
                      8.horizontalSpace,
                      Flexible(
                        child: AppText(
                          _planTitle.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyle.text12.copyWith(
                            color: AppCustomColor.textSecondary,
                            fontWeight: FontWeight.w700,
                            height: 1.75,
                          ),
                        ),
                      ),
                      if (_showDiscountPill) ...[
                        8.horizontalSpace,
                        _DiscountPill(label: '-${product.salePercent.toInt()}%'),
                      ],
                    ],
                  ),
                ),
                12.horizontalSpace,
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppText(
                      _displayPrice,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyle.text20.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected ? AppCustomColor.textPrimary : AppCustomColor.textTertiary,
                        height: 1.5,
                      ),
                    ),
                    4.verticalSpace,
                    if (_showOriginalPrice)
                      AppText(
                        product.originalPriceString,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyle.text12.copyWith(
                          color: const Color(0xFF95A7C2),
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.lineThrough,
                          height: 1.75,
                        ),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText(
                            _displayPeriodPrice,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyle.text12.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppCustomColor.textSecondary,
                              height: 1.75,
                            ),
                          ),
                          if (product.periodLabel.isNotEmpty) ...[
                            4.horizontalSpace,
                            AppText(
                              '/${_periodUnit(product)}',
                              maxLines: 1,
                              style: AppStyle.text12.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppCustomColor.textTertiary,
                                height: 1.75,
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (product.bestDeal)
          Positioned(
            right: 16.w,
            top: -6.h,
            child: _BestDealBadge(label: l10n.monetization.mostPopularBadge.toUpperCase()),
          ),
      ],
    );
  }

  String get _displayTitle => product.title.isEmpty ? product.productId : product.title;

  String get _planTitle {
    final idLower = product.productId.toLowerCase();
    if (idLower.contains('year') || idLower.contains('annual') || idLower.contains('1y')) return l10n.monetization.paywallPlanAnnual;
    if (idLower.contains('quarter') || idLower.contains('3m')) return l10n.monetization.paywallPlanQuarterly;
    if (idLower.contains('month')) return l10n.monetization.paywallPlanMonthly;
    if (idLower.contains('week')) return l10n.monetization.paywallPlanWeekly;
    if (idLower.contains('life')) return l10n.monetization.paywallPlanLifetime;
    return _displayTitle;
  }

  String get _displayPrice => product.price.isEmpty ? product.pricePerPeriodString : product.price;

  String get _displayPeriodPrice => product.pricePerPeriodString.isEmpty ? _displayPrice : product.pricePerPeriodString;

  bool get _showDiscountPill => !selected && product.hasDiscount;

  bool get _showOriginalPrice => !selected && product.hasDiscount && product.originalPriceString.isNotEmpty;

  String _periodUnit(IapProductEntity product) {
    final label = product.periodLabel.trim();
    if (label.toLowerCase().startsWith('per ')) return label.substring(4);
    return label;
  }
}
