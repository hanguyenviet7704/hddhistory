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
  late bool _isCloseButtonVisible;
  Timer? _closeButtonTimer;

  /// The compact sheet's countdown deadline, per reader. Resolved here rather
  /// than in the sheet because it needs storage (an async read) and the sheet
  /// builds synchronously; null until it lands, which simply renders no clock
  /// for that first frame.
  DateTime? _compactCountdownEndAt;

  @override
  void initState() {
    super.initState();
    unawaited(_resolveCompactCountdown());

    _isCloseButtonVisible = !shouldDelayPaywallCloseButton();
    if (!_isCloseButtonVisible) {
      _closeButtonTimer = Timer(paywallCloseButtonDelay, _showCloseButton);
    }

    final cubit = context.read<IapCubit>();
    cubit.init();
    cubit.loadIapProducts();
  }

  Future<void> _resolveCompactCountdown() async {
    final endAt = await AppDI.injector.get<CompactCountdownSchedule>().resolveDeadline();
    if (!mounted) return;
    setState(() => _compactCountdownEndAt = endAt);
  }

  /// Whether this open renders the compact 33%-off sheet — the same condition
  /// the builder branches on.
  bool get _isCompactVariant {
    final cubit = AppDI.injector.get<IapCubit>();
    return cubit.state.resolvedPaywallStrategy?.variant == PaywallProductVariant.compact || cubit.paywallForcedCompact;
  }

  /// The plan the compact sheet actually shows — id-match-then-first, the same
  /// resolution [_PaywallCompactBody] uses (`state.selectedProduct` answers for
  /// the FULL list and can be empty/wrong here).
  IapProductEntity? _compactProduct(IapState state) {
    for (final candidate in state.iapProducts) {
      if (candidate.id == state.selectedProductId) return candidate;
    }
    return state.iapProducts.firstOrNull;
  }

  void _trackValidRender(IapState state) {
    if (_hasTrackedView) return;
    if (state.status != MonetizationStatus.success || state.iapProducts.isEmpty) return;

    _hasTrackedView = true;
    // The sheet's "new" tab treats the compact sheet as its own screen
    // ("33% off bottom sheet"): it reports paywall_offer_scr_view, not
    // paywall_scr_view.
    if (_isCompactVariant) {
      PaywallTracking.offerScrView(productId: _compactProduct(state)?.productId ?? '');
      return;
    }
    AppService.instance.appTrackingService.trackPremiumScrView();
  }

  void _showCloseButton() {
    if (!mounted || _isCloseButtonVisible) return;
    setState(() {
      _isCloseButtonVisible = true;
    });
  }

  Future<void> _handleClose() async {
    // Same screen split as the view event: the compact sheet's X is
    // paywall_offer_close_click ("never see again"), the full page's is
    // paywall_close_click.
    if (_isCompactVariant) {
      PaywallTracking.offerCloseClick();
    } else {
      AppService.instance.appTrackingService.trackPremiumScrExit();
    }
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
              if (state.resolvedPaywallStrategy?.variant == PaywallProductVariant.compact || context.read<IapCubit>().paywallForcedCompact) {
                return _PaywallCompactBody(
                  state: state,
                  countdownEndAt: _compactCountdownEndAt,
                  onClose: _handleClose,
                  onPurchase: () {
                    // The sheet's CTA is paywall_offer_claim_click, and the
                    // SKU it reports is the one the sheet resolved for itself
                    // — `state.selectedProduct` answers for the FULL list and
                    // could name a different plan for one frame.
                    final product = _compactProduct(state);
                    PaywallTracking.offerClaimClick(productId: product?.productId ?? '');
                    context.read<IapCubit>().purchaseProduct();
                  },
                );
              }

              // The CTA rides inside the scroll flow now (design), so no
              // sticky bar and no reserved height — just breathing room under
              // the legal links.
              return PaywallPageDecoration(
                state: state,
                bottomPadding: 24.h + MediaQuery.paddingOf(context).bottom,
                onClose: _handleClose,
                showCloseButton: _isCloseButtonVisible,
                onPurchase: () {
                  final product = state.selectedProduct;
                  AppService.instance.appTrackingService.trackPremiumPurchase(
                    productId: product.productId,
                    price: product.price,
                  );
                  context.read<IapCubit>().purchaseProduct();
                },
                onRetry: () => context.read<IapCubit>().loadIapProducts(forceRetry: true),
              );
            },
          ),
        ),
      ),
    );
  }
}
