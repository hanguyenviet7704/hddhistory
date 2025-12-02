part of '../../monetization.dart';

class PaywallHighlightPackageInfo extends StatelessWidget {
  const PaywallHighlightPackageInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(top: BorderSide(color: AppCustomColor.borderDefault)),
      ),
      child: BlocBuilder<IapCubit, IapState>(
        builder: (context, state) {
          final cubit = context.read<IapCubit>();
          final isLoading = state.status == MonetizationStatus.loading && state.iapProducts.isEmpty;

          if (isLoading) {
            return _HighlightLoading();
          }

          if (state.iapProducts.isEmpty) {
            return _HighlightEmpty(onRetry: cubit.loadIapProducts);
          }

          final IapProductEntity selectedProduct = _getSelectedProduct(state);

          return _HighlightCard(
            product: selectedProduct,
            onPurchase: () => cubit.purchaseProduct(),
            onSeeAllPlans: () => PaywallAllPackageInfoBottomSheet.show(context),
          );
        },
      ),
    );
  }

  IapProductEntity _getSelectedProduct(IapState state) {
    if (state.iapProducts.isEmpty) return const IapProductEntity();

    final selected = state.iapProducts.where((item) => item.id == state.selectedProductId);
    if (selected.isNotEmpty) return selected.first;

    return state.iapProducts.first;
  }
}

class _HighlightLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: _cardDecoration,
      child: Row(
        children: [
          SizedBox(
            height: 48.w,
            width: 48.w,
            child: const CircularProgressIndicator(strokeWidth: 3),
          ),
          16.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _shimmerLine(width: 140.w),
                8.verticalSpace,
                _shimmerLine(width: 100.w),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerLine({required double width}) {
    return Container(
      width: width,
      height: 12.h,
      decoration: BoxDecoration(
        color: AppCustomColor.borderSecondary,
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }
}

class _HighlightEmpty extends StatelessWidget {
  final VoidCallback onRetry;

  const _HighlightEmpty({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: _cardDecoration,
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppCustomColor.textTertiary, size: 24.w),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  t.monetization.emptyProductsTitle,
                  style: AppStyle.text16.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textPrimary),
                ),
                4.verticalSpace,
                AppText(
                  t.monetization.emptyProductsDesc,
                  maxLines: 2,
                  style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
                ),
              ],
            ),
          ),
          AppButton.secondary(
            height: 42.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: t.monetization.retry,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final IapProductEntity product;
  final VoidCallback onPurchase;
  final VoidCallback onSeeAllPlans;

  const _HighlightCard({required this.product, required this.onPurchase, required this.onSeeAllPlans});

  @override
  Widget build(BuildContext context) {
    final perPeriodPrice = _pricePerPeriod(product);
    final periodLabel = _periodLabel(product);
    final planLabel = _planLabel(product);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppCustomColor.backgroundWhite,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppCustomColor.brandPrimary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppText(
                              planLabel,
                              style: AppStyle.text12.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppCustomColor.textSecondary,
                                letterSpacing: 0.2,
                              ),
                            ),
                            if (product.hasDiscount) ...[
                              8.horizontalSpace,
                              _Badge(
                                label: '-${product.salePercent}%',
                                background: AppCustomColor.brandPrimary100,
                                textColor: AppCustomColor.brandPrimary,
                              ),
                            ],
                          ],
                        ),
                        8.verticalSpace,
                        Row(
                          children: [
                            AppText(
                              perPeriodPrice,
                              style: AppStyle.text14.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppCustomColor.textSecondary,
                              ),
                            ),
                            4.horizontalSpace,
                            AppText(
                              '/$periodLabel',
                              style: AppStyle.text10.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppCustomColor.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        product.price,
                        style: AppStyle.text16.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppCustomColor.textSecondary,
                        ),
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
            if (product.hasDiscount)
              Positioned(
                top: -10.h,
                right: 14.w,
                child: _Badge(
                  label: t.monetization.mostPopularBadge.toUpperCase(),
                  background: AppCustomColor.paywallBestDeal,
                  textColor: AppCustomColor.textPrimary,
                  borderColor: AppCustomColor.paywallBestDeal,
                ),
              ),
          ],
        ),
        16.verticalSpace,
        AppButton.primary(
          onPressed: onPurchase,
          fullWidthBtn: true,
          child: AppText(
            t.monetization.payNowCta,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: AppStyle.text16.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textWhite),
          ),
        ),
        12.verticalSpace,
        GestureDetector(
          onTap: onSeeAllPlans,
          child: AppText(
            t.monetization.seeAllPlans,
            textAlign: TextAlign.center,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.brandPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _planLabel(IapProductEntity product) {
    final id = product.id.toLowerCase();

    if (id.contains('year') || id.contains('annual')) return 'ANNUAL';
    if (id.contains('month')) return 'MONTHLY';
    if (id.contains('week')) return 'WEEKLY';

    return t.monetization.premiumBadge.toUpperCase();
  }

  String _periodLabel(IapProductEntity product) {
    final id = product.id.toLowerCase();

    if (id.contains('week')) return t.monetization.pricePerWeek;
    if (id.contains('day')) return t.monetization.pricePerDay;

    return t.monetization.pricePerMonth;
  }

  String _pricePerPeriod(IapProductEntity product) {
    if (product.rawPrice <= 0) return product.price.isNotEmpty ? product.price : '--';

    final id = product.id.toLowerCase();
    double value = product.rawPrice;
    if (id.contains('year') || id.contains('annual')) {
      value = product.rawPrice / 12;
    }

    return product.currencySymbol.isNotEmpty ? '${product.currencySymbol}${value.currency}' : value.currency;
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;
  final Color? borderColor;

  const _Badge({required this.label, required this.background, required this.textColor, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12.r),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: AppText(
        label,
        style: AppStyle.text12.copyWith(fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }
}

final _cardDecoration = BoxDecoration(
  color: AppCustomColor.backgroundWhite,
  borderRadius: BorderRadius.circular(20.r),
  border: Border.all(color: AppCustomColor.borderSecondary),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ],
);
