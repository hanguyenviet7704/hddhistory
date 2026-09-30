part of '../../../monetization.dart';

/// The paywall's dismiss affordance: a translucent white disc floating over the
/// scroll at the top right, as the design draws it.
///
/// It used to be the right-hand cell of a three-cell header row, which pushed
/// the `MeUp PREMIUM` lockup off the screen's centre line (it was centred in the
/// space LEFT OVER beside the button, not on the screen). Floating it takes the
/// button out of the flow entirely, so the lockup centres on the page.
///
/// The tap target is 44 while the disc is 34 — the disc is the drawing, the
/// padding around it is what a thumb actually hits.
class _PaywallCloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PaywallCloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: l10n.common.close,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: SizedBox(
          width: 44.w,
          height: 44.w,
          child: Center(
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppCustomColor.textBrand.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.close_rounded,
                color: const Color(0xFF7A6E4F),
                size: 19.w,
              ),
            ),
          ),
        ),
      ),
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
                colors: [Color(0xFF937424), Color(0xFFF3BF3B)],
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
