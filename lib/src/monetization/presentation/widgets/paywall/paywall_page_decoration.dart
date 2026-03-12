part of '../../../monetization.dart';

class PaywallPageDecoration extends StatefulWidget {
  final Future<void> Function() onClose;

  const PaywallPageDecoration({
    super.key,
    required this.onClose,
  });

  @override
  State<PaywallPageDecoration> createState() => _PaywallPageDecorationState();
}

class _PaywallPageDecorationState extends State<PaywallPageDecoration> {
  final ScrollController _scrollController = ScrollController();
  bool _hasTrackedScroll = false;
  bool _hasTrackedInfoSwipe = false;

  List<_PaywallBenefitItem> get _benefits => [
    _PaywallBenefitItem(
      asset: AppAsset.images.app.openBook,
      title: t.monetization.benefit1Title,
      description: t.monetization.benefit1Desc,
    ),
    _PaywallBenefitItem(
      asset: AppAsset.images.app.statistic,
      title: t.monetization.benefit2Title,
      description: t.monetization.benefit2Desc,
    ),
    _PaywallBenefitItem(
      asset: AppAsset.images.app.chart,
      title: t.monetization.benefit3Title,
      description: t.monetization.benefit3Desc,
    ),
  ];

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

  void _handleInfoSwipe() {
    if (_hasTrackedInfoSwipe) return;
    AppService.instance.appTrackingService.trackPremiumInforSwipe();
    _hasTrackedInfoSwipe = true;
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
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PaywallTopBar(onClose: () => unawaited(widget.onClose())),
            36.verticalSpace,
            AppText(
              t.monetization.paywallHeroEyebrow,
              textAlign: TextAlign.center,
              style: AppStyle.textBold24.copyWith(
                color: AppCustomColor.textBrand.withValues(alpha: 0.4),
                height: 1.5,
              ),
            ),
            4.verticalSpace,
            AppText(
              t.monetization.paywallHeroTitle,
              textAlign: TextAlign.center,
              maxLines: 3,
              style: AppStyle.textBold32.copyWith(
                color: AppCustomColor.textBrand,
                height: 1.25,
              ),
            ),
            20.verticalSpace,
            AppText(
              t.monetization.paywallHeroSubtitle,
              textAlign: TextAlign.center,
              style: AppStyle.textBold14.copyWith(
                color: AppCustomColor.textBrand.withValues(alpha: 0.4),
                height: 1.75,
              ),
            ),
            16.verticalSpace,
            ..._benefits.map(
              (benefit) => Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: _PaywallBenefitRow(item: benefit),
              ),
            ),
            36.verticalSpace,
            PaywallFeedbackList(onFirstScroll: _handleInfoSwipe),
            36.verticalSpace,
            GestureDetector(
              onTap: _handleRestore,
              child: AppText(
                t.monetization.restore,
                textAlign: TextAlign.center,
                style: AppStyle.text14.copyWith(
                  color: AppCustomColor.textBrand.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w500,
                  height: 1.75,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaywallBenefitItem {
  final AssetGenImage asset;
  final String title;
  final String description;

  const _PaywallBenefitItem({
    required this.asset,
    required this.title,
    required this.description,
  });
}

class _PaywallBenefitRow extends StatelessWidget {
  final _PaywallBenefitItem item;

  const _PaywallBenefitRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          item.asset.path,
          width: 32.w,
          height: 32.w,
          fit: BoxFit.contain,
        ),
        12.horizontalSpace,
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: item.title,
                  style: AppStyle.textBold14.copyWith(
                    color: AppCustomColor.textBrand,
                    height: 1.75,
                  ),
                ),
                TextSpan(
                  text: ' ${item.description}',
                  style: AppStyle.text14.copyWith(
                    color: AppCustomColor.textBrand,
                    height: 1.75,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
