part of '../../monetization.dart';

@visibleForTesting
const paywallCloseButtonDelay = Duration(seconds: 5);

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

  Future<void> _handleClose() async {
    AppService.instance.appTrackingService.trackPremiumScrExit();
    if (!mounted) return;
    context.pop();
  }

  Future<void> _handlePurchaseSuccess() async {
    if (_isHandlingPurchaseSuccess) return;
    _isHandlingPurchaseSuccess = true;

    try {
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
                        AppService.instance.appTrackingService.trackPremiumPurchase();
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
