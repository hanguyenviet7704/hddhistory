part of '../monetization.dart';

class PremiumPaywallPage extends StatefulWidget {
  const PremiumPaywallPage({
    super.key,
  });

  @override
  State<PremiumPaywallPage> createState() => _PremiumPaywallPageState();
}

class _PremiumPaywallPageState extends State<PremiumPaywallPage> {
  @override
  void initState() {
    context.read<IAPCubit>().init();
    super.initState();
  }

  @override
  void dispose() {
    AppConfig.instance.context?.read<IAPCubit>().disposeStreamSubscription();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.black23,
      body: BlocSelector<IAPCubit, IAPState, bool>(
        selector: (state) => state.isLoading,
        builder: (context, isLoading) {
          return SafeArea(
            top: false,
            child: Row(
              children: [
                PremiumPaywallContent(),
                PremiumPaywallDecoration(),
              ],
            ),
          );
        },
      ),
    );
  }
}
