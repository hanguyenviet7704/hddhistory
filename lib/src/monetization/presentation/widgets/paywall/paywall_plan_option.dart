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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _RadioIndicator(selected: selected),
                12.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppText(
                              _displayTitle.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppStyle.text12.copyWith(
                                color: AppCustomColor.textSecondary,
                                fontWeight: FontWeight.w700,
                                height: 1.75,
                              ),
                            ),
                          ),
                          if (product.hasDiscount) ...[
                            8.horizontalSpace,
                            _DiscountPill(label: '-${product.salePercent.toInt()}%'),
                          ],
                        ],
                      ),
                      8.verticalSpace,
                      Row(
                        children: [
                          Flexible(
                            child: AppText(
                              _displayPeriodPrice,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppStyle.text20.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppCustomColor.textPrimary,
                                height: 1.25,
                              ),
                            ),
                          ),
                          4.horizontalSpace,
                          if (product.periodLabel.isNotEmpty)
                            AppText(
                              '/${product.periodLabel}',
                              maxLines: 1,
                              style: AppStyle.text10.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppCustomColor.textTertiary,
                                height: 1.75,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                12.horizontalSpace,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppText(
                      _displayPrice,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyle.text14.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppCustomColor.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    if (product.hasDiscount) ...[
                      4.verticalSpace,
                      AppText(
                        product.originalPriceString,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyle.text12.copyWith(
                          color: AppCustomColor.textTertiary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.lineThrough,
                          height: 1.75,
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
            child: _BestDealBadge(label: l10n.monetization.mostPopularBadge.toUpperCase()),
          ),
      ],
    );
  }

  String get _displayTitle => product.title.isEmpty ? product.productId : product.title;

  String get _displayPrice => product.price.isEmpty ? product.pricePerPeriodString : product.price;

  String get _displayPeriodPrice => product.pricePerPeriodString.isEmpty ? _displayPrice : product.pricePerPeriodString;
}
