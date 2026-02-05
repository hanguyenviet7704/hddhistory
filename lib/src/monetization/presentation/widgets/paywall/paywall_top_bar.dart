part of '../../../monetization.dart';

class PaywallTopBar extends StatelessWidget {
  final VoidCallback? onClose;

  const PaywallTopBar({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(width: 40.w),
        PremiumPill(),
        InkWell(
          onTap: onClose,
          child: SizedBox(
            width: 40.w,
            height: 40.w,
            child: Icon(
              Icons.close_rounded,
              color: AppCustomColor.textTertiary,
              size: 24.w,
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppCustomColor.brandPrimary,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppCustomColor.backgroundWhite),
        boxShadow: [
          BoxShadow(
            color: AppCustomColor.borderDefault.withValues(alpha: 0.8),
            blurRadius: 4,
          ),
        ],
      ),
      child: AppText(
        t.monetization.premiumBadge,
        onTap: !kDebugMode
            ? null
            : () {
                AppDI.injector.get<UserSubscriptionLocalDataSource>().cacheProcessedTransactionIds([]);
                LogDev.one('Processed transaction ids cleared');
              },
        style: AppStyle.text12.copyWith(
          fontWeight: FontWeight.w600,
          color: AppCustomColor.textWhite,
        ),
      ),
    );
  }
}
