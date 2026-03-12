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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF362F82),
            Color(0xFF4B44CA),
          ],
        ),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppCustomColor.backgroundWhite),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D453EB4),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            t.monetization.premiumBadge,
            onTap: !kDebugMode
                ? null
                : () {
                    AppDI.injector.get<UserSubscriptionLocalDataSource>().cacheProcessedTransactionIds([]);
                    LogDev.one('Processed transaction ids cleared');
                  },
            style: AppStyle.text14.copyWith(
              fontWeight: FontWeight.w700,
              color: AppCustomColor.textWhite,
              height: 1.75,
            ),
          ),
          2.horizontalSpace,
          Icon(
            Icons.star_rounded,
            color: AppCustomColor.textWhite,
            size: 10.w,
          ),
        ],
      ),
    );
  }
}
