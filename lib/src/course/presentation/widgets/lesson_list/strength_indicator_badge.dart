part of '../../../course.dart';

class StrengthIndicatorBadge extends StatelessWidget {
  final StrengthLevel level;

  const StrengthIndicatorBadge({
    super.key,
    required this.level,
  });

  Color get _getBarColor {
    switch (level) {
      case StrengthLevel.weakPoint:
        return AppCustomColor.errorRed;
      case StrengthLevel.morePractice:
        return AppCustomColor.brandPrimary;
      case StrengthLevel.optionalPractice:
        return AppCustomColor.successGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final barColor = _getBarColor;
    final int barCount = level == StrengthLevel.weakPoint
        ? 1
        : level == StrengthLevel.morePractice
        ? 2
        : 3;

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
          2.horizontalSpace,
          // Bar 2 (medium)
          Container(
            width: 2.w,
            height: 7.h,
            decoration: BoxDecoration(
              color: barCount >= 2 ? barColor : AppCustomColor.textQuaternary,
              borderRadius: BorderRadius.circular(1.r),
            ),
          ),
          2.horizontalSpace,
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
