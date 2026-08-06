part of '../../learning_streak.dart';

class StreakHomeChip extends StatelessWidget {
  const StreakHomeChip({
    super.key,
    required this.currentStreak,
    this.onTap,
  });

  final int currentStreak;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              AppHaptic.select();
              onTap!();
            },
      child: Container(
        height: 28.h,
        // Asymmetric per the design: the flame glyph carries its own left
        // bearing, so a matching 9px on both sides would read as off-centre.
        padding: EdgeInsets.only(left: 6.w, right: 9.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7FA),
          borderRadius: BorderRadius.circular(99.r),
          // The design draws the hairline as `inset 0 0 0 1px rgba(255,255,255,.9)`,
          // which Flutter has no equivalent for — a 1px white border is the same
          // pixel result on this fill. Matches ChangeBackgroundButton beside it.
          border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
          boxShadow: [
            BoxShadow(
              color: const Color(0x24252525), // rgba(37,37,37,.14)
              offset: Offset(0, 4.h),
              blurRadius: 10.r,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flame first, count second — the design reversed the old order.
            SvgPicture.asset(
              AppAsset.svg.app.icFlameActive,
              width: 20.r,
              height: 20.r,
              fit: BoxFit.contain,
            ),
            3.horizontalSpace,
            AppText(
              '$currentStreak',
              style: TextStyle(
                fontFamily: AppFont.mulish,
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: AppCustomColor.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
