part of '../../monetization.dart';

class PaywallPageDecoration extends StatelessWidget {
  final List<BaseMultiLanguage> bannerDecorations;
  final List<FeedbackContent> feedbackContents;

  const PaywallPageDecoration({super.key, required this.bannerDecorations, required this.feedbackContents});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppCustomColor.backgroundBrand,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PaywallTopBar(
              onClose: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
            16.verticalSpace,
            _buildHeroTitle(),
            12.verticalSpace,
            _buildSubtitle(),
            24.verticalSpace,
            PaywallBannerCarousel(banners: bannerDecorations),
            24.verticalSpace,
            PaywallFeedbackList(feedbacks: feedbackContents),
            28.verticalSpace,
            _buildRestorePurchase(),
          ],
        ),
      ),
    );
  }

  
  Widget _buildHeroTitle() {
    return AppText(
      t.monetization.paywallHeroTitle,
      textAlign: TextAlign.center,
      maxLines: 2,
      style: AppStyle.text32.copyWith(
        fontWeight: FontWeight.w700,
        color: AppCustomColor.textBrand,
        height: 1.25,
      ),
    );
  }

  Widget _buildSubtitle() {
    return AppText(
      t.monetization.paywallHeroSubtitle,
      textAlign: TextAlign.center,
      style: AppStyle.text14.copyWith(
        color: AppCustomColor.textBrand.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildRestorePurchase() {
    return AppText(
      t.monetization.restore,
      textAlign: TextAlign.center,
      style: AppStyle.text14.copyWith(
        color: AppCustomColor.textBrand.withValues(alpha: 0.4),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
