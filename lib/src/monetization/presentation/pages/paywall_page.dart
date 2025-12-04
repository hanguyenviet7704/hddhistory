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
    AppDI.injector.get<IapCubit>().disposeStreamSubscription();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundBrand,
      body: Column(
        children: [
          const PaywallPageDecoration(),
          const PaywallHighlightPackageInfo()
        ],
      ),
    );
  }
}
