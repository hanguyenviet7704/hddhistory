part of '../../monetization.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundBrand,
      body: PaywallPageDecoration(),
      // bottomNavigationBar: PaywallPackageInfo(),
    );
  }
}
