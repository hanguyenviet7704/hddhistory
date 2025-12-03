part of '../../monetization.dart';

/// Reusable plan option tile used across paywall highlight and bottom sheet.
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
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: selected ? AppCustomColor.backgroundWhite : AppCustomColor.backgroundGray,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: selected ? AppCustomColor.brandPrimary : AppCustomColor.borderDefault,
                width: 2,
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppText(
                            product.title.toUpperCase(),
                            style: AppStyle.textBold12.copyWith(
                              color: AppCustomColor.textSecondary,
                            ),
                          ),
                          if (product.hasDiscount) ...[
                            8.horizontalSpace,
                            _DiscountPill(label: '-${product.salePercent}%'),
                          ],
                        ],
                      ),
                      if (product.bestDeal) ...[
                        8.verticalSpace,
                        Row(
                          children: [
                            AppText(
                              product.pricePerPeriodString,
                              style: AppStyle.text14.copyWith(fontWeight: FontWeight.w600, color: AppCustomColor.textSecondary),
                            ),
                            4.horizontalSpace,
                            AppText(
                              '/${product.periodLabel}',
                              style: AppStyle.text10.copyWith(fontWeight: FontWeight.w500, color: AppCustomColor.textTertiary),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppText(
                      product.price,
                      style: AppStyle.text16.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textSecondary),
                    ),
                    if (product.hasDiscount) ...[
                      4.verticalSpace,
                      AppText(
                        product.originalPriceString,
                        style: AppStyle.text14.copyWith(
                          color: AppCustomColor.textTertiary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        if (product.bestDeal)
          Positioned(
            right: 14.w,
            top: -8.h,
            child: _BestDealBadge(label: t.monetization.mostPopularBadge.toUpperCase()),
          ),
      ],
    );
  }
}

class _DiscountPill extends StatelessWidget {
  final String label;

  const _DiscountPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppCustomColor.brandPrimary100,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: AppText(
        label,
        style: AppStyle.textBold10.copyWith(color: AppCustomColor.brandPrimary900),
      ),
    );
  }
}

class _BestDealBadge extends StatelessWidget {
  final String label;

  const _BestDealBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppCustomColor.paywallBestDeal,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: AppText(
        label,
        style: AppStyle.text10.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textPrimary),
      ),
    );
  }
}
