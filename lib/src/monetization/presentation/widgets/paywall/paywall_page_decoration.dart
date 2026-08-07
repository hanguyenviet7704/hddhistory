part of '../../../monetization.dart';

class PaywallPageDecoration extends StatefulWidget {
  final IapState state;
  final double bottomPadding;
  final Future<void> Function() onClose;
  final bool showCloseButton;
  final VoidCallback onPurchase;
  final VoidCallback onRetry;

  const PaywallPageDecoration({
    super.key,
    required this.state,
    required this.bottomPadding,
    required this.onClose,
    required this.showCloseButton,
    required this.onPurchase,
    required this.onRetry,
  });

  @override
  State<PaywallPageDecoration> createState() => _PaywallPageDecorationState();
}

class _PaywallPageDecorationState extends State<PaywallPageDecoration> {
  final ScrollController _scrollController = ScrollController();
  bool _hasTrackedScroll = false;
  bool _hasTrackedInfoSwipe = false;

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
          10.verticalSpace,
          // Floating hero illustration. Decorative only — excluded from semantics
          // so the reader lands straight on the heading.
          ExcludeSemantics(
            child: SvgPicture.asset(
              AppAsset.svg.app.pwHeaderGraphic,
              width: 260.w,
              fit: BoxFit.contain,
            ),
          ),
          18.verticalSpace,
          // Heading first, then the subheading beneath it. This used to be the
          // other way round, which put the smallest, faintest text at the top of
          // the screen and buried the promise under it.
          AppText(
            heading,
            textAlign: TextAlign.center,
            maxLines: 4,
            style: AppStyle.textBold24.copyWith(
              fontSize: 30.sp,
              color: AppCustomColor.textBrand,
              height: 1.18,
              letterSpacing: -0.7,
            ),
          ),
          6.verticalSpace,
          AppText(
            subheading,
            textAlign: TextAlign.center,
            maxLines: 3,
            style: AppStyle.text14.copyWith(
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8F8AB9),
              height: 1.4,
            ),
          ),
          30.verticalSpace,
          // Benefits sit ABOVE the plans: the reader has to know what they get
          // before a price means anything.
          if (benefits.isEmpty)
            ..._defaultBenefits()
          else
            for (var index = 0; index < benefits.length; index++)
              Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : 8.h),
                child: _PaywallBenefitRow(text: benefits[index].title.text),
              ),
          30.verticalSpace,
          // Full-width countdown, directly above the plans it discounts. The
          // compact copy inside the purchase bar stays — that one follows the
          // button, this one gives the offer its own line. Renders nothing when
          // no sale is running.
          _CountdownStrip(strategy: widget.state.resolvedPaywallStrategy),
          _PaywallInlinePlans(
            state: widget.state,
            onPlanTap: _handlePlanTap,
          ),
          PaywallPromoCode(state: widget.state),
          // The CTA lives IN the scroll flow, per the design — not in a sticky
          // bottom bar. The reader passes benefits and prices on the way to it,
          // and the trust strip follows right after as the closing argument.
          26.verticalSpace,
          _InlinePurchaseSection(
            state: widget.state,
            onPurchase: widget.onPurchase,
            onRetry: widget.onRetry,
          ),
          32.verticalSpace,
          // Config-gated: a claim about MIT and Harvard may not hold in every
          // market. Absent from the config parses to true (the behaviour of the
          // build that introduced the strip).
          if (context.read<IapCubit>().resolvedPaywallConfig.showCredibilityBlock) ...[
            const _PaywallCredibilityBlock(),
            30.verticalSpace,
          ],
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

  List<Widget> _defaultBenefits() {
    final fallback = [
      '${l10n.monetization.benefit1Title} ${l10n.monetization.benefit1Desc}',
      '${l10n.monetization.benefit2Title} ${l10n.monetization.benefit2Desc}',
      '${l10n.monetization.benefit3Title} ${l10n.monetization.benefit3Desc}',
    ];
    return [
      for (var index = 0; index < fallback.length; index++)
        Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 8.h),
          child: _PaywallBenefitRow(text: fallback[index]),
        ),
    ];
  }
}

/// The trust strip between the plans and the reviews: a laurel-framed claim
/// about where the method comes from, and the store rating.
///
/// Only ONE laurel asset ships. The right-hand branch is the same drawing
/// mirrored on X — the artwork is symmetric, so a second file would have been a
/// second copy of the same paths to download and cache.
class _PaywallCredibilityBlock extends StatelessWidget {
  const _PaywallCredibilityBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _laurel(),
            10.horizontalSpace,
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 220.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    l10n.monetization.paywallScienceTitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: AppStyle.text14.copyWith(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AppCustomColor.textBrand,
                      height: 1.35,
                    ),
                  ),
                  AppText(
                    l10n.monetization.paywallScienceSubtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: AppStyle.text14.copyWith(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6E67D8),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            10.horizontalSpace,
            // Mirrored, not a separate asset.
            Transform.flip(flipX: true, child: _laurel()),
          ],
        ),
        16.verticalSpace,
        // The stars are decoration for a rating the text already states, so
        // they are hidden from screen readers rather than read out five times.
        ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 5; i++)
                Icon(Icons.star_rounded, size: 20.w, color: const Color(0xFFF9C51A)),
            ],
          ),
        ),
        6.verticalSpace,
        AppText(
          l10n.monetization.paywallStoreRating,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: AppStyle.text14.copyWith(
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w800,
            color: AppCustomColor.textBrand,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _laurel() => SvgPicture.asset(
    AppAsset.svg.app.pwLaurelLeft,
    width: 24.w,
    height: 44.w,
    fit: BoxFit.contain,
  );
}

/// The purchase CTA inside the scroll flow — the sticky bottom bar's job,
/// relocated per the design. Same contract as the bar: the button carries the
/// selected plan's total, flips to Retry when the catalogue failed to load,
/// and the renewal caption stays under it because the price a subscription
/// renews at is not information a design pass gets to drop.
class _InlinePurchaseSection extends StatelessWidget {
  final IapState state;
  final VoidCallback onPurchase;
  final VoidCallback onRetry;

  const _InlinePurchaseSection({
    required this.state,
    required this.onPurchase,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final hasProducts = state.iapProducts.isNotEmpty;
    final isBusy = state.status == MonetizationStatus.loading || state.status == MonetizationStatus.purchasing || state.status == MonetizationStatus.restoring;
    final isFailure = state.status == MonetizationStatus.failure && !hasProducts;

    IapProductEntity? selected;
    for (final product in state.iapProducts) {
      if (product.id == state.selectedProductId) selected = product;
    }
    selected ??= state.iapProducts.firstOrNull;

    final price = selected?.price ?? '';
    final label = isFailure
        ? l10n.monetization.retry
        : price.isEmpty
            ? l10n.monetization.paywallCtaUpgrade
            : l10n.monetization.paywallCtaUpgradePrice(price: price);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PurchaseButton(
          label: label,
          busy: state.status == MonetizationStatus.purchasing || state.status == MonetizationStatus.restoring,
          enabled: !isBusy && (hasProducts || isFailure),
          onTap: isFailure ? onRetry : onPurchase,
        ),
        16.verticalSpace,
        _SubscriptionCaption(
          product: selected,
          fallback: hasProducts ? l10n.monetization.paywallHighlightSubtitle : l10n.monetization.emptyProductsDesc,
        ),
      ],
    );
  }
}
