part of '../../monetization.dart';

class PaywallHighlightPackageInfo extends StatelessWidget {
  const PaywallHighlightPackageInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
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
    final benefits = [
      t.monetization.benefit1Title,
      t.monetization.benefit2Title,
      t.monetization.benefit3Title,
    ];

    return Container(
      decoration: _cardDecoration,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _Badge(
                label: t.monetization.mostPopularBadge,
                background: AppCustomColor.brandPrimary,
                textColor: AppCustomColor.textWhite,
              ),
              if (product.hasDiscount) ...[
                8.horizontalSpace,
                _Badge(
                  label: t.monetization.saleBadge(percent: product.salePercent),
                  background: AppCustomColor.brandPrimary50,
                  textColor: AppCustomColor.brandPrimary,
                  borderColor: AppCustomColor.brandPrimary,
                ),
              ],
            ],
          ),
          12.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(
                product.price,
                style: AppStyle.text24.copyWith(fontWeight: FontWeight.w800, color: AppCustomColor.textPrimary),
              ),
              8.horizontalSpace,
              AppText(
                _periodLabel(product),
                style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
              ),
              const Spacer(),
              if (product.hasDiscount)
                AppText(
                  product.originalPriceString,
                  style: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary, decoration: TextDecoration.lineThrough),
                ),
            ],
          ),
          12.verticalSpace,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: benefits
                .map(
                  (benefit) => Padding(
                    padding: EdgeInsets.only(bottom: benefit == benefits.last ? 0 : 8.h),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: AppCustomColor.successGreen, size: 18.w),
                        8.horizontalSpace,
                        Expanded(
                          child: AppText(
                            benefit,
                            maxLines: 2,
                            style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          14.verticalSpace,
          AppButton.primary(
            onPressed: onPurchase,
            fullWidthBtn: true,
            child: t.monetization.payNowCta,
          ),
          10.verticalSpace,
          Center(
            child: GestureDetector(
              onTap: onSeeAllPlans,
              child: AppText(
                t.monetization.seeAllPlans,
                style: AppStyle.text14.copyWith(
                  color: AppCustomColor.brandPrimary,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _periodLabel(IapProductEntity product) {
    final id = product.id.toLowerCase();

    if (id.contains('week')) return t.monetization.pricePerWeek;
    if (id.contains('day')) return t.monetization.pricePerDay;

    return t.monetization.pricePerMonth;
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
