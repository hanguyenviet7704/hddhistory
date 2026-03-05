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
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 6.h, 12.w, 6.h),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(50.r),
          border: Border.all(color: AppCustomColor.borderDefault, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppAsset.icons.common.flame.image(width: 20.w, height: 20.w),
            4.horizontalSpace,
            AppText(
              '$currentStreak',
              style: AppStyle.text14.copyWith(
                color: AppCustomColor.brandPrimary700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
