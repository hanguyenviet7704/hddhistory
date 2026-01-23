part of '../../monetization.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  bool _hasTrackedView = false;

  @override
  void initState() {
    super.initState();

    final cubit = context.read<IapCubit>();
    cubit.init();
    cubit.loadIapProducts();
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackView());
  }

  void _trackView() {
    if (_hasTrackedView) return;
    AppService.instance.appTrackingService.trackPremiumScrView();
    _hasTrackedView = true;
  }

  @override
  void dispose() {
    AppDI.injector.get<IapCubit>().setPaywallEntryPoint(PaywallEntryPoint.other);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundBrand,
      body: BlocListener<IapCubit, IapState>(
        listenWhen: (previous, current) => previous.status != current.status && current.status == MonetizationStatus.purchaseSuccess,
        listener: (context, state) async {
          if (state.lastAction != PurchaseAction.purchase || state.lastOrigin != PurchaseOrigin.paywall) return;
          await PaywallSuccessPurchasePopup.show(context);
          if (!context.mounted) return;
          context.read<IapCubit>().consumePurchaseSuccess();
          context.back();
        },
        child: Column(
          children: [
            const PaywallPageDecoration(),
            const PaywallHighlightPackageInfo()
          ],
        ),
      ),
    );
  }
}
