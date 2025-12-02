part of '../../monetization.dart';

class PaywallPageDecoration extends StatelessWidget {
  const PaywallPageDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          36.verticalSpace,
          PaywallTopBar(
            onClose: () => context.back(),
          ),
          16.verticalSpace,
          AppText(
            t.monetization.paywallHeroTitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppStyle.text32.copyWith(
              fontWeight: FontWeight.w700,
              color: AppCustomColor.textBrand,
              height: 1.25,
            ),
          ),
          12.verticalSpace,
          AppText(
            t.monetization.paywallHeroSubtitle,
            textAlign: TextAlign.center,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.textBrand.withValues(alpha: 0.4),
            ),
          ),
          24.verticalSpace,
          PaywallBannerCarousel(),
          24.verticalSpace,
          PaywallFeedbackList(),
          28.verticalSpace,
          GestureDetector(
            onTap: () => context.read<IapCubit>().restorePurchases(),
            child: AppText(
              t.monetization.restore,
              textAlign: TextAlign.center,
              style: AppStyle.text14.copyWith(
                color: AppCustomColor.textBrand.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          24.verticalSpace,
        ],
      ),
    );
  }
}
