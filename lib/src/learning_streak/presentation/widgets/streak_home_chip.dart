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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundGray,
          borderRadius: BorderRadius.circular(50.r),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              offset: Offset(0, 1),
              blurRadius: 1.5,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              '$currentStreak',
              style: AppStyle.text14.copyWith(
                color: AppCustomColor.brandPrimary700,
                fontWeight: FontWeight.w700,
              ),
            ),
            4.horizontalSpace,
            SvgPicture.asset(
              AppAsset.svg.app.icFlameActive,
              width: 24.r,
              height: 24.r,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
