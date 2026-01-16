part of '../../../monetization.dart';

class PaywallPageDecoration extends StatefulWidget {
  const PaywallPageDecoration({super.key});

  @override
  State<PaywallPageDecoration> createState() => _PaywallPageDecorationState();
}

class _PaywallPageDecorationState extends State<PaywallPageDecoration> {
  final ScrollController _scrollController = ScrollController();
  bool _hasTrackedScroll = false;
  bool _hasTrackedSwipe = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _hasTrackedScroll) return;
    if (_scrollController.position.pixels <= 0) return;
    AppService.instance.appTrackingService.trackPremiumScroll();
    _hasTrackedScroll = true;
  }

  void _handleCarouselChanged(int index) {
    if (_hasTrackedSwipe) return;
    AppService.instance.appTrackingService.trackPremiumInforSwipe();
    _hasTrackedSwipe = true;
  }

  void _handleClose() {
    AppService.instance.appTrackingService.trackPremiumScrExit();
    context.back();
  }

  void _handleRestore() {
    AppService.instance.appTrackingService.trackPremiumRestoreClick();
    context.read<IapCubit>().restorePurchases();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            36.verticalSpace,
            PaywallTopBar(
              onClose: _handleClose,
            ),
            16.verticalSpace,
            AppText(
              t.monetization.paywallHeroTitle,
              textAlign: TextAlign.center,
              maxLines: 3,
              style: AppStyle.textBold28.copyWith(
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
            PaywallBannerCarousel(onIndexChanged: _handleCarouselChanged),
            24.verticalSpace,
            PaywallFeedbackList(),
            28.verticalSpace,
            GestureDetector(
              onTap: _handleRestore,
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
      ),
    );
  }
}
