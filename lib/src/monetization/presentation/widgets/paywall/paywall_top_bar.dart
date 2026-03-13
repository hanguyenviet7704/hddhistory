part of '../../../monetization.dart';

class PaywallTopBar extends StatelessWidget {
  final VoidCallback? onClose;

  const PaywallTopBar({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(width: 36.w, height: 36.w),
        const PremiumPill(),
        InkWell(
          onTap: onClose,
          child: SizedBox(
            width: 36.w,
            height: 36.w,
            child: Icon(
              Icons.close_rounded,
              color: AppCustomColor.textTertiary,
              size: 22.w,
            ),
          ),
        ),
      ],
    );
  }
}

class PremiumPill extends StatelessWidget {
  const PremiumPill({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: !kDebugMode
          ? null
          : () {
              AppDI.injector.get<UserSubscriptionLocalDataSource>().cacheProcessedTransactionIds([]);
              LogDev.one('Processed transaction ids cleared');
            },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Image.asset(
          AppAsset.images.app.premiumButton.path,
          width: 84.w,
          height: 34.h,
        ),
      ),
    );
  }
}
