part of '../../../course.dart';

enum StrengthLevel {
  weak,
  morePractice,
  optional,
}

class StrengthIndicatorBadge extends StatelessWidget {
  final StrengthLevel level;

  const StrengthIndicatorBadge({
    super.key,
    required this.level,
  });

  Color get _getBarColor {
    switch (level) {
      case StrengthLevel.weak:
        return AppCustomColor.errorRed;
      case StrengthLevel.morePractice:
        return AppCustomColor.brandPrimary;
      case StrengthLevel.optional:
        return AppCustomColor.successGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24.w,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(
        child: _buildStrengthIcon(),
      ),
    );
  }

  Widget _buildStrengthIcon() {
    final barColor = _getBarColor;
    final int barCount = level == StrengthLevel.weak ? 1 : level == StrengthLevel.morePractice ? 2 : 3;

    return SizedBox(
      width: 16.w,
      height: 16.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bar 1 (shortest)
          Container(
            width: 2.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: barCount >= 1 ? barColor : AppCustomColor.textQuaternary,
              borderRadius: BorderRadius.circular(1.r),
            ),
          ),
          SizedBox(width: 2.w),
          // Bar 2 (medium)
          Container(
            width: 2.w,
            height: 7.h,
            decoration: BoxDecoration(
              color: barCount >= 2 ? barColor : AppCustomColor.textQuaternary,
              borderRadius: BorderRadius.circular(1.r),
            ),
          ),
          SizedBox(width: 2.w),
          // Bar 3 (tallest)
          Container(
            width: 2.w,
            height: 10.h,
            decoration: BoxDecoration(
              color: barCount >= 3 ? barColor : AppCustomColor.darkStroke,
              borderRadius: BorderRadius.circular(1.r),
            ),
          ),
        ],
      ),
    );
  }
}
