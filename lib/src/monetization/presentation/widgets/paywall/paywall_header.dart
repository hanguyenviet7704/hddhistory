part of '../../../monetization.dart';

class PaywallTopBar extends StatelessWidget {
  final VoidCallback? onClose;
  final bool showCloseButton;

  const PaywallTopBar({
    super.key,
    this.onClose,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(width: 36.w, height: 36.w),
        const PremiumPill(),
        showCloseButton
            ? InkWell(
                onTap: onClose == null
                    ? null
                    : () {
                        AppHaptic.select();
                        onClose!();
                      },
                child: SizedBox(
                  width: 36.w,
                  height: 36.w,
                  child: Icon(
                    Icons.close_rounded,
                    color: AppCustomColor.textTertiary,
                    size: 22.w,
                  ),
                ),
              )
            : SizedBox(width: 36.w, height: 36.w),
      ],
    );
  }
}

/// The `MeUp · PREMIUM` lockup from the design: the wordmark in Poppins next to
/// a gradient badge. Was a prerendered PNG (`premiumButton`), which could never
/// match the design's crisp text at every scale and baked the brand colours
/// into a raster. Text + a gradient box IS the design, at any DPI.
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            'MeUp',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 22.sp,
              letterSpacing: -0.7,
              color: AppCustomColor.textBrand,
              height: 1.2,
            ),
          ),
          6.horizontalSpace,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF5851D5), Color(0xFF857EF7)],
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: AppText(
              'PREMIUM',
              style: AppStyle.text12.copyWith(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.44,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
