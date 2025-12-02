part of '../../monetization.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  @override
  void initState() {
    super.initState();

    final cubit = context.read<IapCubit>();
    cubit.init();
    cubit.loadIapProducts();
  }

  @override
  void dispose() {
    context.read<IapCubit>().disposeStreamSubscription();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IapCubit, IapState>(
      listenWhen: (previous, current) => previous.status != current.status && current.status == MonetizationStatus.success,
      listener: (context, state) {
        PaywallSuccessPurchasePopup.show(context);
      },
      child: Scaffold(
        backgroundColor: AppCustomColor.backgroundBrand,
        body: Column(
          children: [
            const PaywallPageDecoration(),
            const PaywallHighlightPackageInfo()
          ],
        ),
      ),
    );
  }
}
