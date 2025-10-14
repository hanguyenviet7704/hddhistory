part of '../monetization.dart';

class PremiumPaywallDecoration extends StatelessWidget {
  const PremiumPaywallDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Column(
        children: [
          PremiumFeedbackDecoration(),
          Expanded(
            child: Lottie.asset(
              AppAsset.lottie.premiumPaywallDecoration,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              renderCache: RenderCache.drawingCommands,
              repeat: true,
              // animate: true,
              // reverse: true,
            ),
          ),
        ],
      ),
    );
  }
}
