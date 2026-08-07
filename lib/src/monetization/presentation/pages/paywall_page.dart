part of '../../monetization.dart';

@visibleForTesting
const paywallCloseButtonDelay = Duration(seconds: 2);

@visibleForTesting
bool shouldHandlePaywallSuccess({
  required PurchaseAction action,
  required PurchaseOrigin origin,
}) {
  return origin == PurchaseOrigin.paywall && action == PurchaseAction.purchase;
}

@visibleForTesting
bool shouldDelayPaywallCloseButton() => true;

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  bool _hasTrackedView = false;
  bool _isHandlingPurchaseSuccess = false;
  bool _hasShownGiftCampaign = false;
  late bool _isCloseButtonVisible;
  Timer? _closeButtonTimer;

  @override
  void initState() {
    super.initState();

    _isCloseButtonVisible = !shouldDelayPaywallCloseButton();
    if (!_isCloseButtonVisible) {
      _closeButtonTimer = Timer(paywallCloseButtonDelay, _showCloseButton);
    }

    final cubit = context.read<IapCubit>();
    cubit.init();
    cubit.loadIapProducts();
  }

  void _trackValidRender(IapState state) {
    if (_hasTrackedView) return;
    if (state.status != MonetizationStatus.success || state.iapProducts.isEmpty) return;

    _hasTrackedView = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<IapCubit>().recordPaywallRenderedImpression();
    });
    AppService.instance.appTrackingService.trackPremiumScrView();
  }

  void _showCloseButton() {
    if (!mounted || _isCloseButtonVisible) return;
    setState(() {
      _isCloseButtonVisible = true;
    });
  }

  /// Runs the two-step gift flow (popup → sheet → purchase) at most once per
  /// paywall open, and only when everything it needs is real: a campaign the
  /// parser accepted, a window that contains now, and a loaded store product
  /// matching the campaign's SKU for this platform. Each step is a question the
  /// reader answers; declining any of them ends the flow with no side effects.
  void _maybeShowGiftCampaign(IapState state) {
    if (_hasShownGiftCampaign) return;
    if (state.status != MonetizationStatus.success || state.iapProducts.isEmpty) return;

    final campaign = context.read<IapCubit>().resolvedPaywallConfig.giftCampaign;
    if (campaign == null) return;

    // Both bounds are required: an open-ended discount is a price change, not
    // a campaign, and someone would eventually have to explain the "33% OFF"
    // that never ends.
    final start = DateTime.tryParse(campaign.startAtUtc ?? '');
    final end = DateTime.tryParse(campaign.endAtUtc ?? '');
    final now = DateTime.now().toUtc();
    if (start == null || end == null) return;
    if (now.isBefore(start.toUtc()) || now.isAfter(end.toUtc())) return;

    // The campaign names SKUs; the purchase needs the loaded product. No match
    // (not approved yet, wrong platform id) means no gift — the sheet must
    // never open with a Claim button that cannot charge.
    final platform = PaymentPlatform.fromDevicePlatform;
    final skuIds = campaign.products
        .map(
          (ref) => switch (platform) {
            PaymentPlatform.apple => ref.appleProductId,
            PaymentPlatform.google || PaymentPlatform.unknown => ref.googleProductId,
          },
        )
        .where((id) => id.trim().isNotEmpty)
        .toSet();
    IapProductEntity? product;
    for (final candidate in state.iapProducts) {
      if (skuIds.contains(candidate.productId)) {
        product = candidate;
        break;
      }
    }
    if (product == null) return;

    _hasShownGiftCampaign = true;
    final giftProduct = product;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final opened = await PaywallGiftPopup.show(context, campaign: campaign);
      if (!mounted || !opened) return;

      final claimed = await PaywallGiftSheet.show(
        context,
        campaign: campaign,
        originalPriceLabel: giftProduct.hasCompareAtPrice ? giftProduct.compareAtPrice : null,
        offerPriceLabel: giftProduct.price,
      );
      if (!mounted || !claimed) return;

      final cubit = context.read<IapCubit>();
      cubit.setSelectedProductId(giftProduct.id);
      AppService.instance.appTrackingService.trackPremiumPurchase(
        productId: giftProduct.productId,
        price: giftProduct.price,
      );
      cubit.purchaseProduct();
    });
  }

  Future<void> _handleClose() async {
    AppService.instance.appTrackingService.trackPremiumScrExit();
    if (!mounted) return;
    context.pop();
  }

  Future<void> _handlePurchaseSuccess() async {
    if (_isHandlingPurchaseSuccess) return;
    _isHandlingPurchaseSuccess = true;

    try {
      AppService.instance.appTrackingService.trackPaywallSuccessPopupView(
        context.read<IapCubit>().state.selectedProductId,
      );
      await PaywallSuccessPurchasePopup.show(context);
      if (!mounted) return;

      context.read<IapCubit>().consumePurchaseSuccess();
      if (!mounted) return;
      context.pop();
    } finally {
      _isHandlingPurchaseSuccess = false;
    }
  }

  @override
  void dispose() {
    _closeButtonTimer?.cancel();
    AppDI.injector.get<IapCubit>().resetPaywallEntryPoint();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE0DEFC),
              Color(0xFFF6F6FE),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: BlocConsumer<IapCubit, IapState>(
            listenWhen: (previous, current) => previous.status != current.status && current.status == MonetizationStatus.purchaseSuccess,
            listener: (context, state) async {
              if (!shouldHandlePaywallSuccess(
                action: state.lastAction,
                origin: state.lastOrigin,
              )) {
                return;
              }
              await _handlePurchaseSuccess();
            },
            builder: (context, state) {
              _trackValidRender(state);

              // "Rút gọn" in the admin's entry-point table means THIS surface:
              // the sheet-style single-plan paywall, not the full page with a
              // shorter list. The gift popup is skipped here — two sheets
              // stacked on one entry point would fight for the same gesture.
              if (state.resolvedPaywallStrategy?.variant == PaywallProductVariant.compact) {
                return _PaywallCompactBody(
                  state: state,
                  onClose: _handleClose,
                  onPurchase: () {
                    final product = state.selectedProduct;
                    AppService.instance.appTrackingService.trackPremiumPurchase(
                      productId: product.productId,
                      price: product.price,
                    );
                    context.read<IapCubit>().purchaseProduct();
                  },
                );
              }

              _maybeShowGiftCampaign(state);
              return Stack(
                children: [
                  Positioned.fill(
                    child: PaywallPageDecoration(
                      state: state,
                      bottomPadding: PaywallBottomPurchaseBar.totalReservedHeight(context, state),
                      onClose: _handleClose,
                      showCloseButton: _isCloseButtonVisible,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: PaywallBottomPurchaseBar(
                      state: state,
                      onPurchase: () {
                        final product = state.selectedProduct;
                        AppService.instance.appTrackingService.trackPremiumPurchase(
                          productId: product.productId,
                          price: product.price,
                        );
                        context.read<IapCubit>().purchaseProduct();
                      },
                      onRetry: () => context.read<IapCubit>().loadIapProducts(forceRetry: true),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
