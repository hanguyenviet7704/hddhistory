part of '../../monetization.dart';

enum PaywallFlowAction { close, purchaseSuccess }

enum PaywallFlowDestination { back, course }

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
bool shouldDelayPaywallCloseButton({required bool firstTimeUserFlow}) => firstTimeUserFlow;

@visibleForTesting
PaywallFlowDestination resolvePaywallFlowDestination({
  required bool firstTimeUserFlow,
  required PaywallFlowAction action,
}) {
  if (!firstTimeUserFlow) {
    return PaywallFlowDestination.back;
  }

  switch (action) {
    case PaywallFlowAction.close:
    case PaywallFlowAction.purchaseSuccess:
      return PaywallFlowDestination.course;
  }
}

class PaywallPage extends StatefulWidget {
  final bool firstTimeUserFlow;

  const PaywallPage({
    super.key,
    this.firstTimeUserFlow = false,
  });

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

    _isCloseButtonVisible = !shouldDelayPaywallCloseButton(
      firstTimeUserFlow: widget.firstTimeUserFlow,
    );
    if (!_isCloseButtonVisible) {
      _closeButtonTimer = Timer(paywallCloseButtonDelay, _showCloseButton);
    }

    final cubit = context.read<IapCubit>();
    cubit.init();
    if (widget.firstTimeUserFlow) {
      cubit.setPaywallEntryPoint(PaywallEntryPoint.firstTimeUser);
    }
    cubit.loadIapProducts();
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackView());
  }

  void _trackView() {
    if (_hasTrackedView) return;
    AppService.instance.appTrackingService.trackPremiumScrView();
    _hasTrackedView = true;
  }

  void _showCloseButton() {
    if (!mounted || _isCloseButtonVisible) return;
    setState(() {
      _isCloseButtonVisible = true;
    });
  }

  Future<void> _handleClose() async {
    AppService.instance.appTrackingService.trackPremiumScrExit();
    await _navigateAfterFlowAction(PaywallFlowAction.close);
  }

  Future<void> _handlePurchaseSuccess() async {
    if (_isHandlingPurchaseSuccess) return;
    _isHandlingPurchaseSuccess = true;

    try {
      await PaywallSuccessPurchasePopup.show(context);
      if (!mounted) return;

      context.read<IapCubit>().consumePurchaseSuccess();
      await _navigateAfterFlowAction(PaywallFlowAction.purchaseSuccess);
    } finally {
      _isHandlingPurchaseSuccess = false;
    }
  }

  Future<void> _navigateAfterFlowAction(PaywallFlowAction action) async {
    final destination = resolvePaywallFlowDestination(
      firstTimeUserFlow: widget.firstTimeUserFlow,
      action: action,
    );

    switch (destination) {
      case PaywallFlowDestination.back:
        if (!mounted) return;
        context.back();
        return;
      case PaywallFlowDestination.course:
        await _goToFirstTimeCourse();
        return;
    }
  }

  Future<void> _goToFirstTimeCourse() async {
    final homeCubit = AppDI.injector.get<HomeCubit>();
    await homeCubit.initializeData(isInit: true);
    homeCubit.resetSelection(skillsetIndex: 0);
    if (!mounted) return;
    CourseRoute(selectedTabIndex: 0).go(context);
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
          child: BlocListener<IapCubit, IapState>(
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
            child: Column(
              children: [
                PaywallPageDecoration(
                  onClose: _handleClose,
                  showCloseButton: _isCloseButtonVisible,
                ),
                const PaywallHighlightPackageInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
