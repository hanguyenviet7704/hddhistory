part of '../../../monetization.dart';

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

          return _HighlightCard(
            product: state.bestDealProduct,
            onPurchase: () => cubit.purchaseProduct(isHighlight: true),
            onSeeAllPlans: () => PaywallAllPackageInfoBottomSheet.show(context),
          );
        },
      ),
    );
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
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PaywallPlanOption(
          product: product,
          selected: true,
        ),
        24.verticalSpace,
        Container(
          width: double.infinity,
          height: 48.h,
          decoration: BoxDecoration(
            color: const Color(0xFF554FF0),
            borderRadius: BorderRadius.circular(1000.r),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPurchase,
              borderRadius: BorderRadius.circular(1000.r),
              child: Center(
                child: AppText(
                  t.monetization.payNowCta,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: AppStyle.text16.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        16.verticalSpace,
        GestureDetector(
          onTap: onSeeAllPlans,
          child: AppText(
            t.monetization.seeAllPlans,
            textAlign: TextAlign.center,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.brandPrimary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        12.verticalSpace,
        const _PaywallLegalLinks(),
        SizedBox(height: bottomPadding / 2 + 8.h),
      ],
    );
  }
}

class _PaywallLegalLinks extends StatelessWidget {
  const _PaywallLegalLinks();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _LegalLink(label: t.auth.termsOfUse, url: LegalUrl.termsAndConditions),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12.w),
            height: 12.h,
            width: 1.w,
            color: AppCustomColor.textQuaternary,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _LegalLink(label: t.auth.privacyPolicy, url: LegalUrl.privacyPolicy),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final String url;

  const _LegalLink({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => url.launchURL(),
      child: AppText(
        label,
        style: AppStyle.text12.copyWith(
          fontWeight: FontWeight.w600,
          color: AppCustomColor.textQuaternary,
          height: 1.75,
        ),
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
