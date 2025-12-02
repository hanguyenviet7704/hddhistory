part of '../../monetization.dart';

class PaywallPlanCard extends StatelessWidget {
  const PaywallPlanCard({
    super.key,
    required this.product,
    required this.isSelected,
    required this.onTap,
    this.isMostPopular = false,
    this.isCompact = false,
  });

  final IapProductEntity product;
  final bool isSelected;
  final bool isMostPopular;
  final bool isCompact;
  final VoidCallback onTap;

  String _periodLabel(BuildContext context) {
    final type = product.durationType.toLowerCase();
    final value = product.durationValue;

    if (type.contains('week')) return context.text.monetization.pricePerWeek;
    if (type.contains('day')) return context.text.monetization.pricePerDay;
    if (type.contains('month')) return context.text.monetization.pricePerMonth;
    if (type.contains('year')) return context.text.monetization.pricePerMonth; // fallback

    // Fallback when durationType is empty: infer from id
    if (product.id.contains('week')) return context.text.monetization.pricePerWeek;
    if (product.id.contains('day')) return context.text.monetization.pricePerDay;
    if (product.id.contains('month')) return context.text.monetization.pricePerMonth;

    if (value > 0 && type.isNotEmpty) {
      return '$value $type';
    }

    return context.text.monetization.pricePerMonth;
  }

  bool get _hasSale => product.id.contains('monthly') || product.id.contains('month');

  int get _salePercent => 50; // mirrors saleScale = 2 in model extension

  String get _originalPriceString {
    final priceValue = (product.rawPrice * 2).toStringAsFixed(2);
    if (product.currencySymbol.isNotEmpty) return '${product.currencySymbol}$priceValue';
    if (product.currencyCode.isNotEmpty) return '$priceValue ${product.currencyCode}';
    return priceValue;
  }

  Color get _cardColor => isSelected ? AppCustomColor.brandPrimary50 : AppColorLight.surface;

  @override
  Widget build(BuildContext context) {
    final periodLabel = _periodLabel(context);
    final title = product.planName.isNotEmpty ? product.planName : product.title;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isCompact ? 14.w : 16.w),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: isSelected ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary),
          boxShadow: [
            BoxShadow(
              color: AppCustomColor.black0D.op(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        title,
                        style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
                        maxLines: 1,
                      ),
                      4.verticalSpace,
                      AppText(
                        periodLabel,
                        style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                if (isMostPopular)
                  _PaywallBadge(
                    label: context.text.monetization.mostPopularBadge,
                    background: AppCustomColor.brandPrimary,
                    foreground: AppCustomColor.textWhite,
                  ),
                if (_hasSale)
                  Padding(
                    padding: EdgeInsets.only(left: isMostPopular ? 6.w : 0),
                    child: _PaywallBadge(
                      label: context.text.monetization.saleBadge(percent: _salePercent),
                      background: AppCustomColor.yellowFFF4,
                      foreground: AppCustomColor.orangeEC,
                    ),
                  ),
              ],
            ),
            12.verticalSpace,
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppText(
                  product.price,
                  style: AppStyle.textBold22.copyWith(color: AppCustomColor.textPrimary),
                  maxLines: 1,
                ),
                8.horizontalSpace,
                AppText(
                  periodLabel,
                  style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
                  maxLines: 1,
                ),
              ],
            ),
            if (_hasSale) ...[
              6.verticalSpace,
              Row(
                children: [
                  AppText(
                    _originalPriceString,
                    style: AppStyle.text12.copyWith(
                      color: AppCustomColor.textTertiary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  6.horizontalSpace,
                  AppText(
                    context.text.monetization.originalPrice,
                    style: AppStyle.text12.copyWith(color: AppCustomColor.textTertiary),
                  ),
                ],
              ),
            ],
            if (!isCompact && product.features.isNotEmpty) ...[
              12.verticalSpace,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: product.features
                    .map(
                      (feature) => Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppCustomColor.brandPrimary,
                              size: 16.sp,
                            ),
                            8.horizontalSpace,
                            Expanded(
                              child: AppText(
                                feature.featureKey,
                                style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary),
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaywallBadge extends StatelessWidget {
  const _PaywallBadge({required this.label, required this.background, required this.foreground});

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: AppText(
        label,
        style: AppStyle.text12.copyWith(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}
