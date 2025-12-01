part of '../../monetization.dart';

class PaywallPackageCard extends StatelessWidget {
  final IapProductEntity product;
  final bool selected;
  final VoidCallback onTap;
  final bool showMostPopular;

  const PaywallPackageCard({
    super.key,
    required this.product,
    required this.selected,
    required this.onTap,
    this.showMostPopular = false,
  });

  bool get _isSale => product.id.contains('month');

  int get _salePercent => 50;

  String? get _originalPriceString {
    if (!_isSale || product.rawPrice <= 0 || product.price.isEmpty) return null;
    final originalPrice = product.rawPrice * 2;
    int currencySymbolIndex = product.price.indexOf(RegExp(r'[^0-9.,\s]'));
    if (currencySymbolIndex == -1) return null;
    if (currencySymbolIndex == 0) {
      return '${product.price.substring(0, currencySymbolIndex)}${originalPrice.currency}';
    }
    return '${originalPrice.currency}${product.price.substring(currencySymbolIndex)}';
  }

  String get displayTitle {
    if (product.planName.isNotEmpty) return product.planName.toUpperCase();
    if (product.title.isNotEmpty) return product.title.toUpperCase();
    return 'PREMIUM';
  }

  String get periodLabel {
    if (product.durationType.isNotEmpty && product.durationValue > 0) {
      return '${product.durationValue} ${product.durationType}';
    }
    if (product.id.contains('week')) return 'week';
    if (product.id.contains('month')) return 'month';
    if (product.id.contains('year')) return 'year';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240.w,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: selected ? AppCustomColor.backgroundBrand : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.op(0.04),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  AppText(
                    displayTitle,
                    style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary, letterSpacing: 0.5),
                    maxLines: 1,
                    enableFitScaleDown: true,
                  ),
                  if (showMostPopular)
                    Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppCustomColor.brandPrimary,
                          borderRadius: BorderRadius.circular(100.r),
                        ),
                        child: AppText(
                          context.text.monetization.mostPopularBadge,
                          style: AppStyle.text12.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            12.verticalSpace,
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppText(
                    product.price.isNotEmpty ? product.price : '--',
                    style: AppStyle.textBold24.copyWith(color: AppCustomColor.textPrimary),
                    maxLines: 1,
                  ),
                  if (periodLabel.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(left: 8.w, bottom: 2.h),
                      child: AppText(
                        periodLabel,
                        style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
                        maxLines: 1,
                      ),
                    ),
                  if (_isSale && _originalPriceString != null)
                    Padding(
                      padding: EdgeInsets.only(left: 8.w, bottom: 2.h),
                      child: AppText(
                        _originalPriceString!,
                        style: AppStyle.text14.copyWith(
                          color: AppCustomColor.textQuaternary,
                          decoration: TextDecoration.lineThrough,
                        ),
                        maxLines: 1,
                      ),
                    ),
                ],
              ),
            ),
            if (_isSale)
              Padding(
                padding: EdgeInsets.only(top: 6.h),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppCustomColor.backgroundError,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: AppText(
                    context.text.monetization.saleBadge(percent: _salePercent),
                    style: AppStyle.text12.copyWith(color: AppCustomColor.redEC, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            12.verticalSpace,
            if (product.features.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: product.features
                    .take(3)
                    .map(
                      (f) => Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 16.w, color: AppCustomColor.brandPrimary),
                            8.horizontalSpace,
                            Expanded(
                              child: AppText(
                                f.featureKey,
                                style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
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
        ),
      ),
    );
  }
}
