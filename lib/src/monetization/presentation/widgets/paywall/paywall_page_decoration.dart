part of '../../../monetization.dart';

class PaywallPageDecoration extends StatefulWidget {
  final IapState state;
  final double bottomPadding;
  final Future<void> Function() onClose;
  final bool showCloseButton;

  const PaywallPageDecoration({
    super.key,
    required this.state,
    required this.bottomPadding,
    required this.onClose,
    required this.showCloseButton,
  });

  @override
  State<PaywallPageDecoration> createState() => _PaywallPageDecorationState();
}

class _PaywallPageDecorationState extends State<PaywallPageDecoration> {
  final ScrollController _scrollController = ScrollController();
  bool _hasTrackedScroll = false;
  bool _hasTrackedInfoSwipe = false;

  /// Feature icons from the paywall design, cycled when the remote config
  /// does not supply one.
  List<String> get _fallbackBenefitAssets => [
    AppAsset.svg.app.pwLessons,
    AppAsset.svg.app.pwPractice,
    AppAsset.svg.app.pwHabit,
    AppAsset.svg.app.pwProgress,
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
    // premium_scroll tracking removed (not in the paywall spec).
    _hasTrackedScroll = true;
  }

  void _handleInfoSwipe() {
    if (_hasTrackedInfoSwipe) return;
    // premium_infor_swipe tracking removed (not in the paywall spec).
    _hasTrackedInfoSwipe = true;
  }

  void _handleRestore() {
    AppHaptic.select();
    AppService.instance.appTrackingService.trackPremiumRestoreClick();
    context.read<IapCubit>().restorePurchases();
  }

  bool get _isRestoring => widget.state.status == MonetizationStatus.restoring;

  void _handlePlanTap(IapProductEntity product) {
    if (product.id == widget.state.selectedProductId) return;
    AppService.instance.appTrackingService.trackPremiumAllpackPick(product.productId);
    context.read<IapCubit>().setSelectedProductId(product.id);
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.state.paywallContent;
    final heading = _fallbackText(content.heading.text, l10n.monetization.paywallHeroTitle);
    final subheading = _fallbackText(content.subheading.text, l10n.monetization.paywallHeroSubtitle);
    final benefits = content.benefits.where((benefit) => benefit.title.text.isNotEmpty).toList();

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, widget.bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PaywallTopBar(
            showCloseButton: widget.showCloseButton,
            onClose: () => unawaited(widget.onClose()),
          ),
          30.verticalSpace,
          AppText(
            subheading,
            textAlign: TextAlign.center,
            maxLines: 3,
            style: AppStyle.textBold16.copyWith(
              color: AppCustomColor.textBrand.withValues(alpha: 0.45),
              height: 1.7,
            ),
          ),
          6.verticalSpace,
          AppText(
            heading,
            textAlign: TextAlign.center,
            maxLines: 4,
            style: AppStyle.textBold24.copyWith(
              color: AppCustomColor.textBrand,
              height: 1.18,
            ),
          ),
          22.verticalSpace,
          _PaywallInlinePlans(
            state: widget.state,
            onPlanTap: _handlePlanTap,
          ),
          PaywallPromoCode(
            appliedCode: widget.state.hasAppliedVoucher ? widget.state.appliedVoucherCode : null,
            isApplying: widget.state.isValidatingVoucher,
            message: _voucherMessage,
            isMessageError: !widget.state.hasAppliedVoucher,
            onApply: (code) => context.read<IapCubit>().applyVoucher(code),
            onRemove: () => context.read<IapCubit>().removeVoucher(),
          ),
          25.verticalSpace,
          AppText(
            l10n.monetization.paywallHeroSubtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.textBrand.withValues(alpha: 0.4),
              fontWeight: FontWeight.w600,
              height: 1.75,
            ),
          ),
          12.verticalSpace,
          if (benefits.isEmpty)
            ..._defaultBenefits()
          else
            for (var index = 0; index < benefits.length; index++)
              Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : 12.h),
                child: _PaywallRemoteBenefitRow(
                  benefit: benefits[index],
                  fallbackAsset: _fallbackBenefitAssets[index % _fallbackBenefitAssets.length],
                ),
              ),
          36.verticalSpace,
          PaywallFeedbackList(onFirstScroll: _handleInfoSwipe),
          30.verticalSpace,
          GestureDetector(
            onTap: _isRestoring ? null : _handleRestore,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isRestoring) ...[
                  SizedBox(
                    width: 14.w,
                    height: 14.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppCustomColor.textBrand.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  8.horizontalSpace,
                ],
                AppText(
                  l10n.monetization.restore,
                  textAlign: TextAlign.center,
                  style: AppStyle.text14.copyWith(
                    color: AppCustomColor.textBrand.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w500,
                    height: 1.75,
                  ),
                ),
              ],
            ),
          ),
          14.verticalSpace,
          const PaywallLegalLinks(),
          50.verticalSpace,
        ],
      ),
    );
  }

  String _fallbackText(String value, String fallback) => value.isEmpty ? fallback : value;

  /// Feedback under the promo field: the success line once a code is applied,
  /// otherwise the message for whichever reason the server gave.
  String? get _voucherMessage {
    if (!widget.state.hasVoucherFeedback) return null;
    if (widget.state.hasAppliedVoucher) return l10n.monetization.promoCodeApplied;
    return switch (widget.state.voucherRejectReason) {
      VoucherRejectReason.notFound => l10n.monetization.promoCodeErrorInvalid,
      VoucherRejectReason.expired => l10n.monetization.promoCodeErrorExpired,
      VoucherRejectReason.exhausted => l10n.monetization.promoCodeErrorExhausted,
      VoucherRejectReason.notApplicable => l10n.monetization.promoCodeErrorNotApplicable,
      VoucherRejectReason.unknown => l10n.monetization.promoCodeErrorGeneric,
    };
  }

  List<Widget> _defaultBenefits() {
    final fallback = [
      (AppAsset.svg.app.pwLessons, l10n.monetization.benefit1Title, l10n.monetization.benefit1Desc),
      (AppAsset.svg.app.pwPractice, l10n.monetization.benefit2Title, l10n.monetization.benefit2Desc),
      (AppAsset.svg.app.pwProgress, l10n.monetization.benefit3Title, l10n.monetization.benefit3Desc),
    ];
    return [
      for (var index = 0; index < fallback.length; index++)
        Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 12.h),
          child: _PaywallLocalBenefitRow(
            asset: fallback[index].$1,
            title: fallback[index].$2,
            description: fallback[index].$3,
          ),
        ),
    ];
  }
}
